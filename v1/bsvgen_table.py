# Copyright (c) 2016 Han Wang
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
import math
import logging
import cppgen
import sys, os
from sourceCodeBuilder import SourceCodeBuilder
from utils import CamelCase, p4name, GetFieldWidth
from bsvgen_struct import StructT, StructTableReqT, StructTableRspT
from bsvgen_common import build_funct_verbosity

logger = logging.getLogger(__name__)

IRQ_TEMPLATE = """Vector#(%(sz)s, Bool) readyBits = map(fifoNotEmpty, %(fifo)s);
  Bool interruptStatus = False;
  Bit#(%(sz)s) readyChannel = -1;
  for (Integer i=%(szminus1)s; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end
"""

generated_table_sim = []

def simgen():
    cppgen.generate_cpp('generatedcpp', False, generated_table_sim)

class MatchTableSim:
    def __init__(self, name, tid, ksz, vsz):
        self.name = name
        self.tid = tid
        self.ksz = ksz
        self.vsz = vsz

    def build_bdpi(self, tid, ksz, vsz):
        global generated_table_sim
        TMP1 = "`ifndef SVDPI"
        TMP2 = "import \"BDPI\" function ActionValue#(Bit#(%s)) matchtable_read_%s(Bit#(%s) msgtype);"
        TMP3 = "import \"BDPI\" function Action matchtable_write_%s(Bit#(%s) msgtype, Bit#(%s) data);"
        TMP4 = "`endif"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2 % (vsz, self.name, ksz)))
        stmt.append(ast.Template(TMP3 % (self.name, ksz, vsz)))
        stmt.append(ast.Template(TMP4))
        return stmt

    def generate_table_init(self):
        global generated_table_sim
        init_file = os.path.join('generatedbsv', self.name+'.dat')
        if not os.path.isfile(init_file):
            open(init_file, 'w')

    def build_read_function(self, tid, ksz, vsz):
        TMP1 = "let v <- matchtable_read_%s(key);" % (self.name)
        TMP2 = "return v;"
        name = "matchtable_read"
        type = "ActionValue#(Bit#(%s))" % (vsz)
        params = "Bit#(%s) id, Bit#(%s) key" % (tid, ksz)
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        action_block = ast.ActionValueBlock(stmt)
        funct = ast.Function(name, type, params, stmt=[action_block])
        return funct

    def build_write_function(self, tid, ksz, vsz):
        TMP1 = "matchtable_write_%s(key, data);" % (self.name)
        name = "matchtable_write"
        type = "Action"
        params = "Bit#(%s) id, Bit#(%s) key, Bit#(%s) data" % (tid, ksz, vsz)
        stmt = []
        stmt.append(ast.Template(TMP1))
        action_block = ast.ActionBlock(stmt)
        funct = ast.Function(name, type, params, stmt=[action_block])
        return funct

    def emit(self, builder):
        TMP1 = "MatchTableSim#(%d, %s, %s)"
        for s in self.build_bdpi(self.tid, self.ksz, self.vsz):
            s.emit(builder)
            builder.newline()
        stmt = []
        stmt.append(self.build_read_function(self.tid, self.ksz, self.vsz))
        stmt.append(self.build_write_function(self.tid, self.ksz, self.vsz))
        inst = ast.Instance(TMP1%(self.tid, self.ksz, self.vsz), stmt)
        inst.emit(builder)
        generated_table_sim.append({'name': self.name, 'ksz': self.ksz, 'vsz': self.vsz})
        self.generate_table_init()

