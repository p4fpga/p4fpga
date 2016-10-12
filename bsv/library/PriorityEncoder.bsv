// Copyright (c) 2015 Cornell University.

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

import Arith::*;
import Assert::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;

interface PE#(numeric type n);
   interface Put#(Bit#(n)) oht;
   interface Get#(Maybe#(Bit#(TLog#(n)))) bin;
endinterface
typeclass PEncoder#(numeric type n);
   module mkPEncoder(PE#(n));
endtypeclass

function Maybe#(Bit#(1)) mkPE2(Bit#(2) data);
   let valid = boolor(unpack(data[0]), unpack(data[1]));
   let bin = ~data[0];
   let ret = (valid == False) ? tagged Invalid : tagged Valid bin;
   return ret;
endfunction

function Maybe#(Bit#(2)) mkPE4(Bit#(4) data);
   let valid = boolor(boolor(unpack(data[0]), unpack(data[1])), boolor(unpack(data[2]), unpack(data[3])));
   let bin = {pack(!(unpack(data[0])||unpack(data[1]))), pack(!unpack(data[0]) && (unpack(data[1])||!unpack(data[2])))};
   let ret = (valid == False) ? tagged Invalid : tagged Valid bin;
   return ret;
endfunction

function Maybe#(Bit#(3)) mkPE8(Bit#(8) data);
   Vector#(4, Bit#(2)) data2b = unpack(data);
   Vector#(4, Maybe#(Bit#(1))) out2b;
   for(Integer i=0; i<4; i=i+1) begin
      out2b[i] = mkPE2(data2b[i]);
   end
   Vector#(4, Bool) vld2b = map(isValid, out2b);
   Maybe#(Bit#(2)) vldOut = mkPE4(pack(vld2b));
   Maybe#(Bit#(3)) ret;
   if (isValid(vldOut)) begin
      let validOut = fromMaybe(?, vldOut);
      let encodedOut = fromMaybe(?, out2b[validOut]);
      let out = {validOut, encodedOut};
      ret = tagged Valid out;
   end
   else begin
      ret = tagged Invalid;
   end
   return ret;
endfunction

function Maybe#(Bit#(4)) mkPE16(Bit#(16) data);
   Vector#(4, Bit#(4)) data4b = unpack(data);
   Vector#(4, Maybe#(Bit#(2))) out4b;
   for(Integer i=0; i<4; i=i+1) begin
      out4b[i] = mkPE4(data4b[i]);
   end
   Vector#(4, Bool) vld4b = map(isValid, out4b);
   Maybe#(Bit#(2)) vldOut = mkPE4(pack(vld4b));
   Maybe#(Bit#(4)) ret;
   if (isValid(vldOut)) begin
      let validOut = fromMaybe(?, vldOut);
      let encodedOut = fromMaybe(?, out4b[validOut]);
      let out = {validOut, encodedOut};
      ret = tagged Valid out;
   end
   else begin
      ret = tagged Invalid;
   end
   return ret;
endfunction

function Maybe#(Bit#(6)) mkPE64(Bit#(64) data);
   Vector#(4, Bit#(16)) data16b = unpack(data);
   Vector#(4, Maybe#(Bit#(4))) out16b;
   for(Integer i=0; i<4; i=i+1) begin
      out16b[i] = mkPE16(data16b[i]);
   end
   Vector#(4, Bool) vld16b = map(isValid, out16b);
   Maybe#(Bit#(2)) vldOut = mkPE4(pack(vld16b));
   Maybe#(Bit#(6)) ret;
   if (isValid(vldOut)) begin
      let validOut = fromMaybe(?, vldOut);
      let encodedOut = fromMaybe(?, out16b[validOut]);
      let out = {validOut, encodedOut};
      ret = tagged Valid out;
   end
   else begin
      ret = tagged Invalid;
   end
   return ret;
endfunction

function Maybe#(Bit#(8)) mkPE256(Bit#(256) data);
   Vector#(4, Bit#(64)) data64b = unpack(data);
   Vector#(4, Maybe#(Bit#(6))) out64b;
   for(Integer i=0; i<4; i=i+1) begin
      out64b[i] = mkPE64(data64b[i]);
   end
   Vector#(4, Bool) vld64b = map(isValid, out64b);
   Maybe#(Bit#(2)) vldOut = mkPE4(pack(vld64b));
   Maybe#(Bit#(8)) ret;
   if (isValid(vldOut)) begin
      let validOut = fromMaybe(?, vldOut);
      let encodedOut = fromMaybe(?, out64b[validOut]);
      let out = {validOut, encodedOut};
      ret = tagged Valid out;
   end
   else begin
      ret = tagged Invalid;
   end
   return ret;
endfunction

function Maybe#(Bit#(10)) mkPE1024(Bit#(1024) data);
   Vector#(4, Bit#(256)) data256b = unpack(data);
   Vector#(4, Maybe#(Bit#(8))) out256b;
   for(Integer i=0; i<4; i=i+1) begin
      out256b[i] = mkPE256(data256b[i]);
   end
   Vector#(4, Bool) vld256b = map(isValid, out256b);
   Maybe#(Bit#(2)) vldOut = mkPE4(pack(vld256b));
   Maybe#(Bit#(10)) ret;
   if (isValid(vldOut)) begin
      let validOut = fromMaybe(?, vldOut);
      let encodedOut = fromMaybe(?, out256b[validOut]);
      let out = {validOut, encodedOut};
      ret = tagged Valid out;
   end
   else begin
      ret = tagged Invalid;
   end
   return ret;
endfunction

function Maybe#(Bit#(5)) mkPE32(Bit#(32) data);
   Vector#(2, Bit#(16)) data16b = unpack(data);
   Vector#(2, Maybe#(Bit#(4))) out16b;
   for (Integer i=0; i<2; i=i+1) begin
      out16b[i] = mkPE16(data16b[i]);
   end
   Vector#(2, Bool) vld16b = map(isValid, out16b);
   Bool validOut = boolor(vld16b[1], vld16b[0]);
   let out = (vld16b[0]) ? {1'b0, fromMaybe(?, out16b[0])}
                         : {1'b1, fromMaybe(?, out16b[1])};
   let ret = (validOut) ? tagged Valid out : tagged Invalid;
   return ret;
endfunction

instance PEncoder#(2);
   module mkPEncoder(PE#(2));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(2)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(2) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(1))) get;
            reqfifo.deq;
            return mkPE2(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(4);
   module mkPEncoder(PE#(4));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(4)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(4) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(2))) get;
            reqfifo.deq;
            return mkPE4(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(8);
   module mkPEncoder(PE#(8));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(8)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(8) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(3))) get;
            reqfifo.deq;
            return mkPE8(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(16);
   module mkPEncoder(PE#(16));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(16)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(16) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(4))) get;
            reqfifo.deq;
            return mkPE16(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(32);
   module mkPEncoder(PE#(32));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(32)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(32) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(5))) get;
            reqfifo.deq;
            return mkPE32(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(64);
   module mkPEncoder(PE#(64));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(64)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(64) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(6))) get;
            reqfifo.deq;
            return mkPE64(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(256);
   module mkPEncoder(PE#(256));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(256)) input_wire <- mkReg(0);
      interface Put oht;
         method Action put(Bit#(256) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(8))) get;
            reqfifo.deq;
            return mkPE256(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(1024);
   module mkPEncoder(PE#(1024));
      FIFOF#(void) reqfifo <- mkFIFOF;
      Reg#(Bit#(1024)) input_wire <- mkReg(0);

      interface Put oht;
         method Action put(Bit#(1024) v);
            input_wire <= v;
            reqfifo.enq(?);
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(10))) get if (reqfifo.notEmpty);
            reqfifo.deq;
            return mkPE1024(input_wire);
         endmethod
      endinterface
   endmodule
endinstance

instance PEncoder#(n);
   module mkPEncoder(PE#(n));
      staticAssert(True, "PEncoder type not implemented");
      interface Put oht;
         method Action put(Bit#(n) v);
            // empty
         endmethod
      endinterface
      interface Get bin;
         method ActionValue#(Maybe#(Bit#(TLog#(n)))) get();
            return tagged Invalid;
         endmethod
      endinterface
   endmodule
endinstance
