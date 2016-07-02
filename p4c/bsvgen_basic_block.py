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
import astbsv as ast
import primitives as prm
import exceptions
from utils import CamelCase
from bsvgen_struct import Struct, StructM
from collections import OrderedDict
from sourceCodeBuilder import SourceCodeBuilder

logger = logging.getLogger(__name__)

class BasicBlock(object):
    def __init__(self, basicblock_attrs, json_dict):
        def addRuntimeData(action, json_dict):
            fields = set()
            actions = json_dict['actions']
            for at in actions:
                if at['name'] == action:
                    rdata = at['runtime_data']
                    for d in rdata:
                        fields.add((d['bitwidth'], d['name']))
            return fields

        def addRawRuntimeData(action, json_dict):
            actions = json_dict['actions']
            for at in actions:
                if at['name'] == action:
                    rdata = at['runtime_data']
                    return rdata

        self.name = basicblock_attrs['name']
        self.primitives = []
        self.meta_read = set()
        self.meta_write = set()
        for p in basicblock_attrs['primitives']:
            obj, meta_read, meta_write = self.buildPrimitives(p)
            assert obj is not None
            self.primitives.append(obj)
            self.meta_read |= meta_read
            self.meta_write |= meta_write
        # perform RAW optimization
        # build mapping between dst_field and src_field
        self.bypass_map = None
        self.optimize()
        #print self.bypass_map

        header_types = json_dict['header_types']
        header_instances = json_dict['headers']

        # add runtime data to basic block request
        runtime_data = addRuntimeData(self.name, json_dict)
        self.runtime_data = runtime_data
        self.raw_runtime_data = addRawRuntimeData(self.name, json_dict)

        req_name = "%sReqT" % (CamelCase(self.name))
        self.request = StructM(req_name, self.meta_read, header_types, header_instances, runtime_data=runtime_data)

        rsp_name = "%sRspT" % (CamelCase(self.name))
        self.response = StructM(rsp_name, self.meta_write, header_types, header_instances, bypass_map=self.bypass_map)

        self.clientInterfaces = self.buildClientInterfaces(json_dict)
        self.serverInterfaces = self.buildServerInterfaces(json_dict)

        self.json_dict = json_dict
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
        bypass_map = OrderedDict()

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
                    _src = "$".join(dst_field['value'])
                    _dst = "$".join(p.parameters[0]['value'])
                    bypass_map[_dst] = _src
                    logger.info("BYPASS: %s", _p)
                    newPrimitives.append(_p)
                else:
                    newPrimitives.append(p)
            elif type(p) == prm.RegisterWrite:
                wset.add(p)
                newPrimitives.append(p)
            else:
                newPrimitives.append(p)

        self.primitives = newPrimitives
        self.bypass_map = bypass_map

    def buildPrimitives(self, p):
        def check_field(p, idx):
            if p['parameters'][idx]['type'] == 'field':
                return p['parameters'][idx]['value']
            return None
        def set_add(setv, p):
            assert type(setv) is set
            if p is not None:
                setv.add(tuple(p))
        """
        json dict -> python object
        very dumb job.
        """
        field_read = set()
        field_write = set()
        obj = None
        if p['op'] == "register_read":
            set_add(field_write, check_field(p, 0))
            set_add(field_read, check_field(p, 2))
            obj = prm.RegisterRead(p['op'], p['parameters'])
        elif p['op'] == 'register_write':
            set_add(field_read, check_field(p, 1))
            set_add(field_read, check_field(p, 2))
            obj = prm.RegisterWrite(p['op'], p['parameters'])
        elif p['op'] == 'modify_field':
            set_add(field_write, check_field(p, 0))
            set_add(field_read, check_field(p, 1))
            obj = prm.ModifyField(p['op'], p['parameters'])
        elif p['op'] == 'remove_header':
            obj = prm.RemoveHeader(p['op'], p['parameters'])
        elif p['op'] == 'add_header':
            obj = prm.AddHeader(p['op'], p['parameters'])
        elif p['op'] == 'drop':
            obj = prm.Drop(p['op'], p['parameters'])
        elif p['op'] == 'no_op':
            obj = prm.Nop(p['op'], p['parameters'])
        elif p['op'] == 'add_to_field':
            set_add(field_write, check_field(p, 0))
            set_add(field_read, check_field(p, 1))
            obj = prm.AddToField(p['op'], p['parameters'])
        elif p['op'] == 'subtract_from_field':
            set_add(field_write, check_field(p, 0))
            set_add(field_read, check_field(p, 1))
            obj = prm.SubtractFromField(p['op'], p['parameters'])
        elif p['op'] == 'clone_ingress_pkt_to_egress':
            obj = prm.CloneIngressPktToEgress(p['op'], p['parameters'])
        else:
            raise Exception("Unsupported primitive", p['op'])
        return obj, field_read, field_write

    def buildClientInterfaces(self, json_dict):
        """ Client interface for register """
        stmt = []
        for p in self.primitives:
            stmt += p.buildInterface(json_dict)
        return stmt

    def buildServerInterfaces(self, json_dict):
        """ Server interface for metadata """
        TMP1 = "Server#(BBRequest, BBResponse)"
        stmt = []
        iname = "prev_control_state"
        intf = ast.Interface(name=iname, typedef=TMP1)
        stmt.append(intf)
        return stmt

    def buildServerInterfaceDef(self):
        TMP1 = "interface %(name)s = toServer(rx_%(name)s.e, tx_%(name)s.e);"
        stmt = []
        pdict = {"name": "prev_control_state"}
        stmt.append(ast.Template(TMP1, pdict))
        return stmt

    def buildFFs(self):
        TMP1 = "FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        return stmt

    def buildTXRX(self):
        TMP1 = "RX #(BBRequest) rx_%(name)s <- mkRX;"
        TMP2 = "TX #(BBResponse) tx_%(name)s <- mkTX;"
        TMP3 = "let rx_info_%(name)s = rx_%(name)s.u;"
        TMP4 = "let tx_info_%(name)s = tx_%(name)s.u;"
        stmt = []
        pdict = {'name': "prev_control_state"}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP3, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildPacketFF(self):
        TMP1 = "curr_packet_ff.enq(pkt);"
        stmt = []
        stmt.append(ast.Template(TMP1))
        return stmt

    def buildHandleRequest(self):
        TMP1 = "tagged %(type)s {%(field)s}"
        TMP2 = "let v = rx_info_prev_control_state.first;"
        TMP3 = "rx_info_prev_control_state.deq;"
        rules = []
        stmt = []
        rname = self.name + "_request"
        cname = CamelCase(self.name)
        ctype = "%sReqT"%(cname)
        pdict = {"type": ctype, "field": self.request.build_match_expr()}
        casePatStmts = []
        for p in self.primitives:
            casePatStmts += p.buildRequest(self.json_dict, self.raw_runtime_data)
        casePatStmts += self.buildPacketFF()

        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))

        case_stmt = ast.Case("v")
        case_stmt.casePatItem[ctype] = ast.Template(TMP1, pdict)
        case_stmt.casePatStmt[ctype] = casePatStmts
        stmt.append(case_stmt)
        rule = ast.Rule(rname, [], stmt)
        rules.append(rule)
        return rules

    def buildHandleResponse(self):
        TMP1 = "let pkt <- toGet(curr_packet_ff).get;"
        TMP2 = "BBResponse rsp = tagged %(type)s {%(field)s};"
        TMP3 = "tx_info_prev_control_state.enq(rsp);"
        rules = []
        stmt = []
        rname = self.name + "_response"
        for p in self.primitives:
            stmt += p.buildResponse()
        # optimized bypass register
        # field must include bypass register
        stmt.append(ast.Template(TMP1))
        rsp_prefix = CamelCase(self.name)
        stmt.append(ast.Template(TMP2, {"type": "%sRspT"%(rsp_prefix),
                                        "field": self.response.build_case_expr()}))
        stmt.append(ast.Template(TMP3, {"name": self.name}))
        rule = ast.Rule(rname, [], stmt)
        rules.append(rule)
        return rules

    def buildModuleStmt(self):
        TMP1 = "Reg#(Bit#(%(dsz)s)) rg_%(field)s <- mkReg(0);"
        """
        first performing a RAW renaming within the same block
        then build the action module
        """
        stmt = []
        stmt += self.buildTXRX()
        stmt += self.buildFFs()
        #-- begin optimization
        regs = set()
        for p in self.primitives:
            stmt += p.buildTXRX(self.json_dict)
            _reg = p.getDstReg(self.json_dict)
            if _reg != None:
                regs.add(_reg)
        for r in regs:
            stmt.append(ast.Template(TMP1, {'dsz': r[0], 'field': r[1]}))
        #-- end optimization
        for p in self.primitives:
            stmt += p.buildTempReg(self.json_dict)
        stmt += self.buildHandleRequest()
        stmt += self.buildHandleResponse()
        for p in self.primitives:
            stmt += p.buildInterfaceDef();
        stmt += self.buildServerInterfaceDef()
        return stmt

    def optimize(self):
        """ perform any optimization before code generation """
        self.bypass_RAW()

    def emitStruct(self, builder):
        self.request.emit(builder)
        self.response.emit(builder)

    def emitInterface(self, builder):
        logger.info("emitBasicBlockIntf: {}".format(self.name))
        iname = CamelCase(self.name)
        stmt = []
        stmt += self.clientInterfaces
        stmt += self.serverInterfaces
        intf = ast.Interface(typedef=iname)
        intf.subinterfaces = stmt
        intf.emitInterfaceDecl(builder)

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
        builder.newline()
        builder.append("// ====== %s ======" % (self.name.upper()))
        builder.newline()
        builder.newline()
        assert isinstance(builder, SourceCodeBuilder)
        self.emitInterface(builder)
        self.emitModule(builder)

