# Copyright 2016 P4FPGA Project
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

import astbsv as ast
from bsvgen_common import emit_license, emit_import

class TopMemory(object):
    def __init__(self, p4name):
        self.p4name = p4name

    def emit_import(self, builder):
        TMP1 = "import %s::*;"
        modules = ["Connectable",
                   "Clocks",
                   "BuildVector",
                   "GetPut",
                   "HostChannel",
                   "TxChannel",
                   "PacketBuffer",
                   "SharedBuff",
                   "Sims",
                   "Ingress", # should come from arch.p4
                   "Egress", # should come from arch.p4
                   "MainAPI"
                   ]
        for x in sorted(modules):
            builder.append(ast.Template(TMP1 % x))
            builder.newline()

    def buildModule(self):
        TMP = []
        TMP.append("let verbose = True;")
        TMP.append("Clock defaultClock <- exposeCurrentClock();")
        TMP.append("Reset defaultReset <- exposeCurrentReset();")
        TMP.append("`ifdef SIMULATION")
        TMP.append("SimClocks clocks <- mkSimClocks();")
        TMP.append("Clock txClock = clocks.clock_156_25;")
        TMP.append("Clock phyClock = clocks.clock_644_53;")
        TMP.append("Clock mgmtClock = clocks.clock_50;")
        TMP.append("Clock rxClock = txClock;")
        TMP.append("Reset txReset <- mkSyncReset(2, defaultReset, txClock);")
        TMP.append("Reset phyReset <- mkSyncReset(2, defaultReset, phyClock);")
        TMP.append("Reset mgmtReset <- mkSyncReset(2, defaultReset, mgmtClock);")
        TMP.append("Reset rxReset = txReset;")
        TMP.append("`endif")
        TMP.append("HostChannel hostchan <- mkHostChannel();")
        TMP.append("Ingress ingress <- mkIngress(vec(hostchan.next));")
        TMP.append("Egress egress <- mkEgress(vec(ingress.next));")
        TMP.append("TxChannel txchan <- mkTxChannel(txClock, txReset);")

        TMP.append("SharedBuffer#(12, 128, 1) mem <- mkSharedBuffer(vec(txchan.readClient), vec(txchan.freeClient), vec(hostchan.writeClient), vec(hostchan.mallocClient), memServerInd);")
        TMP.append("mkConnection(egress.next, txchan.prev);")
        TMP.append("`ifdef SIMULATION")
        TMP.append("rule drain_mac;")
        TMP.append("   let v <- toGet(txchan.macTx).get;")
        TMP.append("   if (verbose) $display(\"(%%0d) tx data \", $time, fshow(v));")
        TMP.append("endrule")
        TMP.append("`endif")
        TMP.append("MainAPI api <- mkMainAPI(indication, hostchan, ingress, txchan);")
        TMP.append("interface request = api.request;")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt

    def emitInterface(self, builder):
        intf = ast.Interface(typedef="Main")
        intf.subinterfaces.append(ast.Interface("request", "MainRequest"))
        intf.emitInterfaceDecl(builder)

    def emitModule(self, builder):
        mname = "mkMain"
        decls = []
        decls.append("MainIndication indication")
        decls.append("ConnectalMemory::MemServerIndication memServerInd")
        iname = "Main"
        params = []
        provisos = []
        stmt = self.buildModule()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        self.emit_import(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
        emit_license(builder)

class TopStream(object):
    def __init__(self, p4name):
        self.p4name = p4name

    def emit_import(self, builder):
        TMP1 = "import %s::*;"
        modules = ["Connectable",
                   "Clocks",
                   "BuildVector",
                   "GetPut",
                   "HostChannel",
                   "StreamChannel",
                   "PacketBuffer",
                   "SharedBuff",
                   "Sims",
                   "Ingress", # should come from arch.p4
                   "Egress", # should come from arch.p4
                   "MainAPI"
                   ]
        for x in sorted(modules):
            builder.append(ast.Template(TMP1 % x))
            builder.newline()


    def build_module(self):
        TMP = []
        TMP.append("let verbose = True;")
        TMP.append("Clock defaultClock <- exposeCurrentClock();")
        TMP.append("Reset defaultReset <- exposeCurrentReset();")
        TMP.append("`ifdef SIMULATION")
        TMP.append("SimClocks clocks <- mkSimClocks();")
        TMP.append("Clock txClock = clocks.clock_156_25;")
        TMP.append("Clock phyClock = clocks.clock_644_53;")
        TMP.append("Clock mgmtClock = clocks.clock_50;")
        TMP.append("Clock rxClock = txClock;")
        TMP.append("Reset txReset <- mkSyncReset(2, defaultReset, txClock);")
        TMP.append("Reset phyReset <- mkSyncReset(2, defaultReset, phyClock);")
        TMP.append("Reset mgmtReset <- mkSyncReset(2, defaultReset, mgmtClock);")
        TMP.append("Reset rxReset = txReset;")
        TMP.append("`endif")
        TMP.append("HostChannel hostchan <- mkHostChannel();")
        TMP.append("Ingress ingress <- mkIngress(vec(hostchan.next));")
        TMP.append("Egress egress <- mkEgress(vec(ingress.next));")
        TMP.append("StreamOutChannel txchan <- mkStreamOutChannel(txClock, txReset);")

        TMP.append("PacketBuffer buff <- mkPacketBuffer();")
        TMP.append("mkConnection(egress.next, txchan.prev);")
        TMP.append("`ifdef SIMULATION")
        TMP.append("rule drain_mac;")
        TMP.append("   let v <- toGet(txchan.macTx).get;")
        TMP.append("   if (verbose) $display(\"(%%0d) tx data \", $time, fshow(v));")
        TMP.append("endrule")
        TMP.append("`endif")
        TMP.append("MainAPI api <- mkMainAPI(indication, hostchan, ingress, txchan);")
        TMP.append("interface request = api.request;")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt



    def emit_interface(self, builder):
        intf = ast.Interface(typedef = "Main")
        intf.subinterfaces.append(ast.Interface('request', 'MainRequest'))
        intf.emitInterfaceDecl(builder)

    def emit_module(self, builder):
        mname = "mkMain"
        decls = []
        decls.append("MainIndication indication")
        iname = "Main"
        params = []
        provisos = []
        stmt = self.build_module()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        self.emit_import(builder)
        self.emit_interface(builder)
        self.emit_module(builder)
        emit_license(builder)

class API():
    def __init__(self, p4name):
        self.p4name = p4name

    def emit_import(self, builder):
        TMP1 = "import %s::*;"
        modules = ["Connectable",
                   "Clocks",
                   "DefaultValue",
                   "Ethernet",
                   "BuildVector",
                   "GetPut",
                   "HostChannel",
                   "PacketBuffer",
                   "TxChannel",
                   "Vector",
                   "MainDefs",
                   "Ingress", # should come from arch.p4
                   "Egress", # should come from arch.p4
                   ]
        for x in sorted(modules):
            builder.append(ast.Template(TMP1 % x))
            builder.newline()

    # Default API function
    def build_read_version(self):
        TMP1 = "let v = `NicVersion;"
        TMP2 = "indication.read_version_rsp(v);"
        name = "read_version"
        rtype = "Action"
        params = "Bit#(32) version"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        req = ast.Method(name, rtype, stmt=stmt)
        rsp = ast.Method(name+"_rsp", rtype, params)
        return req, rsp

    def build_writePacketData(self):
        TMP = []
        TMP.append("EtherData beat = defaultValue;")
        TMP.append("beat.data = pack(reverse(data));")
        TMP.append("beat.mask = pack(reverse(mask));")
        TMP.append("beat.sop = unpack(sop);")
        TMP.append("beat.eop = unpack(eop);")
        TMP.append("hostchan.writeServer.writeData.put(beat);")
        name = "writePacketData"
        rtype = "Action"
        params = "Vector#(2, Bit#(64)) data, Vector#(2, Bit#(8)) mask, Bit#(1) sop, Bit#(1) eop"
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        req = ast.Method(name, rtype, params, stmt=stmt)
        return req

    def build_verbosity(self):
        TMP = []
        TMP.append("hostchan.set_verbosity(unpack(verbosity));")
        TMP.append("txchan.set_verbosity(unpack(verbosity));")
        TMP.append("ingress.set_verbosity(unpack(verbosity));")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        name = "set_verbosity"
        rtype = "Action"
        params = "Bit#(32) verbosity"
        req = ast.Method(name, rtype, params, stmt=stmt)
        return req

    def buildModule(self):
        stmt = []
        stmt.append(self.buildRequestInterface())
        return stmt

    def buildRequestInterface(self):
        intf = ast.Interface(name="request", typedef="MainRequest")
        intf.subinterfaces.append(self.build_read_version()[0])
        intf.subinterfaces.append(self.build_writePacketData())
        intf.subinterfaces.append(self.build_verbosity())
        return intf

    def buildResponseInterface(self):
        intf = ast.Interface(typedef="MainIndication")
        intf.subinterfaces.append(self.build_read_version()[1])
        return intf

    def emitInterface(self, builder):
        req_intf = self.buildRequestInterface()
        req_intf.emitInterfaceDecl(builder)
        rsp_intf = self.buildResponseInterface()
        rsp_intf.emitInterfaceDecl(builder)
        intf = ast.Interface(typedef="MainAPI")
        intf.subinterfaces.append(req_intf)
        intf.emitInterfaceDecl(builder)

    def emitModule(self, builder):
        mname = "mkMainAPI"
        decls = []
        decls.append("MainIndication indication")
        decls.append("HostChannel hostchan")
        decls.append("Ingress ingress")
        decls.append("TxChannel txchan")
        iname = "MainAPI"
        params = []
        provisos = []
        stmt = self.buildModule()
        builder.emitIndent()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        self.emit_import(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
        emit_license(builder)

class Defs:
    def __init__(self, typedefs):
        self.typedefs = typedefs

    def emit(self, builder):
        for t in self.typedefs:
            t.emit(builder)

