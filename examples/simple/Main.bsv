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
import Clocks::*;
import Connectable::*;
import GetPut::*;
import HostChannel::*;
import MainAPI::*;
import PacketBuffer::*;
import Simple::*;
import SharedBuff::*;
import Sims::*;
import TxChannel::*;

interface Main;
   interface MainRequest request;
endinterface

module mkMain#(MainIndication indication
              ,ConnectalMemory::MemServerIndication memServerInd
              )(Main);
   let verbose = True;
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

`ifdef SIMULATION
   SimClocks clocks <- mkSimClocks();
   Clock txClock = clocks.clock_156_25;
   Clock phyClock = clocks.clock_644_53;
   Clock mgmtClock = clocks.clock_50;
   Clock rxClock = txClock;
   Reset txReset <- mkSyncReset(2, defaultReset, txClock);
   Reset phyReset <- mkSyncReset(2, defaultReset, phyClock);
   Reset mgmtReset <- mkSyncReset(2, defaultReset, mgmtClock);
   Reset rxReset = txReset;
`endif

   HostChannel hostchan <- mkHostChannel();
   Ingress0 ingress <- mkIngress0(vec(hostchan.next));
   TxChannel txchan <- mkTxChannel(txClock, txReset);

   SharedBuffer#(12, 128, 1) mem <- mkSharedBuffer(vec(txchan.readClient)
                                                  ,vec(txchan.freeClient)
                                                  ,vec(hostchan.writeClient)
                                                  ,vec(hostchan.mallocClient)
                                                  ,memServerInd
                                                  );

   mkConnection(ingress.eventPktSend, txchan.eventPktSend);

`ifdef SIMULATION
   rule drain_mac;
      let v <- toGet(txchan.macTx).get;
      if (verbose) $display("(%0d) tx data ", $time, fshow(v));
   endrule
`endif

   MainAPI api <- mkMainAPI(indication, hostchan, ingress);
   interface request = api.request;
endmodule
