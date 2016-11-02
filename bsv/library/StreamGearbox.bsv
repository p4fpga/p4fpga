// Copyright (c) 2016 Cornell University.
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

import BuildVector::*;
import DefaultValue::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import Stream::*;
import Gearbox::*;
import SynthBuilder::*;
import PrintTrace::*;

`include "SynthBuilder.defines"

interface StreamGearbox#(numeric type n, numeric type m);
   interface Put#(ByteStream#(n)) datain;
   interface Get#(ByteStream#(m)) dataout;
   method Bit#(64) getEopCount;
   method Bit#(64) getSopCount;
   method Bit#(64) getIdleCount;
   method Bit#(64) getDataCount;
endinterface

typeclass GetGearbox#(numeric type n, numeric type m);
   function Put#(ByteStream#(n)) getDataIn(StreamGearbox#(n, m) gb);
   function Get#(ByteStream#(m)) getDataOut(StreamGearbox#(n, m) gb);
endtypeclass

instance GetGearbox#(n, m);
   function Put#(ByteStream#(n)) getDataIn(StreamGearbox#(n, m) gb);
      return gb.datain;
   endfunction
   function Get#(ByteStream#(m)) getDataOut(StreamGearbox#(n, m) gb);
      return gb.dataout;
   endfunction
endinstance

typeclass MkStreamGearboxUp#(numeric type n, numeric type m);
   module mkStreamGearboxUp(StreamGearbox#(n, m));
endtypeclass

// Gearbox Box 1-to-2
instance MkStreamGearboxUp#(n, m)
   provisos(Mul#(n, 2, m)
           ,Add#(a__, TLog#(TAdd#(1, n)), 64)
           ,Add#(1, b__, TLog#(TAdd#(1, n))));
   module mkStreamGearboxUp(StreamGearbox#(n, m));
      let verbose = False;
      FIFOF#(ByteStream#(n)) in_ff <- mkSizedFIFOF(2);
      FIFOF#(ByteStream#(m)) out_ff <- mkSizedFIFOF(2);
      Reg#(Bool) inProgress <- mkReg(False);
      Reg#(Bool) oddBeat    <- mkReg(True);
      Reg#(ByteStream#(n)) v_prev <- mkReg(defaultValue);

      Reg#(Bit#(64)) idle_cycles <- mkReg(0);
      Reg#(Bit#(64)) sopCount <- mkReg(0);
      Reg#(Bit#(64)) eopCount <- mkReg(0);
      Reg#(Bit#(64)) data_bytes <- mkReg(0);

      function ByteStream#(m) combine(Vector#(2, ByteStream#(n)) v);
         ByteStream#(m) data = defaultValue;
         data.data = {v[1].data, v[0].data};
         data.mask = {v[1].mask, v[0].mask};
         data.user = v[0].user;
         data.sop = v[0].sop;
         data.eop = v[0].eop || v[1].eop;
         return data;
      endfunction
      rule startOfPacket if (!inProgress);
         let v = in_ff.first;
         inProgress <= v.sop;
         if (!v.sop)
            in_ff.deq;
         else
            sopCount <= sopCount + 1;
         if (verbose) $display("gearbox start");
      endrule
      rule readPacketOdd if (inProgress && oddBeat);
         let v <- toGet(in_ff).get;
         if (verbose) $display("gearbox read odd beat %h", v.data);
         let bytes = zeroExtend(pack(countOnes(v.mask)));
         data_bytes <= data_bytes + bytes;
         if (v.eop) begin
            ByteStream#(n) vo = defaultValue;
            out_ff.enq(combine(vec(v, vo)));
            if (verbose) $display("gearbox odd eop %h %h", v.data, v.mask);
            inProgress <= False;
            eopCount <= eopCount + 1;
         end
         else begin
            oddBeat <= !oddBeat;
         end
         v_prev <= v;
      endrule

      rule readPacketEven if (inProgress && !oddBeat);
         let v <- toGet(in_ff).get;
         let bytes = zeroExtend(pack(countOnes(v.mask)));
         data_bytes <= data_bytes + bytes;
         out_ff.enq(combine(vec(v_prev, v)));
         if (verbose) $display("gearbox read even beat %h", v.data);
         if (v.eop) begin
            inProgress <= False;
            if (verbose) $display("gearbox even eop %h %h %h %h", v.data, v.mask, v_prev.data, v_prev.mask);
            eopCount <= eopCount + 1;
         end
         oddBeat <= !oddBeat;
      endrule

      rule count_idle_cycles (!inProgress);
         idle_cycles <= idle_cycles + 1;
      endrule

      interface datain = toPut(in_ff);
      interface dataout = toGet(out_ff);
      method Bit#(64) getEopCount;
         return eopCount;
      endmethod
      method Bit#(64) getSopCount;
         return sopCount;
      endmethod
      method Bit#(64) getIdleCount;
         return idle_cycles;
      endmethod
      method Bit#(64) getDataCount;
         return data_bytes;
      endmethod
   endmodule
endinstance

typeclass MkStreamGearboxDn#(numeric type n, numeric type m);
   module mkStreamGearboxDn(StreamGearbox#(n, m));
endtypeclass

// Gearbox 2-to-1
instance MkStreamGearboxDn#(n, m) provisos(Mul#(m, 2, n));
   module mkStreamGearboxDn(StreamGearbox#(n, m));
      let clock <- exposeCurrentClock();
      let reset <- exposeCurrentReset();

      FIFO#(ByteStream#(n)) in_ff <- mkFIFO;
      FIFO#(ByteStream#(m)) out_ff <- mkFIFO;
      Gearbox#(2, 1, ByteStream#(m)) fifoTxData <- mkNto1Gearbox(clock, reset, clock, reset);

      function Vector#(2, ByteStream#(m)) split(ByteStream#(n) in);
         Vector#(2, ByteStream#(m)) v = defaultValue;
         Vector#(2, Bit#(TMul#(m, 8))) data = unpack(in.data);
         Vector#(2, Bit#(m)) mask = unpack(in.mask);
         v[0].sop = in.sop;
         v[0].data = data[0];
         v[0].eop = (mask[1] == 0) ? in.eop : False;
         v[0].mask = mask[0];
         v[0].user = in.user;
         v[1].sop = False;
         v[1].data = data[1];
         v[1].eop = in.eop;
         v[1].mask = mask[1];
         v[1].user = in.user;
         return v;
      endfunction

      rule process_incoming_packet;
         let v <- toGet(in_ff).get;
         fifoTxData.enq(split(v));
      endrule

      rule process_outgoing_packet;
         let data = fifoTxData.first; fifoTxData.deq;
         let temp = head(data);
         let bytes = zeroExtend(pack(countOnes(temp.mask)));
         if (temp.mask != 0) begin
            out_ff.enq(temp);
         end
      endrule

      interface datain = toPut(in_ff);
      interface dataout = toGet(out_ff);
   endmodule
endinstance
