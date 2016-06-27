# Copyright 2016 Han Wang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import logging
import lib.ast as ast
from lib.utils import CamelCase, camelCase
from lib.exceptions import CompilationException
from collections import OrderedDict

logger = logging.getLogger(__name__)

class Control (object):
    """
        Control module maps to a pipeline
    """
    def __init__(self, name):
        self.name = name
        self.init_table = None
        self.tables = OrderedDict()
        self.conditionals = OrderedDict()
        self.basic_blocks = []
        self.registers = []
        self.entry = []

    def buildFFs(self):
        TMP1 = "FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;"
        TMP2 = "FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;"
        TMP3 = "FIFOF#(MetadataRequest) %(name)s_req_ff <- mkFIFOF;"
        TMP4 = "FIFOF#(MetadataResponse) %(name)s_rsp_ff <- mkFIFOF;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        for t in self.tables.values():
            stmt.append(ast.Template(TMP3, {"name": t.name} ))
            stmt.append(ast.Template(TMP4, {"name": t.name} ))
        return stmt

    def buildRegisterArrays(self):
        TMP1 = "RegisterIfc#(%(asz)s, %(dsz)s) %(name)s <- mkP4Register(%(client)s);"
        stmt = []
        for r in self.registers:
            dsz = r['bitwidth']
            asz = r['size']
            name = r['name']
            stmt.append(ast.Template(TMP1, {"asz": asz, "dsz": dsz, "name": name, "client": "nil"}))
        return stmt

    def buildBasicBlocks(self):
        TMP1 = "%(type)s %(name)s <- mk%(type)s();"
        stmt = []
        stmt.append(ast.Template("// Basic Blocks"))
        for b in self.basic_blocks:
            name = b.name
            stmt.append(ast.Template(TMP1, {"type": CamelCase(name), "name": name}))
        return stmt

    def buildBasicBlockConnection(self):
        TMP1 = "mkConnection(%(tbl)s.next_control_state_%(id)s, %(bb)s.prev_control_state);"
        stmt = []
        for k, v in self.tables.items():
            for idx, action in enumerate(v.actions):
                stmt.append(ast.Template(TMP1, {"tbl": k, "id": idx, "bb": action}))
        return stmt

    def buildRegisterMakeChan(self):
        #mkChan(mkFIFOF, );
        pass

    def buildConnection(self):
        TMP1 = "Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));"
        TMP2 = "mkConnection(mds, mdc);"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        return stmt

    def buildTableInstance(self):
        TMP1 = "%(tblType)s %(tblName)s <- mk%(tblType)s();"
        TMP2 = "mkConnection(toClient(%(tblName)s_req_ff, %(tblName)s_rsp_ff), %(tblName)s.prev_control_state_%(id)s);"
        stmt = []
        for t in self.tables.values():
            stmt.append(ast.Template(TMP1, {"tblType": CamelCase(t.name),
                                            "tblName": t.name}))
        for t in self.tables.values():
            stmt.append(ast.Template(TMP2, {"tblName": t.name,
                                            "id": 0}))
        return stmt

    def buildDefaultRuleStmt(self, nextState):
        TMP1 = "default_req_ff.deq;"
        TMP2 = "let _req = default_req_ff.first;"
        TMP3 = "let meta = _req.meta;"
        TMP4 = "let pkt = _req.pkt;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        stmt.append(ast.Template(TMP3))
        stmt.append(ast.Template(TMP4))
        return stmt

    def buildIfStmt(self, true=None, false=None):
        # conditional table
        _if = ast.If()
        if true:
            _if.stmt += self.buildIfStmt(true, false)
        if false:
            _if.stmt += self.buildIfStmt(true, false)
        return _if


    def buildConditionalStmt(self, tblName, stmt):
        TMP1 = "MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};"
        TMP2 = "%(name)s_req_ff.enq(req);"
        def search_conditional (name):
            for key, cond in self.conditionals.items():
                #print key, cond
                if key == name:
                    return cond
            return None

        if tblName is None:
            stmt.append(ast.Template("MetadataRequest request = MetadataRequest {pkt: pkt, meta: meta};"))
            #stmt.append(ast.Template("currPacketFifo.enq(req);"))

        if tblName in self.tables:
            next_tables = self.tables[tblName].next_tables
            for next_table in next_tables.values():
                if next_table is None:
                    #stmt.append(ast.Template("currPacketFifo.enq(req);"))
                    pass
                elif next_table in self.conditionals:
                    self.buildConditionalStmt(next_table, stmt)
                else:
                    raise Exception("ERROR: ConditionalStmt", tblName, next_table)

        if tblName in self.conditionals:
            cond = search_conditional(tblName)
            expr = cond['expression']
            #print 'www', expr
            true_next = cond['true_next']
            false_next = cond['false_next']
            if true_next in self.tables:
                _stmt = []
                _stmt.append(ast.Template(TMP1, {"name": CamelCase(true_next)}))
                _stmt.append(ast.Template(TMP2, {"name": true_next}))
                stmt.append(ast.If(expr, _stmt))
            if false_next in self.tables:
                _stmt = []
                _stmt.append(ast.Template(TMP1, {"name": CamelCase(false_next)}))
                _stmt.append(ast.Template(TMP2, {"name": false_next}))
                stmt.append(ast.Else(_stmt))

            if true_next in self.conditionals:
                _stmt = []
                self.buildConditionalStmt(true_next, _stmt)
                stmt.append(ast.If(expr, _stmt))
            if false_next in self.conditionals:
                _stmt = []
                self.buildConditionalStmt(false_next, _stmt)
                stmt.append(ast.Else(_stmt))
        return stmt

    def buildTableRuleStmt(self, tblName):
        TMP1 = "%(tblName)s_rsp_ff.deq;"
        TMP2 = "let _req = %(tblName)s_rsp_ff.first;"
        TMP3 = "let meta = _req.meta;"
        TMP4 = "let pkt = _req.pkt;"
        stmt = []
        stmt.append(ast.Template(TMP1, {"tblName": tblName}))
        stmt.append(ast.Template(TMP2, {"tblName": tblName}));
        stmt.append(ast.Template(TMP3));
        stmt.append(ast.Template(TMP4));
        _stmt = []
        self.buildConditionalStmt(tblName, _stmt)
        stmt += _stmt
        return stmt

    def buildRules(self):
        TMP1 = "%(name)s_req_ff.notEmpty"#first matches tagged %(type)sRequest {pkt: .pkt, meta: .meta}"
        TMP2 = "%(name)s_rsp_ff.notEmpty"#first matches tagged %(type)sRequest {pkt: .pkt, meta: .meta}"
        rules = []
        rname = "default_next_state"
        cond = TMP1 % ({"name": "default", "type": "Default"})
        stmt = self.buildDefaultRuleStmt(self.init_table)
        _stmt = []
        self.buildConditionalStmt(self.init_table, _stmt)
        stmt += _stmt
        rule = ast.Rule(rname, cond, stmt)
        rules.append(rule)
        for t in self.tables.values():
            rname = t.name + "_next_state"
            cond = TMP2 % ({"name": t.name, "type": CamelCase(t.name)})
            stmt = self.buildTableRuleStmt(t.name)
            rule = ast.Rule(rname, cond, stmt)
            rules.append(rule)
        return rules

    def buildMethodDefs(self):
        pass

    def buildModuleStmt(self):
        stmt = []
        stmt += self.buildFFs()
        stmt += self.buildConnection()
        stmt += self.buildTableInstance()
        stmt += self.buildBasicBlocks()
        stmt += self.buildRegisterArrays()
        stmt += self.buildBasicBlockConnection()
        stmt += self.buildRules()
        return stmt

    def emitInterface(self, builder):
        iname = CamelCase(self.name)
        table_intf = ast.Interface(iname, [], [], [])
        intf0 = ast.Interface("eventPktSend", None, [], "PipeOut#(MetadataRequest)")
        table_intf.subinterfaces.append(intf0)
        #method0 = ast.Method("add_entry", "Action", [])
        #table_intf.methodProto = [ method0 ]
        table_intf.emit(builder)

    def emitModule(self, builder):
        mname = "mk{}".format(CamelCase(self.name))
        iname = CamelCase(self.name)
        params = []
        decls = ["Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc"]
        provisos = []
        stmt = self.buildModuleStmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        for t in self.tables.values():
            t.emit(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
