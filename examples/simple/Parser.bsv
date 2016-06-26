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
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import Simple::*;
import Utils::*;
import TxRx::*;
import Pipe::*;

typedef enum {
   StateParseStart,
   StateParseEthernet,
   StateParseIpv4
} ParserState deriving (Bits, Eq);

typedef enum {
   TYPE_ERROR,
   TYPE_ETH,
   TYPE_IPV4
} PacketType deriving (Bits, Eq);

interface Parser;
   interface Put#(EtherData) frameIn;
   interface Get#(MetadataT) meta;
   interface Put#(int) verbosity;
   method ParserPerfRec read_perf_info;
endinterface

(* synthesize *)
module mkParser(Parser);
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
   Wire#(PacketType) parse_state_w <- mkDWire(TYPE_ERROR);
   Reg#(Bit#(32)) rg_offset <- mkReg(0);
   Reg#(Bit#(144)) rg_tmp_ipv4 <- mkReg(0);

   Reg#(Bit#(32)) rg_dst_addr[2] <- mkCRegU(2);
   Reg#(Bit#(16)) rg_ether_type[2] <- mkCRegU(2);
   Reg#(Bit#(9)) rg_egress_port[2] <- mkCRegU(2);

   PulseWire parse_done <- mkPulseWire();

   function Tuple2 #(Bit#(112), Bit#(16)) extract_header (Bit#(128) d);
      Vector#(128, Bit#(1)) data_vec = unpack(d);
      Bit#(112) curr_data = pack(takeAt(0, data_vec));
      Bit#(16) next_data = pack(takeAt(16, data_vec));
      return tuple2 (curr_data, next_data);
   endfunction

   function Action report_parse_action (ParserState state, Bit#(32) offset, Bit#(128) data);
      action
         if (cr_verbosity[0] > 0)
            $display ("(%d) Parser State %h offset 0x%h %h", $time, state, offset, data);
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

   function Action push_phv (PacketType ty);
      action
         //if (ty == TYPE_IPV4) begin
         //   let phv = MetadataT {
         //      ipv4 : tagged Valid M_Ipv4T { dstAddr : rg_dst_addr[1] },
         //      ethernet : tagged Valid M_EthernetT { etherType : rg_ether_type[1] },
         //      standard_metadata : tagged Valid M_StandardMetadata { egress_port : rg_egress_port[1] },
         //      table_action : tagged Invalid
         //   };
         //   meta_out_ff.enq(phv);
         //end
         //else if (ty == TYPE_ETH) begin
         //   let phv = MetadataT {
         //      ipv4 : tagged Invalid,
         //      ethernet : tagged Valid M_EthernetT { etherType : rg_ether_type[1] },
         //      standard_metadata : tagged Valid M_StandardMetadata { egress_port : rg_egress_port[1] },
         //      table_action : tagged Invalid
         //   };
         //   meta_out_ff.enq(phv);
         //end
         //else begin
         //   // error
         //end
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

   rule rl_parse_ethernet ((rg_parse_state == StateParseEthernet) && (rg_offset == 0));
      report_parse_action(rg_parse_state, rg_offset, din);
      let tmp_ethernet = din[111:0];
      let ethernet = extract_ethernet_t(tmp_ethernet);
      let next_state = compute_next_state(ethernet.etherType);
      rg_parse_state <= next_state;
      rg_tmp_ipv4 <= zeroExtend(din[127:112]);
      parse_state_w <= TYPE_ETH;
      succeed_and_next(rg_offset + 128);
   endrule

   rule rl_parse_ipv4_1 ((rg_parse_state == StateParseIpv4) && (rg_offset == 128));
      report_parse_action(rg_parse_state, rg_offset, din);
      rg_tmp_ipv4 <= zeroExtend( { din, rg_tmp_ipv4[15:0] } );
      succeed_and_next(rg_offset + 128);
   endrule

   rule rl_parse_ipv4_2 ((rg_parse_state == StateParseIpv4) && (rg_offset == 256));
      report_parse_action(rg_parse_state, rg_offset, din);
      Bit#(272) data = {din, rg_tmp_ipv4};
      Vector#(272, Bit#(1)) dataVec = unpack(data);
      let ipv4 = extract_ipv4_t(pack(takeAt(0, dataVec)));
      rg_parse_state <= StateParseStart;
      rg_dst_addr[0] <= ipv4.dstAddr;
      $display("dstAddr = %h", ipv4.dstAddr);
      parse_state_w <= TYPE_IPV4;
      parse_done.send();
      succeed_and_next(rg_offset + 128);
   endrule

   rule rl_push_phv (parse_done);
      push_phv(parse_state_w);
   endrule

   interface frameIn = toPut(data_in_ff);
   interface meta = toGet(meta_out_ff);
   interface verbosity = toPut(cr_verbosity_ff);
endmodule

