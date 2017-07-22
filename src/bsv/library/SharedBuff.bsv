// Copyright (c) 2015 Cornell University.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// NOTE:
// - This module stores packet in FIFO order with no guarantees on per-port fairness.
// - Access-control module provides per-port fairness, which is outside the packet buffer.

import BRAM::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import Connectable::*;
import ConnectalBram::*;
import ConnectalMemory::*;
import MemTypes::*;
import SharedBuffMemServer::*;
import SharedBuffMemServerInternal::*;
import SharedBuffMMU::*;
import MemMgmt::*;
import PhysMemSlaveFromBram::*;
import Ethernet::*;
import DbgDefs::*;
import ConnectalConfig::*;
 `include "ConnectalProjectConfig.bsv"

// FIXME: Client#(Bit#(EtherLen), Maybe#(PktId))
// FIXME: Server#(Bit#(EtherLen), Maybe#(PktId))
interface MemAllocServer;
   interface Put#(Bit#(EtherLen)) mallocReq;
   interface Get#(Maybe#(PktId)) mallocDone;
endinterface

interface MemAllocClient;
   interface Get#(Bit#(EtherLen)) mallocReq;
   interface Put#(Maybe#(PktId)) mallocDone;
endinterface

// FIXME: Client#(PktId, Bool)
// FIXME: Server#(PktId, Bool)
interface MemFreeServer;
   interface Put#(PktId) freeReq;
   interface Get#(Bool) freeDone;
endinterface

interface MemFreeClient;
   interface Get#(PktId) freeReq;
   interface Put#(Bool) freeDone;
endinterface

instance Connectable#(MemAllocClient, MemAllocServer);
   module mkConnection#(MemAllocClient client, MemAllocServer server)(Empty);
      mkConnection(client.mallocReq, server.mallocReq);
      mkConnection(server.mallocDone, client.mallocDone);
   endmodule
endinstance

instance Connectable#(MemFreeClient, MemFreeServer);
   module mkConnection#(MemFreeClient client, MemFreeServer server)(Empty);
      mkConnection(client.freeReq, server.freeReq);
      mkConnection(server.freeDone, client.freeDone);
   endmodule
endinstance

interface SharedBuffer#(numeric type addrWidth, numeric type busWidth, numeric type nMasters);
   interface MemServerRequest memServerRequest;
   method MemMgmtDbgRec dbg;
endinterface

module mkSharedBuffer#(Vector#(numReadClients, MemReadClient#(busWidth)) readClients
                       ,Vector#(numFreeClients, MemFreeClient) memFreeClients
                       ,Vector#(numWriteClients, MemWriteClient#(busWidth)) writeClients
                       ,Vector#(numAllocClients, MemAllocClient) memAllocClients
                       ,MemServerIndication memServerInd
`ifdef DEBUG
                       ,MemMgmtIndication memTestInd
                       ,MMUIndication mmuInd
`endif
                      )(SharedBuffer#(addrWidth, busWidth, nMasters))
   provisos(Add#(TLog#(TDiv#(busWidth, 8)), e__, 8)
	    ,Add#(TLog#(TDiv#(busWidth, 8)), f__, BurstLenSize)
	    ,Add#(c__, addrWidth, 64)
	    ,Add#(d__, addrWidth, MemOffsetSize)
	    ,Add#(numWriteClients, a__, TMul#(TDiv#(numWriteClients, nMasters),nMasters))
	    ,Add#(numReadClients, b__, TMul#(TDiv#(numReadClients, nMasters),nMasters))
	    ,Add#(numAllocClients, b__, TMul#(TDiv#(numAllocClients, nMasters),nMasters))
        ,Mul#(TDiv#(busWidth, TDiv#(busWidth, 8)), TDiv#(busWidth, 8), busWidth)
        ,Mul#(TDiv#(busWidth, ByteEnableSize), ByteEnableSize, busWidth)
        ,Add#(DataBusWidth, 0, busWidth)
	    );
   MemMgmt#(addrWidth, numAllocClients, numReadClients) alloc <- mkMemMgmt(
`ifdef DEBUG
                                                                           memTestInd
                                                                          ,mmuInd
`endif
                                                                          );
   MemServer#(addrWidth, busWidth, nMasters) dma <- mkMemServer(readClients, writeClients, cons(alloc.mmu, nil), memServerInd);

   // TODO: use two ports to improve throughput
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 2;
`ifdef BYTE_ENABLES
   BRAM1PortBE#(Bit#(addrWidth), Bit#(busWidth), ByteEnableSize) memBuff <- mkBRAM1ServerBE(bramConfig);
   Vector#(nMasters, PhysMemSlave#(addrWidth, busWidth)) memSlaves <- replicateM(mkPhysMemSlaveFromBramBE(memBuff.portA));
`else
   BRAM1Port#(Bit#(addrWidth), Bit#(busWidth)) memBuff <- ConnectalBram::mkBRAM1Server(bramConfig);
   Vector#(nMasters, PhysMemSlave#(addrWidth, busWidth)) memSlaves <- replicateM(mkPhysMemSlaveFromBram(memBuff.portA));
`endif

   mkConnection(dma.masters, memSlaves);

   FIFO#(MemMgmtAllocResp#(numAllocClients)) mallocDoneFifo <- mkFIFO;

   rule fill_malloc_done;
      let v <- alloc.mallocDone.get;
      mallocDoneFifo.enq(v);
   endrule

   Vector#(numAllocClients, MemAllocServer) memAllocServers = newVector;
   for (Integer i=0; i<valueOf(numAllocClients); i=i+1) begin
      memAllocServers[i] = (interface MemAllocServer;
         interface Put mallocReq;
            method Action put(Bit#(EtherLen) req);
               alloc.mallocReq.put(MemMgmtAllocReq{req: req, clients:fromInteger(i)});
            endmethod
         endinterface
         interface Get mallocDone;
            method ActionValue#(Maybe#(PktId)) get if (mallocDoneFifo.first.clients == fromInteger(i));
               mallocDoneFifo.deq;
               return mallocDoneFifo.first.id;
            endmethod
         endinterface
      endinterface);
   end

   Vector#(numFreeClients, MemFreeServer) memFreeServers = newVector;
   for (Integer i=0; i<valueOf(numFreeClients); i=i+1) begin
      memFreeServers[i] = (interface MemFreeServer;
         interface Put freeReq;
            method Action put(PktId id);
               alloc.freeReq.put(MemMgmtFreeReq{id: id, clients: fromInteger(i)});
            endmethod
         endinterface
         interface Get freeDone;
            method ActionValue#(Bool) get;
               return True;
            endmethod
         endinterface
      endinterface);
   end

   mkConnection(memAllocClients, memAllocServers);
   mkConnection(memFreeClients, memFreeServers);

   interface MemServerRequest memServerRequest = dma.request;
   method MemMgmtDbgRec dbg = alloc.dbg;
endmodule

