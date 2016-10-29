import HostInterface::*;
import Clocks::*;
import Sims::*;
import Vector::*;
import GetPut::*;
import EthMac::*;
import Connectable::*;
import Stream::*;
import NfsumePins::*;
`include "ConnectalProjectConfig.bsv"

`ifdef BOARD_nfsume
import Xilinx10GE::*;
import XilinxEthPhy::*;
import XilinxMacWrap::*;
import EthMac::*;
`endif

interface Board;
   interface Clock txClock;
   interface Reset txReset;
   interface Clock rxClock;
   interface Reset rxReset;
`ifdef BOARD_nfsume
   interface Vector#(4, Put#(ByteStream#(8))) packet_tx;
   interface Vector#(4, Get#(ByteStream#(8))) packet_rx;
   interface `PinType pins;
`endif
endinterface

module mkBoard#(Clock hostClock)(Board);
  Clock defaultClock <- exposeCurrentClock();
  Reset defaultReset <- exposeCurrentReset();
  `ifdef BOARD_nfsume
  // platform
  Clock mgmtClock = hostClock;
  EthPhyIfc phys <- mkXilinxEthPhy(mgmtClock);
  Clock _txClock = phys.tx_clkout;
  Reset _txReset <- mkSyncReset(2, defaultReset, _txClock);
  Clock _rxClock = _txClock;
  Reset _rxReset = _txReset;
  Vector#(4, EthMacIfc) mac <- replicateM(mkEthMac(mgmtClock, _txClock, _txReset, clocked_by _txClock, reset_by _txReset));
  function Get#(XGMIIData) getTx(EthMacIfc _mac); return _mac.tx; endfunction
  function Put#(XGMIIData) getRx(EthMacIfc _mac); return _mac.rx; endfunction
  mapM(uncurry(mkConnection), zip(map(getTx, mac), phys.tx));
  mapM(uncurry(mkConnection), zip(phys.rx, map(getRx, mac)));
  NfsumeLeds leds <- mkNfsumeLeds(mgmtClock, _txClock);
  NfsumeSfpCtrl sfpctrl <- mkNfsumeSfpCtrl(phys);
  `endif

  `ifdef SIMULATION
  SimClocks clocks <- mkSimClocks();
  Clock _txClock = clocks.clock_156_25;
  Clock phyClock = clocks.clock_644_53;
  Clock mgmtClock = clocks.clock_50;
  Clock _rxClock = _txClock;
  Reset _txReset <- mkSyncReset(2, defaultReset, _txClock);
  Reset phyReset <- mkSyncReset(2, defaultReset, phyClock);
  Reset mgmtReset <- mkSyncReset(2, defaultReset, mgmtClock);
  Reset _rxReset = _txReset;
  `endif

  interface txClock = _txClock;
  interface txReset = _txReset;
  interface rxClock = _rxClock;
  interface rxReset = _rxReset;
`ifdef BOARD_nfsume
  interface packet_tx = map(getEthMacTx, mac);
  interface packet_rx = map(getEthMacRx, mac);
  interface pins = mkNfsumePins(defaultClock, phys, leds, sfpctrl);
`endif
endmodule

// add synthesis boundary to Board
(* synthesize *)
module mkBoardSynth#(Clock mgmtClock)(Board);
   (* hide *)
   Board _i <- mkBoard(mgmtClock);
   return _i;
endmodule
