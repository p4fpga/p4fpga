// Copyright (c) 2014 Cornell University.

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

import FIFO::*;
import FIFOF::*;
import BRAMFIFO::*;
import ConfigReg::*;
import DefaultValue::*;
import Vector::*;
import BuildVector::*;
import GetPut::*;
import ClientServer::*;
import Connectable::*;
import Clocks::*;
import Gearbox::*;
import Pipe::*;
import Ethernet::*;
import Stream::*;
import PacketBuffer::*;
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"

typedef 1 MinimumIPG; // 1 beat == 16 bytes

// PacketBuffer has a read latency of two cycles
// When used in packet generator, we must consider read latency when
// computing generated packet rate to ensure right amount of IDLE is generated
typedef 16 ReadLatency; // readLatency * datawidth, 3 * 16

interface PktGen;
   interface PktWriteServer#(8) writeServer;
   interface PktWriteClient#(8) writeClient;
   method Action start(Bit#(32) iter, Bit#(32) ipg);
   method Action stop();
   method Action set_verbosity (int verbosity);
endinterface

module mkPktGen#(Integer id)(PktGen)
   provisos (Div#(64, 8, bytesPerBeat)
            ,Log#(bytesPerBeat, beatShift));
   `PRINT_DEBUG_MSG
   Reg#(Bit#(64)) byteSent <- mkReg(0);
   Reg#(Bit#(64)) idleSent <- mkReg(0);
   Reg#(Bit#(32)) traceLen <- mkReg(0);
   Reg#(Bit#(32)) pktCount <- mkReg(0);
   Reg#(Bit#(32)) ipgCount <- mkReg(0);
   Reg#(Bit#(32)) currIPG <- mkReg(fromInteger(valueOf(ReadLatency)));
   Reg#(Bool) idle[2] <- mkCReg(2, False);
   Reg#(Bool) started <- mkReg(False);
   Reg#(Bool) infiniteLoop <- mkReg(False);

   FIFO#(ByteStream#(8)) outgoing_fifo <- mkFIFO();
   FIFO#(ByteStream#(8)) buff <- mkSizedBRAMFIFO(1024);

   rule enqueue_packet if (pktCount>0 && !idle[1]);
      let data = buff.first;
      buff.deq;
      buff.enq(data);
      outgoing_fifo.enq(data);
      if (data.eop) begin
         if (!infiniteLoop)
            pktCount <= pktCount - 1;
         idle[1] <= True;
         currIPG <= fromInteger(valueOf(ReadLatency));
         dbprint(4, $format("pktgen %0d:: eop %h %h %h %h", id, idle[1], started, currIPG, ipgCount));
      end
      dbprint(4, $format("pktgen %0d:: sent byte", id));
      byteSent <= byteSent + 8;
   endrule

   // get rid of latency here
   rule compute_idle if (pktCount>0 && idle[0]);
      if (currIPG < ipgCount + fromInteger(valueOf(MinimumIPG))) begin
         currIPG <= currIPG + fromInteger(valueOf(bytesPerBeat));
         dbprint(4, $format("pktgen %0d:: curr_ipg = %d, ipg_count = %d", id, currIPG, ipgCount));
      end
      else begin
         currIPG <= fromInteger(valueOf(ReadLatency));
         idle[0] <= False;
      end
      idleSent <= idleSent + fromInteger(valueOf(bytesPerBeat));
   endrule

   rule drainBufferPayload if (pktCount==0 && traceLen>0 && started);
      let data = buff.first;
      buff.deq;
      // do nothing
      dbprint(4, $format("pktgen %0d:: drain buffer payload", id));
      if (data.eop) begin
         traceLen <= traceLen - 1;
      end
   endrule

   rule drainFinished if (pktCount==0 && traceLen==0 && started);
      started <= False;
      dbprint(4, $format("%d: byteSent=%d, idleSent=%d", id, byteSent, idleSent));
   endrule

   interface PktWriteServer writeServer;
      interface Put writeData;
         method Action put (ByteStream#(8) d);
            buff.enq(d);
            if (d.eop) begin
               traceLen <= traceLen + 1;
            end
         endmethod
      endinterface
   endinterface
   interface PktWriteClient writeClient;
       interface Get writeData = toGet(outgoing_fifo);
   endinterface
   method Action start(Bit#(32) pc, Bit#(32) ipg) if (pktCount==0 && traceLen!=0);
      started <= True;
      ipgCount <= ipg; // double idle amount because output rate is 10G
      if (pc != 0) begin
         pktCount <= pc;
      end
      else begin
         pktCount <= 1;
         infiniteLoop <= True;
      end
   endmethod
   method Action stop();
      infiniteLoop <= False;
   endmethod
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule

