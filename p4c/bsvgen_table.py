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
from bsvgen_common import generate_table
from lib.sourceCodeBuilder import SourceCodeBuilder
from lib.utils import CamelCase
import lib.ast as ast

logger = logging.getLogger(__name__)

TBL_TEMPLATE = "MatchTable#(%(sz)s, SizeOf#(%(reqT)s), SizeOf#(%(rspT)s) tbl <- mkMatchTable();"

IRQ_TEMPLATE = """Vector#(%(sz)s, Bool) readyBits = map(fifoNotEmpty, %(fifo)s);
    Bool interruptStatus = False;
    Bit#(16) readyChannel = -1;
    for (Integer i=%(szminus1)s; i>=0; i=i-1) begin
        if (readyBits[i]) begin
            interruptStatus = True;
            readyChannel = fromInteger(i);
        end
    end
"""

META_IN_TEMPLATE = """let md <- metadata.request.get;"""
MATCH_LOOKUP_TEMPLATE = """matchTable.lookupPort.request.put(pack(req));"""

class Table(object):
    required_attributes = ["name", "match_type", "max_size", "key", "actions"]
    def __init__(self, table_attrs):
        #check_attributes(name, table_attrs, Table.required_attributes)
        self.name = table_attrs["name"]
        self.match_type = table_attrs['match_type']
        self.depth = table_attrs['max_size']
        self.key = table_attrs.get('key', None)
        #self.req_attrs = table_attrs['request']
        #self.rsp_attrs = table_attrs['response']
        self.actions = table_attrs.get('actions', None)
        self.next_tables= table_attrs.get('next_tables', None)

    def __repr__(self):
        return "{} ({}, {}, {}, {})".format(
                    self.__class__.__name__,
                    self.match_type,
                    self.depth,
                    self.key,
                    self.actions)

    def buildRuleRequestStmt(self):
        EXPR_CASE_PATT = "tagged %(case)s {pkt: .pkt, meta: .meta}"
        stmt = []
        stmt.append(ast.Template(META_IN_TEMPLATE, []))
        case_stmt = ast.Case("metadata")
        logger.debug("TODO: FIX Request Type.")
        pdict = {"case": "ReqT"}
        case_stmt.casePatItem["ReqT"] = ast.Template(EXPR_CASE_PATT, pdict)
        casePatStmts = []
        logger.debug("TODO: GET lookup key from metadata")
        logger.debug("TODO: BUILD lookup request")
        casePatStmts.append(ast.Template(MATCH_LOOKUP_TEMPLATE, []))
        case_stmt.casePatStmt["ReqT"] = casePatStmts
        stmt.append(case_stmt)
        return stmt

    def buildRuleRequest(self):
        rname = "rl_handle_request"
        cond = []
        stmt = self.buildRuleRequestStmt()
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleExecuteActionStmt(self):
        ACTIONS = [ "NOP", "FORWARD" ] #FIXME
        TMP1 = "let v <- matchTable.lookupPort.response.get;"
        TMP2 = "let pkt <- toGet(packetPipelineFifo).get;"
        TMP3 = "let metadata <- toGet(metadataPipelineFifo[0]).get;"
        TMP4 = "RspT resp = unpack(data);"
        TMP5 = "let _act = tagged {} {e: resp.p4_action};"
        TMP6 = "meta.table_action = tagged Valid _act;"
        TMP7 = "metadataPipelineFifo[1].enq(meta);"

        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        if_stmt = ast.If("v matches tagged Valid .data", [])
        case_stmt = ast.Case("resp.p4_action")

        action = []
        action.append(ast.Template("BBRequest req = tagged {} {pkt: pkt};", []))
        action.append(ast.Template("bbReqFifo[{}].enq(req);", []))

        case_stmt.casePatItem["NOP"] = "NOP"
        case_stmt.casePatItem["FORWARD"] = "FORWARD"
        case_stmt.casePatStmt["NOP"] = action
        case_stmt.casePatStmt["FORWARD"] = action

        if_stmt.stmt.append(ast.Template(TMP4))
        if_stmt.stmt.append(case_stmt)
        if_stmt.stmt.append(ast.Template(TMP5))
        if_stmt.stmt.append(ast.Template(TMP6))
        if_stmt.stmt.append(ast.Template(TMP7))
        stmt.append(if_stmt)
        return stmt

    def buildRuleExecuteAction(self):
        rname = "rl_handle_execute"
        cond = []
        stmt = self.buildRuleExecuteActionStmt()
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildRuleResponseStmt(self):
        logger.debug("TODO: fix Resp type")
        TMP1 = "let v <- toGet(bbRespFifo[readyChannel]).get;"
        TMP2 = "let meta <- toGet(metadataPipelineFifo[1]).get;"
        TMP3 = "tagged %(case)s {pkt: .pkt, meta: .meta}"
        TMP4 = "MetadataResponse rsp = tagged RoutingTableResponse {pkt: .pkt, meta: .meta};"
        TMP5 = "md.response.put(rsp);"

        stmt = []
        case_stmt = ast.Case("v")

        actions = []
        #FIXME: if action modifies metadata, update metadata
        actions.append(ast.Template(TMP4))
        actions.append(ast.Template(TMP5))

        case_stmt.casePatItem["BBNopResponse"] = ast.Template(TMP3, {"case": "BBNopResponse"})
        case_stmt.casePatStmt["BBNopResponse"] = actions
        case_stmt.casePatItem["BBForwardResponse"] = ast.Template(TMP3, {"case": "BBForwardResponse"})
        case_stmt.casePatStmt["BBForwardResponse"] = actions

        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(case_stmt)
        return stmt

    def buildRuleResponse(self):
        rname = "rl_handle_response"
        cond = "interruptStatus"
        stmt = self.buildRuleResponseStmt()
        rule = ast.Rule(rname, cond, stmt)
        return rule

    def buildModuleStmt(self):
        stmt = []
        pdict = {"sz": 256, "reqT": "ReqT", "rspT": "RspT"}
        stmt.append(ast.Template(TBL_TEMPLATE, pdict))
        pdict = {"sz": 16, "szminus1": 15, "fifo": "pipeout"}
        stmt.append(ast.Template(IRQ_TEMPLATE, pdict))
        stmt.append(self.buildRuleRequest())
        stmt.append(self.buildRuleExecuteAction())
        stmt.append(self.buildRuleResponse())
        return stmt

    def emitTableInterface(self, builder):
        logger.info("emitTable: {}".format(self.name))

        iname = CamelCase(self.name)
        table_intf = ast.Interface(iname, None, [], None)

        subintf_s = ast.Interface("prev_control_state_{}".format(0), None, [],
                    "Server #(BBRequest, BBResponse)") #FIXME
        table_intf.subinterfaces.append(subintf_s)

        subintf_c = ast.Interface("next_control_state_{}".format(0), None, [],
                    "Client #(BBRequest, BBResponse)")
        table_intf.subinterfaces.append(subintf_c)

        table_intf.emit(builder)

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
        self.emitTableInterface(builder)
        self.emitModule(builder)

