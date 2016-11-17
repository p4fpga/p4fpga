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
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"

`define BuffWidth 256

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

typedef struct {
   Bool sop;
   Bool eop;
   Bit#(`BuffWidth) data;
   Bit#(10) len;
   MetadataT meta;
   DeparserState state;
} Stage2Req deriving (Bits, FShow);

typedef struct {
   Bool sop;
   Bool eop;
   Bit#(`BuffWidth) data;
   Bit#(10) len;
} Stage3Req deriving (Bits);

interface Deparser;
   interface PipeIn#(MetadataT) metadata;
   interface PipeIn#(ByteStream#(16)) writeServer;
   interface PipeOut#(ByteStream#(16)) writeClient;
   method Action set_verbosity (int verbosity);
   method DeparserPerfRec read_perf_info ();
endinterface

(* synthesize *)
module mkDeparser (Deparser);
   `PRINT_DEBUG_MSG

   FIFOF#(ByteStream#(16)) data_in_ff <- mkFIFOF;
   FIFOF#(ByteStream#(16)) data_out_ff <- mkFIFOF;
   FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
   FIFO#(DeparserState) deparse_state_ff <- mkPipelineFIFO();
   Reg#(Bool) deparse_done <- mkReg(True);
   Reg#(Bool) header_done <- mkReg(False);
   Reg#(MetadataT) rg_metadata <- mkReg(defaultValue);
   Reg#(Bit#(10)) rg_buffered <- mkReg(0); // number of bytes buffered in rg_tmp
   Reg#(Bit#(10)) rg_processed <- mkReg(0); // number of bytes in current header that have been sent.
   Reg#(Bit#(10)) rg_shift_amt <- mkReg(0); // number of bytes to shift to append new bytes to rg_tmp
   Reg#(Bit#(`BuffWidth)) rg_tmp <- mkReg(0);
   Reg#(Bit#(128)) eoh_mask <- mkReg(0); // mask for end of header
   Reg#(Bool) rg_sop <- mkReg(False);
   Reg#(Bool) rg_eop <- mkReg(False);

   // stage 1: byte stream to header
   FIFOF#(Bit#(`BuffWidth)) stage1_ff <- mkFIFOF;

   // stage 2: apply metadata to header
   FIFOF#(MetadataT) meta_in_ff <- mkSizedFIFOF(16);
   FIFOF#(Stage2Req) stage2_ff <- mkFIFOF;

   // stage 3: header to byte stream
   FIFOF#(Stage3Req) stage3_ff <- mkFIFOF;
   Reg#(Bit#(`BuffWidth)) rg_stage3 <- mkReg(0);
   Reg#(Bit#(10)) rg_beat <- mkReg(0);
   Reg#(Bool) deparsing <- mkReg(False);

   let mask_this_cycle = data_in_ff.first.mask;
   let sop_this_cycle = data_in_ff.first.sop;
   let eop_this_cycle = data_in_ff.first.eop;
   let data_this_cycle = data_in_ff.first.data;
   function Action report_deparse_action(String msg, Bit#(10) buffered, Bit#(10) processed, Bit#(10) shift, Bit#(`BuffWidth) data);
    action
      if (cf_verbosity > 0) begin
        $display("(%0d) Deparser:report_deparse_action %s buffered %d %d %d data %h", $time, msg, buffered, processed, shift, data);
      end
    endaction
  endfunction
  function Action move_buffered_amt(Bit#(10) len);
    action
      rg_buffered <= rg_buffered + len;
      rg_shift_amt <= rg_shift_amt + len;
    endaction
  endfunction
  function Action succeed_and_next(Bit#(10) len);
    action
      rg_processed <= rg_processed + len;
      rg_buffered <= rg_buffered - len;
      rg_shift_amt <= rg_shift_amt - len;
    endaction
  endfunction
  function Bit#(max) create_mask(LUInt#(max) count);
    Bit#(max) v = ~('1 << count);
    return v;
  endfunction

  // app-specific states
  `define DEPARSER_STATE
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_STATE

  // key: we let rl_deparse_start preempts rl_deparse_payload
  // set flag, save metadata, branch
  // fires rl_deparse_next in same cycle.
  // which then fires, load or send?
  (* preempts = "rl_deparse_start, rl_deparse_payload" *)
  rule rl_deparse_start if (deparse_done && sop_this_cycle);
    deparse_done <= False;
    let metadata = meta_in_ff.first;
    rg_metadata <= metadata;
    transit_next_state(metadata);
    dbprint(4, $format("Deparser:rl_deparse_start ", fshow(metadata)));
    meta_in_ff.deq;
  endrule

  // process payload portion of packet, until last beat
  // apply data to mask, enqueue to output
  rule rl_deparse_payload if (deparse_done);
    // send payload
    let v = data_in_ff.first;
    data_in_ff.deq;
    dbprint(4, $format("Deparser:rl_deparse_payload ", fshow(v)));
    if (eop_this_cycle) begin
       rg_tmp <= 0;
       rg_buffered <= 0;
       rg_shift_amt <= 0;
       rg_processed <= 0;
       dbprint(4, $format("Deparser:rl_reset"));
    end
    data_out_ff.enq(v);
  endrule

`ifndef MDP
  // same cycle rule from deparse_start or rl_deparse_send
  function Rules genDeparseNextRule(PulseWire wl, DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      rule rl_deparse_next if (wl);
        // decide what next state to deparse next
        deparse_state_ff.enq(state);
        dbprint(3, $format("Deparser rl_deparse_next ", fshow(state)));
      endrule
    endrules);
  endfunction

  // one cycle after rl_deparse_send or start, load data from data_in_ff to rg_tmp
  function Rules genDeparseLoadRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      // stage 1: convert byte stream to header
      // accumulate enough byte, before apply mask
      rule rl_deparse_load if ((deparse_state_ff.first == state) && (rg_buffered < len));
        let v = data_in_ff.first;
        rg_tmp <= zeroExtend(v.data) << rg_shift_amt | rg_tmp;
        UInt#(NumBytes) n_bytes_used = countOnes(v.mask);
        UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
        move_buffered_amt(cExtend(n_bits_used));
        if (v.sop) begin
          rg_sop <= True;
        end
        dbprint(3, $format("Deparser rl_deparse_load shift_amt=%d ", rg_shift_amt, fshow(state), fshow(v)));
        data_in_ff.deq;
      endrule
    endrules);
  endfunction

  // if enough data buffered, apply metadata, and send
  function Rules genDeparseSendRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules 
      // stage 1: convert bytestream to header with deparsing FSM
      rule rl_stage1 if ((deparse_state_ff.first == state) && (rg_buffered >= len));
        let metadata = update_metadata(state);
        let req = Stage2Req {data: rg_tmp, len: len, sop: rg_sop, eop: rg_eop, meta: metadata, state: state};
        stage2_ff.enq(req);
        Bit#(`BuffWidth) remainder = zeroExtend(rg_tmp >> len);
        rg_tmp <= remainder;
        succeed_and_next(len);
        dbprint(3, $format("stage1 rg_tmp = %h ", rg_tmp));
        dbprint(3, $format("stage1 remainder = %h ", remainder));
        dbprint(3, $format("stage1 rg_shift_amt = %d ", rg_shift_amt - len));
        // decide which state to deparse next
        deparse_state_ff.deq;
        rg_metadata <= metadata;
        transit_next_state(metadata);
      endrule
    endrules);
  endfunction

  // stage 2: apply metadata
  rule rl_stage2_apply_metadata;
    let v = stage2_ff.first;
    stage2_ff.deq;
    let len = v.len;
    let meta = v.meta;
    let state = v.state;
    // FIXME: skip field edit for now
    // field_edit(state, data, meta);
    let req = Stage3Req {data: v.data, sop: v.sop, eop: v.eop, len: len};
    $display("(%0d) stage2 %h len=%d", $time, v.data, len);
    stage3_ff.enq(req); // enqueue buffered, rg_tmp
  endrule

  // stage 3: send header as byte stream in one or more beats
  rule rl_stage3_begin (!deparsing);
    let v = stage3_ff.first;
    // create mask
    deparsing <= True;
    rg_stage3 <= v.data;
    let len = v.len;
    let n_beat = v.len >> valueOf(TLog#(128));
    rg_beat <= n_beat;
    $display("(%0d) stage3 %h beat=%d", $time, v.data, n_beat);
    $display("(%0d) stage3 begin rg_shift_amt next = %d", $time, rg_shift_amt);
  endrule

  // can we compute required mask in previous cycle?
  rule rl_stage3_cont if (deparsing && rg_beat > 0);
    // data_out_ff.enq(data);
    Bit#(128) data = truncate(rg_stage3);
    rg_stage3 <= rg_stage3 >> 128;
    rg_processed <= rg_processed - 128;
    rg_beat <= rg_beat - 1;
    ByteStream#(16) beat = ByteStream { sop: rg_sop, eop: False, data: data, mask: 'hffff, user:0 };
    if (rg_sop) begin
      rg_sop <= False;
    end
    $display("(%0d) stage3 cont ", $time, fshow(beat));
    $display("(%0d) stage3 cont rg_shift_amt next = %d", $time, rg_shift_amt);
    data_out_ff.enq(beat);
  endrule

  rule rl_stage3_end if (deparsing && rg_beat == 0);
    Bit#(128) data_mask = create_mask(cExtend(rg_processed));
    Bit#(16) mask_out = create_mask(cExtend(rg_processed >> 3));
    let beat = ByteStream { sop: rg_sop, eop: False, data: truncate(rg_stage3), mask: mask_out, user:0 };
    rg_processed <= 0;
    if (rg_sop) begin
      rg_sop <= False;
    end
    deparsing <= False;
    stage3_ff.deq;
    $display("(%0d) stage3 end %h rg_processed %d", $time, rg_stage3, rg_processed);
    data_out_ff.enq(beat);
  endrule

  // wait till all processed bits are sent, cont. to send payload.
  // some data are buffered not processed.
  rule rl_header_completion if (!deparse_done && !deparsing && header_done && (rg_processed == 0));
    deparse_done <= True;
    header_done <= False;
    rg_shift_amt <= 0;
    Bit#(128) data = truncate(rg_tmp);
    Bit#(128) data_mask = create_mask(cExtend(rg_shift_amt));
    Bit#(16) mask_out = create_mask(cExtend(rg_shift_amt >> 3));
    let beat = ByteStream { sop: False, eop: False, data: data, mask: mask_out, user:0 };
    dbprint(3, $format("Deparser:rl_completion len=%d %h", rg_shift_amt, rg_tmp));
    dbprint(4, $format("Deparser:rl_completion ", fshow(beat)));
    data_out_ff.enq(beat);
 endrule

  List#(Rules) deparse_fsm = List::nil;
`endif

  `define DEPARSER_RULES
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_RULES

`ifndef MDP
  Empty fsmrl <- addRules(foldl(rJoin, emptyRules, fsmRules));
`endif

  interface metadata = toPipeIn(meta_in_ff);
  interface writeServer = toPipeIn(data_in_ff);
  interface writeClient = toPipeOut(data_out_ff);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
