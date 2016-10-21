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
import StreamGearbox::*;
import Deparser::*;

// Encapsulate a packet generator inside a channel
interface PktGenChannel;
   interface Put#(ByteStream#(16)) writeData;
   interface Get#(ByteStream#(8)) macTx;
   method Action start (Bit#(32) iter, Bit#(32) ipg);
   method Action stop ();
   method Action set_verbosity (int verbosity);
endinterface

module mkPktGenChannel#(Clock txClock, Reset txReset)(PktGenChannel);
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   PktGen pktgen <- mkPktGen(clocked_by txClock, reset_by txReset);
   StreamGearbox#(16, 8) gearbox <- mkStreamGearboxDn(clocked_by txClock, reset_by txReset);
   mkConnection(pktgen.writeClient.writeData, gearbox.datain);

   SyncFIFOIfc#(Tuple2#(Bit#(32),Bit#(32))) start_sync_ff <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);
   SyncFIFOIfc#(void) stop_sync_ff <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);
   SyncFIFOIfc#(ByteStream#(16)) write_sync_ff <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);
   SyncFIFOIfc#(int) verbose_sync_ff <- mkSyncFIFO(4, defaultClock, defaultReset, txClock);

   rule r_write_data;
      let v <- toGet(write_sync_ff).get;
      pktgen.writeServer.writeData.put(v);
   endrule

   rule r_start;
      let v <- toGet(start_sync_ff).get;
      pktgen.start(tpl_1(v), tpl_2(v));
   endrule

   rule r_stop;
      let v <- toGet(stop_sync_ff).get;
      pktgen.stop();
   endrule

   rule r_verbose;
      let v <- toGet(verbose_sync_ff).get;
      pktgen.set_verbosity(v);
   endrule

   method Action start(Bit#(32) iter, Bit#(32) ipg);
      start_sync_ff.enq(tuple2(iter, ipg));
   endmethod
   method Action stop ();
      stop_sync_ff.enq(?);
   endmethod
   interface writeData = toPut(write_sync_ff);
   interface macTx = gearbox.dataout;
   method Action set_verbosity (int verbosity);
      verbose_sync_ff.enq(verbosity);
   endmethod
endmodule

