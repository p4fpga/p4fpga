// Copyright (c) 2016 Cornell University.

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

import Clocks::*;
import Connectable::*;
import DbgDefs::*;
import Ethernet::*;
import EthMac::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import MemMgmt::*;
import MemTypes::*;
import Pipe::*;
import PacketBuffer::*;
import PktGen::*;
import StoreAndForward::*;
import SharedBuff::*;
import SpecialFIFOs ::*;
import Stream::*;
import Deparser::*;

// Encapsulate a packet generator inside a channel
interface PktGenChannel;
   interface Put#(ByteStream#(16)) writeData;
   method Action start (Bit#(32) iter, Bit#(32) ipg);
   method Action stop ();
   interface Get#(ByteStream#(8)) macTx;
endinterface

module mkPktGenChannel#(Clock txClock, Reset txReset)(PktGenChannel);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   PktGen pktgen <- mkPktGen(clocked_by txClock, reset_by txReset);
   PacketBuffer#(16) pkt_buff <- mkPacketBuffer("pktgen chan", clocked_by txClock, reset_by txReset);
   StoreAndFwdFromRingToMac ringToMac <- mkStoreAndFwdFromRingToMac(txClock, txReset, clocked_by txClock, reset_by txReset);

   mkConnection(pktgen.writeClient, pkt_buff.writeServer);
   mkConnection(ringToMac.readClient, pkt_buff.readServer);

   SyncFIFOIfc#(Tuple2#(Bit#(32),Bit#(32))) pktGenStartSyncFifo <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);
   SyncFIFOIfc#(void) pktGenStopSyncFifo <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);
   SyncFIFOIfc#(ByteStream#(16)) pktGenWriteSyncFifo <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);

   rule r_write_data;
      let v <- toGet(pktGenWriteSyncFifo).get;
      pktgen.writeServer.writeData.put(v);
   endrule

   rule r_start;
      let v <- toGet(pktGenStartSyncFifo).get;
      pktgen.start(tpl_1(v), tpl_2(v));
   endrule

   rule r_stop;
      let v <- toGet(pktGenStopSyncFifo).get;
      pktgen.stop();
   endrule

   method Action start(Bit#(32) iter, Bit#(32) ipg);
      pktGenStartSyncFifo.enq(tuple2(iter, ipg));
   endmethod
   method Action stop ();
      pktGenStopSyncFifo.enq(?);
   endmethod
   interface writeData = toPut(pktGenWriteSyncFifo);
   interface macTx = ringToMac.macTx;
endmodule

