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

import Connectable::*;
import ClientServer::*;
import DbgTypes::*;
import DbgDefs::*;
import Ethernet::*;
import EthMac::*;
import GetPut::*;
import FIFO::*;
import MemMgmt::*;
import MemTypes::*;
import PacketBuffer::*;
import Pipe::*;
import StoreAndForward::*;
import SharedBuff::*;
import Stream::*;
import Tap::*;
import HostChannel::*;
`include "ConnectalProjectConfig.bsv"
import `PARSER::*;
import `TYPEDEF::*;

interface RxChannel;
   interface Put#(ByteStream#(8)) macRx;
   interface MemWriteClient#(`DataBusWidth) writeClient;
   interface MemAllocClient mallocClient;
   interface PipeOut#(MetadataRequest) next;
   method HostChannelDbgRec read_debug_info;
   method ParserPerfRec read_parser_perf_info;
endinterface

module mkRxChannel#(Clock rxClock, Reset rxReset)(RxChannel);
   let verbose = True;
   HostChannel host <- mkHostChannel();
   StoreAndFwdFromMacToRing macToRing <- mkStoreAndFwdFromMacToRing(rxClock, rxReset);
   mkConnection(macToRing.writeClient, host.writeServer);
   interface macRx = macToRing.macRx;
   interface writeClient = host.writeClient;
   interface next = host.next;
   interface mallocClient = host.mallocClient;
   method read_debug_info = host.read_debug_info;
   method read_parser_perf_info = host.read_parser_perf_info;
endmodule
