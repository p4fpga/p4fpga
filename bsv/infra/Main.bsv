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
import Vector::*;
import HostInterface::*;
import MainAPI::*;
import DbgDefs::*;
import Sims::*;
import TieOff::*;
import PktGenChannel::*;
import PktCapChannel::*;
import TxChannel::*;
import RxChannel::*;
import HostChannel::*;
import StreamChannel::*;
import MetaGenChannel::*;
import PktGen::*;
import Board::*;
import Runtime::*;
import Program::*;
import Pipe::*;
import Channel::*;
import Stream::*;
import StructDefines::*;
import ConnectalTypes::*;
import NfsumePins::*;
`include "ConnectalProjectConfig.bsv"
`ifdef BOARD_nfsume
import Xilinx10GE::*;
import XilinxMacWrap::*;
import XilinxEthPhy::*;
import EthMac::*;
`endif
interface Main;
  interface MainRequest request;
  interface `PinType pins;
endinterface
module mkMain #(HostInterface host, MainIndication indication, ConnectalMemory::MemServerIndication memServerInd) (Main)
  provisos(NumAlias#(pktgen_offset, TAdd#(`NUM_RXCHAN, `NUM_HOSTCHAN))
          ,NumAlias#(metagen_offset, TAdd#(TAdd#(`NUM_RXCHAN, `NUM_HOSTCHAN), `NUM_PKTGEN))
          ,NumAlias#(naux, TAdd#(`NUM_PKTGEN, `NUM_METAGEN)));
  let verbose = True;
  Clock defaultClock <- exposeCurrentClock();
  Reset defaultReset <- exposeCurrentReset();

  Board board <- mkBoardSynth(host.tsys_clk_200mhz_buf);
  Clock txClock = board.txClock;
  Reset txReset = board.txReset;
  Clock rxClock = board.rxClock;
  Reset rxReset = board.rxReset;

  Runtime#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN) runtime <- mkRuntime_4_4_1(rxClock, rxReset, txClock, txReset);
  Program#(`NUM_RXCHAN, `NUM_TXCHAN, `NUM_HOSTCHAN, naux) prog <- mkProgram_4_4_1_5();

  // Port 0 is HostChan
  for (Integer i=0; i<`NUM_HOSTCHAN; i=i+1) begin
    mkConnection(runtime.hostchan[i].next, prog.prev[i]);
  end

  // Port 1-4 is RxChan
  for (Integer i=0; i<`NUM_RXCHAN; i=i+1) begin
    messageM("program " + printType(typeOf(prog.prev)) + " " + "runtime " + printType(typeOf(runtime.rxchan)));
    mkConnection(runtime.rxchan[i].next, prog.prev[i+`NUM_HOSTCHAN]);
  end

  // Port 5-8 is PktGen
  messageM("Generating pktgen/pktcap channels.");
  Vector#(4, PktGenChannel) pktgen <- genWithM(mkPktGenChannel(txClock, txReset));

  PktCapChannel pktcap <- mkPktCapChannel(rxClock, rxReset);

  // LOOPBACK
  Vector#(4, SyncFIFOIfc#(ByteStream#(8))) lpbk_ff <- replicateM(mkSyncFIFO(16, txClock, txReset, rxClock));
  mapM_(uncurry(mkConnection), zip(map(getMacTx, pktgen), map(toPut, lpbk_ff)));
  mapM_(uncurry(mkConnection), zip(map(toGet, lpbk_ff), map(getMacRx, runtime.rxchan)));

  // Port 6 is MetaGen
  // Generate parsed packet metadata to test p4 pipeline throughput
  MetaGenChannel metagen <- mkMetaGenChannel(valueOf(metagen_offset));
  mkConnection(metagen.next, prog.prev[valueOf(metagen_offset)]);

  // return processed metadata to runtime
  for (Integer i=0; i<`NUM_HOSTCHAN+`NUM_RXCHAN; i=i+1) begin
    mkConnection(prog.next[i], runtime.prev[i]);
  end

`ifdef SIMULATION
  mapM_(mkTieOff, map(getMacTx, runtime.txchan));
  //mapM_(mkTieOff, prog.next);
  mkTieOff(prog.next[valueOf(metagen_offset)]);
  //mkConnection(pktgen.macTx, runtime.rxchan[0].macRx);
`endif

  MainAPI api <- mkMainAPI(indication, runtime, prog, pktgen, pktcap, metagen);
  interface request = api.request;
`ifdef BOARD_nfsume
  interface pins = board.pins;
`endif
endmodule
