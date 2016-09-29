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

/*
  Multi-cycle Action Engine

 - Actions are implemented in different ways: DSP, local operator

 */
import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import FShow::*;
import GetPut::*;
import Pipe::*;
import TxRx::*;
import Utils::*;

`include "Debug.defines"

interface Engine#(numeric type depth, type metaI, type actI);
   interface Server#(Tuple2#(metaI, actI), metaI) prev_control_state;
   method Action set_verbosity(int verbosity);
endinterface
module mkEngine#(List#(function ActionValue#(metaI) func(metaI meta, actI param)) proc)(Engine#(depth, metaI, actI))
   provisos(Bits#(metaI, a__)
           ,Bits#(actI, b__)
           ,Add#(depth, 0, dep)
           ,FShow#(actI)
           ,FShow#(metaI));

   `PRINT_DEBUG_MSG
   RX #(Tuple2#(metaI, actI)) meta_in<- mkRX;
   TX #(metaI) meta_out<- mkTX;
   Vector#(dep, FIFOF#(Tuple2#(metaI, actI))) meta_ff <- replicateM(mkFIFOF);

   // Optimization: Use DSP
   // DSP48E1
   rule rl_read;
      let v = meta_in.u.first;
      meta_in.u.deq;
      dbprint(3, fshow(tpl_1(v)));
      meta_ff[0].enq(v);
   endrule

   // List of functions, each acts on packet, but performed in different cycles
   for (Integer i = 0; i < valueOf(dep); i = i+1) begin
      rule rl_modify;
         let v <- toGet(meta_ff[i]).get;
         let meta = tpl_1(v);
         let param = tpl_2(v);
         let updated_metadata <- proc[i](meta, param);
         // TODO: extern
         if (i < valueOf(dep) - 1) begin
            meta_ff[i+1].enq(tuple2(updated_metadata, param));
            messageM("next proc " + integerToString(i));
         end
         else begin
            meta_out.u.enq(updated_metadata);
            messageM("exit " + integerToString(i));
         end
      endrule
   end
   interface prev_control_state = toServer(meta_in.e, meta_out.e);
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
