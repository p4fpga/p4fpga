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
import sourceCodeBuilder
from utils import CamelCase
from p4fpga import DP_WIDTH

logger = logging.getLogger(__name__)

class Deparser(object):
    def __init__(self, deparse_states):
        self.deparse_states = deparse_states

    def emitInterface(self, builder):
        logger.info("emitInterface: Deparser")
        TMP1 = "PipeIn#(MetadataT)"
        TMP2 = "PktWriteServer"
        TMP3 = "PktWriteClient"
        TMP4 = "Put#(int)"
        TMP5 = "DeparserPerfRec"
        intf = ast.Interface(typedef="Deparser")
        intf.subinterfaces.append(ast.Interface("metadata", TMP1))
        intf.subinterfaces.append(ast.Interface("writeServer", TMP2))
        intf.subinterfaces.append(ast.Interface("writeClient", TMP3))
        intf.subinterfaces.append(ast.Interface("verbosity", TMP4))
        intf.subinterfaces.append(ast.Method("read_perf_info", TMP5, []))
        intf.emitInterfaceDecl(builder)

    def buildFFs(self):
        TMP = []
        TMP.append("FIFOF#(EtherData) data_in_ff <- mkFIFOF;")
        TMP.append("FIFOF#(EtherData) data_out_ff <- mkFIFOF;")
        TMP.append("FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt

    def buildRegs(self):
        TMP = []
        TMP.append("Reg#(Bit#(32)) rg_offset <- mkReg(0);")
        TMP.append("Reg#(Bit#(128)) rg_buff <- mkReg(0);")
        TMP.append("Reg#(DeparserState) rg_deparse_state <- mkReg(StateDeparseStart);")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt

    def buildInputs(self):
        TMP = []
        TMP.append("let din = data_in_ff.first;")
        TMP.append("let meta = meta_in_ff.first;")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt

    def funct_report_deparse_action(self):
        TMP1 = "$display(\"(%%d) Deparse State %%h offset %%h\", $time, state, offset);"
        fname = "report_deparse_action"
        rtype = "Action"
        params = "DeparserState state, Bit#(32) offset"
        if_stmt = ast.If("cr_verbosity[0] > 0", [])
        if_stmt.stmt.append(ast.Template(TMP1))
        stmt = []
        stmt.append(if_stmt)
        ablock = [ast.ActionBlock("action", stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_succeed(self):
        TMP1 = "data_in_ff.deq;"
        TMP2 = "rg_offset <= offset;"
        fname = "succeed_and_next"
        rtype = "Action"
        params = "Bit#(32) offset"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        ablock = [ast.ActionBlock("action", stmt)]
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
        ablock = [ast.ActionBlock("action", stmt)]
        funct = ast.Function(fname, rtype, params, ablock)
        return funct

    def funct_compute_next_state(self):
        TMP1 = "DeparserState nextState = StateDeparseStart;"
        TMP2 = "return nextState;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        fname = "compute_next_state"
        rtype = "DeparserState"
        params = "DeparserState state"
        funct = ast.Function(fname, rtype, params, stmt)
        return funct

    def funct_read_data(self):
        TMP1 = "Bit#(l) ldata = truncate(din.data) << (fromInteger(valueOf(l))-lhs);"
        TMP2 = "Bit#(l) rdata = truncate(rg_buff) >> (fromInteger(valueOf(l))-rhs);"
        TMP3 = "Bit#(l) cdata = ldata | rdata;"
        TMP4 = "return cdata;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        stmt.append(ast.Template(TMP4))
        fname = "read_data"
        rtype = "Bit#(l)"
        params = "UInt#(8) lhs, UInt#(8) rhs"
        provisos = "Add#(a__, l, 128)"
        funct = ast.Function(fname, rtype, params, stmt, provisos=provisos)
        return funct

    def funct_create_mask(self):
        TMP1 = "Bit#(max) v = 1 << count - 1;"
        TMP2 = "return v;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        fname = "create_mask"
        rtype = "Bit#(max)"
        params = "UInt#(max) count"
        funct = ast.Function(fname, rtype, params, stmt)
        return funct

    def funct_deparse_rule_no_opt(self):
        TMP = []
        TMP.append("report_deparse_action(rg_deparse_state, rg_offset);")
        TMP.append("match {.meta, .mask} = m;")
        TMP.append("Vector#(n, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(meta)));")
        TMP.append("Vector#(n, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(mask)));")
        TMP.append("Bit#(n) curr_data = read_data (clen, plen);")
        TMP.append("$display (\"read_data %%h\", curr_data);")
        TMP.append("let data = apply_changes (curr_data, pack(curr_meta), pack(curr_mask));")
        TMP.append("let data_this_cycle = EtherData { sop: din.sop, eop: din.eop, data: zeroExtend(data), mask: create_mask(cExtend(fromInteger(valueOf(n)))) };")
        TMP.append("data_out_ff.enq (data_this_cycle);")
        TMP.append("DeparserState next_state = compute_next_state(state);")
        TMP.append("$display (\"next_state %%h\", next_state);")
        TMP.append("rg_deparse_state <= next_state;")
        TMP.append("rg_buff <= din.data;")
        TMP.append("// apply header removal by marking mask zero")
        TMP.append("// apply added header by setting field at offset.")
        TMP.append("succeed_and_next (rg_offset + cExtend(clen) + cExtend(plen));")
        rcond = "(rg_deparse_state == state) && (rg_offset == unpack(pack(offset)))"
        rstmt = []
        for n in TMP: rstmt.append(ast.Template(n))
        rule = ast.Rule("rl_deparse", rcond, rstmt)
        rules = ast.Rules([rule])
        rules_stmt = [rules]
        fname = "build_deparse_rule_no_opt"
        rtype = "Rules"
        params = "DeparserState state, int offset, Tuple2#(Bit#(n), Bit#(n)) m, UInt#(8) clen, UInt#(8) plen"
        provisos = "Mul#(TDiv#(n, 8), 8, n), Add#(a__, n, 128)"
        funct = ast.Function(fname, rtype, params, rules_stmt, provisos)
        stmt = []
        stmt.append(funct)
        return stmt

    def rule_start(self, first_state):
        TMP1 = "let v = data_in_ff.first;"
        TMP2 = "rg_deparse_state <= %(state)s;"
        TMP3 = "data_in_ff.deq;"
        TMP4 = "data_out_ff.enq(v);"
        stmt = []
        stmt.append(ast.Template(TMP1))
        if_stmt = []
        if_stmt.append(ast.Template(TMP2, {"state": "State{}".format(CamelCase(first_state))}))
        stmt.append(ast.If("v.sop", if_stmt))
        else_stmt = []
        else_stmt.append(ast.Template(TMP3))
        else_stmt.append(ast.Template(TMP4))
        stmt.append(ast.Else(else_stmt))
        rname = "rl_start_state"
        rcond = "rg_deparse_state == StateDeparseStart"
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def rule_deparse(self):
        TMP1 = "Tuple2#(%(type)s, %(type)s) %(name)s = toTuple(meta);"
        TMP2 = "Bit#(%(width)s) %(name)s_meta = pack(tpl_1(%(name)s));"
        TMP3 = "Bit#(%(width)s) %(name)s_mask = pack(tpl_2(%(name)s));"
        TMP4 = "addRules(build_deparse_rule_no_opt(%(state)s, %(offset)s, %(tuple)s, %(clen)s, %(plen)s));"
        stmt = []
        pdict = {"type": "FIXME",
                "name": "FIXME",
                "width": 0,
                "state": "FIXME",
                "offset": "FIXME",
                "tuple": "FIXME",
                "clen": 0,
                "plen": 0}
        stmt.append(ast.Template(TMP1 % pdict))
        stmt.append(ast.Template(TMP2 % pdict))
        stmt.append(ast.Template(TMP3 % pdict))
        stmt.append(ast.Template(TMP4 % pdict))
        return stmt

    def buildModuleStmt(self):
        stmt = []
        stmt += bsvgen_common.buildVerbosity()
        stmt += self.buildFFs()
        stmt += self.buildRegs()
        stmt += self.buildInputs()
        stmt.append(self.funct_report_deparse_action())
        stmt.append(self.funct_succeed())
        stmt.append(self.funct_failed())
        stmt.append(self.funct_compute_next_state())
        stmt.append(self.funct_read_data())
        stmt.append(self.funct_create_mask())
        first_state = self.deparse_states[0]
        stmt.append(self.rule_start(first_state))
        stmt += self.funct_deparse_rule_no_opt()
        #stmt += self.rule_deparse()
        return stmt

    def emitTypes(self, builder):
        elem = []
        elem.append(ast.EnumElement("StateDeparseStart", None, None))
        for state in self.deparse_states:
            elem.append(ast.EnumElement("State%s" % (CamelCase(state)), None, None))
        state = ast.Enum("DeparserState", elem)
        state.emit(builder)

    def emitModule(self, builder):
        logger.info("emitModule: Deparser")
        stmt = []
        mname = "mkDeparser"
        iname = "Deparser"
        params = []
        provisos = []
        decls = []
        stmt = self.buildModuleStmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        self.emitTypes(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
