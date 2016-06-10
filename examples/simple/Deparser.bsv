// Copyright (c) 2016 Cornell University

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

import DbgDefs::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import Simple::*;
import Utils::*;
import Pipe::*;
import PacketBuffer::*;

interface Deparser;
   interface PipeIn#(MetadataT) metadata;
   interface PktWriteServer writeServer;
   interface PktWriteClient writeClient;
   interface Put#(int) verbosity;
   method DeparserPerfRec read_perf_info;
endinterface

typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4
} DeparserState deriving (Bits, Eq, FShow);

(* synthesize *)
module mkDeparser(Deparser);
   Reg#(int) cr_verbosity[2] <- mkCRegU(2);
   FIFOF#(int) cr_verbosity_ff <- mkFIFOF;

   Reg#(DeparserState) rg_deparse_state <- mkReg(StateDeparseStart);
   FIFOF#(EtherData) data_in_ff <- mkFIFOF;
   FIFOF#(EtherData) data_out_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
   Reg#(Bit#(32)) rg_offset <- mkReg(0);

   rule set_verbosity;
      let x = cr_verbosity_ff.first;
      cr_verbosity_ff.deq;
      cr_verbosity[1] <= x;
   endrule

   function Action report_deparse_action (DeparserState state, Bit#(32) offset);
      action
         if (cr_verbosity[0] > 0)
            $display ("(%d) Deparser State %h offset 0x%h", $time, state, offset);
      endaction
   endfunction

   function Action succeed_and_next (Bit#(32) next_offset);
      action
         data_in_ff.deq;
         rg_offset <= next_offset;
      endaction
   endfunction

   function Action fail_and_trap (Bit#(32) next_offset);
      action
         data_in_ff.deq;
         rg_offset <= 0;
      endaction
   endfunction

   let din = data_in_ff.first.data;

   rule start_state if (rg_deparse_state == StateDeparseStart);
      let v = data_in_ff.first;
      if (v.sop) begin
         rg_deparse_state <= StateDeparseEthernet;
         $display("(%0d) Deparse Ethernet Start", $time, fshow(v));
      end
      else begin
         data_in_ff.deq;
         data_out_ff.enq(v);
      end
   endrule

   rule deparse_ethernet if ((rg_deparse_state == StateDeparseEthernet) && (rg_offset == 0));
      report_deparse_action(rg_deparse_state, rg_offset);

      succeed_and_next(rg_offset + 128);
   endrule

   rule deparse_ipv4_1 if ((rg_deparse_state == StateDeparseIpv4) && (rg_offset == 128));
      report_deparse_action(rg_deparse_state, rg_offset);

      succeed_and_next(rg_offset + 128);
   endrule

   rule deparse_ipv4_2 if ((rg_deparse_state == StateDeparseIpv4) && (rg_offset == 256));
      report_deparse_action(rg_deparse_state, rg_offset);

      succeed_and_next(rg_offset + 128);
   endrule

   interface PktWriteServer writeServer;
      interface writeData = toPut(data_in_ff);
   endinterface
   interface PktWriteClient writeClient;
      interface writeData = toGet(data_out_ff);
   endinterface
   interface verbosity = toPut(cr_verbosity_ff);
endmodule
