// Copyright (c) 2016 P4FPGA Project

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
import HostInterface::*;
import MainAPI::*;
import Sims::*;
import TieOff::*;
import PktGenChannel::*;
import PktCapChannel::*;
import TxChannel::*;
import RxChannel::*;
import HostChannel::*;
import StreamChannel::*;
import PktGen::*;
import Board::*;
import Runtime::*;
import Program::*;
`include "ConnectalProjectConfig.bsv"

interface Main;
  interface MainRequest request;
  interface `PinType pins;
endinterface
module mkMain #(HostInterface host, MainIndication indication, ConnectalMemory::MemServerIndication memServerInd) (Main);
  let verbose = True;
  Clock defaultClock <- exposeCurrentClock();
  Reset defaultReset <- exposeCurrentReset();

  Board board <- mkBoardSynth(host.tsys_clk_200mhz_buf);
  Clock txClock = board.txClock;
  Reset txReset = board.txReset;
  Clock rxClock = board.rxClock;
  Reset rxReset = board.rxReset;

  Runtime#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN) runtime <- mkRuntime(rxClock, rxReset, txClock, txReset);
  Program#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN) prog <- mkProgram();

  for (Integer i=0; i<`NUM_HOSTCHAN; i=i+1) begin
    mkConnection(runtime.hostchan[i].next, prog.prev[i]);
  end

  PktGenChannel pktgen <- mkPktGenChannel(txClock, txReset);
  PktCapChannel pktcap <- mkPktCapChannel(rxClock, rxReset);
  //mkConnection(egress.next, runtime.txchan[0].prev); // insert demux, metadata fifo

`ifdef SIMULATION
  mkTieOff(runtime.txchan[0].macTx);
  //mkConnection(pktgen.macTx, runtime.rxchan[0].macRx);
`endif

  MainAPI api <- mkMainAPI(indication, runtime, prog, pktgen, pktcap);
  interface request = api.request;
`ifdef BOARD_nfsume
  interface pins = board.pins;
`endif
endmodule
