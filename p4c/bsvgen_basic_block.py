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
import primitives as prm
from lib.exceptions import CompilationException

logger = logging.getLogger(__name__)

class BasicBlock(object):
    def __init__(self, basicblock_attrs):
        self.name = basicblock_attrs['name']
        self.primitives = []
        for p in basicblock_attrs['primitives']:
            obj = self.buildPrimitives(p)
            assert obj is not None
            self.primitives.append(obj)

    #
    # A few source-level optimizations that I have encountered
    # - bypass_RAW: replace register_read with modify_field
    #
    def bypass_RAW(self):
        """
        if register is read after write in the same 
        action block, rename the source register in
        read inst to the value in write inst.
        """

        def check_raw(wset, p):
            for s in wset:
                dst_reg = s.parameters[0]
                dst_idx = s.parameters[1]
                dst_field = s.parameters[2]
                src_reg = p.parameters[1]
                src_idx = p.parameters[2]
                if dst_reg == src_reg and dst_idx == src_idx:
                    return dst_field
            return None

        newPrimitives = []

        rset = set()
        wset = set()
        for p in self.primitives:
            if type(p) == prm.RegisterRead:
                rset.add(p)
                dst_field = check_raw(wset, p)
                if dst_field:
                    # RAW exists, forward
                    logger.debug("DEBUG: execute RAW bypass")
                    param = []
                    param.append(p.parameters[0])
                    param.append(dst_field)
                    _p = prm.ModifyField("modify_field", param)
                    newPrimitives.append(_p)
                else:
                    newPrimitives.append(p)
            elif type(p) == prm.RegisterWrite:
                wset.add(p)
                newPrimitives.append(p)
            else:
                newPrimitives.append(p)

        self.primitives = newPrimitives

    def buildPrimitives(self, p):
        """
        json dict -> python object
        very dumb job.
        """
        if p['op'] == "register_read":
            return prm.RegisterRead(p['op'], p['parameters'])
        elif p['op'] == 'register_write':
            return prm.RegisterWrite(p['op'], p['parameters'])
        elif p['op'] == 'modify_field':
            return prm.ModifyField(p['op'], p['parameters'])
        elif p['op'] == 'remove_header':
            return prm.RemoveHeader(p['op'], p['parameters'])
        elif p['op'] == 'add_header':
            return prm.AddHeader(p['op'], p['parameters'])
        elif p['op'] == 'drop':
            return prm.Drop(p['op'], p['parameters'])
        elif p['op'] == 'no_op':
            return prm.Nop(p['op'], p['parameters'])
        else:
            raise Exception("Unsupported primitive", p['op'])
        return None

    def buildClientInterfaces(self):
        """ Client interface for register """
        stmt = []
        for p in self.primitives:
            stmt += p.buildInterface()
        return stmt

    def buildServerInterfaces(self):
        """ Server interface for metadata """
        stmt = []
        return stmt

    def buildFFs(self):
        return []

    def buildPacketFF(self):
        TMP1 = "curr_packet_ff.enq(pkt);"
        stmt = []
        stmt.append(ast.Template(TMP1))
        return stmt

    def buildHandleRequest(self):
        TMP1 = "tagged %(type)s {%(field)s}"
        rules = []
        stmt = []
        rname = self.name + "_request"
        cname = CamelCase(self.name)
        ctype = "ReqT" #FIXME
        pdict = {"type": ctype, "field": []}
        casePatStmts = []
        for p in self.primitives:
            if p.isRegRead():
                casePatStmts += p.buildReadRequest()
            if p.isRegWrite():
                casePatStmts += p.buildWriteRequest()
        casePatStmts += self.buildPacketFF()

        case_stmt = ast.Case("v")
        case_stmt.casePatItem[ctype] = ast.Template(TMP1, pdict)
        case_stmt.casePatStmt[ctype] = casePatStmts
        stmt.append(case_stmt)
        rule = ast.Rule(rname, [], stmt)
        rules.append(rule)
        return rules

    def buildHandleResponse(self):
        TMP1 = "let pkt <- toGet(curr_packet_ff).get;"
        TMP2 = "BasicBlockResponse rsp = tagged %(type)s {%(field)s};"
        TMP3 = "%(name)s_response_ff.enq(rsp);"
        rules = []
        stmt = []
        rname = self.name + "_response"
        for p in self.primitives:
            if p.isRegRead():
                stmt += p.buildReadResponse()
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2, {"type": "RespT", "field": []}))
        stmt.append(ast.Template(TMP3, {"name": self.name}))
        rule = ast.Rule(rname, [], stmt)
        rules.append(rule)
        return rules

    def buildModuleStmt(self):
        """
        first performing a RAW renaming within the same block
        then build the action module
        """
        stmt = []
        stmt += self.buildFFs()
        for p in self.primitives:
            stmt += p.buildTXRX()
        stmt += self.buildHandleRequest()
        stmt += self.buildHandleResponse()
        for p in self.primitives:
            stmt += p.buildInterfaceDef();
        return stmt

    def build(self):
        """ perform any optimization before code generation """
        self.bypass_RAW()

    def emitInterface(self, builder):
        logger.info("emitBasicBlockIntf: {}".format(self.name))
        iname = CamelCase(self.name)
        stmt = []
        stmt += self.buildClientInterfaces()
        stmt += self.buildServerInterfaces()
        intf = ast.Interface(iname, subinterfaces=stmt)
        intf.emit(builder)

    def emitModule(self, builder):
        logger.info("emitBasicBlockModule: {}".format(self.name))
        mname = "mk%(name)s" % {"name": CamelCase(self.name)}
        iname = CamelCase(self.name)
        params = []
        provisos = []
        decls = []
        stmt = self.buildModuleStmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.build()
        self.emitInterface(builder)
        self.emitModule(builder)

