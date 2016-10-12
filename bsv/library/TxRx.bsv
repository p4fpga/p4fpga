// Copyright (c) 2016 Cornell University

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

import GetPut::*;
import ClientServer::*;
import Connectable::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Pipe::*;

interface TX #(type t);
   interface PipeIn#(t) u;
   interface PipeOut#(t) e;
endinterface

module mkTX (TX #(t))
   provisos (Bits#(t, tsz));
   (*hide*) FIFOF#(t) _ifc <- mkBypassFIFOF;
   interface PipeIn u = toPipeIn(_ifc);
   interface PipeOut e = toPipeOut(_ifc);
endmodule

interface RX #(type t);
   interface PipeOut#(t) u;
   interface PipeIn#(t) e;
endinterface

module mkRX (RX #(t))
   provisos (Bits#(t, tsz));
   (* hide *) FIFOF#(t) _ifc <- mkBypassFIFOF;
   interface PipeOut u = toPipeOut(_ifc);
   interface PipeIn e = toPipeIn(_ifc);
endmodule

//module mkChan #(module #(FIFOF #(t)) mkFIFOF,
//                PipeOut #(t) txe,
//                PipeIn #(t) rxe)(Empty);
//   let fifof <- mkFIFOF;
//   let txe_to_fifof <- mkConnection(txe, toPipeIn(fifof));
//   let fifof_to_rxe <- mkConnection(toPipeOut(fifof), rxe);
//endmodule

module mkChan #(module #(FIFOF #(req)) mkFIFOF_req,
                module #(FIFOF #(rsp)) mkFIFOF_rsp,
               Client #(req, rsp) txe,
               Server #(req, rsp) rxe)(Empty);
   let fifof_req <- mkFIFOF_req;
   let fifof_rsp <- mkFIFOF_rsp;
   let txe_to_fifof <- mkConnection(txe.request, toPut(fifof_req));
   let fifof_to_rxe <- mkConnection(toGet(fifof_req), rxe.request);
   let rxe_to_fifof <- mkConnection(rxe.response, toPut(fifof_rsp));
   let fifof_to_txe <- mkConnection(toGet(fifof_rsp), txe.response);
endmodule
