import HostInterface::*;
import Clocks::*;
import Sims::*;

`include "ConnectalProjectConfig.bsv"
`ifdef BOARD_nfsume
import XilinxEthPhy::*;
import NfsumePins::*;
`endif

interface Board;
   interface Clock txClock;
   interface Reset txReset;
   interface Clock rxClock;
   interface Reset rxReset;
`ifdef BOARD_nfsume
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
