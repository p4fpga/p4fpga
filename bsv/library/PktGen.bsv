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
`include "Debug.defines"

typedef 1 MinimumIPG; // 1 beat == 16 bytes.

interface PktGen;
   interface PktWriteServer#(16) writeServer;
   interface PktWriteClient#(16) writeClient;
   method Action start(Bit#(32) iter, Bit#(32) ipg);
   method Action stop();
   method Action set_verbosity (int verbosity);
endinterface

module mkPktGen(PktGen)
   provisos (Div#(64, 8, bytesPerBeat)
            ,Log#(bytesPerBeat, beatShift));
   `PRINT_DEBUG_MSG
   Reg#(Bit#(64)) byteSent <- mkReg(0);
   Reg#(Bit#(64)) idleSent <- mkReg(0);
   Reg#(Bit#(32)) traceLen <- mkReg(0);
   Reg#(Bit#(32)) pktCount <- mkReg(0);
   Reg#(Bit#(32)) ipgCount <- mkReg(0);
   Reg#(Bit#(32)) currIPG <- mkReg(0);
   Reg#(Bool) idle <- mkReg(False);
   Reg#(Bool) started <- mkReg(False);
   Reg#(Bool) infiniteLoop <- mkReg(False);

   FIFO#(ByteStream#(16)) outgoing_fifo <- mkFIFO();
   PacketBuffer#(16) buff <- mkPacketBuffer("pktgen");

   rule prepare_packet if (pktCount>0 && !idle);
      let pktLen <- buff.readServer.readLen.get;
      buff.readServer.readReq.put(pktLen);
      dbprint(3, $format("pktgen:: fetch_packet pktlen=%h", pktLen));
   endrule

   rule enqueue_packet if (pktCount>0 && !idle);
      let data <- buff.readServer.readData.get;
      buff.writeServer.writeData.put(data);
      outgoing_fifo.enq(data);

      if (data.eop) begin
         if (!infiniteLoop)
            pktCount <= pktCount - 1;
         idle <= True;
         currIPG <= 0;
         dbprint(3, $format("pktgen:: eop %h %h %h %h", idle, started, currIPG, ipgCount));
      end
   endrule

   rule compute_idle if (pktCount>0 && idle);
      dbprint(3, $format("pktgen:: curr_ipg = %d, ipg_count = %d", currIPG, ipgCount));
      if (currIPG < ipgCount + fromInteger(valueOf(MinimumIPG))) begin
         currIPG <= currIPG + fromInteger(valueOf(bytesPerBeat));
      end
      else begin
         currIPG <= 0;
         idle <= False;
      end
   endrule

   // has to drain buffer at the end of packet generation
   rule cleanup if (pktCount==0 && traceLen>0 && started);
      let pktLen <- buff.readServer.readLen.get;
      buff.readServer.readReq.put(pktLen);
      dbprint(3, $format("pktgen:: drain buffer"));
   endrule

   rule drainBufferPayload if (pktCount==0 && traceLen>0 && started);
      let data <- buff.readServer.readData.get;
      // do nothing
      dbprint(3, $format("pktgen:: drain buffer payload"));
      if (data.eop) begin
         traceLen <= traceLen - 1;
      end
   endrule

   rule drainFinished if (pktCount==0 && traceLen==0 && started);
      started <= False;
   endrule

   interface PktWriteServer writeServer;
      interface Put writeData;
         method Action put (ByteStream#(16) d);
            buff.writeServer.writeData.put(d);
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
      ipgCount <= ipg;
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
      buff.set_verbosity(verbosity);
   endmethod
endmodule

