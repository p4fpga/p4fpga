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
import Vector::*;
import Stream::*;

interface StreamGearbox#(numeric type n);
   interface Put#(ByteStream#(n)) datain;
   interface Get#(ByteStream#(TMul#(2, n))) dataout;
endinterface


typeclass MkStreamGearbox#(numeric type n);
   module mkStreamGearbox(StreamGearbox#(n));
   function Put#(ByteStream#(n)) getDataIn(StreamGearbox#(n) gb);
   function Get#(ByteStream#(TMul#(2, n))) getDataOut(StreamGearbox#(n) gb);
endtypeclass

// toHost
// toNetwork
instance MkStreamGearbox#(n);

   function Put#(ByteStream#(n)) getDataIn(StreamGearbox#(n) gb);
      return gb.datain;
   endfunction

   function Get#(ByteStream#(TMul#(2, n))) getDataOut(StreamGearbox#(n) gb);
      return gb.dataout;
   endfunction

   module mkStreamGearbox(StreamGearbox#(n));
      let verbose = True;
      FIFO#(ByteStream#(n)) in_ff <- mkFIFO;
      FIFO#(ByteStream#(TMul#(2, n))) out_ff <- mkFIFO;
      Reg#(Bool) inProgress <- mkReg(False);
      Reg#(Bool) oddBeat    <- mkReg(True);
      Reg#(ByteStream#(n)) v_prev <- mkReg(defaultValue);

      function ByteStream#(TMul#(2, n)) combine(Vector#(2, ByteStream#(n)) v);
         ByteStream#(TMul#(2, n)) data = defaultValue;
         data.data = {v[1].data, v[0].data};
         data.mask = {v[1].mask, v[0].mask};
         data.sop = v[0].sop;
         data.eop = v[0].eop || v[1].eop;
         return data;
      endfunction
      rule startOfPacket if (!inProgress);
         let v = in_ff.first;
         inProgress <= v.sop;
         if (!v.sop)
            in_ff.deq;
         if (verbose) $display("gearbox start");
      endrule
      rule readPacketOdd if (inProgress && oddBeat);
         let v <- toGet(in_ff).get;
         if (verbose) $display("gearbox read odd beat %h", v.data);
         if (v.eop) begin
            ByteStream#(n) vo = defaultValue;
            out_ff.enq(combine(vec(v, vo)));
            if (verbose) $display("gearbox odd eop %h %h", v.data, v.mask);
            inProgress <= False;
         end
         else begin
            oddBeat <= !oddBeat;
         end
         v_prev <= v;
      endrule

      rule readPacketEven if (inProgress && !oddBeat);
         let v <- toGet(in_ff).get;
         out_ff.enq(combine(vec(v_prev, v)));
         if (verbose) $display("gearbox read even beat %h", v.data);
         if (v.eop) begin
            inProgress <= False;
            if (verbose) $display("gearbox even eop %h %h %h %h", v.data, v.mask, v_prev.data, v_prev.mask);
         end
         oddBeat <= !oddBeat;
      endrule
      interface datain = toPut(in_ff);
      interface dataout = toGet(out_ff);
   endmodule
endinstance

