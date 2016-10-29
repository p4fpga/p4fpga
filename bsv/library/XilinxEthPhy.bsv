
// Copyright (c) 2015 Cornell University.

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

package XilinxEthPhy;

import Clocks::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Connectable::*;
import GetPut::*;
import Pipe::*;
import Xilinx10GE::*;
import XilinxPhyWrap::*; 

(*always_ready, always_enabled*)
interface EthPhyIfc;
   interface Vector#(4, Put#(XGMIIData)) tx;
   interface Vector#(4, Get#(XGMIIData)) rx;
   method Vector#(4, Bit#(1)) serial_tx_p;
   method Vector#(4, Bit#(1)) serial_tx_n;
   method Action serial_rx_p(Vector#(4, Bit#(1)) v);
   method Action serial_rx_n(Vector#(4, Bit#(1)) v);
   interface Clock tx_clkout;
   method Action refclk(Bit#(1) p, Bit#(1) n);
   method Action signal_detect (Vector#(4, Bit#(1)) v);
   method Action tx_fault (Vector#(4, Bit#(1)) v);
   method Bit#(4) tx_leds;
   method Bit#(4) rx_leds;
endinterface

module mkXilinxEthPhy#(Clock mgmtClock)(EthPhyIfc);
   Clock defaultClock <- exposeCurrentClock;
   Reset defaultReset <- exposeCurrentReset;

   PhyWrapShared phy0 <- mkPhyWrapShared(mgmtClock);
   Clock clk_156_25 = phy0.coreclk;
   Vector#(4, FIFOF#(XGMIIData)) txFifo <- replicateM(mkUGFIFOF(clocked_by clk_156_25, reset_by noReset));
   Vector#(4, FIFOF#(XGMIIData)) rxFifo <- replicateM(mkUGFIFOF(clocked_by clk_156_25, reset_by noReset));
   Wire#(Bit#(1)) qplllock_w <- mkDWire(0);
   Wire#(Bit#(1)) qplloutclk_w <- mkDWire(0);
   Wire#(Bit#(1)) qplloutrefclk_w <- mkDWire(0);
   Wire#(Bit#(1)) txusrclk_w <- mkDWire(0);
   Wire#(Bit#(1)) txusrclk2_w <- mkDWire(0);
   Wire#(Bit#(1)) txuserrdy_w <- mkDWire(0);
   Wire#(Bit#(1)) gtrxreset_w <- mkDWire(0);
   Wire#(Bit#(1)) gttxreset_w <- mkDWire(0);
   Wire#(Bit#(1)) reset_counter_done_w <- mkDWire(0);

   Vector#(4, Wire#(Bit#(1))) signal_detect_wire <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) tx_fault_wire <- replicateM(mkDWire(0));

   Reset invertedReset <- mkResetInverter(defaultReset, clocked_by defaultClock);
   PhyWrapNonShared phy1 <- mkPhyWrapNonShared(clk_156_25, mgmtClock, invertedReset, invertedReset);
   PhyWrapNonShared phy2 <- mkPhyWrapNonShared(clk_156_25, mgmtClock, invertedReset, invertedReset);
   PhyWrapNonShared phy3 <- mkPhyWrapNonShared(clk_156_25, mgmtClock, invertedReset, invertedReset);

   rule phy0_qplllock;
      qplllock_w <= phy0.qplllock_out();
   endrule

   rule phyx_qplllock;
      phy1.qplllock(qplllock_w);
      phy2.qplllock(qplllock_w);
      phy3.qplllock(qplllock_w);
   endrule

   rule phy0_qplloutclk;
      qplloutclk_w <= phy0.qplloutclk_out();
   endrule

   rule phyx_qplloutclk;
      phy1.qplloutclk(qplloutclk_w);
      phy2.qplloutclk(qplloutclk_w);
      phy3.qplloutclk(qplloutclk_w);
   endrule

   rule phy0_qplloutrefclk;
      qplloutrefclk_w <= phy0.qplloutrefclk_out();
   endrule

   rule phyx_qplloutrefclk;
      phy1.qplloutrefclk(qplloutrefclk_w);
      phy2.qplloutrefclk(qplloutrefclk_w);
      phy3.qplloutrefclk(qplloutrefclk_w);
   endrule

   rule phy0_txusrclk;
      txusrclk_w <= phy0.txusrclk_out();
   endrule

   rule phyx_txusrclk;
      phy1.txusrclk(txusrclk_w);
      phy2.txusrclk(txusrclk_w);
      phy3.txusrclk(txusrclk_w);
   endrule

   rule phy0_txusrclk2;
      txusrclk2_w <= phy0.txusrclk2_out();
   endrule

   rule phyx_txusrclk2;
      phy1.txusrclk2(txusrclk2_w);
      phy2.txusrclk2(txusrclk2_w);
      phy3.txusrclk2(txusrclk2_w);
   endrule

   rule phy0_txuserrdy;
      txuserrdy_w <= phy0.txuserrdy_out();
   endrule

   rule phyx_txuserrdy;
      phy1.txuserrdy(txuserrdy_w);
      phy2.txuserrdy(txuserrdy_w);
      phy3.txuserrdy(txuserrdy_w);
   endrule

   rule phy0_gtrxreset;
      gtrxreset_w <= phy0.gtrxreset_out();
   endrule

   rule phyx_gtrxreset;
      phy1.gtrxreset(gtrxreset_w);
      phy2.gtrxreset(gtrxreset_w);
      phy3.gtrxreset(gtrxreset_w);
   endrule

   rule phy0_gttxreset;
      gttxreset_w <= phy0.gttxreset_out();
   endrule

   rule phyx_gttxreset;
      phy1.gttxreset(gttxreset_w);
      phy2.gttxreset(gttxreset_w);
      phy3.gttxreset(gttxreset_w);
   endrule

   rule phy0_reset_counter_done;
      reset_counter_done_w <= phy0.reset_counter_done_out();
   endrule

   rule phyx_reset_counter_done;
      phy1.reset_counter_done(reset_counter_done_w);
      phy2.reset_counter_done(reset_counter_done_w);
      phy3.reset_counter_done(reset_counter_done_w);
   endrule

   for (Integer i=0; i<4; i=i+1) begin
      txFifo[i] <- mkUGFIFOF(clocked_by clk_156_25, reset_by noReset);
      rule tx_mac;
         let v <- toGet(txFifo[i]).get;
         case (i)
            0: begin
               phy0.xgmii.txd(v.data);
               phy0.xgmii.txc(v.ctrl);
            end
            1: begin
               phy1.xgmii.txd(v.data);
               phy1.xgmii.txc(v.ctrl);
            end
            2: begin
               phy2.xgmii.txd(v.data);
               phy2.xgmii.txc(v.ctrl);
            end
            3: begin
               phy3.xgmii.txd(v.data);
               phy3.xgmii.txc(v.ctrl);
            end
         endcase
      endrule
   end

   for (Integer i=0; i<4; i=i+1) begin
      rule rx_mac;
         case(i)
            0: begin
               rxFifo[0].enq(XGMIIData{ data: phy0.xgmii.rxd, ctrl: phy0.xgmii.rxc });
            end
            1: begin
               rxFifo[1].enq(XGMIIData{ data: phy1.xgmii.rxd, ctrl: phy1.xgmii.rxc });
            end
            2: begin
               rxFifo[2].enq(XGMIIData{ data: phy2.xgmii.rxd, ctrl: phy2.xgmii.rxc });
            end
            3: begin
               rxFifo[3].enq(XGMIIData{ data: phy3.xgmii.rxd, ctrl: phy3.xgmii.rxc });
            end
         endcase
      endrule
   end

   Vector#(4, Wire#(Bit#(1))) tx_serial_p <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) tx_serial_n <- replicateM(mkDWire(0));
   rule tx_serial0;
      tx_serial_p[0] <= phy0.tx_serial.txp;
      tx_serial_n[0] <= phy0.tx_serial.txn;
   endrule
   rule tx_serial1;
      tx_serial_p[1] <= phy1.tx_serial.txp;
      tx_serial_n[1] <= phy1.tx_serial.txn;
   endrule
   rule tx_serial2;
      tx_serial_p[2] <= phy2.tx_serial.txp;
      tx_serial_n[2] <= phy2.tx_serial.txn;
   endrule
   rule tx_serial3;
      tx_serial_p[3] <= phy3.tx_serial.txp;
      tx_serial_n[3] <= phy3.tx_serial.txn;
   endrule

   Vector#(4, Wire#(Bit#(1))) rx_serial_wire_p <- replicateM(mkDWire(0));
   Vector#(4, Wire#(Bit#(1))) rx_serial_wire_n <- replicateM(mkDWire(0));

   rule rx_serial0;
      phy0.rx_serial.rxp(rx_serial_wire_p[0]);
      phy0.rx_serial.rxn(rx_serial_wire_n[0]);
   endrule
   rule rx_serial1;
      phy1.rx_serial.rxp(rx_serial_wire_p[1]);
      phy1.rx_serial.rxn(rx_serial_wire_n[1]);
   endrule
   rule rx_serial2;
      phy2.rx_serial.rxp(rx_serial_wire_p[2]);
      phy2.rx_serial.rxn(rx_serial_wire_n[2]);
   endrule
   rule rx_serial3;
      phy3.rx_serial.rxp(rx_serial_wire_p[3]);
      phy3.rx_serial.rxn(rx_serial_wire_n[3]);
   endrule

   rule set_sd;
      phy0.sfp.signal_detect(signal_detect_wire[0]);
      phy1.sfp.signal_detect(signal_detect_wire[1]);
      phy2.sfp.signal_detect(signal_detect_wire[2]);
      phy3.sfp.signal_detect(signal_detect_wire[3]);
   endrule

   rule set_txfault;
      phy0.sfp.tx_fault(tx_fault_wire[0]);
      phy1.sfp.tx_fault(tx_fault_wire[1]);
      phy2.sfp.tx_fault(tx_fault_wire[2]);
      phy3.sfp.tx_fault(tx_fault_wire[3]);
   endrule

   module drpLoopback#(PhywrapCoreGtDrp core, PhywrapUserGtDrp user)(Empty);
      rule conn;
         user.drp_daddr_i(core.drp_daddr_o);
         user.drp_den_i(core.drp_den_o);
         user.drp_di_i(core.drp_di_o);
         user.drp_drdy_i(core.drp_drdy_o);
         user.drp_drpdo_i(core.drp_drpdo_o);
         user.drp_dwe_i(core.drp_dwe_o);
         core.drp_gnt(user.drp_req);
      endrule
   endmodule
   /* no access to drp is required PG068: p94 */
   drpLoopback(phy0.core_drp, phy0.user_drp);
   drpLoopback(phy1.core_drp, phy1.user_drp);
   drpLoopback(phy2.core_drp, phy2.user_drp);
   drpLoopback(phy3.core_drp, phy3.user_drp);

   interface tx = map(toPut, txFifo);
   interface rx = map(toGet, rxFifo);
   method serial_tx_p = readVReg(tx_serial_p);
   method serial_tx_n = readVReg(tx_serial_n);
   method serial_rx_p = writeVReg(rx_serial_wire_p);
   method serial_rx_n = writeVReg(rx_serial_wire_n);
   interface tx_clkout = phy0.coreclk;
   method Action refclk (Bit#(1) p, Bit#(1) n);
      phy0.refclk_p(p);
      phy0.refclk_n(n);
   endmethod
   method signal_detect = writeVReg(signal_detect_wire);
   method tx_fault = writeVReg(tx_fault_wire);
   method tx_leds = {phy3.xcvr.tx_resetdone, phy2.xcvr.tx_resetdone,
                     phy1.xcvr.tx_resetdone, phy0.resetdone_out};
   method rx_leds = {phy3.xcvr.rx_resetdone, phy2.xcvr.rx_resetdone,
                     phy1.xcvr.rx_resetdone, phy0.resetdone_out};
endmodule
endpackage
