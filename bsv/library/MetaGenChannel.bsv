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

import Connectable::*;
import ConfigReg::*;
import GetPut::*;
import FIFOF::*;
import StreamChannel::*;
import StructDefines::*;
import Stream::*;
import PacketBuffer::*;
import Pipe::*;
import TieOff::*;
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"
`include "TieOff.defines"

// Metadata Repeater to repeatedly generate multiple identical metadata from one
// default behavior is to repeat exactly once
interface MetaGenChannel;
   interface Put#(ByteStream#(16)) writeData;
   interface PipeOut#(MetadataRequest) next;
   method Action start (Bit#(32) iter, Bit#(32) ipg);
   method Action stop();
endinterface

(* synthesize *)
module mkMetaGenChannel(MetaGenChannel);
   `PRINT_DEBUG_MSG
   StreamInChannel host <- mkStreamInChannel(255);
   Reg#(Bit#(20)) rg_iter <- mkReg(0);
   Reg#(Bit#(20)) rg_gap <- mkReg(1);
   Reg#(Bit#(20)) freq_cnt <- mkReg(0);
   PulseWire w_send_meta <- mkPulseWire;
   FIFOF#(MetadataRequest) meta_in_ff <- mkFIFOF;
   FIFOF#(MetadataRequest) meta_out_ff <- mkFIFOF;
   FIFOF#(Bool) pktgen_running <- mkFIFOF;

   // drain packet
   mkTieOff(host.writeClient.writeData);
   mkConnection(toGet(host.next), toPut(meta_in_ff));

   rule rl_freq_ctrl if (meta_in_ff.notEmpty && pktgen_running.notEmpty());
      if (freq_cnt < rg_gap) begin
         freq_cnt <= freq_cnt + 1;
      end
      else begin
         freq_cnt <= 0;
         w_send_meta.send();
      end
   endrule

   rule rl_send_metadata if (w_send_meta);
      let req = meta_in_ff.first;
      req.meta.standard_metadata.ingress_port = tagged Valid fromInteger(0); //FIXME: fake metadata goes to channel 0
      rg_iter <= rg_iter - 1;
      meta_out_ff.enq(req);
      $display("(%0d) enqueue iter=%d", $time, rg_iter);
      if (rg_iter == 0) begin
         meta_in_ff.deq;
      end
   endrule

   // frequency N means send a metadata once every n cycles
   method Action start(Bit#(32) iter, Bit#(32) freq) if (!pktgen_running.notEmpty());
      $display("(%0d) metagen start %d gap %d", $time, iter, freq);
      rg_iter <= truncate(iter);
      rg_gap <= truncate(freq);
      pktgen_running.enq(True);
   endmethod
   method Action stop() if (pktgen_running.notEmpty());
      $display("(%0d) metagen stop", $time);
      rg_iter <= 0;
      rg_gap <= 0;
      freq_cnt <= 0;
      pktgen_running.deq;
   endmethod
   interface writeData = host.writeServer.writeData;
   interface next = toPipeOut(meta_out_ff);
endmodule
