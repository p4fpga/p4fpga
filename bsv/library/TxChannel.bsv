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
import Channel::*;
import MemMgmt::*;
import MemTypes::*;
import StoreAndForward::*;
import SharedBuff::*;
import HeaderSerializer::*;
import Channel::*;
`include "ConnectalProjectConfig.bsv"
import `DEPARSER::*;
import `TYPEDEF::*;
`include "Debug.defines"

// FIXME:
interface TxChannel;
   interface PipeIn#(ByteStream#(16)) writeServer;
   interface Get#(ByteStream#(8)) macTx;
   interface PipeIn#(int) verbose;
endinterface

instance GetMacTx#(TxChannel);
   function Get#(ByteStream#(8)) getMacTx(TxChannel chan);
      return chan.macTx;
   endfunction
endinstance

instance GetWriteServer#(TxChannel);
   function Put#(ByteStream#(16)) getWriteServer(TxChannel chan);
      return toPut(chan.writeServer);
   endfunction
endinstance

instance SetVerbosity#(TxChannel);
   function Action set_verbosity(TxChannel t, int verbosity);
      action
         t.verbose.enq(verbosity);
      endaction
   endfunction
endinstance

// Tx Channel
module mkTxChannel#(Clock txClock, Reset txReset)(TxChannel);
   `PRINT_DEBUG_MSG
   FIFOF#(int) verbose_ff <- mkFIFOF;
   PacketBuffer#(16) pktBuff <- mkPacketBuffer("txchan");
   StoreAndFwdFromRingToMac ringToMac <- mkStoreAndFwdFromRingToMac(txClock, txReset);
   mkConnection(ringToMac.readClient, pktBuff.readServer);

   interface writeServer = pktBuff.writeServer;
   interface macTx = ringToMac.macTx;
   interface verbose = toPipeIn(verbose_ff);
endmodule


