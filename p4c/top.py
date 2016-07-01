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

from bsvgen_common import emit_license, emit_import
import lib.ast as ast

class Top(object):
    def __init__(self):
        pass

    def buildModule(self):
        TMP = []
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
        TMP.append("TxChannel txchan <- mkTxChannel(txClock, txReset);")

        TMP.append("SharedBuffer#(12, 128, 1) mem <- mkSharedBuffer(vec(txchan.readClient), vec(txchan.freeClient), vec(hostchan.writeClient), vec(hostchan.mallocClient), memServerInd);")
        TMP.append("mkConnection(ingress.eventPktSend, txchan.eventPktSend);")
        TMP.append("`ifdef SIMULATION")
        TMP.append("rule drain_mac;")
        TMP.append("   let v <- toGet(txchan.macTx).get;")
        TMP.append("   if (verbose) $display(\"(%%0d) tx data \", $time, fshow(v));")
        TMP.append("endrule")
        TMP.append("`endif")
        TMP.append("MainAPI api <- mkMainAPI(indication, hostchan, ingress);")
        TMP.append("interface request = api.request;")
        stmt = []
        for t in TMP:
            stmt.append(ast.Template(t))
        return stmt

    def emitInterface(self, builder):
        intf = ast.Interface("Main")
        intf.subinterfaces.append(ast.Interface("request", "MainRequest"))
        intf.emit(builder)

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
        emit_import(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
        emit_license(builder)

class API():
    def __init__(self):
        pass

    def build_read_version(self):
        pass

    def build_writePacketData(self):
        pass

    def buildModule(self):
        stmt = []
        return stmt

    def buildRequestInterface(self):
        intf = ast.Interface("MainRequest")
        return intf

    def buildResponseInterface(self):
        intf = ast.Interface("MainIndication")
        return intf

    def emitInterface(self, builder):
        req_intf = self.buildRequestInterface()
        req_intf.emit(builder)
        rsp_intf = self.buildResponseInterface()
        rsp_intf.emit(builder)

    def emitModule(self, builder):
        mname = "mkMainAPI"
        decls = []
        decls.append("MainIndication indication")
        decls.append("HostChannel hostchan")
        decls.append("Ingress ingress")
        iname = "MainAPI"
        params = []
        provisos = []
        stmt = self.buildModule()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emit(self, builder):
        emit_import(builder)
        self.emitInterface(builder)
        self.emitModule(builder)
        emit_license(builder)

def top_create():
    top = Top()
    return top

def top_api_create():
    api = API()
    return api

