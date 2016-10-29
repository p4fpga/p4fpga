import Clocks::*;
import Vector::*;
import DefaultValue::*;

import XilinxCells::*;
import LedController::*;
import ConnectalClocks::*;
import ConnectalXilinxCells::*;

import XilinxEthPhy::*;
 `include "ConnectalProjectConfig.bsv"

(* always_ready, always_enabled *)
interface NfsumePins;
`ifdef BOARD_nfsume
   method Action sfp(Bit#(1) refclk_p, Bit#(1) refclk_n);
   method Bit#(2) leds;
   method Bit#(4) serial_tx_p;
   method Bit#(4) serial_tx_n;
   method Action serial_rx_p(Vector#(4, Bit#(1)) v);
   method Action serial_rx_n(Vector#(4, Bit#(1)) v);
   method Bit#(4) led_grn;
   method Bit#(4) led_ylw;
   interface NfsumeSfpCtrl sfpctrl;
   interface Clock deleteme_unused_clock;
`endif
endinterface

function NfsumePins mkNfsumePins(Clock defaultClock, EthPhyIfc phys, NfsumeLeds leds, NfsumeSfpCtrl sfpctrl) =
   interface NfsumePins;
`ifdef BOARD_nfsume
      method Action sfp(Bit#(1) refclk_p, Bit#(1) refclk_n);
         phys.refclk(refclk_p, refclk_n);
      endmethod
      method serial_tx_p = pack(phys.serial_tx_p);
      method serial_tx_n = pack(phys.serial_tx_n);
      method serial_rx_p = phys.serial_rx_p;
      method serial_rx_n = phys.serial_rx_n;
      interface leds = leds.led_out;
      interface led_grn = phys.tx_leds;
      interface led_ylw = phys.rx_leds;
      interface deleteme_unused_clock = defaultClock;
      interface sfpctrl = sfpctrl;
`endif
   endinterface;

interface NfsumeLeds;
   method Bit#(2) led_out;
endinterface

module mkNfsumeLeds#(Clock clk0, Clock clk1)(NfsumeLeds);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   Reset reset0 <- mkSyncReset(2, defaultReset, clk0);
   Reset reset1 <- mkSyncReset(2, defaultReset, clk1);

   LedController led0 <- mkLedController(False, clocked_by clk0, reset_by reset0);
   LedController led1 <- mkLedController(False, clocked_by clk1, reset_by reset1);

   rule led0_run;
      led0.setPeriod(led_off, 500, led_on_max, 500);
   endrule

   rule led1_run;
      led1.setPeriod(led_off, 500, led_on_max, 500);
   endrule

   method led_out = {
                     led1.ifc.out,
                     led0.ifc.out
                     };
endmodule

interface NfsumeSfpCtrl;
   method Action los (Vector#(4, Bit#(1)) v);
   method Action mod0_presnt_n (Vector#(4, Bit#(1)) v);
   method Action txfault (Vector#(4, Bit#(1)) v);
(* prefix="", result="ratesel0" *)   method Vector#(4, Bit#(1)) ratesel0;
(* prefix="", result="ratesel1" *)   method Vector#(4, Bit#(1)) ratesel1;
(* prefix="", result="txdisable" *)  method Vector#(4, Bit#(1)) txdisable;
endinterface

module mkNfsumeSfpCtrl#(EthPhyIfc phys)(NfsumeSfpCtrl);
   Vector#(4, Wire#(Bit#(1))) los_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) mod0_presnt_n_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) txfault_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) ratesel0_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) ratesel1_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) txdisable_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) signal_detect_wire <- replicateM(mkDWire(0));

   for (Integer i=0; i<4; i=i+1) begin
      rule set_output;
         ratesel0_wire[i] <= 1'b1;
         ratesel1_wire[i] <= 1'b1;
         txdisable_wire[i] <= 1'b0;
      endrule

      rule set_sd;
         signal_detect_wire[i] <= (~los_wire[i]) & (~mod0_presnt_n_wire[i]);
      endrule
   end

   rule conn_sd;
      phys.signal_detect(readVReg(signal_detect_wire));
   endrule

   rule conn_txfault;
      phys.tx_fault(readVReg(txfault_wire));
   endrule

   method los = writeVReg(los_wire);
   method mod0_presnt_n = writeVReg(mod0_presnt_n_wire);
   method txfault = writeVReg(txfault_wire);
   method ratesel0 = readVReg(ratesel0_wire);
   method ratesel1 = readVReg(ratesel1_wire);
   method txdisable = readVReg(txdisable_wire);
endmodule

