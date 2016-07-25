// Copyright (c) 2016 P4FPGA Project

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

// Deparser Template

import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import MIMO::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import PrintTrace::*;
import Register::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;

import StructGenerated::*;

// app-specific structs
`define DEPARSER_STRUCT
`include "DeparserGenerated.bsv"
`undef DEPARSER_STRUCT

interface Deparser;
   interface PipeIn#(MetadataT) metadata;
   interface PktWriteServer writeServer;
   interface PktWriteClient writeClient;
   method Action set_verbosity (int verbosity);
   method DeparserPerfRec read_perf_info ();
endinterface
module mkDeparser (Deparser);
   Reg#(int) cf_verbosity <- mkConfigRegU;

   FIFOF#(EtherData) data_in_ff <- mkFIFOF;
   FIFOF#(EtherData) data_out_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
   FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
   FIFO#(DeparserState) deparse_state_ff <- mkPipelineFIFO();
   Array#(Reg#(Bit#(32))) rg_next_header_len <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_buffered <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_processed <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_shift_amt <- mkCReg(3, 0);
   Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);
   Array#(Reg#(Bool)) deparse_done <- mkCReg(2, True);
   Array#(Reg#(Bool)) header_done <- mkCReg(2, True);
   PulseWire w_deparse_header_done <- mkPulseWire();

   function Action dbprint(Integer level, Fmt msg);
      action
      if (cf_verbosity > fromInteger(level)) begin
         $display("(%0d) ", $time, msg);
      end
      endaction
   endfunction

   // app-specific states
   `define DEPARSER_STATE
   `include "DeparserGenerated.bsv"
   `undef DEPARSER_STATE

   let mask_this_cycle = data_in_ff.first.mask;
   let sop_this_cycle = data_in_ff.first.sop;
   let eop_this_cycle = data_in_ff.first.eop;
   let data_this_cycle = data_in_ff.first.data;
   let meta = meta_in_ff.first;
   function Action report_deparse_action(String msg, Bit#(32) buffered, Bit#(32) processed, Bit#(32) shift, Bit#(512) data);
    action
      if (cf_verbosity > 0) begin
        $display("(%0d) Deparse %s buffered %d %d %d data %h", $time, msg, buffered, processed, shift, data);
      end
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      rg_next_header_len[0] <= len;
    endaction
  endfunction
  function Action move_buffered_amt(Bit#(32) len);
    action
      rg_buffered[0] <= rg_buffered[0] + len;
      rg_shift_amt[0] <= rg_shift_amt[0] + len;
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) len);
    action
      rg_processed[0] <= rg_processed[0] + len;
      rg_buffered[0] <= rg_buffered[0] - len;
    endaction
  endfunction
  function Bit#(max) create_mask(LUInt#(max) count);
    Bit#(max) v = (1 << count) - 1;
    return v;
  endfunction

  rule rl_start_state if (deparse_done[1] && sop_this_cycle);
    rg_buffered[2] <= 0;
    rg_shift_amt[2] <= 0;
    rg_processed[2] <= 0;
    deparse_done[1] <= False;
    header_done[1] <= False;
    deparse_state_ff.enq(StateDeparseEthernet);
    fetch_next_header(112);
    dbprint(3, $format("start deparse %d", valueOf(SizeOf#(DeparserState))));
  endrule

  rule rl_deparse_payload if (deparse_done[1] && !sop_this_cycle);
    let v = data_in_ff.first;
    data_in_ff.deq;
    dbprint(3, $format("shift amt %d", rg_shift_amt[1]));
    if (rg_shift_amt[1] != 0) begin
      Bit#(128) data_mask = create_mask(cExtend(rg_shift_amt[1]));
      Bit#(16) mask_out = create_mask(cExtend(rg_shift_amt[1] >> 3));
      let data = EtherData { sop: v.sop, eop: v.eop, data: truncate(rg_tmp[1]) & data_mask, mask: mask_out};
      data_out_ff.enq(data);
      rg_shift_amt[1] <= 0;
    end
    else begin
      data_out_ff.enq(v);
    end
  endrule

  rule rl_data_ff_load if (!deparse_done[1] && (rg_buffered[2] < rg_next_header_len[2]));
    dbprint(3, $format("dequeue data_in_ff"));
    data_in_ff.deq;
  endrule

  rule rl_deparse_send if (!deparse_done[1] && (rg_processed[1] > 0));
    let amt = 128;
    if (rg_processed[1] < 128) begin
       amt = rg_processed[1];
    end
    Bit#(128) data_out = truncate(rg_tmp[1] & create_mask(cExtend(amt)));
    Bit#(16) mask_out = create_mask(cExtend(amt >> 3));
    let data = EtherData { sop: sop_this_cycle, eop: eop_this_cycle, data: data_out, mask: mask_out };
    rg_tmp[1] <= rg_tmp[1] >> amt;
    rg_processed[1] <= rg_processed[1] - amt;
    rg_shift_amt[1] <= rg_shift_amt[1] - amt;
    data_out_ff.enq(data);
    dbprint(3, $format("Deparser ", fshow(data), rg_shift_amt[1] - amt));
  endrule

  // wait till all processed bits are sent, cont. to send payload.
  // some data are buffered not processed.
  rule rl_wait_till_processed_done if (header_done[1] && (rg_processed[1] == 0));
    deparse_done[1] <= True;
  endrule

  `define DEPARSER_RULES
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_RULES

  interface metadata = toPipeIn(meta_in_ff);
  interface PktWriteServer writeServer;
    interface writeData = toPut(data_in_ff);
  endinterface
  interface PktWriteClient writeClient;
    interface writeData = toGet(data_out_ff);
  endinterface
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
