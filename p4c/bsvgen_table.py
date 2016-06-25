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

import logging
from lib.sourceCodeBuilder import SourceCodeBuilder
from lib.utils import CamelCase
import lib.ast as ast
from bsvgen_struct import StructT

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


class Table(object):
    required_attributes = ["name", "match_type", "max_size", "key", "actions"]
    def __init__(self, table_attrs):
        self.name = table_attrs["name"]
        self.match_type = table_attrs['match_type']
        self.depth = table_attrs['max_size']
        self.key = table_attrs.get('key', None)
        self.actions = table_attrs.get('actions', None)
        self.next_tables= table_attrs.get('next_tables', None)
        self.req_name = "%sReqT" % (CamelCase(self.name))
        self.request = StructT(self.req_name)
        self.rsp_name = "%sRspT" % (CamelCase(self.name))
        self.response = StructT(self.rsp_name)

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
        TMP1 = "let data = rx_info_%(name)s.get;"
        TMP2 = "match {.pkt, .meta} = data;"
        TMP3 = "%(type)s req = %(type)s {%(field)s};"
        TMP4 = "matchTable.lookupPort.request.put(pack(req));"
        TMP5 = "let %(name)s = fromMaybe(?, meta.%(name)s);"
        TMP6 = "{%(field)s}"
        rname = "rl_handle_request"
        stmt = []
        stmt.append(ast.Template(TMP1, {"name": "metadata"}))
        stmt.append(ast.Template(TMP2))
        keys = self.buildMatchKey()
        fields = []
        for k in keys:
            stmt.append(ast.Template(TMP5, {"name": "$".join(k)}))
            fields.append("%s: %s"%("$".join(k), "$".join(k)))
        stmt.append(ast.Template(TMP3, {"type": self.req_name, "field": ",".join(fields)}))
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

        TMP8 = "BBRequest req = tagged BB%(type)sRequest {%(field)s};"
        TMP9 = "bbReqFifo[%(id)s].enq(req); //FIXME: replace with RXTX."

        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        case_stmt = ast.Case("resp.p4_action")

        for idx, action in enumerate(self.actions):
            action_stmt = []
            action_stmt.append(ast.Template(TMP8, {"type": CamelCase(action),
                                                   "field": "FIXME"}))
            action_stmt.append(ast.Template(TMP9, {"id": idx}))
            case_stmt.casePatItem[action] = action.upper()
            case_stmt.casePatStmt[action] = action_stmt

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
        TMP1 = "let v <- toGet(bbRespFifo[readyChannel]).get;"
        TMP2 = "let meta <- toGet(metadata_ff[1]).get;"
        TMP3 = "tagged BB%(name)sResponse {FIXME}"
        TMP4 = "MetadataRspT rsp = MetadataRspT {pkt: pkt, meta: meta};"
        TMP5 = "tx_info_%(name)s.put(rsp);"

        stmt = []
        case_stmt = ast.Case("v")

        action_stmt = []
        action_stmt.append(ast.Template("//FIXME: modify metadata from basic block"))
        action_stmt.append(ast.Template(TMP4 % {"name": CamelCase(self.name)}))
        action_stmt.append(ast.Template(TMP5 % {"name": "metadata"}))

        for idx, action in enumerate(self.actions):
            case_stmt.casePatItem[action] = TMP3 % {"name": CamelCase(action)}
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
        TMP3 = "TX #(%(type)sResponse) tx_%(name)s <- mkTX;"
        TMP2 = "let rx_info_%(name)s = rx_%(name)s.u;"
        TMP4 = "let tx_info_%(name)s = tx_%(name)s.u;"
        stmt = []
        pdict = {'type': CamelCase(pname), 'name': pname}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP3, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildRuleActionRequest(self):
        TMP1 = "let data = rx_info_%(name)s.get;"
        TMP2 = "match {.pkt, .meta} = data;"

        TMP8 = "BBRequest req = tagged BB%(type)sRequest {%(field)s};"
        TMP9 = "bbReqFifo[%(id)s].enq(req); //FIXME: replace with RXTX."

        stmt = []
        stmt.append(ast.Template(TMP1, {"name": "metadata"}))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template("packet_ff.enq(pkt);"))
        stmt.append(ast.Template("metadata_ff[0].enq(meta);"))
        for idx, action in enumerate(self.actions):
            stmt.append(ast.Template(TMP8, {"type": CamelCase(action), "field": "FIXME"}))
            stmt.append(ast.Template(TMP9, {"id": idx}))

        rname = "rl_handle_action_request"
        cond = []
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleActionResponse(self):
        TMP1 = "let v <- toGet(bbRespFifo[readyChannel]).get;"
        TMP2 = "let meta <- toGet(metadata_ff[1]).get;"
        TMP3 = "tagged BB%(name)sResponse {FIXME}"
        TMP4 = "MetadataRspT rsp = MetadataRspT {pkt: pkt, meta: meta};"
        TMP5 = "tx_info_%(name)s.put(rsp);"

        stmt = []
        case_stmt = ast.Case("v")

        action_stmt = []
        action_stmt.append(ast.Template("// FIXME: modify metadata from basic block"))
        action_stmt.append(ast.Template(TMP4 % {"name": CamelCase(self.name)}))
        action_stmt.append(ast.Template(TMP5 % {"name": "metadata"}))

        for idx, action in enumerate(self.actions):
            case_stmt.casePatItem[action] = TMP3 % {"name": CamelCase(action)}
            case_stmt.casePatStmt[action] = action_stmt

        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(case_stmt)

        rname = "rl_handle_action_response"
        cond = "interruptStatus"
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildModuleStmt(self):
        TMP1 = "Vector#(%(num)s, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);"
        TMP2 = "Vector#(%(num)s, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);"
        TMP3 = "MatchTable#(%(sz)s, SizeOf#(%(reqT)s), SizeOf#(%(rspT)s) tbl <- mkMatchTable();"
        TMP4 = "interface next_control_state_%(id)s = toClient(bbReqFifo[%(id)s], bbRespFifo[%(id)s]]);"
        TMP5 = "interface prev_control_state_%(id)s = toServer(tx_info_%(name)s.e, rx_info_%(name)s.e);"
        TMP6 = "Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);"

        stmt = []
        stmt += self.buildTXRX("metadata")

        num = len(self.actions)
        stmt.append(ast.Template(TMP1, {"num": num}))
        stmt.append(ast.Template(TMP2, {"num": num}))

        if len(self.key) != 0:
            reqT = "%sReqT" % (CamelCase(self.name))
            rspT = "%sRspT" % (CamelCase(self.name))
            pdict = {"sz": self.depth, "reqT": reqT, "rspT": rspT}
            stmt.append(ast.Template(TMP3, pdict))

        pdict = {"sz": num, "szminus1": num-1, "fifo": "bbRspFifo"}
        stmt.append(ast.Template(IRQ_TEMPLATE, pdict))

        if len(self.key) != 0:
            stmt.append(ast.Template(TMP6))
            stmt.append(self.buildRuleMatchRequest())
            stmt.append(self.buildRuleExecuteAction())
            stmt.append(self.buildRuleMatchResponse())
        else:
            stmt.append(self.buildRuleActionRequest())
            stmt.append(self.buildRuleActionResponse())

        stmt.append(ast.Template(TMP5 % {"name": "metadata","id": 0}))
        for idx, _ in enumerate(self.actions):
            stmt.append(ast.Template(TMP4 % {"id": idx}))
        return stmt

    def emitInterface(self, builder):
        logger.info("emitTable: {}".format(self.name))
        TMP1 = "prev_control_state_%(id)s"
        TMP2 = "Server #(MetadataReqT, MetadataRspT)"
        TMP3 = "next_control_state_%(id)s"
        TMP4 = "Client #(BBRequest, BBResponse)"
        iname = CamelCase(self.name)
        intf = ast.Interface(iname, None, [], None)
        subintf_s = ast.Interface(TMP1 % {"id": 0}, None, [], TMP2)
        intf.subinterfaces.append(subintf_s)
        for idx, _ in enumerate(self.actions):
            subintf_c = ast.Interface(TMP3 % {"id": idx}, None, [], TMP4)
            intf.subinterfaces.append(subintf_c)
        intf.emit(builder)

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
        pass

    def emitValueType(self, builder):
        pass

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.emitKeyType(builder)
        self.emitValueType(builder)
        self.emitInterface(builder)
        self.emitModule(builder)

