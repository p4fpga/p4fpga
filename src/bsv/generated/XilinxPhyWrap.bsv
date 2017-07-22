
/*
   /home/hwang/dev/connectal/generated/scripts/importbvi.py
   -o
   XilinxPhyWrap.bsv
   -I
   PhyWrap
   -P
   PhyWrap
   -r
   areset
   -r
   gttxreset
   -r
   gtrxreset
   -c
   dclk
   -c
   rxrecclk_out
   -c
   coreclk
   -c
   txuserclk
   -c
   txuserclk2
   -r
   areset_coreclk
   -f
   xgmii
   -f
   drp
   /home/hwang/dev/sonic-lite/hw/tests/test_xilinx_mac/project_2/project_2.srcs/sources_1/ip/ten_gig_eth_pcs_pma_0/ten_gig_eth_pcs_pma_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface PhywrapCore;
    method Bit#(8)     status();
endinterface
(* always_ready, always_enabled *)
interface PhywrapCoreGtDrp;
    method Bit#(16)    drp_daddr_o();
    method Bit#(1)     drp_den_o();
    method Bit#(16)    drp_di_o();
    method Bit#(1)     drp_drdy_o();
    method Bit#(16)    drp_drpdo_o();
    method Bit#(1)     drp_dwe_o();
    method Action      drp_gnt(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PhywrapUserGtDrp;
    method Action      drp_daddr_i(Bit#(16) v);
    method Action      drp_den_i(Bit#(1) v);
    method Action      drp_di_i(Bit#(16) v);
    method Action      drp_drdy_i(Bit#(1) v);
    method Action      drp_drpdo_i(Bit#(16) v);
    method Action      drp_dwe_i(Bit#(1) v);
    method Bit#(1)     drp_req();
endinterface
(* always_ready, always_enabled *)
interface PhywrapMdio;
    method Action      mdioin(Bit#(1) v);
    method Bit#(1)     mdioout();
    method Bit#(1)     mdiotri();
    method Action      mdiomdc(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PhywrapPma;
    method Action      pmd_type(Bit#(3) v);
endinterface
(* always_ready, always_enabled *)
interface PhywrapReset;
    method Bit#(1)     tx_resetdone();
    method Bit#(1)     rx_resetdone();
endinterface
(* always_ready, always_enabled *)
interface PhywrapSfp;
    method Action      signal_detect(Bit#(1) v);
    method Action      tx_fault(Bit#(1) v);
    method Bit#(1)     tx_disable();
endinterface
(* always_ready, always_enabled *)
interface PhywrapSim;
    method Action      speedup_control(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PhywrapXgmii;
    method Bit#(8)     rxc();
    method Bit#(64)    rxd();
    method Action      txc(Bit#(8) v);
    method Action      txd(Bit#(64) v);
endinterface
(* always_ready, always_enabled *)
interface PhyTxSerial;
    method Bit#(1)     txp();
    method Bit#(1)     txn();
endinterface
(* always_ready, always_enabled *)
interface PhyRxSerial;
    method Action      rxp(Bit#(1) v);
    method Action      rxn(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface PhyWrapNonShared;
    interface PhywrapCore      core;
    interface PhywrapCoreGtDrp core_drp;
    interface PhywrapUserGtDrp user_drp;
    interface PhywrapMdio      mdio;
    interface PhywrapPma       pma;
    method Action              prtad(Bit#(5) v);
    method Action              qplllock(Bit#(1) v);
    method Action              qplloutclk(Bit#(1) v);
    method Action              qplloutrefclk(Bit#(1) v);
    method Bit#(1)             txoutclk();
    method Action              txuserrdy(Bit#(1) v);
    method Action              txusrclk(Bit#(1) v);
    method Action              txusrclk2(Bit#(1) v);
    method Action              gtrxreset(Bit#(1) v);
    method Action              gttxreset(Bit#(1) v);
    method Action              reset_counter_done(Bit#(1) v);
    interface PhywrapReset     xcvr;
    interface Clock            rxrecclk;
    interface PhywrapSfp       sfp;
    interface PhywrapSim       sim;
    interface PhyRxSerial      rx_serial;
    interface PhyTxSerial      tx_serial;
    interface PhywrapXgmii     xgmii;
endinterface
import "BVI" ten_gig_eth_pcs_pma_non_shared =
module mkPhyWrapNonShared#(Clock coreclk, Clock dclk, Reset areset, Reset areset_coreclk)(PhyWrapNonShared);
    default_clock clk();
    default_reset rst();
    input_reset areset(areset) = areset;
    input_reset areset_coreclk(areset_coreclk) = areset_coreclk;
    input_clock coreclk(coreclk) = coreclk;
    input_clock dclk(dclk) = dclk;
    output_clock rxrecclk(rxrecclk_out);
    interface PhywrapCore     core;
        method core_status status();
    endinterface
    interface PhywrapCoreGtDrp core_drp;
        method drp_daddr_o drp_daddr_o();
        method drp_den_o drp_den_o();
        method drp_di_o drp_di_o();
        method drp_drdy_o drp_drdy_o();
        method drp_drpdo_o drp_drpdo_o();
        method drp_dwe_o drp_dwe_o();
        method drp_gnt(drp_gnt) enable((*inhigh*) EN_drp_gnt);
    endinterface
    interface PhywrapUserGtDrp user_drp;
        method drp_daddr_i(drp_daddr_i) enable((*inhigh*) EN_drp_daddr_i);
        method drp_den_i(drp_den_i) enable((*inhigh*) EN_drp_den_i);
        method drp_di_i(drp_di_i) enable((*inhigh*) EN_drp_di_i);
        method drp_drdy_i(drp_drdy_i) enable((*inhigh*) EN_drp_drdy_i);
        method drp_drpdo_i(drp_drpdo_i) enable((*inhigh*) EN_drp_drpdo_i);
        method drp_dwe_i(drp_dwe_i) enable((*inhigh*) EN_drp_dwe_i);
        method drp_req drp_req();
    endinterface
    method prtad(prtad) enable((*inhigh*) EN_prtad);
    method qplllock(qplllock) enable((*inhigh*) EN_qplllock);
    method qplloutclk(qplloutclk) enable((*inhigh*) EN_qplloutclk);
    method qplloutrefclk(qplloutrefclk) enable((*inhigh*) EN_qplloutrefclk);
    method txoutclk txoutclk();
    method txuserrdy(txuserrdy) enable((*inhigh*) EN_txuserrdy);
    method txusrclk(txusrclk) enable((*inhigh*) EN_txusrclk);
    method txusrclk2(txusrclk2) enable((*inhigh*) EN_txusrclk2);
    method gtrxreset(gtrxreset) enable((*inhigh*) EN_gtrxreset);
    method gttxreset(gttxreset) enable((*inhigh*) EN_gttxreset);
    method reset_counter_done(reset_counter_done) enable((*inhigh*) EN_reset_counter_done);
    interface PhywrapMdio     mdio;
        method mdioin(mdio_in) enable((*inhigh*) EN_mdio_in);
        method mdio_out mdioout();
        method mdio_tri mdiotri();
        method mdiomdc(mdc) enable((*inhigh*) EN_mdc);
    endinterface
    interface PhywrapPma     pma;
        method pmd_type(pma_pmd_type) enable((*inhigh*) EN_pma_pmd_type);
    endinterface
    interface PhywrapReset     xcvr;
        method rx_resetdone rx_resetdone();
        method tx_resetdone tx_resetdone();
    endinterface
    interface PhywrapSfp     sfp;
        method signal_detect(signal_detect) enable((*inhigh*) EN_signal_detect);
        method tx_fault(tx_fault) enable((*inhigh*) EN_tx_fault);
        method tx_disable    tx_disable();
    endinterface
    interface PhywrapSim     sim;
        method speedup_control(sim_speedup_control) enable((*inhigh*) EN_sim_speedup_control);
    endinterface
    interface PhyTxSerial tx_serial;
        method txn txn();
        method txp txp();
    endinterface
    interface PhyRxSerial rx_serial;
        method rxn(rxn) enable((*inhigh*) EN_rxn);
        method rxp(rxp) enable((*inhigh*) EN_rxp);
    endinterface
    interface PhywrapXgmii     xgmii;
        method xgmii_rxc rxc() clocked_by (coreclk);
        method xgmii_rxd rxd() clocked_by (coreclk);
        method txc(xgmii_txc) clocked_by (coreclk) enable((*inhigh*) EN_xgmii_txc);
        method txd(xgmii_txd) clocked_by (coreclk) enable((*inhigh*) EN_xgmii_txd);
    endinterface
    schedule (core.status, user_drp.drp_daddr_i, user_drp.drp_den_i, user_drp.drp_di_i, user_drp.drp_drdy_i, user_drp.drp_drpdo_i, user_drp.drp_dwe_i, user_drp.drp_req, core_drp.drp_daddr_o, core_drp.drp_den_o, core_drp.drp_di_o, core_drp.drp_drdy_o, core_drp.drp_drpdo_o, core_drp.drp_dwe_o, core_drp.drp_gnt, mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pma.pmd_type, prtad, gttxreset, reset_counter_done, gtrxreset, qplllock, qplloutclk, qplloutrefclk, xcvr.rx_resetdone, rx_serial.rxn, rx_serial.rxp, sfp.signal_detect, sim.speedup_control, sfp.tx_disable, sfp.tx_fault, xcvr.tx_resetdone, tx_serial.txn, txoutclk, tx_serial.txp, txuserrdy, txusrclk, txusrclk2, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd) CF (core.status, user_drp.drp_daddr_i, user_drp.drp_den_i, user_drp.drp_di_i, user_drp.drp_drdy_i, user_drp.drp_drpdo_i, user_drp.drp_dwe_i, user_drp.drp_req, core_drp.drp_den_o, core_drp.drp_daddr_o, core_drp.drp_di_o, core_drp.drp_drdy_o, core_drp.drp_drpdo_o, core_drp.drp_dwe_o, core_drp.drp_gnt, mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pma.pmd_type, prtad, gttxreset, reset_counter_done, gtrxreset, qplllock, qplloutclk, qplloutrefclk, xcvr.rx_resetdone, rx_serial.rxn, rx_serial.rxp, sfp.signal_detect, sim.speedup_control, sfp.tx_disable, sfp.tx_fault, xcvr.tx_resetdone, tx_serial.txn, txoutclk, tx_serial.txp, txuserrdy, txusrclk, txusrclk2, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd);
endmodule

(* always_ready, always_enabled *)
interface PhyWrapShared;
    interface PhywrapCore      core;
    interface PhywrapCoreGtDrp core_drp;
    interface PhywrapUserGtDrp user_drp;
    interface PhywrapMdio      mdio;
    interface PhywrapPma       pma;
    method Action              prtad(Bit#(5) v);
    method Bit#(1)             qplllock_out();
    method Bit#(1)             qplloutclk_out();
    method Bit#(1)             qplloutrefclk_out();
    method Bit#(1)             txuserrdy_out();
    method Bit#(1)             txusrclk_out();
    method Bit#(1)             txusrclk2_out();
    method Bit#(1)             gtrxreset_out();
    method Bit#(1)             gttxreset_out();
    method Bit#(1)             resetdone_out();
    method Bit#(1)             reset_counter_done_out;
    method Action              refclk_p(Bit#(1) v);
    method Action              refclk_n(Bit#(1) v);
    interface Clock            rxrecclk;
    interface Clock            coreclk;
    interface PhywrapSfp       sfp;
    interface PhywrapSim       sim;
    interface PhyRxSerial      rx_serial;
    interface PhyTxSerial      tx_serial;
    interface PhywrapXgmii     xgmii;
endinterface
import "BVI" ten_gig_eth_pcs_pma_shared =
module mkPhyWrapShared#(Clock dclk)(PhyWrapShared);
    default_clock clk();
    default_reset rst();
    input_clock dclk(dclk) = dclk;
    output_clock rxrecclk(rxrecclk_out);
    output_clock coreclk(coreclk_out);
    interface PhywrapCore     core;
        method core_status status();
    endinterface
    interface PhywrapCoreGtDrp core_drp;
        method drp_daddr_o drp_daddr_o();
        method drp_den_o drp_den_o();
        method drp_di_o drp_di_o();
        method drp_drdy_o drp_drdy_o();
        method drp_drpdo_o drp_drpdo_o();
        method drp_dwe_o drp_dwe_o();
        method drp_gnt(drp_gnt) enable((*inhigh*) EN_drp_gnt);
    endinterface
    interface PhywrapUserGtDrp user_drp;
        method drp_daddr_i(drp_daddr_i) enable((*inhigh*) EN_drp_daddr_i);
        method drp_den_i(drp_den_i) enable((*inhigh*) EN_drp_den_i);
        method drp_di_i(drp_di_i) enable((*inhigh*) EN_drp_di_i);
        method drp_drdy_i(drp_drdy_i) enable((*inhigh*) EN_drp_drdy_i);
        method drp_drpdo_i(drp_drpdo_i) enable((*inhigh*) EN_drp_drpdo_i);
        method drp_dwe_i(drp_dwe_i) enable((*inhigh*) EN_drp_dwe_i);
        method drp_req drp_req();
    endinterface
    method prtad(prtad) enable((*inhigh*) EN_prtad);
    method refclk_p(refclk_p) enable((*inhigh*) EN_refclk_p);
    method refclk_n(refclk_n) enable((*inhigh*) EN_refclk_n);
    method qplllock_out qplllock_out();
    method qplloutclk_out qplloutclk_out();
    method qplloutrefclk_out qplloutrefclk_out();
    method txuserrdy_out txuserrdy_out();
    method txusrclk_out txusrclk_out();
    method txusrclk2_out txusrclk2_out();
    method gtrxreset_out gtrxreset_out();
    method gttxreset_out gttxreset_out();
    method resetdone_out resetdone_out();
    method reset_counter_done_out reset_counter_done_out();
    interface PhywrapMdio     mdio;
        method mdioin(mdio_in) enable((*inhigh*) EN_mdio_in);
        method mdio_out mdioout();
        method mdio_tri mdiotri();
        method mdiomdc(mdc) enable((*inhigh*) EN_mdc);
    endinterface
    interface PhywrapPma     pma;
        method pmd_type(pma_pmd_type) enable((*inhigh*) EN_pma_pmd_type);
    endinterface
    interface PhywrapSfp     sfp;
        method signal_detect(signal_detect) enable((*inhigh*) EN_signal_detect);
        method tx_fault(tx_fault) enable((*inhigh*) EN_tx_fault);
        method tx_disable    tx_disable();
    endinterface
    interface PhywrapSim     sim;
        method speedup_control(sim_speedup_control) enable((*inhigh*) EN_sim_speedup_control);
    endinterface
    interface PhyTxSerial tx_serial;
        method txn txn();
        method txp txp();
    endinterface
    interface PhyRxSerial rx_serial;
        method rxn(rxn) enable((*inhigh*) EN_rxn);
        method rxp(rxp) enable((*inhigh*) EN_rxp);
    endinterface
    interface PhywrapXgmii     xgmii;
        method xgmii_rxc rxc() clocked_by (coreclk);
        method xgmii_rxd rxd() clocked_by (coreclk);
        method txc(xgmii_txc) clocked_by (coreclk) enable((*inhigh*) EN_xgmii_txc);
        method txd(xgmii_txd) clocked_by (coreclk) enable((*inhigh*) EN_xgmii_txd);
    endinterface
    schedule (core.status, user_drp.drp_daddr_i, user_drp.drp_den_i, user_drp.drp_di_i, user_drp.drp_drdy_i, user_drp.drp_drpdo_i, user_drp.drp_dwe_i, user_drp.drp_req, core_drp.drp_daddr_o, core_drp.drp_den_o, core_drp.drp_di_o, core_drp.drp_drdy_o, core_drp.drp_drpdo_o, core_drp.drp_dwe_o, core_drp.drp_gnt, mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pma.pmd_type, prtad, qplllock_out, qplloutclk_out, qplloutrefclk_out, resetdone_out, reset_counter_done_out, refclk_p, refclk_n, rx_serial.rxn, rx_serial.rxp, sfp.signal_detect, sim.speedup_control, sfp.tx_disable, sfp.tx_fault, tx_serial.txn, tx_serial.txp, txuserrdy_out, txusrclk_out, txusrclk2_out, gtrxreset_out, gttxreset_out, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd) CF (core.status, user_drp.drp_daddr_i, user_drp.drp_den_i, user_drp.drp_di_i, user_drp.drp_drdy_i, user_drp.drp_drpdo_i, user_drp.drp_dwe_i, user_drp.drp_req, core_drp.drp_den_o, core_drp.drp_daddr_o, core_drp.drp_di_o, core_drp.drp_drdy_o, core_drp.drp_drpdo_o, core_drp.drp_dwe_o, core_drp.drp_gnt, mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pma.pmd_type, prtad, qplllock_out, qplloutclk_out, qplloutrefclk_out, resetdone_out, reset_counter_done_out, refclk_p, refclk_n, rx_serial.rxn, rx_serial.rxp, sfp.signal_detect, sim.speedup_control, sfp.tx_disable, sfp.tx_fault, tx_serial.txn, tx_serial.txp, txuserrdy_out, txusrclk_out, txusrclk2_out, gtrxreset_out, gttxreset_out, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd);
endmodule
