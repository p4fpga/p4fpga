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

import Assert::*;
import CBus::*;
import BUtils::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import StmtFSM::*;
import Vector::*;
import List::*;
import MIMO::*;
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

typedef union tagged {
   Tuple2#(Bit#(112), Bit#(112)) UEthernetT;
   Tuple2#(Bit#(160), Bit#(160)) UIpv4T;
} MetaT;

typeclass ToTuple#(type t, type d);
   function Tuple2#(t, t) toTuple(d arg);
endtypeclass

instance ToTuple#(EthernetT, MetadataT);
   function Tuple2#(EthernetT, EthernetT) toTuple (MetadataT t);
      EthernetT data = defaultValue;
      EthernetT mask = defaultMask;
      let ethernet = fromMaybe(?, t.ethernet);
      data.etherType = ethernet.etherType;
      mask.etherType = 0;
      return tuple2(data, mask);
   endfunction
endinstance

instance ToTuple#(Ipv4T, MetadataT);
   function Tuple2#(Ipv4T, Ipv4T) toTuple (MetadataT t);
      Ipv4T data = defaultValue;
      Ipv4T mask = defaultMask;
      let ipv4 = fromMaybe(?, t.ipv4);
      data.dstAddr = ipv4.dstAddr;
      mask.dstAddr = 0;
      return tuple2(data, mask);
   endfunction
endinstance

