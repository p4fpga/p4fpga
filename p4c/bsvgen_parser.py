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
from bsvgen_common import build_funct_dbg3
from sourceCodeBuilder import SourceCodeBuilder
from utils import CamelCase, camelCase, GetFieldWidth
from utils import GetHeaderInState, GetHeaderType, GetHeaderWidth
from utils import GetExpressionInState, GetTransitionKey, GetHeaderWidthInState
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

        self.states = states
        self.initial_state = "default"

    def emitInterface(self, builder):
        logger.info("emitParser")
        TMP1 = "Put#(EtherData)"
        TMP2 = "Get#(MetadataT)"
        TMP3 = "Put#(int)"
        TMP4 = "ParserPerfRec"
        intf = ast.Interface(typedef="Parser")
        intf.subinterfaces.append(ast.Interface("frameIn", TMP1))
        intf.subinterfaces.append(ast.Interface("meta", TMP2))
        intf.subinterfaces.append(ast.Interface("verbosity", TMP3))
        intf.subinterfaces.append(ast.Method(name="read_perf_info", rtype=TMP4, params=[]))
        intf.emitInterfaceDecl(builder)

    def build_funct_succeed(self):
        tmpl = []
        tmpl.append("rg_buffered[0] <= rg_buffered[0] - offset;")
        tmpl.append("rg_shift_amt[0] <= rg_buffered[0] - offset;")
        tmpl.append("dbg3($format(\"succeed_and_next subtract offset = %%d shift_amt/buffered = %%d\", offset, rg_buffered[0] - offset));")
        stmt = apply_pdict(tmpl, {})
        ablock = apply_action_block(stmt)
        funct = ast.Function("succeed_and_next", 'Action', "Bit#(32) offset", ablock)
        return funct

    def build_funct_fetch_next_header(self):
        tmpl = []
        tmpl.append("rg_next_header_len[0] <= len;")
        stmt = apply_pdict(tmpl, {})
        ablock = apply_action_block(stmt)
        funct = ast.Function('fetch_next_header', 'Action', 'Bit#(32) len', ablock)
        return funct

    def build_funct_move_shift_amt(self):
        tmpl = []
        tmpl.append("rg_shift_amt[0] <= rg_shift_amt[0] + len;")
        stmt = apply_pdict(tmpl, {})
        ablock = apply_action_block(stmt)
        funct = ast.Function('move_shift_amt', 'Action', 'Bit#(32) len', ablock)
        return funct

    def build_funct_failed_and_trap(self):
        tmpl = []
        tmpl.append("rg_buffered[0] <= 0;")
        stmt = apply_pdict(tmpl, {})
        ablock = apply_action_block(stmt)
        funct = ast.Function('failed_and_trap', 'Action', 'Bit#(32) offset', ablock)
        return funct

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

    def build_funct_report_parse_action(self):
        tmpl = []
        tmpl.append("$display(\"(%%0d) Parser State %%h buffered %%d, %%h, %%h\", $time, state, offset, data, buff);")
        stmt = apply_pdict(tmpl, {})
        ifstmt = apply_if_verbosity(3, stmt)
        ablock = apply_action_block(ifstmt)
        params = "ParserState state, Bit#(32) offset, Bit#(128) data, Bit#(512) buff"
        funct = ast.Function('report_parse_action', 'Action', params, ablock)
        return funct

    def build_funct_transition(self):
        def build_transition(name, transition):
            TMP1 = "w_%(curr_state)s_%(next_state)s.send();"
            key = transition['value'].replace("0x", "'h")
            next_state = transition['next_state']
            next_name = "%s" % (next_state) if next_state != None else self.initial_state
            stmt = []
            stmt.append(ast.Template("dbg3($format(\"transit to %s\"));", next_name))
            stmt.append(ast.Template(TMP1 % {'curr_state': name, 'next_state': next_name}))
            return key, stmt

        def build_funct(name, parameters, transition):
            ab_stmt = []
            if len(parameters) != 0:
                case_stmt = ast.Case('v')
                for t in transition:
                    _key, _stmt = build_transition(name, t)
                    case_stmt.casePatStmt[_key] = _stmt
                key_stmt = ast.Template("let v = {%s};" % (", ".join([p[1] for p in parameters])))
                ab_stmt.append(key_stmt)
                ab_stmt.append(case_stmt)
            else:
                for t in transition:
                    _, _stmt = build_transition(name, t)
                    ab_stmt += _stmt
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
        for _, s in self.states.items():
            if s.name == self.initial_state:
                continue
            params = build_param(s)
            funct.append(build_funct(s.name, params, s.transitions))
        return funct

    # need a default state to skip payload after processing header
    def build_rule_start(self, curr_state, next_state):
        tmpl = []
        tmpl.append("let v = data_in_ff.first;")
        tmpl.append("rg_parse_state <= %(state)s;")
        tmpl.append("rg_buffered[0] <= 128;")
        tmpl.append("rg_shift_amt[0] <= 0;")
        tmpl.append("rg_dequeue_data[2] <= True;")
        rules = []
        stmt = apply_pdict(tmpl, {"state": "State{}".format(CamelCase(next_state))})
        rcond = "rg_parse_state == State{} && sop_this_cycle".format(CamelCase(curr_state))
        rules.append(ast.Rule('rl_start_state_deq', rcond, stmt))
        tmpl2 = []
        tmpl2.append("data_in_ff.deq;")
        stmt2 = apply_pdict(tmpl2, {})
        rcond2 = "rg_parse_state == State{} && !sop_this_cycle".format(CamelCase(curr_state))
        rules.append(ast.Rule('rl_start_state_idle', rcond2, stmt2))
        return rules

    def build_rule_data_ff_load(self):
        tmpl = []
        tmpl.append("rg_buffered[1] <= rg_buffered[1] + %s;"%(config.DP_WIDTH))
        tmpl.append("data_in_ff.deq;")
        tmpl.append("rg_dequeue_data[1] <= True;")
        tmpl.append("dbg3($format(\"dequeue data %%d %%d\", rg_buffered[1], rg_next_header_len[1]));")
        stmt = apply_pdict(tmpl, {})
        rcond = 'rg_buffered[1] < rg_next_header_len[1]'
        rule = ast.Rule('rl_data_ff_load', rcond, stmt)
        return [rule]

    def build_rule_data_ff_idle(self):
        tmpl = []
        tmpl.append("rg_dequeue_data[1] <= False;")
        stmt = apply_pdict(tmpl, {})
        rcond = 'rg_buffered[1] >= rg_next_header_len[1]'
        rule = ast.Rule('rl_data_ff_idle', rcond, stmt)
        return [rule]

    def build_rule_state_load(self, state):
        tmpl = []
        tmpl.append("report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle, rg_tmp);")
        tmpl.append("let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;")
        tmpl.append("rg_tmp <= zeroExtend(data);")
        tmpl.append("move_shift_amt(%d);" % (config.DP_WIDTH))
        pdict = {}
        pdict['name'] = state.name
        pdict['CurrState'] = 'State%s' % (CamelCase(state.name))
        pdict['len'] = state.len
        stmt = apply_pdict(tmpl, pdict)
        rcond = '(rg_parse_state == %(CurrState)s) && (rg_buffered[0] < %(len)s)' % pdict
        attr = ['fire_when_enabled']
        rule = ast.Rule('rl_%(name)s_load' % pdict, rcond, stmt, attr)
        return [rule]

    def build_rule_state_extract(self, state):
        tmpl = []
        tmpl.append("let data = rg_tmp;")
        tmpl.append("if (rg_dequeue_data[0] == True) begin")
        tmpl.append("  data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;")
        tmpl.append("end")
        tmpl.append("report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle, data);")
        TMP = "let %(ktype)s = extract_%(ktype)s(truncate(data));"
        tmpl2 = []
        tmpl2.append("compute_next_state_%(name)s(%(field)s);")
        tmpl2.append("rg_tmp <= zeroExtend(data >> %(len)s);")
        tmpl2.append("succeed_and_next(%(len)s);")
        tmpl2.append("dbg3($format(\"extract %%s %%h\", \"%(name)s\", rg_dequeue_data[0]));")

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
        rcond = '(rg_parse_state == %(CurrState)s) && (rg_buffered[0] >= %(len)s)' % pdict
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

    def build_rule_state_transitions(self, state):
        def build_rule_state_transition(state, next_state):
            tmpl = []
            tmpl.append("rg_parse_state <= %(NextState)s;")
            tmpl.append("dbg3($format(\"%%s -> %%s\", \"%(name)s\", \"%(next_state)s\"));")
            tmpl.append("fetch_next_header(%(length)s);")
            pdict = {}
            pdict['name'] = state.name
            pdict['CurrState'] = "State%s" % (CamelCase(state.name))
            pdict['next_state'] = next_state
            pdict['NextState'] = "State%s" % (CamelCase(next_state))
            pdict['length'] = GetHeaderWidthInState(next_state)
            stmt = apply_pdict(tmpl, pdict)
            rname = 'rl_%(name)s_%(next_state)s' % pdict
            rcond = "(rg_parse_state == %(CurrState)s) && (w_%(name)s_%(next_state)s)" % pdict
            rule = ast.Rule(rname, rcond, stmt)
            # 
            wname = "w_%s_%s" % (state.name, next_state)
            self.pulse_wires.add(wname)
            return rule
        rules = []
        for s in state.transitions:
            next_state_name = s['next_state']
            if next_state_name is None:
                next_state_name = self.initial_state
            rules.append(build_rule_state_transition(state, next_state_name))
        return rules

    def build_ff(self):
        tmpl = []
        tmpl.append("FIFOF#(EtherData) data_in_ff <- mkFIFOF;")
        tmpl.append("FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;")
        tmpl.append("PulseWire parse_done <- mkPulseWire();")
        tmpl.append("Reg#(Bit#(32)) rg_next_header_len[3] <- mkCReg(3, 0);")
        tmpl.append("Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);")
        tmpl.append("Reg#(Bit#(32)) rg_shift_amt[3] <- mkCReg(3, 0);")
        tmpl.append("Reg#(Bit#(512)) rg_tmp <- mkReg(0);")
        tmpl.append("Reg#(Bool) rg_dequeue_data[3] <- mkCReg(3, False);")
        stmt = apply_pdict(tmpl, {})
        return stmt

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

    def build_boiler_plates(self):
        stmt = []
        stmt += bsvgen_common.buildVerbosity()
        stmt += self.build_ff()
        #phv = self.build_phv()
        #stmt += self.build_reg(phv)
        stmt.append(build_funct_dbg3())
        stmt.append(self.build_funct_succeed())
        stmt.append(self.build_funct_fetch_next_header())
        stmt.append(self.build_funct_move_shift_amt())
        stmt.append(self.build_funct_failed_and_trap())
        #stmt.append(self.build_funct_push_phv(phv))
        stmt.append(self.build_funct_report_parse_action())
        stmt.append(ast.Template("let sop_this_cycle = data_in_ff.first.sop;"))
        stmt.append(ast.Template("let eop_this_cycle = data_in_ff.first.eop;"))
        stmt.append(ast.Template("let data_this_cycle = data_in_ff.first.data;"))
        return stmt

    def buildModuleStmt(self):
        self.decide_default_state()
        stmt = []
        stmt += self.build_boiler_plates()
        stmt += self.build_funct_transition()
        stmt += self.build_rule_data_ff_load()
        stmt += self.build_rule_data_ff_idle()

        for idx, s in enumerate(self.states.values()):
            if idx == 0:
                if self.initial_state == s.name:
                    stmt += self.build_rule_start(s.name, s.transitions[0]['next_state'])
                    _name = "State%s" % (CamelCase(s.name))
                    self.regs.add(('ParserState', 'rg_parse_state', _name))
                    continue
                else:
                    stmt += self.build_rule_start('Default', s.name)
                    self.regs.add(('ParserState', 'rg_parse_state', 'StateDefault'))
            stmt += self.build_rule_state_load(s)
            stmt += self.build_rule_state_extract(s)
            stmt += self.build_mutually_exclusive_attribute(s)
            stmt += self.build_rule_state_transitions(s)

        # fill in missing registers
        for reg in self.regs:
            stmt.insert(0, ast.Template("Reg#(%s) %s <- mkReg(%s);"% (reg[0], reg[1], reg[2])))
        for wire in self.pulse_wires:
            stmt.insert(0, ast.Template("PulseWire %(name)s <- mkPulseWireOR();", {'name': wire}))
        for wire in self.dwires:
            stmt.insert(0, ast.Template("Wire#(Bit#(%(width)s)) %(name)s <- mkDWire(0);", {'name': wire[0], 'width': wire[1]}))

        stmt.append(ast.Template("interface frameIn = toPut(data_in_ff);"))
        stmt.append(ast.Template("interface meta = toGet(meta_in_ff);"))
        stmt.append(ast.Template("interface verbosity = toPut(cr_verbosity_ff);"))
        return stmt

    def decide_default_state(self):
        def first_state_has_no_extract(idx, s):
            return (idx==0) and (s.parse_ops==[])
        for idx, s in enumerate(self.states.values()):
            if first_state_has_no_extract(idx, s):
                self.initial_state = s.name # use 'start' as default state

    def emitTypes(self, builder):
        elem = []
        if self.initial_state == 'default':
            elem.append(ast.EnumElement("StateDefault", None, None))
        for s in self.states.values():
            elem.append(ast.EnumElement("State%s" % (CamelCase(s.name)), None, None))
        state = ast.Enum("ParserState", elem)
        state.emit(builder)

    def emitModule(self, builder):
        logger.info("emitModule: Parser")
        mname = "mkParser"
        iname = "Parser"
        params = []
        provisos = []
        decls = []
        stmt = self.buildModuleStmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        builder.newline()
        builder.append("// ====== PARSER ======")
        builder.newline()
        builder.newline()
        assert isinstance(builder, SourceCodeBuilder)
        self.decide_default_state()
        self.emitTypes(builder)
        self.emitInterface(builder)
        self.emitModule(builder)

    #FIXME: need to factor out this logic
    def _find_prev_unmerged_state(self, curr_state, visited):
        if curr_state in self.map_merged_state and self.map_merged_state[curr_state] == True:
            if curr_state in visited:
                return []
            visited.add(curr_state)
            prev_states = []
            if curr_state in self.map_parse_state_reverse:
                prev_states = self.map_parse_state_reverse[curr_state]

            all_states = []
            print 'xxxxxxxxx', all_states, curr_state, prev_states
            for state in prev_states:
                all_states += self.find_prev_unmerged_state(state, visited)
            return all_states
        else:
            return [ curr_state ]


