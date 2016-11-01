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
import Channel::*;
import DbgDefs::*;
import DbgTypes::*;
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

interface PktCapChannel;
   method Action start(Bit#(32) iter);
   method Action stop();
   method PktCapRec read_perf_info();
   interface Put#(ByteStream#(8)) macRx;
endinterface

instance GetMacRx#(PktCapChannel);
   function Put#(ByteStream#(8)) getMacRx(PktCapChannel chan);
      return chan.macRx;
   endfunction
endinstance

module mkPktCapChannel#(Clock rxClock, Reset rxReset)(PktCapChannel);
   let verbose = True;
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   Reg#(Bit#(32)) pktCnt <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(32)) totalCnt <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bool) logging <- mkReg(False, clocked_by rxClock, reset_by rxReset);
   Reg#(Bool) log_started <- mkReg(False, clocked_by rxClock, reset_by rxReset);
   Reg#(Bool) log_stopped <- mkReg(False, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) cycle_start <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) data_bytes_start <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) data_bytes_end <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) idle_cycle_start <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) idle_cycle_end <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) total_cycle_start <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) total_cycle_end <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Wire#(Bool) pkt_sop <- mkDWire(False, clocked_by rxClock, reset_by rxReset);

   Reg#(Bit#(64)) data_bytes <- mkSyncReg(0, rxClock, rxReset, defaultClock);
   Reg#(Bit#(64)) idle_cycles <- mkSyncReg(0, rxClock, rxReset, defaultClock);
   Reg#(Bit#(64)) total_cycles <- mkSyncReg(0, rxClock, rxReset, defaultClock);

   StoreAndFwdFromMacToRing macToRing <- mkStoreAndFwdFromMacToRing(rxClock, rxReset, clocked_by rxClock, reset_by rxReset);

   SyncFIFOIfc#(Bit#(32)) pktCapStartSyncFifo <- mkSyncFIFO(4, defaultClock, defaultReset, rxClock);
   SyncFIFOIfc#(Bit#(1)) pktCapStopSyncFifo <- mkSyncFIFO(4, defaultClock, defaultReset, rxClock);

   rule pkt_sink;
      let v <- macToRing.writeClient.writeData.get;
      pkt_sop <= v.sop;
      if (v.sop) begin
         pktCnt <= pktCnt + 1;
         if (verbose) $display("(%0d) packet count %h/%h", $time, pktCnt, totalCnt);
      end
   endrule

   rule snapshot_start_cycle if (logging && !log_started && pkt_sop);
      total_cycle_start <= macToRing.sdbg.total_cycles;
      data_bytes_start <= macToRing.sdbg.data_bytes;
      idle_cycle_start <= macToRing.sdbg.idle_cycles;
      if (verbose) $display("(%0d) snapshot start %h %h %h", $time, macToRing.sdbg.total_cycles, macToRing.sdbg.data_bytes, macToRing.sdbg.idle_cycles);
      log_started <= True;
   endrule

   rule snapshot_end_cycle if (logging && log_started && pktCnt == totalCnt-1);
      total_cycle_end <= macToRing.sdbg.total_cycles;
      data_bytes_end <= macToRing.sdbg.data_bytes;
      idle_cycle_end <= macToRing.sdbg.idle_cycles;
      if (verbose) $display("(%0d) snapshot end %h %h %h", $time, macToRing.sdbg.total_cycles, macToRing.sdbg.data_bytes, macToRing.sdbg.idle_cycles);
      log_started <= False;
      logging <= False;
   endrule

   rule r_start;
      let v <- toGet(pktCapStartSyncFifo).get;
      totalCnt <= v;
      logging <= True;
   endrule

   rule r_stop;
      let v <- toGet(pktCapStopSyncFifo).get;
      log_started <= False;
      logging <= False;
   endrule

   rule r_perf_info;
      data_bytes <= data_bytes_end - data_bytes_start;
      idle_cycles <= idle_cycle_end - idle_cycle_start;
      total_cycles <= total_cycle_end - total_cycle_start;
   endrule

   method Action start(Bit#(32) iter);
      pktCapStartSyncFifo.enq(iter);
   endmethod
   method Action stop();
      pktCapStopSyncFifo.enq(1'b1);
   endmethod
   method PktCapRec read_perf_info();
      return PktCapRec {data_bytes: data_bytes,
                        idle_cycles: idle_cycles,
                        total_cycles: total_cycles};
   endmethod
   interface macRx = macToRing.macRx;
endmodule

