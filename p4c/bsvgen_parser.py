# Copyright (c) 2016 P4FPGA Project
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

import astbsv as ast
import config
import bsvgen_common
import logging
from ast_util import ParseState
from bsvgen_common import build_funct_dbg3
from sourceCodeBuilder import SourceCodeBuilder
from utils import CamelCase, camelCase, GetFieldWidth
from utils import GetHeaderInState, GetHeaderType, GetHeaderWidth
from utils import GetExpressionInState, GetTransitionKey, GetHeaderWidthInState
from utils import GetState
from ast_util import apply_pdict, apply_action_block, apply_if_verbosity

logger = logging.getLogger(__name__)

class Parser(object):
    # proper use of parser class constant?
    def __init__(self, states):
        # tmp var for code generation
        self.mutex_rules = {}
        self.transition_rules = {}
        self.pulse_wires = set()
        self.dwires = set()
        self.regs = set()
        self.cregs = set()

        self.states = states
        self.initial_state = "start"

    def build_funct_push_phv(self, phv):
        TMP1 = "MetadataT meta = defaultValue;"
        TMP2 = "meta.%(field)s = tagged Valid rg_tmp_%(field)s;"
        TMP3 = "meta_in_ff.enq(meta);"
        params = "ParserState ty"
        stmt = []
        stmt.append(ast.Template(TMP1))
        for _, p in phv:
            stmt.append(ast.Template(TMP2, {"field": p}))
        stmt.append(ast.Template(TMP3))
        ablock = apply_action_block(stmt)
        funct = ast.Function("push_phv", 'Action', params, ablock)
        return funct

    def build_funct_transition(self):
        def build_transition(name, transition):
            TMP1 = "w_%(curr_state)s_%(next_state)s.send();"
            key = transition['value'].replace("0x", "'h")
            if transition['mask'] is not None:
                mask = transition['mask'].replace("0x", "'h")
            else:
                mask = None
            next_state = transition['next_state']
            next_name = "%s" % (next_state) if next_state != None else self.initial_state
            stmt = []
            stmt.append(ast.Template("dbg3($format(\"transit to %s\"));", next_name))
            stmt.append(ast.Template(TMP1 % {'curr_state': name, 'next_state': next_name}))
            return key, mask, stmt

        def build_funct(name, parameters, transition):
            ab_stmt = []

            if len(parameters) == 0 or (len(parameters) == 1 and transition[0]['value'] == 'start'):
                for t in transition:
                    _, _, _stmt = build_transition(name, t)
                    ab_stmt += _stmt
            else:
                key_stmt = ast.Template("let v = {%s};" % (", ".join([p[1] for p in parameters])))
                ab_stmt.append(key_stmt)
                for idx, t in enumerate(transition):
                    _value, _mask, _stmt = build_transition(name, t)
                    expr = "(v & %s) == %s" % (_mask, _value) if _mask != None else "v == %s" % (_value)
                    if _value == 'start' or _value == 'default':
                        ab_stmt.append(ast.Else(_stmt))
                    else:
                        if idx == 0:
                            ab_stmt.append(ast.If(expr, _stmt))
                        else:
                            ab_stmt.append(ast.ElseIf(expr, _stmt))
            stmt = apply_action_block(ab_stmt)
            params = ', '.join(["Bit#(%s) %s" % (p[0], p[1]) for p in parameters])
            f = ast.Function("compute_next_state_%s"%(name), 'Action', params, stmt)
            return f

        def build_param(state):
            param = []
            for k in state.transition_keys:
                if k['type'] == 'lookahead':
                    value = k
                    width = k['value'][1] - k['value'][0]
                    param.append((width, 'current'))
                else:
                    param.append((k['width'], k['value'][1]))
            return param

        funct = []
        funct.append(ast.Template("\n"))
        funct.append(ast.Template("`ifdef PARSER_FUNCTION\n"))
        for _, s in self.states.items():
            if s.name == self.initial_state:
                continue
            params = build_param(s)
            funct.append(build_funct(s.name, params, s.transitions))
        funct.append(ast.Template("`endif // PARSER_FUNCTION\n"))
        return funct

    def build_rule_state_load(self, state):
        tmpl = []
        tmpl.append("data_ff.deq;")
        tmpl.append("let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];")
        tmpl.append("rg_tmp[0] <= zeroExtend(data);")
        tmpl.append("move_shift_amt(%d);" % (config.DP_WIDTH))
        pdict = {}
        pdict['name'] = state.name
        pdict['CurrState'] = 'State%s' % (CamelCase(state.name))
        pdict['len'] = state.len
        stmt = apply_pdict(tmpl, pdict)
        expr = "isValid(data_ff.first)"
        ifstmt = []
        ifstmt.append(ast.Template("report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);"))
        ifstmt.append(ast.If(expr, stmt))
        rcond = '(parse_state_ff.first == %(CurrState)s) && (rg_buffered[0] < %(len)s)' % pdict
        attr = ['fire_when_enabled']
        rule = ast.Rule('rl_%(name)s_load' % pdict, rcond, ifstmt, attr)
        return [rule]

    def build_rule_state_extract(self, state):
        tmpl = []
        tmpl.append("let data = rg_tmp[0];")
        tmpl.append("if (isValid(data_ff.first)) begin")
        tmpl.append("  data_ff.deq;")
        tmpl.append("  data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];")
        tmpl.append("end")
        tmpl.append("report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);")
        TMP = "let %(ktype)s = extract_%(ktype)s(truncate(data));"
        tmpl2 = []
        tmpl2.append("compute_next_state_%(name)s(%(field)s);")
        tmpl2.append("rg_tmp[0] <= zeroExtend(data >> %(len)s);")
        tmpl2.append("succeed_and_next(%(len)s);")
        tmpl2.append("dbg3($format(\"extract %%s\", \"%(name)s\"));")
        tmpl2.append("parse_state_ff.deq;")

        pdict = {}
        pdict['name'] = state.name
        pdict['CurrState'] = 'State%s' % (CamelCase(state.name))
        pdict['len'] = state.len
        keys = []
        pdict['ktype'] = set()
        for k in state.transition_keys:
            if k['type'] == 'lookahead':
                print "WARNING: lookahead type not handled"
                continue
            keys.append("%s.%s" % (GetHeaderType(k['value'][0]), k['value'][1]))
            pdict['ktype'].add(GetHeaderType(k['value'][0]))
        pdict['field'] = ",".join(keys)


        stmt = apply_pdict(tmpl, pdict)
        for ktype in pdict['ktype']:
            stmt += [ast.Template(TMP, {'ktype': ktype})]
        stmt += apply_pdict(tmpl2, pdict)

        # build expression
        setexpr = GetExpressionInState(state.name)
        if setexpr[2] != None and setexpr[1] != None:
            dst = "".join(setexpr[1])+"[0]"
            src = "".join(setexpr[2])
            stmt += [ast.Template(dst + " <= " + src.replace("0x", "'h") + ";")]

        rcond = '(parse_state_ff.first == %(CurrState)s) && (rg_buffered[0] >= %(len)s)' % pdict
        rname = 'rl_%(name)s_extract' % pdict
        attr = ['fire_when_enabled']
        rule = ast.Rule(rname, rcond, stmt, attr)
        return [rule]

    def build_mutually_exclusive_attribute(self, state):
        attribute = []
        stmt = []
        for s in state.transitions:
            next_state_name = s['next_state']
            if next_state_name is None:
                next_state_name = self.initial_state
            rname = 'rl_%s_%s' % (state.name, next_state_name)
            attribute.append(rname)
        TMP="(* mutually_exclusive=\"{}\" *)".format(", ".join(attribute))
        stmt.append(ast.Template(TMP))
        return stmt

    def build_rule_state_transitions(self, cregIdx, state):
        def build_rule_state_transition(cregIdx, state, next_state):
            # forward transition
            tmpl_forward_flow = []
            tmpl_forward_flow.append("parse_state_ff.enq(%(NextState)s);")
            tmpl_forward_flow.append("dbg3($format(\"%%s -> %%s\", \"%(name)s\", \"%(next_state)s\"));")
            tmpl_forward_flow.append("fetch_next_header%(cregIdx)s(%(length)s);")

            # back to start
            tmpl_to_start = []
            tmpl_to_start.append("parse_done[0] <= True;")
            tmpl_to_start.append("w_parse_done.send();")
            tmpl_to_start.append("dbg3($format(\"%%s -> %%s\", \"%(name)s\", \"%(next_state)s\"));")
            tmpl_to_start.append("fetch_next_header%(cregIdx)s(0);")

            # transition with lookahead
            tmpl_lookahead = []
            tmpl_lookahead.append("Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);")
            tmpl_lookahead.append("Bit#(%(lookahead)s) lookahead = pack(takeAt(0, buffer));")
            tmpl_lookahead.append("dbg3($format(\"look ahead %%h, %%h\", lookahead, rg_tmp[1]));")
            tmpl_lookahead.append("compute_next_state_%(next_state)s(%(field)s);")
            tmpl_lookahead.append("dbg3($format(\"counter\", %(field)s ));")
            tmpl_lookahead.append("dbg3($format(\"%%s -> %%s\", \"%(name)s\", \"%(next_state)s\"));")
            tmpl_lookahead.append('fetch_next_header%(cregIdx)s(0);')

            pdict = {}
            pdict['name'] = state.name
            pdict['CurrState'] = "State%s" % (CamelCase(state.name))
            pdict['next_state'] = next_state.name
            pdict['NextState'] = "State%s" % (CamelCase(next_state.name))
            pdict['length'] = GetHeaderWidthInState(next_state.name)
            pdict['cregIdx'] = cregIdx
            pdict['lookahead'] = 8 #FIXME
            keys = []
            for k in next_state.transition_keys:
                if k['type'] == 'lookahead':
                    keys.append("lookahead")
                else:
                    keys.append("%s$%s[1]" % (k['value'][0], k['value'][1]))
            pdict['field'] = ", ".join(keys)

            #print state.name, state.state_type
            if next_state.id == 0:
                stmt = apply_pdict(tmpl_to_start, pdict)
            elif state.id > next_state.id and state.state_type == ParseState.EMPTY:
                stmt = apply_pdict(tmpl_lookahead, pdict)
            elif next_state.state_type == ParseState.EMPTY:
                stmt = apply_pdict(tmpl_lookahead, pdict)
            else:
                stmt = apply_pdict(tmpl_forward_flow, pdict)
            rname = 'rl_%(name)s_%(next_state)s' % pdict
            rcond = "(w_%(name)s_%(next_state)s)" % pdict
            rule = ast.Rule(rname, rcond, stmt)
            # 
            wname = "w_%s_%s" % (state.name, next_state.name)
            self.pulse_wires.add(wname)
            return rule
        rules = []

        for s in state.transitions:
            # ugly, from name to state object
            next_state_name = s['next_state']
            if next_state_name is None:
                next_state_name = self.initial_state
            print next_state_name
            state_dict = GetState(next_state_name)
            state_id = state_dict['id']
            next_state = self.states[state_id]
            rules.append(build_rule_state_transition(cregIdx, state, next_state))
        return rules

    def build_reg(self, phv):
        TMP1 = "Reg#(Bit#(%(sz)s)) rg_tmp_%(name)s <- mkReg(0);"
        stmt = []
        for state, parse_steps in self.rules.items():
            for rule in parse_steps:
                rcvdlen = rule.rcvdlen
                last = rule.lastBeat
                if last:
                    stmt.append(ast.Template(TMP1, {'sz': rcvdlen, 'name': state}))

        for sz, name in phv:
            stmt.append(ast.Template(TMP1, {'sz': sz, 'name': name}))

        return stmt

    def build_phv(self):
        metadata = set()
        fields = []
        for it in config.ir.basic_blocks.values():
            for f in it.request.members:
                if f not in metadata:
                    width = GetFieldWidth(f)
                    name = "$".join(f)
                    fields.append((width, name))
                    metadata.add(f)
        for f in config.ir.controls.values():
            for _, v in f.tables.items():
                for k in v.key:
                    d = tuple(k['target'])
                    if d not in metadata:
                        width = GetFieldWidth(k['target'])
                        name = "$".join(k['target'])
                        fields.append((width, name))
                        metadata.add(d)
        #for it in config.ir.parsers.values():
        #    for h in it.header_instances.values():
        #        name = "valid_%s" % (camelCase(h))
        #        fields.append((0, name))
        return fields

    def build_rules(self):
        self.decide_default_state()
        stmt = []
        stmt.append(ast.Template("\n"))
        stmt.append(ast.Template("`ifdef PARSER_RULES\n"))
        for idx, s in enumerate(self.states.values()):
            if s.state_type == ParseState.REGULAR:
                stmt += self.build_rule_state_load(s)
                stmt += self.build_rule_state_extract(s)
                stmt += self.build_mutually_exclusive_attribute(s)
                stmt += self.build_rule_state_transitions(0, s)
            else:
                print s.state_type
                stmt += self.build_rule_state_transitions(1, s)
        stmt.append(ast.Template("`endif // PARSER_RULES\n"))
        return stmt

    def build_states(self):
        stmt = []
        # fill in missing registers
        for reg in self.regs:
            stmt.insert(0, ast.Template("Reg#(%s) %s <- mkReg(%s);\n"% (reg[0], reg[1], reg[2])))
        for reg in self.cregs:
            stmt.insert(0, ast.Template("Reg#(%s) %s[%d] <- mkCReg(%d, %s);\n" % (reg[0], reg[1], reg[2], reg[2], reg[3])))
        for wire in self.pulse_wires:
            stmt.insert(0, ast.Template("PulseWire %(name)s <- mkPulseWireOR();\n", {'name': wire}))
        for wire in self.dwires:
            stmt.insert(0, ast.Template("Wire#(Bit#(%(width)s)) %(name)s <- mkDWire(0);\n", {'name': wire[0], 'width': wire[1]}))

        return stmt

    def decide_default_state(self):
        def first_state_has_no_extract(idx, s):
            return (idx==0) and (s.parse_ops==[])
        for idx, s in enumerate(self.states.values()):
            if first_state_has_no_extract(idx, s):
                self.initial_state = s.name
            else:
                self.initial_state = "start"

    def buildTypes(self):
        stmt = []
        stmt.append(ast.Template("\n"))
        stmt.append(ast.Template("`ifdef PARSER_STRUCT\n"))
        elem = []
        if self.initial_state == 'default':
            elem.append(ast.EnumElement("StateDefault", None, None))
        for s in self.states.values():
            elem.append(ast.EnumElement("State%s" % (CamelCase(s.name)), None, None))
        state = ast.Enum("ParserState", elem)
        stmt.append(state)
        stmt.append(ast.Template("`endif //PARSER_STRUCT\n"))
        return stmt

    def emit(self, builder):
        self.decide_default_state()
        for s in self.buildTypes():
            s.emit(builder)
        for s in self.build_funct_transition():
            s.emit(builder)
        for s in self.build_states():
            s.emit(builder)
        for s in self.build_rules():
            s.emit(builder)

