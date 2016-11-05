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
import PktGenMainAPI::*;
import DbgDefs::*;
import Sims::*;
import TieOff::*;
import PktGenChannel::*;
import PktCapChannel::*;
import PktGen::*;
import Board::*;
import Channel::*;
//`ifdef BOARD_nfsume
import Xilinx10GE::*;
import XilinxMacWrap::*;
import XilinxEthPhy::*;
import NfsumePins::*;
import EthMac::*;
//`endif

`include "ConnectalProjectConfig.bsv"

interface PktGenMain;
  interface MainRequest request;
  interface `PinType pins;
endinterface
module mkPktGenMain #(HostInterface host, MainIndication indication) (PktGenMain);
  let verbose = True;
  Clock defaultClock <- exposeCurrentClock();
  Reset defaultReset <- exposeCurrentReset();

  Board board <- mkBoardSynth(host.tsys_clk_200mhz_buf);
  Clock txClock = board.txClock;
  Reset txReset = board.txReset;
  Clock rxClock = board.rxClock;
  Reset rxReset = board.rxReset;

  messageM("Generating pktgen/pktcap channels.");
  Vector#(4, PktGenChannel) pktgen <- genWithM(mkPktGenChannel(txClock, txReset));
  Vector#(4, PktCapChannel) pktcap <- replicateM(mkPktCapChannel(rxClock, rxReset));

`ifdef BOARD_nfsume
  mapM_(uncurry(mkConnection), zip(map(getMacTx, pktgen), board.packet_tx));
  mapM_(uncurry(mkConnection), zip(board.packet_rx, map(getMacRx, pktcap)));
`endif

`ifdef SIMULATION
   mkConnection(pktgen[1].macTx, pktcap[0].macRx);
`endif

  MainAPI api <- mkMainAPI(indication, pktgen, pktcap);
  interface request = api.request;
`ifdef BOARD_nfsume
  interface pins = board.pins;
`endif
endmodule
