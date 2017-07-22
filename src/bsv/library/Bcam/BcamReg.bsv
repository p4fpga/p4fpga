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
import Arith::*;
import BRAM::*;
import BRAMCore::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import OInt::*;
import StmtFSM::*;
import Vector::*;
import Pipe::*;
import BcamTypes::*;
import PriorityEncoder::*;

// camDepth = 256
// pattWidth = 16
// camSz = 8
module mkBinaryCamReg(BinaryCam#(camDepth, pattWidth))
   provisos(Log#(camDepth, camSz)
           ,PriorityEncoder::PEncoder#(camDepth));
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   let verbose = True;
   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule every1 if (verbose);
      cycle <= cycle + 1;
   endrule

   FIFO#(Maybe#(Bit#(camSz))) readFifo <- mkFIFO;
   Vector#(camDepth, Reg#(Maybe#(Bit#(pattWidth)))) data <- replicateM(mkReg(tagged Invalid));
   PE#(camDepth) pe_bcam <- mkPEncoder();

   rule pe_bcam_out;
      let bin <- pe_bcam.bin.get;
      if (verbose) $display("indc pe_bcam %d: bin=", cycle, fshow(bin));
      readFifo.enq(bin);
   endrule

   interface Server readServer;
      interface Put request;
         method Action put(Bit#(pattWidth) v);
            Bit#(camDepth) indc = minBound;
            for (Integer i=0; i<valueOf(camDepth); i=i+1) begin
               indc[i] = pack(isValid(data[i]) && (v == fromMaybe(0, data[i])));
            end
            pe_bcam.oht.put(indc);
            if (verbose) $display("bcam %d: indc=%h", cycle, indc);
         endmethod
      endinterface
      interface Get response = toGet(readFifo);
   endinterface
   interface Put writeServer;
      method Action put(BcamWriteReq#(Bit#(camSz), Bit#(pattWidth)) v);
         data[v.addr] <= tagged Valid v.data;
      endmethod
   endinterface
endmodule
