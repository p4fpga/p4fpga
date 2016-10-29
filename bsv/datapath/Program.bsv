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

import Library::*;
import ConnectalTypes::*;
import Control::*;
import SynthBuilder::*;
`include "SynthBuilder.defines"

`include "Debug.defines"
//`include "TieOff.defines"
//`TIEOFF_PIPEOUT("program ", MetadataRequest)

interface Program#(numeric type nrx, numeric type ntx, numeric type nhs, numeric type nextra);
   interface Vector#(TAdd#(TAdd#(nrx, nhs), nextra), PipeIn#(MetadataRequest)) prev;
   interface Vector#(TAdd#(TAdd#(nrx, nhs), nextra), PipeOut#(MetadataRequest)) next;
   method Action set_verbosity (int verbosity);
`include "APIDefGenerated.bsv" // for table api
endinterface

module mkProgram(Program#(nrx, ntx, nhs, nextra))
   provisos(Add#(b__, TLog#(TAdd#(TAdd#(nrx, nhs), nextra)), 9) // introduced by truncate
           ,Pipe::FunnelPipesPipelined#(1, TAdd#(TAdd#(nrx, nhs), nextra), StructDefines::MetadataRequest, 2)
           ,NumAlias#(TLog#(TAdd#(TAdd#(nrx, nhs), nextra)), wpi)
           ,NumAlias#(TAdd#(TAdd#(nrx, nhs), nextra), npi)
           );
   `PRINT_DEBUG_MSG

   // N-to-1 arbitration
   Vector#(npi, FIFOF#(MetadataRequest)) funnel_ff <- replicateM(mkFIFOF);
   function PipeIn#(MetadataRequest) metaPipeIn(Integer i);
      return toPipeIn(funnel_ff[i]);
   endfunction
   function PipeOut#(MetadataRequest) metaPipeOut(Integer i);
      return toPipeOut(funnel_ff[i]);
   endfunction
   FunnelPipe#(1, npi, MetadataRequest, 2) metaPipe <- mkFunnelPipesPipelined(genWith(metaPipeOut));

   Ingress ingress <- mkIngress();
   mkConnection(metaPipe[0], ingress.prev);

   Egress egress <- mkEgress();
   mkConnection(ingress.next, egress.prev);

   FIFOF#(Tuple2#(Bit#(wpi), MetadataRequest)) writeData <- mkFIFOF;
   UnFunnelPipe#(1, npi, MetadataRequest, 2) demux <- mkUnFunnelPipesPipelined(vec(toPipeOut(writeData)));
   messageM("unFunnel " + printType(typeOf(demux)));

   // use egress_port value to pick outgoing port
   // truncate egress_port to fit number of ports on board
   rule egress_demux;
      let v = egress.next.first;
      egress.next.deq;
      if (v.meta.standard_metadata.ingress_port matches tagged Valid .prt) begin
         let tpl = tuple2(truncate(prt), v);
         writeData.enq(tpl);
      end
      else begin
         dbprint(3, $format("invalid ingress_port"));
      end
   endrule

   interface prev = genWith(metaPipeIn);
   interface next = demux;
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
      ingress.set_verbosity(verbosity);
      egress.set_verbosity(verbosity);
   endmethod
`include "ProgDeclGenerated.bsv"
endmodule

`SynthBuildModule(mkProgram, Program#(4,4,1,2), mkProgram_4_4_1_2)
`SynthBuildModule(mkProgram, Program#(4,4,1,5), mkProgram_4_4_1_5)