class Table(object):
    required_attributes = ["name", "match_type", "max_size", "key", "actions"]
    def __init__(self, table_attrs, basic_block_map, json_dict):
        self.name = table_attrs["name"]
        self.tid = table_attrs["id"]
        self.match_type = table_attrs['match_type']
        self.depth = 256 if table_attrs['max_size'] == 16384 else table_attrs['max_size']
        self.key = table_attrs.get('key', None)
        self.actions = table_attrs.get('actions', None)
        self.next_tables= table_attrs.get('next_tables', None)
        self.req_name = "%sReqT" % (CamelCase(self.name))
        self.request = StructT(self.req_name)
        self.rsp_name = "%sRspT" % (CamelCase(self.name))
        self.response = StructT(self.rsp_name)
        self.basic_block_map = basic_block_map
        self.json_dict = json_dict

    def __repr__(self):
        return "{} ({}, {}, {}, {})".format(
                    self.__class__.__name__,
                    self.match_type,
                    self.depth,
                    self.key,
                    self.actions)

    def buildMatchKey(self):
        keys = []
        for k in self.key:
            keys.append(k['target'])
        return keys

    def buildRuleMatchRequest(self):
        TMP1 = "let data = rx_info_%(name)s.first;"
        TMP2 = "let meta = data.meta;"
        TMP8 = "let pkt = data.pkt;"
        TMP3 = "%(type)s req = %(type)s {%(field)s};"
        TMP4 = "matchTable.lookupPort.request.put(pack(req));"
        TMP5 = "let %(name)s = fromMaybe(?, meta.%(name)s);"
        TMP6 = "{%(field)s}"
        TMP7 = "rx_info_%(name)s.deq;"
        rname = "rl_handle_request"
        stmt = []
        stmt.append(ast.Template(TMP1, {"name": "metadata"}))
        stmt.append(ast.Template(TMP7, {"name": "metadata"}))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP8))
        keys = self.buildMatchKey()
        fields = []
        total_width = 0
        for k in keys:
            if type(k) != list:
                total_width += 1
                name = 'valid_%s' % k
                fields.append("%s: %s" %(p4name(name), p4name(name)))
            else:
                width = GetFieldWidth(k)
                total_width += width
                stmt.append(ast.Template(TMP5, {"name": p4name(k)}))
                fields.append("%s: %s" % (p4name(k), p4name(k)))
        if (total_width % 9):
            fields.insert(0, "padding: 0")
        stmt.append(ast.Template(TMP3, {"type": self.req_name, "field": ", ".join(fields)}))
        stmt.append(ast.Template(TMP4))
        stmt.append(ast.Template("packet_ff.enq(pkt);"))
        stmt.append(ast.Template("metadata_ff[0].enq(meta);"))
        cond = []
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleExecuteAction(self):
        TMP1 = "let rsp <- matchTable.lookupPort.response.get;"
        TMP2 = "let pkt <- toGet(packet_ff).get;"
        TMP3 = "let meta <- toGet(metadata_ff[0]).get;"
        TMP4 = "%(type)s resp = unpack(data);"
        TMP7 = "metadata_ff[1].enq(meta);"

        TMP8 = "BBRequest req = tagged %(type)sReqT {%(field)s};"
        TMP9 = "bbReqFifo[%(id)s].enq(req); //FIXME: replace with RXTX."

        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        case_stmt = ast.Case("resp._action")

        for idx, action in enumerate(self.actions):
            basic_block = self.basic_block_map[action]
            fields = basic_block.request.build_case_expr()
            action_stmt = []
            action_stmt.append(ast.Template(TMP8, {"type": CamelCase(action),
                                                   "field": fields}))
            action_stmt.append(ast.Template(TMP9, {"id": idx}))
            _action = action.lstrip('_').upper()
            case_stmt.casePatStmt[_action] = action_stmt

        if_stmt = ast.If("rsp matches tagged Valid .data", [])
        if_stmt.stmt.append(ast.Template(TMP4, {"type": self.rsp_name}))
        if_stmt.stmt.append(case_stmt)
        if_stmt.stmt.append(ast.Template("// forward metadata to next stage."))
        if_stmt.stmt.append(ast.Template(TMP7))
        stmt.append(if_stmt)

        rname = "rl_handle_execute"
        cond = []
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleMatchResponseStmt(self):
        TMP1 = "let v <- toGet(bbRspFifo[readyChannel]).get;"
        TMP2 = "let meta <- toGet(metadata_ff[1]).get;"
        TMP3 = "tagged %(name)sRspT {%(field)s}"
        TMP4 = "%(ty_metadata)s rsp = tagged %(name)s {pkt: pkt, meta: meta};"
        TMP5 = "tx_info_%(name)s.enq(rsp);"
        TMP6 = "meta.%(mname)s = tagged Valid %(mname)s;"

        stmt = []
        case_stmt = ast.Case("v")

        for idx, action in enumerate(self.actions):
            basic_block = self.basic_block_map[action]
            fields = basic_block.response.build_match_expr()
            action_stmt = []
            for field in basic_block.response.members:
                mname = p4name(field)
                action_stmt.append(ast.Template(TMP6 % {"mname": mname}))

            tagname = "%s%sRspT" % (CamelCase(self.name), CamelCase(action))
            action_stmt.append(ast.Template(TMP4 % {"name": tagname, "ty_metadata": CamelCase(self.name)+"Response"}))
            action_stmt.append(ast.Template(TMP5 % {"name": "metadata"}))
            action = TMP3 % {"name": CamelCase(action), "field": fields}
            case_stmt.casePatStmt[action] = action_stmt

        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(case_stmt)
        return stmt

    def buildRuleMatchResponse(self):
        rname = "rl_handle_response"
        cond = "interruptStatus"
        stmt = self.buildRuleMatchResponseStmt()
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildTXRX(self, pname):
        TMP1 = "RX #(%(type)sRequest) rx_%(name)s <- mkRX;"
        TMP3 = "TX #(%(tblname)sResponse) tx_%(name)s <- mkTX;"
        TMP2 = "let rx_info_%(name)s = rx_%(name)s.u;"
        TMP4 = "let tx_info_%(name)s = tx_%(name)s.u;"
        stmt = []
        pdict = {'type': CamelCase(pname), 'name': pname, 'tblname': CamelCase(self.name)}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP3, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildRuleActionRequest(self):
        TMP1 = "let data = rx_info_%(name)s.first;"
        TMP2 = "rx_info_%(name)s.deq;"
        TMP3 = "let meta = data.meta;"
        TMP4 = "let pkt = data.pkt;"
        TMP5 = "let %(field)s = fromMaybe(?, meta.%(field)s);"

        TMP8 = "BBRequest req = tagged %(type)sReqT {%(field)s};"
        TMP9 = "bbReqFifo[%(id)s].enq(req); //FIXME: replace with RXTX."

        stmt = []
        stmt.append(ast.Template(TMP1, {"name": "metadata"}))
        stmt.append(ast.Template(TMP2, {"name": "metadata"}))
        stmt.append(ast.Template(TMP3))
        stmt.append(ast.Template(TMP4))
        stmt.append(ast.Template("packet_ff.enq(pkt);"))
        stmt.append(ast.Template("metadata_ff.enq(meta);"))

        for idx, action in enumerate(self.actions):
            basic_block = self.basic_block_map[action]
            for f in basic_block.request.members:
                stmt.append(ast.Template(TMP5, {"field": p4name(f)}))

        for idx, action in enumerate(self.actions):
            basic_block = self.basic_block_map[action]
            fields = basic_block.request.build_case_expr()
            stmt.append(ast.Template(TMP8, {"type": CamelCase(action), "field": fields}))
            stmt.append(ast.Template(TMP9, {"id": idx}))

        rname = "rl_handle_action_request"
        cond = []
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleActionResponse(self):
        TMP1 = "let v <- toGet(bbRspFifo[readyChannel]).get;"
        TMP2 = "let meta <- toGet(metadata_ff).get;"
        TMP3 = "tagged %(name)sRspT {%(field)s}"
        TMP4 = "MetadataResponse rsp = tagged %(name)s%(action)sRspT {pkt: pkt, meta: meta};"
        TMP5 = "tx_info_%(name)s.enq(rsp);"
        TMP6 = "meta.%(name)s = tagged Valid %(name)s;"

        stmt = []
        case_stmt = ast.Case("v")

        for idx, action in enumerate(self.actions):
            basic_block = self.basic_block_map[action]
            fields = basic_block.response.build_match_expr()
            action_stmt = []
            for field in basic_block.response.get_members():
                action_stmt.append(ast.Template(TMP6 % {"name": field}))
            action_stmt.append(ast.Template(TMP4 % {"name": CamelCase(self.name),
                                                    "action": CamelCase(action)}))
            action_stmt.append(ast.Template(TMP5 % {"name": "metadata"}))

            action = TMP3 % {"name": CamelCase(action), "field": fields}
            case_stmt.casePatStmt[action] = action_stmt

        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(case_stmt)

        rname = "rl_handle_action_response"
        cond = "interruptStatus"
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def build_intf_decl_verbosity(self):
        stmt = []
        stmt.append(ast.Template("method Action set_verbosity (int verbosity);"))
        stmt.append(ast.Template("  cf_verbosity <= verbosity;"))
        stmt.append(ast.Template("endmethod"))
        return stmt

    def buildModuleStmt(self):
        TMP1 = "Vector#(%(num)s, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);"
        TMP2 = "Vector#(%(num)s, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);"
        TMP3 = "MatchTable#(%(tid)s, %(sz)s, SizeOf#(%(reqT)s), SizeOf#(%(rspT)s)) matchTable <- mkMatchTable(\"%(name)s\");"
        TMP4 = "interface next_control_state_%(id)s = toClient(bbReqFifo[%(id)s], bbRspFifo[%(id)s]);"
        TMP5 = "interface prev_control_state_%(id)s = toServer(rx_%(name)s.e, tx_%(name)s.e);"
        TMP6 = "Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);"
        TMP8 = "FIFOF#(MetadataT) metadata_ff <- mkFIFOF;"
        TMP7 = "FIFOF#(PacketInstance) packet_ff <- mkFIFOF;"

        stmt = []
        stmt += build_funct_verbosity()
        stmt += self.buildTXRX("metadata")

        num = len(self.actions)
        stmt.append(ast.Template(TMP1, {"num": num}))
        stmt.append(ast.Template(TMP2, {"num": num}))
        stmt.append(ast.Template(TMP7))

        if len(self.key) != 0:
            reqT = "%sReqT" % (CamelCase(self.name))
            rspT = "%sRspT" % (CamelCase(self.name))
            # size must be 256 or multiple of 256
            size = int(256 * math.ceil(float(self.depth)/256))
            tid = self.tid;
            pdict = {"sz": size, "reqT": reqT, "rspT": rspT, "tid": tid, "name": self.name+'.dat'}
            stmt.append(ast.Template(TMP3, pdict))

        pdict = {"sz": num, "szminus1": num-1, "fifo": "bbRspFifo"}
        stmt.append(ast.Template(IRQ_TEMPLATE, pdict))

        if len(self.key) != 0:
            stmt.append(ast.Template(TMP6))
            stmt.append(self.buildRuleMatchRequest())
            stmt.append(self.buildRuleExecuteAction())
            stmt.append(self.buildRuleMatchResponse())
        else:
            stmt.append(ast.Template(TMP8))
            stmt.append(self.buildRuleActionRequest())
            stmt.append(self.buildRuleActionResponse())

        stmt.append(ast.Template(TMP5 % {"name": "metadata","id": 0}))
        for idx, _ in enumerate(self.actions):
            stmt.append(ast.Template(TMP4 % {"id": idx}))
        stmt += self.build_intf_decl_verbosity()
        return stmt

    def emitInterface(self, builder):
        logger.info("emitTable: {}".format(self.name))
        TMP1 = "prev_control_state_%(id)s"
        TMP2 = "Server #(MetadataRequest, %(ty_metadata)s)"
        TMP3 = "next_control_state_%(id)s"
        TMP4 = "Client #(BBRequest, BBResponse)"
        iname = CamelCase(self.name)
        intf = ast.Interface(typedef=iname)
        s_intf = ast.Interface(TMP1 % {"id": 0}, TMP2 % {"ty_metadata": iname+"Response"})
        intf.subinterfaces.append(s_intf)
        for idx, _ in enumerate(self.actions):
            c_intf = ast.Interface(TMP3 % {"id": idx}, TMP4)
            intf.subinterfaces.append(c_intf)
        intf1 = ast.Method("set_verbosity", "Action", "int verbosity")
        intf.subinterfaces.append(intf1)
        intf.emitInterfaceDecl(builder)

    def emitModule(self, builder):
        logger.info("emitModule: {}".format(self.name))
        mname = "mk{}".format(CamelCase(self.name))
        iname = CamelCase(self.name)
        params = []
        provisos = []
        decls = []
        stmt = self.buildModuleStmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emitKeyType(self, builder):
        global generated_table_sim
        req_struct = StructTableReqT(self.name, self.key)
        req_struct.emit(builder)

        action_info = self.json_dict['actions']
        rsp_struct = StructTableRspT(self.name, self.actions, action_info)
        rsp_struct.emit(builder)

        simmodel = MatchTableSim(self.name, self.tid, req_struct.width, rsp_struct.width)
        simmodel.emit(builder)

    def emitValueType(self, builder):
        pass

    def emit(self, builder):
        builder.newline()
        builder.append("// ====== %s ======" % (self.name.upper()))
        builder.newline()
        builder.newline()
        assert isinstance(builder, SourceCodeBuilder)
        self.emitValueType(builder)
        self.emitKeyType(builder)
        self.emitInterface(builder)
        builder.appendLine("(* synthesize *)")
        self.emitModule(builder)

