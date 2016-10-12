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
import BRAM::*;
import ClientServer::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Pipe::*;
import RegFile::*;
import Vector::*;
import DefaultValue::*;
import ConnectalBram::*;
`include "ConnectalProjectConfig.bsv"

`ifdef CONNECTAL_TYPE
import ConnectalTypes::*;
`else
typedef struct {
   Bit#(addrSz) addr;
   Bit#(dataSz) data;
   Bool write;
} RegRequest#(numeric type addrSz, numeric type dataSz) deriving (Bits, Eq);

typedef struct {
   Bit#(dataSz) data;
} RegResponse#(numeric type dataSz) deriving (Bits, Eq);
`endif

interface RegisterIfc#(numeric type asz, numeric type dsz);
endinterface

module mkP4Register#(Vector#(numClients, Client#(RegRequest#(asz, dsz), RegResponse#(dsz))) clients)(RegisterIfc#(asz, dsz));
   let verbose = True;
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 2;
   BRAM2Port#(Bit#(asz), Bit#(dsz)) regFile <- ConnectalBram::mkBRAM2Server(bramConfig);
   FIFO#(RegRequest#(asz, dsz)) inReqFifo <- mkFIFO;
   FIFOF#(Bit#(TAdd#(1, TLog#(numClients)))) client <- mkFIFOF;
   FIFO#(RegResponse#(dsz)) outRespFifo <- mkFIFO;

   rule processReq;
      RegRequest#(asz, dsz) req <- toGet(inReqFifo).get;
      if (req.write) begin
         regFile.portA.request.put(BRAMRequest{write: True, responseOnWrite: False,
            address: req.addr, datain: req.data});
         if (verbose) $display("(%0d) Reg: write addr=%h data=%h", $time, req.addr, req.data);
      end
      else begin
         regFile.portB.request.put(BRAMRequest{write: False, responseOnWrite: False,
            address: req.addr, datain: ?});
         if (verbose) $display("(%0d) Reg: read addr=%h", $time, req.addr);
      end
   endrule

   rule processResp;
      let data <- regFile.portB.response.get;
      let resp = RegResponse {data: data};
      outRespFifo.enq(resp);
   endrule

   Rules rs = emptyRules;
   for (Integer selectClient=0; selectClient < valueOf(numClients); selectClient = selectClient + 1) begin
      Rules r =
         rules
            rule loadRequest;
               let req <- clients[selectClient].request.get;
               if (!req.write) begin
                  client.enq(fromInteger(selectClient));
               end
               inReqFifo.enq(req);
            endrule
         endrules;
      rs = rJoinDescendingUrgency(rs, r);
      rule sendResp if (client.first == fromInteger(selectClient));
         let resp <- toGet(outRespFifo).get;
         clients[selectClient].response.put(resp);
         client.deq;
      endrule
   end
   addRules(rs);
endmodule
