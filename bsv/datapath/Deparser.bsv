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
import Library::*;
`include "Debug.defines"

// app-specific structs
`define DEPARSER_STRUCT
`include "DeparserGenerated.bsv"
`undef DEPARSER_STRUCT

`define COLLECT_RULE(collectrule, rl) collectrule = List::cons (rl, collectrule)

typeclass CheckForward#(type t);
   function Bool checkForward(t x);
endtypeclass
instance CheckForward#(Maybe#(Header#(t)));
   function Bool checkForward(Maybe#(Header#(t)) x);
      case (x) matches
         tagged Valid .h: begin
            return h.state matches tagged Forward ? True : False;
         end
         tagged Invalid: begin
            return False;
         end
      endcase
   endfunction
endinstance

typeclass UpdateState#(type t);
   function t updateState(t x, HeaderState state);
endtypeclass
instance UpdateState#(Maybe#(Header#(t)));
   function Maybe#(Header#(t)) updateState(Maybe#(Header#(t)) x, HeaderState state);
      case (x) matches
         tagged Valid .h: begin
            return tagged Valid Header {hdr: h.hdr, state: state};
         end
         tagged Invalid: begin
            return tagged Invalid;
         end
      endcase
   endfunction
endinstance

typedef TDiv#(PktDataWidth, 8) MaskWidth;
typedef TLog#(PktDataWidth) DataSize;
typedef TLog#(TDiv#(PktDataWidth, 8)) MaskSize;
typedef TAdd#(DataSize, 1) NumBits;
typedef TAdd#(MaskSize, 1) NumBytes;

interface Deparser;
   interface PipeIn#(MetadataT) metadata;
   interface PktWriteServer#(16) writeServer;
   interface PktWriteClient#(16) writeClient;
   method Action set_verbosity (int verbosity);
   method DeparserPerfRec read_perf_info ();
endinterface
(* synthesize *)
module mkDeparser (Deparser);
   `PRINT_DEBUG_MSG

   FIFOF#(ByteStream#(16)) data_in_ff <- mkFIFOF;
   FIFOF#(ByteStream#(16)) data_out_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_in_ff <- mkSizedFIFOF(16);
   FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
   FIFO#(DeparserState) deparse_state_ff <- mkPipelineFIFO();
   Array#(Reg#(Bit#(32))) rg_next_header_len <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_buffered <- mkCReg(3, 0); // number of bytes buffered in rg_tmp
   Array#(Reg#(Bit#(32))) rg_processed <- mkCReg(3, 0); // number of bytes in current header that have been sent.
   Array#(Reg#(Bit#(32))) rg_shift_amt <- mkCReg(3, 0); // number of bytes to shift to append new bytes to rg_tmp
   Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);
   Array#(Reg#(Bool)) deparse_done <- mkCReg(2, True);
   Array#(Reg#(Bool)) header_done <- mkCReg(2, True);
   Array#(Reg#(MetadataT)) meta <- mkCReg(2, defaultValue);
   PulseWire w_deparse_header_done <- mkPulseWire();

   let mask_this_cycle = data_in_ff.first.mask;
   let sop_this_cycle = data_in_ff.first.sop;
   let eop_this_cycle = data_in_ff.first.eop;
   let data_this_cycle = data_in_ff.first.data;
   function Action report_deparse_action(String msg, Bit#(32) buffered, Bit#(32) processed, Bit#(32) shift, Bit#(512) data);
    action
      if (cf_verbosity > 0) begin
        $display("(%0d) Deparser:report_deparse_action %s buffered %d %d %d data %h", $time, msg, buffered, processed, shift, data);
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

  // app-specific states
  `define DEPARSER_STATE
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_STATE

  // key: we let rl_deparse_start preempts rl_deparse_payload
  (* preempts = "rl_deparse_start, rl_deparse_payload" *)
  rule rl_deparse_start if (deparse_done[1] && sop_this_cycle);
    deparse_done[1] <= False;
    header_done[1] <= False;
    let metadata = meta_in_ff.first;
    meta_in_ff.deq;
    meta[1] <= metadata;
    transit_next_state(metadata);
    dbprint(4, $format("Deparser:rl_start_state start deparse %d", valueOf(SizeOf#(DeparserState))));
    dbprint(1, $format("START deparse pkt"));
  endrule

  // process payload portion of packet, until last beat
  rule rl_deparse_payload if (deparse_done[1] && !eop_this_cycle);
    let v = data_in_ff.first;
    data_in_ff.deq;
    if (rg_shift_amt[1] != 0) begin
      Bit#(128) data_mask = create_mask(cExtend(rg_shift_amt[1]));
      Bit#(16) mask_out = create_mask(cExtend(rg_shift_amt[1] >> 3));
      let data = ByteStream { sop: v.sop, eop: v.eop, data: truncate(rg_tmp[1]) & data_mask, mask: mask_out, user:0 };
      data_out_ff.enq(data);
      dbprint(4, $format("Deparser:rl_deparse_payload rg_shift_amt=%d", rg_shift_amt[1], fshow(data)));
      rg_shift_amt[1] <= 0;
    end
    else begin
      dbprint(4, $format("Deparser:rl_deparse_payload ", fshow(v)));
      data_out_ff.enq(v);
    end
  endrule

  // reset all temporary states at last beat
  rule rl_reset if (deparse_done[1] && eop_this_cycle);
    let v = data_in_ff.first;
    data_in_ff.deq;
    rg_tmp[1] <= 0;
    rg_buffered[2] <= 0;
    rg_shift_amt[2] <= 0;
    rg_processed[2] <= 0;
    dbprint(4, $format("Deparser:rl_reset"));
    data_out_ff.enq(v);
  endrule

  // from deparse state, indicate header is all parsed
  rule rl_deparse_done if (w_deparse_header_done);
    fetch_next_header(0);
    header_done[0] <= True;
    dbprint(4, $format("Deparser:rl_deparse_header_done"));
  endrule

  // wait till all processed bits are sent, cont. to send payload.
  // some data are buffered not processed.
  rule rl_wait_till_processed_done if (!deparse_done[1] && header_done[1] && (rg_processed[1] == 0));
    deparse_done[1] <= True;
    dbprint(3, $format("Deparser:rl_wait_till_processed_done"));
  endrule

  // dequeue data_in_ff during header deparsing
  rule rl_data_ff_load if (!deparse_done[1] && (rg_buffered[2] < rg_next_header_len[2]));
    dbprint(4, $format("Deparser:rl_data_ff_load %d < %d", rg_buffered[2], rg_next_header_len[2]));
    data_in_ff.deq;
  endrule

  // apply mask and send data
  // use rg_processed to keep track how much data in buffer has been processed;
  // use rg_shift_amt to keep track how much more data is yet to be processed;
  rule rl_deparse_send if (!deparse_done[1] && (rg_processed[1] > 0));
    let amt = 128;
    if (rg_processed[1] < 128) begin
       amt = rg_processed[1];
    end
    let v = data_in_ff.first;
    dbprint(3, $format("Deparser:rl_deparse_send ", fshow(v)));
    Bit#(128) data_out = truncate(rg_tmp[1] & create_mask(cExtend(amt)));
    Bit#(16) mask_out = create_mask(cExtend(amt >> 3));
    let data = ByteStream { sop: sop_this_cycle, eop: False, data: data_out, mask: mask_out, user:0 };
    rg_tmp[1] <= rg_tmp[1] >> amt;
    rg_processed[1] <= rg_processed[1] - amt;
    rg_shift_amt[1] <= rg_shift_amt[1] - amt;
    data_out_ff.enq(data);
    dbprint(4, $format("Deparser:rl_deparse_send rg_processed=%d rg_shift_amt=%d amt=%d", rg_processed[1], rg_shift_amt[1], amt, fshow(data)));
  endrule

  function Rules genDeparseNextRule(PulseWire wl, DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      rule rl_deparse_next if (wl);
        deparse_state_ff.enq(state);
        fetch_next_header(len);
      endrule
    endrules);
  endfunction

  function Rules genDeparseLoadRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      rule rl_deparse_load if ((deparse_state_ff.first == state) && (rg_buffered[0] < len));
        rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
        UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);
        UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
        move_buffered_amt(cExtend(n_bits_used));
      endrule
    endrules);
  endfunction

  function Rules genDeparseSendRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules 
      rule rl_deparse_send if ((deparse_state_ff.first == state) && (rg_buffered[0] >= len));
        succeed_and_next(len);
        deparse_state_ff.deq;
        let metadata = meta[0];
        metadata = update_metadata(state);
        transit_next_state(metadata);
        meta[0] <= metadata;
      endrule
    endrules);
  endfunction

  List#(Rules) deparse_fsm = List::nil;

  `define DEPARSER_RULES
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_RULES

  Empty fsmrl <- addRules(foldl(rJoin, emptyRules, fsmRules));

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
