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
 Packet Processing Engine

 - Actions are implemented in different ways: DSP, local operator
 - 
 */

interface Engine#(type metaI, type actI);
   interface Server#(actI, metaI) prev_control_state;
   method Action set_verbosity(int verbosity);
endinterface

module mkEngine#(Engine#(metaI, actI));
   `PRINT_DEBUG_MSG
   RX #(actI) meta_in<- mkRX;
   TX #(metaI) meta_out<- mkTX;

   // Optimization: Use DSP
   // DSP48E1
   rule rl_read;
      // read_meta;
      // pipe_ff.enq();
   endrule

   rule rl_modify;
      // pipe_ff.deq;
      // operation -> dsp?
      // pipe_ff.enq;
   endrule

   // rule rl_dsp;

   rule rl_write;
      // meta_in from pipeline register
      // metaI meta_out = meta_in;
      // field modification
      // let m = modify_field(meta_in, nhop_ipv4, _port);
      // meta_out.u.enq(metaI);
   endrule
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
