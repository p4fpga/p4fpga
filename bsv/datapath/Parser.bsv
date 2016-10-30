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

// Parser Template
import Library::*;
import List::*;
import UnitAppendList::*;
import HList::*;
`include "Debug.defines"

`include "ConnectalProjectConfig.bsv"

`define PARSER_STRUCT
`include "ParserGenerated.bsv"
`undef PARSER_STRUCT

`define COLLECT_RULE(collectrule, rl) collectrule = List::cons (rl, collectrule)

interface Parser;
   interface Put#(ByteStream#(16)) frameIn;
   interface Get#(MetadataT) meta;
   method Action set_verbosity (int verbosity);
   method ParserPerfRec read_perf_info ();
endinterface

module mkParser#(Integer portnum)(Parser);
   `PRINT_DEBUG_MSG
   Reg#(Bool) parse_done[2] <- mkCReg(2, True);
   FIFO#(ParserState) parse_state_ff <- mkPipelineFIFO();
   FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
   FIFOF#(ByteStream#(16)) data_in_ff <- mkFIFOF;
   FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
   PulseWire w_parse_done <- mkPulseWire();
   PulseWire w_parse_header_done <- mkPulseWireOR();
   PulseWire w_load_header <- mkPulseWireOR();
   Array#(Reg#(Bit#(10))) rg_next_header_len <- mkCReg(3, 0);
   Array#(Reg#(Bit#(10))) rg_buffered <- mkCReg(3, 0);
   Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);

   `define PARSER_STATE
   `include "ParserGenerated.bsv"
   `undef PARSER_STATE

   function Action succeed_and_next(Bit#(10) offset);
     action
       rg_buffered[0] <= rg_buffered[0] - offset;
       dbprint(4,$format("succeed_and_next subtract offset = %d shift_amt/buffered = %d", offset, rg_buffered[0] - offset));
     endaction
   endfunction
   function Action fetch_next_header0(Bit#(10) len);
     action
       rg_next_header_len[0] <= len;
       w_parse_header_done.send();
     endaction
   endfunction
   function Action fetch_next_header1(Bit#(10) len);
     action
       rg_next_header_len[1] <= len;
       w_parse_header_done.send();
     endaction
   endfunction
   function Action move_shift_amt(Bit#(10) len);
     action
       rg_buffered[0] <= rg_buffered[0] + len;
       w_load_header.send();
     endaction
   endfunction
   function Action failed_and_trap(Bit#(10) offset);
     action
       rg_buffered[0] <= 0;
     endaction
   endfunction
   function Action report_parse_action(ParserState state, Bit#(10) offset, Bit#(128) data, Bit#(512) buff);
     action
       if (cf_verbosity > 3) begin
         $display("(%0d) Parser State %h buffered %d, %h, %h", $time, state, offset, data, buff);
       end
     endaction
   endfunction
   let sop_this_cycle = data_in_ff.first.sop;
   let eop_this_cycle = data_in_ff.first.eop;
   let data_this_cycle = data_in_ff.first.data;

   `define PARSER_FUNCTION
   `include "ParserGenerated.bsv"
   `undef PARSER_FUNCTION

   rule rl_data_ff_load if ((!parse_done[1] && rg_buffered[2] < rg_next_header_len[2]) && (w_parse_header_done || w_load_header));
      let v = data_in_ff.first.data;
      data_in_ff.deq;
      data_ff.enq(tagged Valid v);
      dbprint(4, $format("dequeue data %d %d", rg_buffered[2], rg_next_header_len[2]));
   endrule

   rule rl_start_state_deq if (parse_done[1] && sop_this_cycle && !w_parse_header_done);
      let v = data_in_ff.first.data;
      data_ff.enq(tagged Valid v);
      rg_buffered[2] <= 0;
      parse_done[1] <= False;
      parse_state_ff.enq(initState);
      dbprint(1, $format("START parse pkt"));
   endrule

   rule rl_start_state_idle if (parse_done[1] && (!sop_this_cycle || w_parse_header_done));
      data_in_ff.deq;
   endrule

   // One cycle delay to allow last extracted data to propagate through DFIFOF.
   // TODO: We can remove this delay with a customized DFIFOF that
   //       returns default value when empty AND allow deq/enq when empty.
   FIFOF#(void) delay_ff <- mkFIFOF;
   rule rl_delay if (w_parse_done);
      delay_ff.enq(?);
   endrule

   function Rules genLoadRule (ParserState state, Integer i);
      let len = fromInteger(i);
      return (rules 
         rule rl_load if ((parse_state_ff.first == state) && rg_buffered[0] < len);
            if (isValid(data_ff.first)) begin
               data_ff.deq;
               let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp[0];
               rg_tmp[0] <= zeroExtend(data);
               move_shift_amt(128);
               report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
            end
         endrule
      endrules);
   endfunction

   function Rules genAcceptRule (PulseWire wl);
      return (rules
         rule rl_accept if (wl);
            parse_done[0] <= True;
            w_parse_done.send();
            fetch_next_header0(0);
         endrule
      endrules);
   endfunction

   function Rules genContRule (PulseWire wl, ParserState state, Integer i);
      let len = fromInteger(i);
      return (rules
         rule rl_cont if (wl);
            parse_state_ff.enq(state);
            fetch_next_header0(len);
         endrule
      endrules);
   endfunction

   function Rules genExtractRule (ParserState state, Integer i);
      let len = fromInteger(i);
      return (rules
         rule rl_extract if ((parse_state_ff.first == state) && (rg_buffered[0] >= len));
            let data = rg_tmp[0];
            if (isValid(data_ff.first)) begin
               data_ff.deq;
               data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp[0];
            end
            report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
            extract_header(state, data);
            rg_tmp[0] <= zeroExtend(data >> len);
            succeed_and_next(len);
            parse_state_ff.deq;
         endrule
      endrules);
   endfunction

   List#(Rules) parse_fsm = List::nil;

   `define PARSER_RULES
   `include "ParserGenerated.bsv"
   `undef PARSER_RULES

   Empty fsmrl <- addRules(foldl(rJoin, emptyRules, fsmRules));

   interface frameIn = toPut(data_in_ff);
   interface meta = toGet(meta_in_ff);
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
