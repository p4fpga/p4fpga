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
import Connectable::*;
import DefaultValue::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import Pipe::*;
import GetPut::*;
import SpecialFIFOs::*;
import Stream::*;
import Vector::*;
import PacketBuffer::*;
import Ethernet::*;

interface TapPktRead;
   interface PktReadClient#(16) readClient;
   interface PktReadServer#(16) readServer;
   interface Get#(ByteStream#(16)) tap_out;
endinterface

module mkTapPktRead(TapPktRead);
   FIFO#(ByteStream#(16)) readDataFifoIn <- mkFIFO;
   FIFO#(ByteStream#(16)) readDataFifoOut <- mkBypassFIFO;
   FIFO#(ByteStream#(16)) readDataFifoTap <- mkBypassFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkBypassFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkBypassFIFO;

   rule tapIntoReadData;
      let v <- toGet(readDataFifoIn).get;
      readDataFifoOut.enq(v);
      readDataFifoTap.enq(v);
   endrule

   interface PktReadClient readClient;
      interface Put readData = toPut(readDataFifoIn);
      interface Put readLen = toPut(readLenFifo);
      interface Get readReq = toGet(readReqFifo);
   endinterface
   interface PktReadServer readServer;
      interface Get readData = toGet(readDataFifoOut);
      interface Get readLen = toGet(readLenFifo);
      interface Put readReq = toPut(readReqFifo);
   endinterface
   interface Get tap_out = toGet(readDataFifoTap);
endmodule