(* synthesize *)
module mkDeparser(Deparser);
   Reg#(int) cr_verbosity[2] <- mkCRegU(2);
   FIFOF#(int) cr_verbosity_ff <- mkFIFOF;

   Reg#(DeparserState) rg_deparse_state <- mkReg(StateDeparseStart);
   FIFOF#(EtherData) data_in_ff <- mkFIFOF;
   FIFOF#(EtherData) data_out_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;

   Reg#(Bit#(32)) rg_offset <- mkReg(0);
   Reg#(Bit#(32)) rg_edit_offset <- mkReg(0);

   Reg#(Bit#(128)) rg_buff <- mkReg(0);
   Reg#(Bit#(32)) rg_shamt <- mkReg(0);

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

   //function Bool matchesOffset ();

   let din = data_in_ff.first;
   let meta = meta_in_ff.first;

   rule rl_start_state if (rg_deparse_state == StateDeparseStart);
      let v = data_in_ff.first;
      if (v.sop) begin
         rg_deparse_state <= StateDeparseEthernet;
         $display("(%0d) Deparse Ethernet Start ", $time, fshow(v));
      end
      else begin
         data_in_ff.deq;
         data_out_ff.enq(v);
      end
   endrule

   function DeparserState compute_next_state_ethernet(Bit#(16) v);
      DeparserState nextState = StateDeparseStart;
      case (byteSwap(v)) matches
         'h800: begin
            nextState = StateDeparseIpv4;
         end
         default: begin
            nextState = StateDeparseStart;
         end
      endcase
      return nextState;
   endfunction

   function DeparserState compute_next_state (DeparserState state);
      DeparserState nextState = StateDeparseStart;
      case (state) matches
         StateDeparseEthernet: begin
            M_EthernetT ethernet = fromMaybe(?, meta.ethernet);
            nextState = compute_next_state_ethernet (ethernet.etherType);
         end
         default: begin
            nextState = StateDeparseStart;
         end
      endcase
      return nextState;
   endfunction

   function Bit#(l) read_data (UInt#(8) lhs, UInt#(8) rhs)
      provisos (Add#(a__, l, 128));
      Bit#(l) ldata = truncate(din.data) << (fromInteger(valueOf(l))-lhs);
      Bit#(l) rdata =truncate(rg_buff >> (fromInteger(valueOf(l))-rhs));
      Bit#(l) cdata = ldata | rdata;
      return cdata;
   endfunction

   function Bit#(max) create_mask (LUInt#(max) count);
      Bit#(max) v = 1 << count - 1;
      return v;
   endfunction

   // build_deparse_rule_no_opt
   function Rules build_deparse_rule_no_opt (DeparserState state,
                                             int offset,
                                             Tuple2#(Bit#(n), Bit#(n)) m,
                                             UInt#(8) clen,
                                             UInt#(8) plen)
      provisos (Mul#(TDiv#(n, 8), 8, n),
                Add#(a__, n, 128));
      Rules d =
      rules
         rule rl_deparse if ((rg_deparse_state == state) && (rg_offset == unpack(pack(offset))));
            report_deparse_action(rg_deparse_state, rg_offset);
            match {.meta, .mask} = m;
            Vector#(n, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(meta)));
            Vector#(n, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(mask)));
            Bit#(n) curr_data = read_data (clen, plen);
            let data = apply_changes (curr_data, pack(curr_meta), pack(curr_mask));
            let data_this_cycle = EtherData { sop: din.sop,
                                              eop: din.eop,
                                              data: zeroExtend(data),
                                              mask: create_mask(cExtend(fromInteger(valueOf(n)))) };
            data_out_ff.enq (data_this_cycle);
            rg_deparse_state <= compute_next_state(state);
            rg_buff <= din.data;
            // apply header removal by marking mask zero
            // apply added header by setting field at offset.
            succeed_and_next (rg_offset + cExtend(clen) + cExtend(plen));
         endrule
      endrules;
      return d;
   endfunction

   rule rl_deparse_ipv4_1 if ((rg_deparse_state == StateDeparseIpv4) && (rg_offset == 112));
      report_deparse_action(rg_deparse_state, rg_offset);
      Tuple2#(Ipv4T, Ipv4T) tp = toTuple(meta);
      match {.mta, .msk} = tp;
      Vector#(128, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(pack(mta))));
      Vector#(128, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(pack(msk))));
      Bit#(112) d = truncate (din.data);
      Bit#(16) e = grab_left (rg_buff);
      let curr_data = {d, e};
      let data = apply_changes(curr_data, pack(curr_meta), pack(curr_mask));
      let data_this_cycle = EtherData { sop: din.sop, eop: din.eop, data: zeroExtend(data), mask: din.mask };
      data_out_ff.enq(data_this_cycle);
      // if eoh:
      //   state <= next_state
      rg_buff <= din.data;
      succeed_and_next(rg_offset + 128);
   endrule

   rule rl_deparse_ipv4_2 if ((rg_deparse_state == StateDeparseIpv4) && (rg_offset == 240));
      report_deparse_action(rg_deparse_state, rg_offset);
      Tuple2#(Ipv4T, Ipv4T) tp = toTuple(meta);
      match {.mta, .msk} = tp;
      // let data_in = read_data (16);
      Vector#(32, Bit#(1)) curr_meta = takeAt(128, unpack(byteSwap(pack(mta))));
      Vector#(32, Bit#(1)) curr_mask = takeAt(128, unpack(byteSwap(pack(msk))));
      //Bit#(32) curr_data = read_data (16, 16);
      Bit#(16) d = truncate (din.data);
      Bit#(16) e = grab_left (rg_buff);
      let curr_data = {d, e};
      let data = apply_changes(curr_data, pack(curr_meta), pack(curr_mask));
      let data_this_cycle = EtherData { sop: din.sop, eop: din.eop, data: zeroExtend(data), mask: din.mask };
      data_out_ff.enq(data_this_cycle);
      // if eoh:
      //    state <= next_state;
      rg_buff <= din.data;
      succeed_and_next(rg_offset + 32);
   endrule

   Tuple2#(EthernetT, EthernetT) ethernet = toTuple(meta);
   Bit#(112) ethernet_meta = pack(tpl_1(ethernet));
   Bit#(112) ethernet_mask = pack(tpl_2(ethernet));
   addRules(build_deparse_rule_no_opt(StateDeparseEthernet,
                                      0,
                                      tuple2(ethernet_meta, ethernet_mask),
                                      112,
                                      0));

//   Tuple2#(Ipv4T, Ipv4T) ipv4 = toTuple(meta);
//   let ipv4_meta = pack(tpl_1(ipv4));
//   let ipv4_mask = pack(tpl_2(ipv4));
//   addRules(build_deparse_rule_no_opt(StateDeparseIpv4, 112,
//      tuple2(ipv4_meta, ipv4_mask), 160, 112, 16));
//   addRules(build_deparse_rule_no_opt(StateDeparseIpv4, 240, 
//      tuple2(ipv4_meta, ipv4_mask), 160, 16, 16));

   rule rl_deparse_done;

   endrule

   interface metadata = toPipeIn(meta_in_ff);
   interface PktWriteServer writeServer;
      interface writeData = toPut(data_in_ff);
   endinterface
   interface PktWriteClient writeClient;
      interface writeData = toGet(data_out_ff);
   endinterface
   interface verbosity = toPut(cr_verbosity_ff);
endmodule
