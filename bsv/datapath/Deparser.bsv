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
import BRAMFIFO::*;
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
   interface PipeIn#(ByteStream#(16)) writeServer;
   interface PipeOut#(ByteStream#(16)) writeClient;
   method Action set_verbosity (int verbosity);
   method DeparserPerfRec read_perf_info ();
endinterface
(* synthesize *)
module mkDeparser (Deparser);
   `PRINT_DEBUG_MSG

   FIFOF#(ByteStream#(16)) data_in_ff <- mkFIFOF();
   FIFOF#(ByteStream#(16)) data_out_ff <- mkFIFOF();
   FIFOF#(MetadataT) meta_in_ff <- mkSizedFIFOF(16);
   FIFO#(DeparserState) deparse_state_ff <- mkPipelineFIFO();
   Array#(Reg#(Bit#(10))) rg_next_header_len <- mkCReg(3, 0);
   Array#(Reg#(Bit#(10))) rg_processed <- mkCReg(3, 0); // number of bytes in current header that have been sent.
   Array#(Reg#(Bit#(10))) rg_buffered <- mkCReg(3, 0); // number of bytes to shift to append new bytes to rg_tmp
   Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);
   Array#(Reg#(Bool)) deparse_done <- mkCReg(2, True);
   Array#(Reg#(Bool)) header_done <- mkCReg(2, True);
   Array#(Reg#(MetadataT)) meta <- mkCReg(2, defaultValue);
   PulseWire w_deparse_header_done <- mkPulseWire();

   // pipeline register at data_in
   Reg#(ByteStream#(16)) data_in_tmp <- mkReg(defaultValue);

   // stage 1
   FIFO#(void) flit_ff <- mkFIFO;
   Reg#(ByteStream#(16)) deparse_send_r <- mkReg(unpack(0));
   rule stage_1;
      let _ <- toGet(flit_ff).get;
      data_out_ff.enq(deparse_send_r);
   endrule

  function Action fetch_next_header(Bit#(10) len);
    action
      rg_next_header_len[0] <= len;
    endaction
  endfunction
  function Action move_buffered_amt(Bit#(10) len);
    action
      rg_buffered[0] <= rg_buffered[0] + len;
    endaction
  endfunction
  function Action succeed_and_next(Bit#(10) len);
    action
      rg_processed[0] <= rg_processed[0] + len;
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
  rule rl_deparse_start if (deparse_done[1] && data_in_ff.first.sop);
    // get new metadata
    deparse_done[1] <= False;
    header_done[1] <= False;
    let metadata = meta_in_ff.first;
    meta_in_ff.deq;
    meta[1] <= metadata;
    transit_next_state(metadata);
    dbprint(4, $format("Deparser:rl_start_state start deparse %d", valueOf(SizeOf#(DeparserState))));
  endrule

  // process payload portion of packet, until last beat
  rule rl_deparse_payload if (deparse_done[0] && !data_in_tmp.eop);
    let v = data_in_ff.first;
    data_in_ff.deq;
    data_in_tmp <= v;
    if (rg_buffered[0] != 0) begin
      Bit#(128) data_mask = create_mask(cExtend(rg_buffered[0]));
      Bit#(16) mask_out = create_mask(cExtend(rg_buffered[0] >> 3));
      let data = ByteStream { sop: data_in_tmp.sop,
                              eop: data_in_tmp.eop,
                              data: truncate(rg_tmp[0]) & data_mask,
                              mask: mask_out,
                              user:data_in_tmp.user};
      deparse_send_r <= data;
      flit_ff.enq(?);
      dbprint(4, $format("Deparser:rl_deparse_payload rg_buffered=%d", rg_buffered[0], fshow(data)));
      rg_buffered[0] <= 0;
    end
    else begin
      dbprint(4, $format("Deparser:rl_deparse_payload ", fshow(v)));
      let data = ByteStream { sop: data_in_tmp.sop,
                              eop: data_in_tmp.eop,
                              data: data_in_tmp.data,
                              mask: data_in_tmp.mask,
                              user: data_in_tmp.user };
      deparse_send_r <= data;
      flit_ff.enq(?);
    end
  endrule

  // reset all temporary states at last beat
  rule rl_reset if (deparse_done[0] && data_in_tmp.eop);
    data_in_tmp <= defaultValue;
    rg_tmp[0] <= 0;
    rg_buffered[0] <= 0;
    rg_processed[0] <= 0;
    dbprint(4, $format("Deparser:rl_reset"));
    let data = ByteStream { sop: data_in_tmp.sop,
                            eop: data_in_tmp.eop,
                            data: data_in_tmp.data,
                            mask: data_in_tmp.mask,
                            user: data_in_tmp.user };
    deparse_send_r <= data;
    flit_ff.enq(?);
  endrule

  // from deparse state, indicate header is all parsed
  rule rl_deparse_done if (w_deparse_header_done);
    // set counter: rg_next_header_len
    fetch_next_header(0);
    header_done[0] <= True;
    dbprint(4, $format("Deparser:rl_deparse_header_done"));
  endrule

  // wait till all processed bits are sent, cont. to send payload.
  // some data are buffered not processed.
  rule rl_wait_till_processed_done if (!deparse_done[1] && header_done[1] && (rg_processed[1] == 0));
    // wait till processed is done
    deparse_done[1] <= True;
    dbprint(3, $format("Deparser:rl_wait_till_processed_done"));
  endrule

  // apply mask and send data
  // use rg_processed to keep track how much data in buffer has been processed;
  // use rg_buffered to keep track how much more data is yet to be processed;
  rule rl_deparse_send if (!deparse_done[0] && (rg_processed[0] > 0));
    // rg_tmp >> amt
    // rg_processed -= amt
    // rg_buffered -= amt
    let amt = 128;
    if (rg_processed[0] < 128) begin
       amt = rg_processed[0];
    end
    Bit#(128) data_out = truncate(rg_tmp[0] & create_mask(cExtend(amt)));
    Bit#(16) mask_out = create_mask(cExtend(amt >> 3));
    let data = ByteStream { sop: data_in_tmp.sop,
                            eop: data_in_tmp.eop,
                            data: data_out,
                            mask: mask_out,
                            user: data_in_tmp.user };
    rg_tmp[0] <= rg_tmp[0] >> amt;
    rg_processed[0] <= rg_processed[0] - amt;
    rg_buffered[0] <= rg_buffered[0] - amt;
    deparse_send_r <= data;
    flit_ff.enq(?);
    dbprint(4, $format("Deparser:rl_deparse_send rg_processed=%d rg_buffered=%d amt=%d", rg_processed[0], rg_buffered[0], amt, fshow(data)));
  endrule

  function Rules genDeparseNextRule(PulseWire wl, DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      rule rl_deparse_next if (wl);
        // update counter : rg_next_header_len
        deparse_state_ff.enq(state);
        fetch_next_header(len);
      endrule
    endrules);
  endfunction

  function Rules genDeparseLoadRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules
      rule rl_deparse_load if ((deparse_state_ff.first == state) && (rg_buffered[0] < len));
        // take data from data_in_ff, shift and append
        // rg_tmp = data << rg_buffered | rg_tmp;
        // rg_buffered += len
        let v = data_in_ff.first;
        data_in_tmp <= v; // delay sop and eop by one cycle
        rg_tmp[0] <= zeroExtend(v.data) << rg_buffered[0] | rg_tmp[0];

        dbprint(4, $format("Deparser:rl_data_ff_load "));
        data_in_ff.deq;

        UInt#(NumBytes) n_bytes_used = countOnes(v.mask);
        UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
        move_buffered_amt(cExtend(n_bits_used));
        dbprint(4, $format("load state %d %d ", rg_buffered[0], n_bits_used, fshow(state)));
      endrule
    endrules);
  endfunction

  function Rules genDeparseSendRule(DeparserState state, Integer i);
    let len = fromInteger(i);
    return (rules 
      rule rl_deparse_send if ((deparse_state_ff.first == state) && (rg_buffered[0] >= len));
        // rg_processed += len
        // r <= rg_processed ?
        // amt = rg_processed < 128 ? rg_processed : 128;
        // rg_processed -= amt
        // rg_buffered -= amt
        // rg_tmp >> amt
        succeed_and_next(len);
        deparse_state_ff.deq;
        let metadata = meta[0];
        metadata = update_metadata(state);
        transit_next_state(metadata);
        meta[0] <= metadata;
        dbprint(4, $format("RULE: deparse send %d %d", rg_buffered[0], rg_processed[0]));
      endrule
    endrules);
  endfunction

  List#(Rules) deparse_fsm = List::nil;

  `define DEPARSER_RULES
  `include "DeparserGenerated.bsv"
  `undef DEPARSER_RULES

  Empty fsmrl <- addRules(foldl(rJoin, emptyRules, fsmRules));

  interface metadata = toPipeIn(meta_in_ff);
  interface writeServer = toPipeIn(data_in_ff);
  interface writeClient = toPipeOut(data_out_ff);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
