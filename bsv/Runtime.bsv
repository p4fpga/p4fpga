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

import Vector::*;
import RxChannel::*;
import HostChannel::*;
import TxChannel::*;
import SharedBuff::*;
import PacketBuffer::*;

/*
   P4FPGA runtime consists of 5 types of channels and optional packet memory
   to acclerate packet re-entry
 */
interface Runtime#(numeric type nrx, numeric type ntx, numeric type nhs);
   interface Vector#(nrx, RxChannel) rxchan;
   interface Vector#(ntx, TxChannel) txchan;
   interface Vector#(nhs, HostChannel) hostchan;
   // TODO: reentryChannel and dropChannel
   method Action set_verbosity (Bit#(32) verbosity);
endinterface
module mkRuntime#(Clock rxClock, Reset rxReset, Clock txClock, Reset txReset)(Runtime#(nrx, ntx, nhs));
   Vector#(nhs, HostChannel) _hostchan <- replicateM(mkHostChannel());
   Vector#(nrx, RxChannel) _rxchan <- replicateM(mkRxChannel(rxClock, rxReset));
   Vector#(ntx, TxChannel) _txchan <- replicateM(mkTxChannel(txClock, txReset));

   // Optimization: Gearbox to 512 bit

   // Optimization: Optional Packet Memory
   // SharedBuff buff <- mkSharedBuff(); // vector of buffers, to improve throughput?
   // mkConnection(channels.readClients, buff.readServers);
   // mkConnection(channels.freeClients, buff.freeServers);
   // mkConnection(channels.writeClients, buff.writeServers);
   // mkConnection(channels.mallocClients, buff.mallocServers);

   //ConnectalMemory::MemServerIndication memServerInd;
   //SharedBuffer#(12, 128, 1) mem <- mkSharedBuffer(vec(_txchan[0].readClient),
   //                                    vec(_txchan[0].freeClient),
   //                                    vec(_hostchan[0].writeClient, _rxchan[0].writeClient),
   //                                    vec(_hostchan[0].mallocClient, _rxchan[0].mallocClient),
   //                                    memServerInd); //FIXME: clean up this indication

   interface rxchan = _rxchan;
   interface txchan = _txchan;
   interface hostchan = _hostchan;
   method Action set_verbosity (Bit#(32) verbosity);
      //_rxchan.set_verbosity(verbosity);
      _txchan[0].set_verbosity(unpack(verbosity));
      _hostchan[0].set_verbosity(unpack(verbosity));
   endmethod
endmodule
