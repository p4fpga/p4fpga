
import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface EthwrapM_axis;
    method Bit#(64)    tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Bit#(1)     tuser();
    method Bit#(1)     tvalid();
endinterface

(* always_ready, always_enabled *)
interface EthwrapMac;
    method Action      rx_configuration_vector(Bit#(80) v);
    method Action      tx_configuration_vector(Bit#(80) v);
endinterface

(* always_ready, always_enabled *)
interface EthwrapPcs;
    method Action      pma_configuration_vector(Bit#(536) v);
    method Bit#(448)   pma_status_vector();
endinterface

(* always_ready, always_enabled *)
interface EthwrapRx;
    method Bit#(1)     statistics_valid();
    method Bit#(30)    statistics_vector();
endinterface

(* always_ready, always_enabled *)
interface EthwrapS_axis_pause;
    method Action      tdata(Bit#(16) v);
    method Action      tvalid(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface EthwrapS_axis_tx;
    method Action      tdata(Bit#(64) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tuser(Bit#(1) v);
    method Action      tvalid(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface EthwrapSfp;
    method Action      signal_detect(Bit#(1) v);
    method Action      tx_fault(Bit#(1) v);
    method Bit#(1)     tx_disable();
endinterface

(* always_ready, always_enabled *)
interface EthwrapSim;
    method Action      speedup_control(Bit#(1) v);
endinterface

(* always_ready, always_enabled *)
interface EthwrapTx;
    method Bit#(1)     statistics_valid();
    method Bit#(26)    statistics_vector();
endinterface

(* always_ready, always_enabled *)
interface PhywrapReset;
    method Bit#(1)     tx_resetdone();
    method Bit#(1)     rx_resetdone();
endinterface

(* always_ready, always_enabled *)
interface EthWrapNonShared;
    method Action      coreclk(Bit#(1) v);
    method Action      gtrxreset(Bit#(1) v);
    method Action      gttxreset(Bit#(1) v);
    method Action      qplllock(Bit#(1) v);
    method Action      qplloutclk(Bit#(1) v);
    method Action      qplloutrefclk(Bit#(1) v);
    method Action      rxn(Bit#(1) v);
    method Action      rxp(Bit#(1) v);
    method Bit#(1)     txn();
    method Bit#(1)     txp();
    method Bit#(1)     txoutclk();
    method Action      txuserrdy(Bit#(1) v);
    method Action      txusrclk(Bit#(1) v);
    method Action      txusrclk2(Bit#(1) v);
    method Action      reset_counter_done(Bit#(1) v);
    interface EthwrapMac        mac;
    interface EthwrapPcs        pcs;
    interface EthwrapPcspma     pcspma;
    interface EthwrapRxrecclk   rxrecclk;
    interface EthwrapS_axis_pause  s_axis_pause;
    interface EthwrapM_axis_rx  m_axis_rx;
    interface EthwrapS_axis_tx  s_axis_tx;
    interface EthwrapSfp        sfp;
    interface EthwrapSim        sim;
    interface EthwrapTx         tx;
    interface EthwrapRx         rx;
endinterface
import "BVI" axi_10g_ethernet_non_shared = 
module mkEthWrapNonShared#(Clock dclk, Reset areset, Reset areset_coreclk, Reset tx_axis_aresetn, Reset rx_axis_aresetn)(EthWrapNonShared);
    default_clock clk();
    default_reset rst();
    input_clock dclk(dclk) = dclk;
    input_reset areset(areset) = areset;
    input_reset areset_coreclk(areset_coreclk) = areset_coreclk;
    method coreclk(coreclk) enable((*inhigh*) EN_coreclk);
    method gtrxreset(gtrxreset) enable((*inhigh*) EN_gtrxreset);
    method gttxreset(gttxreset) enable((*inhigh*) EN_gttxreset);
    method qplllock(qplllock) enable((*inhigh*) EN_qplllock);
    method qplloutclk(qplloutclk) enable((*inhigh*) EN_qplloutclk);
    method qplloutrefclk(qplloutrefclk) enable((*inhigh*) EN_qplloutrefclk);
    method rxn(rxn) enable((*inhigh*) EN_rxn);
    method rxp(rxp) enable((*inhigh*) EN_rxp);
    interface EthwrapM_axis_rx     m_axis_rx;
        method m_axis_rx_tdata tdata();
        method m_axis_rx_tkeep tkeep();
        method m_axis_rx_tlast tlast();
        method m_axis_rx_tuser tuser();
        method m_axis_rx_tvalid tvalid();
    endinterface
    interface EthwrapMac     mac;
        method rx_configuration_vector(mac_rx_configuration_vector) enable((*inhigh*) EN_mac_rx_configuration_vector);
        method mac_status_vector status_vector();
        method tx_configuration_vector(mac_tx_configuration_vector) enable((*inhigh*) EN_mac_tx_configuration_vector);
    endinterface
    interface EthwrapPcs     pcs;
        method pma_configuration_vector(pcs_pma_configuration_vector) enable((*inhigh*) EN_pcs_pma_configuration_vector);
        method pcs_pma_status_vector pma_status_vector();
    endinterface
    interface EthwrapPcspma     pcspma;
        method pcspma_status status();
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
    interface EthwrapRx     rx;
        method rx_statistics_valid statistics_valid();
        method rx_statistics_vector statistics_vector();
    endinterface
    interface EthwrapRxrecclk     rxrecclk;
        output_clock out(rxrecclk_out);
    endinterface
    interface EthwrapS_axis_pause     s_axis_pause;
        method tdata(s_axis_pause_tdata) enable((*inhigh*) EN_s_axis_pause_tdata);
        method tvalid(s_axis_pause_tvalid) enable((*inhigh*) EN_s_axis_pause_tvalid);
    endinterface
    interface EthwrapS_axis_tx     s_axis_tx;
        method tdata(s_axis_tx_tdata) enable((*inhigh*) EN_s_axis_tx_tdata);
        method tkeep(s_axis_tx_tkeep) enable((*inhigh*) EN_s_axis_tx_tkeep);
        method tlast(s_axis_tx_tlast) enable((*inhigh*) EN_s_axis_tx_tlast);
        method s_axis_tx_tready tready();
        method tuser(s_axis_tx_tuser) enable((*inhigh*) EN_s_axis_tx_tuser);
        method tvalid(s_axis_tx_tvalid) enable((*inhigh*) EN_s_axis_tx_tvalid);
    endinterface
    interface EthwrapSim     sim;
        method speedup_control(sim_speedup_control) enable((*inhigh*) EN_sim_speedup_control);
    endinterface
    interface EthwrapTx     tx;
        method ifg_delay(tx_ifg_delay) enable((*inhigh*) EN_tx_ifg_delay);
        method tx_statistics_valid statistics_valid();
        method tx_statistics_vector statistics_vector();
    endinterface
    method txn txn();
    method txoutclk txoutclk();
    method txp txp();
    method txuserrdy(txuserrdy) enable((*inhigh*) EN_txuserrdy);
    method txusrclk(txusrclk) enable((*inhigh*) EN_txusrclk);
    method txusrclk2(txusrclk2) enable((*inhigh*) EN_txusrclk2);
    schedule (areset, areset.coreclk, coreclk, gtrxreset, gttxreset, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tuser, m_axis_rx.tvalid, mac.rx_configuration_vector, mac.status_vector, mac.tx_configuration_vector, pcs.pma_configuration_vector, pcs.pma_status_vector, pcspma.status, qplllock, qplloutclk, qplloutrefclk, reset.counter_done, rx.axis_aresetn, sfp.rx_resetdone, rx.statistics_valid, rx.statistics_vector, rxn, rxp, s_axis_pause.tdata, s_axis_pause.tvalid, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, signal.detect, sim.speedup_control, tx.axis_aresetn, tx.disable, tx.fault, tx.ifg_delay, sfp.tx_resetdone, tx.statistics_valid, tx.statistics_vector, txn, txoutclk, txp, txuserrdy, txusrclk, txusrclk2) CF (areset, areset.coreclk, coreclk, gtrxreset, gttxreset, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tuser, m_axis_rx.tvalid, mac.rx_configuration_vector, mac.status_vector, mac.tx_configuration_vector, pcs.pma_configuration_vector, pcs.pma_status_vector, pcspma.status, qplllock, qplloutclk, qplloutrefclk, reset.counter_done, rx.axis_aresetn, sfp.rx_resetdone, rx.statistics_valid, rx.statistics_vector, rxn, rxp, s_axis_pause.tdata, s_axis_pause.tvalid, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, signal.detect, sim.speedup_control, tx.axis_aresetn, tx.disable, tx.fault, tx.ifg_delay, sfp.tx_resetdone, tx.statistics_valid, tx.statistics_vector, txn, txoutclk, txp, txuserrdy, txusrclk, txusrclk2);
endmodule
(* always_ready, always_enabled *)
interface EthWrapShared;
    method Bit#(1)     areset_datapathclk_out;
    method Bit#(1)     gtrxreset_out;
    method Bit#(1)     gttxreset_out;
    interface Clock    rxrecclk;
    interface Clock    coreclk;
    method Action      rxn(Bit#(1) v);
    method Action      rxp(Bit#(1) v);
    method Bit#(1)     txn();
    method Bit#(1)     txp();
    method Bit#(1)     qplllock_out();
    method Bit#(1)     qplloutclk_out();
    method Bit#(1)     qplloutrefclk_out();
    method Bit#(1)     txuserrdy_out();
    method Bit#(1)     txusrclk_out();
    method Bit#(1)     txusrclk2_out();
    method Action      refclk_p(Bit#(1) v);
    method Action      refclk_n(Bit#(1) v);
    method Bit#(1)     resetdone_out();
    method Bit#(1)     reset_counter_done_out;
    method Bit#(8)     pcspma_status();
    interface EthwrapM_axis    m_axis_rx;
    interface EthwrapS_axis    s_axis_tx;
    interface EthwrapMac       mac;
    interface EthwrapPcs       pcs;
    interface EthwrapS_axis_pause s_axis_pause;
    interface EthwrapSfp       sfp;
    interface EthwrapSim       sim;
    interface EthwrapRx        rx;
    interface EthwrapTx        tx;
endinterface
import "BVI" axi_10g_ethernet_shared =
module mkEthWrapShared#(Clock dclk, Reset tx_axis_aresetn, Reset rx_axis_aresetn)(EthWrapShared);
    default_clock clk();
    default_reset rst();
    input_clock dclk(dclk) = dclk;
    output_clock rxrecclk(rxrecclk_out);
    output_clock coreclk(coreclk_out);
    interface EthwrapMac     mac;
        method rx_configuration_vector(mac_rx_configuration_vector) enable((*inhigh*) EN_mac_rx_configuration_vector);
        method mac_status_vector status_vector();
        method tx_configuration_vector(mac_tx_configuration_vector) enable((*inhigh*) EN_mac_tx_configuration_vector);
    endinterface
    interface EthwrapPcs     pcs;
        method pma_configuration_vector(pcs_pma_configuration_vector) enable((*inhigh*) EN_pcs_pma_configuration_vector);
        method pcs_pma_status_vector pma_status_vector();
    endinterface
    method qplllock_out qplllock_out();
    method qplloutclk_out qplloutclk_out();
    method qplloutrefclk_out qplloutrefclk_out();
    method rxn(rxn) enable((*inhigh*) EN_rxn);
    method rxp(rxp) enable((*inhigh*) EN_rxp);
    method txn txn();
    method txp txp();
    method tx_ifg_delay(tx_ifg_delay) enable((*inhigh*) EN_tx_ifg_delay);
    method pcspma_status pcspma_status();
    interface EthwrapS_axis_pause     s_axis_pause;
        method tdata(s_axis_pause_tdata) enable((*inhigh*) EN_s_axis_pause_tdata);
        method tvalid(s_axis_pause_tvalid) enable((*inhigh*) EN_s_axis_pause_tvalid);
    endinterface
    interface EthwrapM_axis     m_axis_rx;
        method m_axis_rx_tdata tdata();
        method m_axis_rx_tkeep tkeep();
        method m_axis_rx_tlast tlast();
        method m_axis_rx_tuser tuser();
        method m_axis_rx_tvalid tvalid();
    endinterface
    interface EthwrapS_axis     s_axis_tx;
        method tdata(s_axis_tx_tdata) enable((*inhigh*) EN_s_axis_tx_tdata);
        method tkeep(s_axis_tx_tkeep) enable((*inhigh*) EN_s_axis_tx_tkeep);
        method tlast(s_axis_tx_tlast) enable((*inhigh*) EN_s_axis_tx_tlast);
        method s_axis_tx_tready tready();
        method tuser(s_axis_tx_tuser) enable((*inhigh*) EN_s_axis_tx_tuser);
        method tvalid(s_axis_tx_tvalid) enable((*inhigh*) EN_s_axis_tx_tvalid);
    endinterface
    interface EthwrapSfp     sfp;
        method signal_detect(signal_detect) enable((*inhigh*) EN_signal_detect);
        method tx_disable tx_disable();
        method tx_fault(tx_fault) enable((*inhigh*) EN_tx_fault);
    endinterface
    interface EthwrapSim     sim;
        method speedup_control(sim_speedup_control) enable((*inhigh*) EN_sim_speedup_control);
    endinterface
    interface EthwrapRx     rx;
        method rx_statistics_valid statistics_valid();
        method rx_statistics_vector statistics_vector();
    endinterface
    interface EthwrapTx     tx;
        method tx_statistics_valid statistics_valid();
        method tx_statistics_vector statistics_vector();
    endinterface
    schedule (areset_datapathclk_out, gtrxreset_out, gttxreset_out, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tuser, m_axis_rx.tvalid, mac.rx_configuration_vector, mac.tx_configuration_vector, pcs.pma_configuration_vector, pcs.pma_status_vector, pcspma_status, qplllock_out, qplloutclk_out, qplloutrefclk_out, refclk_n, refclk_p, reset_counter_done_out, resetdone_out, rx.statistics_valid, rx.statistics_vector, rxn, rxp, s_axis_pause.tdata, s_axis_pause.tvalid, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, sfp.signal_detect, sfp.tx_fault, sfp.tx_disable, sim.speedup_control, tx_ifg_delay, tx.statistics_valid, tx.statistics_vector, txn, txp, txuserrdy_out, txusrclk2_out, txusrclk_out) CF (areset_datapathclk_out, gtrxreset_out, gttxreset_out, m_axis_rx.tdata, m_axis_rx.tkeep, m_axis_rx.tlast, m_axis_rx.tuser, m_axis_rx.tvalid, mac.rx_configuration_vector, mac.tx_configuration_vector, pcs.pma_configuration_vector, pcs.pma_status_vector, pcspma_status, qplllock_out, qplloutclk_out, qplloutrefclk_out, refclk_n, refclk_p, reset_counter_done_out, resetdone_out, rx.statistics_valid, rx.statistics_vector, rxn, rxp, s_axis_pause.tdata, s_axis_pause.tvalid, s_axis_tx.tdata, s_axis_tx.tkeep, s_axis_tx.tlast, s_axis_tx.tready, s_axis_tx.tuser, s_axis_tx.tvalid, sfp.signal_detect, sfp.tx_fault, sfp.tx_disable, sim.speedup_control, tx_ifg_delay, tx.statistics_valid, tx.statistics_vector, txn, txp, txuserrdy_out, txusrclk2_out, txusrclk_out);
endmodule
