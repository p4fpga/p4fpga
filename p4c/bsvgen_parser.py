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
import bsvgen_common
import logging
from sourceCodeBuilder import SourceCodeBuilder
from utils import CamelCase, camelCase, field_width
import config

logger = logging.getLogger(__name__)

class Parser(object):
    def __init__(self, ir, parse_rules, transitions, transition_key, header_types, header_instances):
        self.rules = parse_rules
        self.transitions = transitions
        self.transition_key = transition_key
        self.header_types = header_types
        self.header_instances = header_instances
        self.ir = ir

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
        intf.subinterfaces.append(ast.Method(name="read_perf_info", return_type=TMP4, params=[]))
        intf.emitInterfaceDecl(builder)

    def funct_succeed(self):
        TMP1 = "data_in_ff.deq;"
        TMP2 = "rg_offset <= offset;"
        fname = "succeed_and_next"
        rtype = "Action"
        params = "Bit#(32) offset"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        ablock = [ast.ActionBlock(stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_failed(self):
        TMP1 = "data_in_ff.deq;"
        TMP2 = "rg_offset <= 0;"
        fname = "failed_and_trap"
        rtype = "Action"
        params = "Bit#(32) offset"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        ablock = [ast.ActionBlock(stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_push_phv(self, phv):
        TMP1 = "MetadataT meta = defaultValue;"
        TMP2 = "meta.%(field)s = tagged Valid rg_tmp_%(field)s;"
        TMP3 = "meta_in_ff.enq(meta);"
        fname = "push_phv"
        rtype = "Action"
        params = "ParserState ty"
        stmt = []
        stmt.append(ast.Template(TMP1))
        for _, p in phv:
            stmt.append(ast.Template(TMP2, {"field": p}))
        stmt.append(ast.Template(TMP3))
        ablock = [ast.ActionBlock(stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_report_parse_action(self):
        TMP1 = "$display(\"(%%d) Parser State %%h offset %%h, %%h\", $time, state, offset, data);"
        fname = "report_parse_action"
        rtype = "Action"
        params = "ParserState state, Bit#(32) offset, Bit#(128) data"
        if_stmt = ast.If("cr_verbosity[0] > 0", [])
        if_stmt.stmt.append(ast.Template(TMP1))
        stmt = []
        stmt.append(if_stmt)
        ablock = [ast.ActionBlock(stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_compute_next_states(self, rules, transition_key, transitions):
        def compute_next_state(name, width, transition):
            TMP1 = "ParserState nextState = StateParseStart;"
            TMP2 = "nextState = %(next_state)s;"
            TMP3 = "return nextState;"
            pdict = {'width': width, 'name': name}
            fname = "compute_next_state_%(name)s" % pdict
            rtype = "ParserState"
            params = "Bit#(%(width)s) v" % pdict
            stmt = []
            stmt.append(ast.Template(TMP1))
            caseExpr = "byteSwap(v)"
            case_stmt = ast.Case(caseExpr)
            for t in transition:
                value = t['value'].replace("0x", "'h")
                next_state = t['next_state']
                name = "State%s" % (CamelCase(next_state)) if next_state != None else "StateParseStart"
                action_stmt = []
                action_stmt.append(ast.Template(TMP2 % {'next_state': name}))
                case_stmt.casePatItem[value] = value
                case_stmt.casePatStmt[value] = action_stmt
            stmt.append(case_stmt)
            stmt.append(ast.Template(TMP3))
            f = ast.Function(fname, rtype, params, stmt)
            return f

        funct = []
        for name, rule in rules.items():
            transition = transitions[name]
            key = transition_key[name]
            width = 0
            for k in key:
                width = k['width']
                funct.append(compute_next_state(name, width, transition))
        return funct

    def rule_start(self, first_state):
        TMP1 = "let v = data_in_ff.first;"
        TMP2 = "rg_parse_state <= %(state)s;"
        TMP3 = "data_in_ff.deq;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        if_stmt = []
        if_stmt.append(ast.Template(TMP2, {"state": "State{}".format(CamelCase(first_state))}))
        stmt.append(ast.If("v.sop", if_stmt))
        else_stmt = []
        else_stmt.append(ast.Template(TMP3))
        stmt.append(ast.Else(else_stmt))
        rname = "rl_start_state"
        rcond = "rg_parse_state == StateParseStart"
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def rule_parse(self, rule_attrs, transition_key, transitions):
        TMP1 = "rl_parse_%(name)s_%(idx)s"
        TMP2 = "(rg_parse_state == %(state)s) && (rg_offset == %(offset)s)"
        TMP3 = "report_parse_action(rg_parse_state, rg_offset, data_this_cycle);"
        TMP4 = "Vector#(%(prevLen)s, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_%(name)s));"
        TMP5 = "Bit#(%(prevLen)s) data_last_cycle = pack(takeAt(0, tmp_dataVec));"
        TMP6 = "Bit#(%(rcvdLen)s) data = {data_this_cycle, data_last_cycle};"
        TMP7 = "Vector#(%(rcvdLen)s, Bit#(1)) dataVec = unpack(data);"
        TMP8 = "let %(name)s = extract_%(header_type)s(pack(takeAt(0, dataVec)));"
        TMP9 = "let next_state = compute_next_state_%(name)s(%(field)s);"
        TMP9_0 = "let next_state = StateParseStart;"
        TMP10 = "rg_parse_state <= next_state;"
        TMP11 = "rg_tmp_%(next_state)s <= zeroExtend(pack(unparsed));"
        TMP12 = "parse_state_w <= %(state)s;"
        TMP13 = "succeed_and_next(rg_offset + %(dp_width)s);"
        TMP14 = "Vector#(%(nextLen)s, Bit#(1)) unparsed = takeAt(%(width)s, dataVec);"
        TMP15 = "rg_tmp_%(name)s <= zeroExtend(data);"
        TMP16 = "push_phv(%(state)s);"
        first = rule_attrs['firstBeat']
        last = rule_attrs['lastBeat']
        name = rule_attrs['name']
        idx = rule_attrs['idx']
        rcvdLen = rule_attrs['rcvdLen']
        nextLen = rule_attrs['nextLen']
        offset = rule_attrs['offset']
        width = rule_attrs['width']
        keys = []
        for key in transition_key[name]:
            keys.append("parse_%s" % (".".join(key['value'])))

        next_states = set()
        for transition in transitions[name]:
            next_state = transition['next_state']
            if next_state == None:
                continue
            next_states.add(next_state)

        pdict = {"name": name,
                "idx": idx,
                "state": "State"+CamelCase(name),
                "header_type": self.header_types[name],
                "offset": offset,
                "rcvdLen": rcvdLen,
                "prevLen": rcvdLen - config.DP_WIDTH,
                "nextLen": nextLen,
                "width": width,
                "dp_width": config.DP_WIDTH,
                "field": ",".join(keys)}
        rname = TMP1 % pdict
        rcond = TMP2 % pdict
        stmt = []
        stmt.append(ast.Template(TMP3, pdict))
        if last:
            stmt.append(ast.Template(TMP4, pdict))
            stmt.append(ast.Template(TMP5, pdict))
            stmt.append(ast.Template(TMP6, pdict))
            stmt.append(ast.Template(TMP7, pdict))
            stmt.append(ast.Template(TMP8, pdict))
            if pdict['field'] != "":
                stmt.append(ast.Template(TMP9, pdict))
            else:
                stmt.append(ast.Template(TMP9_0))
            stmt.append(ast.Template(TMP10, pdict))
            stmt.append(ast.Template(TMP14, pdict))
            for s in next_states:
                stmt.append(ast.Template(TMP11, {'next_state': s, 'name': name}))
            if len(next_states) == 0:
                stmt.append(ast.Template(TMP16, pdict))
            stmt.append(ast.Template(TMP12, pdict))
            stmt.append(ast.Template(TMP13, pdict))
        else:
            stmt.append(ast.Template(TMP4, pdict))
            stmt.append(ast.Template(TMP5, pdict))
            stmt.append(ast.Template(TMP6, pdict))
            stmt.append(ast.Template(TMP15, pdict))
            stmt.append(ast.Template(TMP13, pdict))
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def buildFFs(self):
        TMP1 = "FIFOF#(EtherData) data_in_ff <- mkFIFOF;"
        TMP2 = "FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;"
        TMP3 = "Reg#(ParserState) rg_parse_state <- mkReg(StateParseStart);"
        TMP4 = "Wire#(ParserState) parse_state_w <- mkDWire(StateParseStart);"
        TMP5 = "Reg#(Bit#(32)) rg_offset <- mkReg(0);"
        TMP6 = "PulseWire parse_done <- mkPulseWire();"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        stmt.append(ast.Template(TMP4))
        stmt.append(ast.Template(TMP5))
        stmt.append(ast.Template(TMP6))
        return stmt

    def buildTmpRegs(self, phv):
        TMP1 = "Reg#(Bit#(%(sz)s)) rg_tmp_%(name)s <- mkReg(0);"
        stmt = []
        for state, parse_steps in self.rules.items():
            for rule_attrs in parse_steps:
                rcvdLen = rule_attrs['rcvdLen']
                last = rule_attrs['lastBeat']
                if last:
                    stmt.append(ast.Template(TMP1, {'sz': rcvdLen, 'name': state}))

        for sz, name in phv:
            stmt.append(ast.Template(TMP1, {'sz': sz, 'name': name}))

        return stmt

    def build_phv(self):
        header_types = config.jsondata['header_types']
        headers = config.jsondata['headers']
        metadata = set()
        fields = []
        for it in config.ir.basic_blocks.values():
            for f in it.request.members:
                if f not in metadata:
                    width = field_width(f, header_types, headers)
                    name = "$".join(f)
                    fields.append((width, name))
                    metadata.add(f)
        for f in config.ir.controls.values():
            for _, v in f.tables.items():
                for k in v.key:
                    d = tuple(k['target'])
                    if d not in metadata:
                        width = field_width(k['target'], header_types, headers)
                        name = "$".join(k['target'])
                        fields.append((width, name))
                        metadata.add(d)
        for it in config.ir.parsers.values():
            for h in it.header_instances.values():
                name = "valid_%s" % (camelCase(h))
                fields.append((0, name))
        return fields

    def buildModuleStmt(self):
        phv = self.build_phv()
        stmt = []
        stmt += bsvgen_common.buildVerbosity()
        stmt += self.buildFFs()
        stmt += self.buildTmpRegs(phv)
        stmt.append(self.funct_succeed())
        stmt.append(self.funct_failed())
        stmt.append(self.funct_push_phv(phv))
        stmt.append(self.funct_report_parse_action())
        stmt += self.funct_compute_next_states(self.rules, self.transition_key, self.transitions)
        first_state = self.rules.keys()[0]
        stmt.append(self.rule_start(first_state))
        stmt.append(ast.Template("let data_this_cycle = data_in_ff.first.data;"))
        for state, parse_steps in self.rules.items():
            for rule_attrs in parse_steps:
                rule_attrs['name'] = state
                transition_key = self.transition_key
                transitions = self.transitions
                stmt.append(self.rule_parse(rule_attrs, transition_key, transitions))
        stmt.append(ast.Template("interface frameIn = toPut(data_in_ff);"))
        stmt.append(ast.Template("interface meta = toGet(meta_in_ff);"))
        stmt.append(ast.Template("interface verbosity = toPut(cr_verbosity_ff);"))
        return stmt

    def emitTypes(self, builder):
        elem = []
        elem.append(ast.EnumElement("StateParseStart", None, None))
        for state in self.rules.keys():
            elem.append(ast.EnumElement("State%s" % (CamelCase(state)), None, None))
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
        self.emitTypes(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
