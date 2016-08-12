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

`define PARSER_STRUCT
`include "ParserGenerated.bsv"
`undef PARSER_STRUCT

interface Parser;
   interface Put#(EtherData) frameIn;
   interface Get#(MetadataT) meta;
   method Action set_verbosity (int verbosity);
   method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
   Reg#(int) cf_verbosity <- mkConfigRegU;
   Reg#(Bool) parse_done[2] <- mkCReg(2, True);
   FIFO#(ParserState) parse_state_ff <- mkPipelineFIFO();
   FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
   FIFOF#(EtherData) data_in_ff <- printTimedTraceM("parse_data_in_ff", mkFIFOF);
   FIFOF#(MetadataT) meta_in_ff <- printTimedTraceM("parse_meta_in_ff", mkFIFOF);
   PulseWire w_parse_done <- mkPulseWire();
   PulseWire w_parse_header_done <- mkPulseWireOR();
   PulseWire w_load_header <- mkPulseWireOR();
   Array#(Reg#(Bit#(32))) rg_next_header_len <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_buffered <- mkCReg(3, 0);
   Array#(Reg#(Bit#(32))) rg_shift_amt <- mkCReg(3, 0);
   Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);

   function Action dbprint(Integer level, Fmt msg);
      action
      if (cf_verbosity > fromInteger(level)) begin
         $display("(%0d) ", $time, msg);
      end
      endaction
   endfunction

   `define PARSER_STATE
   `include "ParserGenerated.bsv"
   `undef PARSER_STATE

   function Action succeed_and_next(Bit#(32) offset);
     action
       rg_buffered[0] <= rg_buffered[0] - offset;
       rg_shift_amt[0] <= rg_buffered[0] - offset;
       dbprint(3,$format("succeed_and_next subtract offset = %d shift_amt/buffered = %d", offset, rg_buffered[0] - offset));
     endaction
   endfunction
   function Action fetch_next_header0(Bit#(32) len);
     action
       rg_next_header_len[0] <= len;
       w_parse_header_done.send();
     endaction
   endfunction
   function Action fetch_next_header1(Bit#(32) len);
     action
       rg_next_header_len[1] <= len;
       w_parse_header_done.send();
     endaction
   endfunction
   function Action move_shift_amt(Bit#(32) len);
     action
       rg_shift_amt[0] <= rg_shift_amt[0] + len;
       w_load_header.send();
     endaction
   endfunction
   function Action failed_and_trap(Bit#(32) offset);
     action
       rg_buffered[0] <= 0;
     endaction
   endfunction
   function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data, Bit#(512) buff);
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
      rg_buffered[2] <= rg_buffered[2] + 128;
      data_ff.enq(tagged Valid v);
      dbprint(3, $format("dequeue data %d %d", rg_buffered[2], rg_next_header_len[2]));
   endrule

   rule rl_start_state_deq if (parse_done[1] && sop_this_cycle && !w_parse_header_done);
      let v = data_in_ff.first.data;
      data_ff.enq(tagged Valid v);
      rg_buffered[2] <= 128;
      rg_shift_amt[2] <= 0;
      parse_done[1] <= False;
      parse_state_ff.enq(StateParseEthernet);
   endrule

   rule rl_start_state_idle if (parse_done[1] && (!sop_this_cycle || w_parse_header_done));
      data_in_ff.deq;
   endrule

   `define PARSER_RULES
   `include "ParserGenerated.bsv"
   `undef PARSER_RULES

   interface frameIn = toPut(data_in_ff);
   interface meta = toGet(meta_in_ff);
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
