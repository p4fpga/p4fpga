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

interface Parser;
   interface Put#(EtherData) frameIn;
   interface Get#(MetadataT) meta;
   method ParserPerfRec read_perf_info;
   interface Put#(int) verbosity;
endinterface

(* synthesize *)
module mkParser(Parser);
   // verbosity
   Reg#(int) cr_verbosity[2] <- mkCRegU(2);
   FIFOF#(int) cr_verbosity_ff <- mkFIFOF;

   rule set_verbosity;
      let x = cr_verbosity_ff.first;
      cr_verbosity_ff.deq;
      cr_verbosity[1] <= x;
   endrule

   FIFOF#(EtherData) data_in_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_out_ff <- mkFIFOF;
   Reg#(ParserState) rg_parse_state <- mkReg(StateParseStart);
   Reg#(Bit#(32)) rg_offset <- mkReg(0);
   Reg#(Bit#(160)) rg_tmp_ipv4 <- mkReg(0);

   function Tuple2 #(Bit#(112), Bit#(16)) extract_header (Bit#(128) d);
      Vector#(128, Bit#(1)) data_vec = unpack(d);
      Bit#(112) curr_data = pack(takeAt(0, data_vec));
      Bit#(16) next_data = pack(takeAt(16, data_vec));
      return tuple2 (curr_data, next_data);
   endfunction

   function Action report_parse_action (ParserState state, Bit#(32) offset);
      action
         if (cr_verbosity[0] > 0)
            $display ("(%d) Parser State %h offset 0x%h", $time, state, offset);
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

   rule start_state if (rg_parse_state == StateParseStart);
      let v = data_in_ff.first;
      if (v.sop) begin
         rg_parse_state <= StateParseEthernet;
      end
      else begin
         data_in_ff.deq;
      end
   endrule

   function ParserState compute_next_state(Bit#(16) v);
      ParserState nextState = StateParseStart;
      case (byteSwap(v)) matches
         'h800: begin
            nextState = StateParseIpv4;
         end
         default: begin
            nextState = StateParseStart;
         end
      endcase
      return nextState;
   endfunction

   let din = data_in_ff.first.data;

   rule parse_ethernet ((rg_parse_state == StateParseEthernet) && (rg_offset == 0));
      report_parse_action(rg_parse_state, rg_offset);
      let tmp_ethernet = din[111:0];
      let ethernet = extract_ethernet_t(tmp_ethernet);
      let next_state = compute_next_state(ethernet.etherType);
      rg_parse_state <= next_state;
      rg_tmp_ipv4 <= zeroExtend(din[127:112]);
      succeed_and_next(rg_offset + 128);
   endrule

   rule parse_ipv4_1 ((rg_parse_state == StateParseIpv4) && (rg_offset == 128));
      report_parse_action(rg_parse_state, rg_offset);
      rg_tmp_ipv4 <= zeroExtend( { din<<16 , rg_tmp_ipv4[11:0] } );
      succeed_and_next(rg_offset + 128);
   endrule

   rule parse_ipv4_2 ((rg_parse_state == StateParseIpv4) && (rg_offset == 256));
      report_parse_action(rg_parse_state, rg_offset);
      let tmp_ipv4 = {din[15:0], rg_tmp_ipv4[143:0]};
      let ipv4 = extract_ipv4_t(tmp_ipv4);
      rg_parse_state <= StateParseStart;
      succeed_and_next(rg_offset + 128);
   endrule

   interface frameIn = toPut(data_in_ff);
   interface meta = toGet(meta_out_ff);
   interface verbosity = toPut(cr_verbosity_ff);
endmodule

