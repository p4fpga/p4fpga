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
import Connectable::*;
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
import Stream::*;
import TieOff::*;

`include "TieOff.defines"
`TIEOFF_PIPEOUT("program ", MetadataRequest)

interface Program#(numeric type nrx, numeric type ntx, numeric type nhs);
   interface Vector#(nrx, PipeIn#(MetadataRequest)) prev;
   interface Vector#(ntx, PipeOut#(MetadataRequest)) next;
   method Action set_verbosity (int verbosity);
`include "APIDefGenerated.bsv"
endinterface

module mkProgram(Program#(nrx, ntx, nhs))
   provisos(Pipe::FunnelPipesPipelined#(1, nrx, StructDefines::MetadataRequest, 2)
           ,Add#(b__, TLog#(TAdd#(TAdd#(nrx, ntx), nhs)), 9)
           ,Pipe::FunnelPipesPipelined#(1, TAdd#(TAdd#(nrx, ntx), nhs), StructDefines::MetadataRequest, 2)
           ,NumAlias#(TLog#(TAdd#(TAdd#(nrx, ntx), nhs)), wport)
           ,NumAlias#(TAdd#(TAdd#(nrx, ntx), nhs), nport));
   // N-to-1 arbitration
   Vector#(nrx, FIFOF#(MetadataRequest)) funnel_ff <- replicateM(mkFIFOF);
   function PipeIn#(MetadataRequest) metaPipeIn(Integer i);
      return toPipeIn(funnel_ff[i]);
   endfunction
   function PipeOut#(MetadataRequest) metaPipeOut(Integer i);
      return toPipeOut(funnel_ff[i]);
   endfunction
   FunnelPipe#(1, nrx, MetadataRequest, 2) metaPipe <- mkFunnelPipesPipelined(genWith(metaPipeOut));

   Ingress ingress <- mkIngress();
   mkConnection(metaPipe[0], ingress.prev);

   Egress egress <- mkEgress();
   mkConnection(ingress.next, egress.prev);

   FIFOF#(Tuple2#(Bit#(wport), MetadataRequest)) writeData <- mkFIFOF;
   UnFunnelPipe#(1, nport, MetadataRequest, 2) demux <- mkUnFunnelPipesPipelined(vec(toPipeOut(writeData)));
   mapM_(mkTieOff, demux);

   // use egress_port as tag to select outgoing port
   rule egress_demux;
      let v = egress.next.first;
      egress.next.deq;
      if (v.meta.egress_port matches tagged Valid .prt) begin
         let tpl = tuple2(truncate(prt), v);
         writeData.enq(tpl);
         $display("type of port ", printType(typeOf(writeData)));
      end
   endrule

   interface prev = genWith(metaPipeIn);
   // interface next = demux.next;?
   method Action set_verbosity (int verbosity);
      ingress.set_verbosity(verbosity);
      egress.set_verbosity(verbosity);
   endmethod
endmodule

