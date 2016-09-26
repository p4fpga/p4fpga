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
import ClientServer::*;
import Control::*;
import GetPut::*;
import FIFOF::*;
import Vector::*;
import Ethernet::*;
import Pipe::*;
import StructDefines::*;
import UnionDefines::*;
import Control::*;
import ConnectalTypes::*;

interface Program#(numeric type nrx, numeric type ntx, numeric type nhs);
   interface Vector#(nrx, PipeIn#(MetadataRequest)) prev;
   interface Vector#(ntx, PipeOut#(MetadataRequest)) next;
   method Action set_verbosity (int verbosity);
`include "APIDefGenerated.bsv"
endinterface

// mkConnection(rxchan.next, arbiter.prev[1]);

module mkProgram(Program#(nrx, ntx, nhs))
   provisos(Pipe::FunnelPipesPipelined#(1, nrx, StructDefines::MetadataRequest, 2));
   // N-to-1 RR Arbitration
   Vector#(nrx, FIFOF#(MetadataRequest)) funnel_ff <- replicateM(mkFIFOF);
   function PipeIn#(MetadataRequest) metaPipeIn(Integer i);
      return toPipeIn(funnel_ff[i]);
   endfunction
   function PipeOut#(MetadataRequest) metaPipeOut(Integer i);
      return toPipeOut(funnel_ff[i]);
   endfunction
   FunnelPipe#(1, nrx, MetadataRequest, 2) funnel <- mkFunnelPipesPipelined(genWith(metaPipeOut));


   // Ingress ingress <- mkIngress();
   // Egress egress <- mkEgress();
   // mkConnection(arbiter.next, ingress.prev);
   // mkConnection(ingress.next, egress.prev);
   // mkConnection(egress.next, demux.prev);

   // 1-to-N unfunnel
   // Demux#(2) <- mkDemux();

   interface prev = genWith(metaPipeIn);
   // interface next = demux.next;?
   method Action set_verbosity (int verbosity);
      //ingress.set_verbosity(verbosity);
      //egress.set_verbosity(verbosity);
   endmethod
endmodule
