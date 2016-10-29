
/*
   /home/hwang/dev/connectal/generated/scripts/importbvi.py
   -o
   XilinxMacWrap.bsv
   -I
   MacWrap
   -P
   MacWrap
   -r
   reset
   -c
   tx_clk0
   -c
   tx_clk90
   -c
   s_axi_aclk
   -r
   s_axi_aresetn
   -r
   tx_axis_aresetn
   -r
   rx_axis_aresetn
   -c
   xgmii_tx_clk
   -c
   xgmii_rx_clk
   -c
   rx_clk_out
   -f
   tx_axis
   -f
   rx_axis
   -f
   s_axi
   -f
   mdio
   -f
   xgmii
   /home/hwang/dev/connectal/out/nfsume/ten_gig_eth_mac_0/ten_gig_eth_mac_0_stub.v
*/

import Clocks::*;
import DefaultValue::*;
import XilinxCells::*;
import GetPut::*;
import AxiBits::*;

(* always_ready, always_enabled *)
interface MacwrapMdio;
    method Action      mdioin(Bit#(1) v);
    method Bit#(1)     mdioout();
    method Bit#(1)     mdiotri();
    method Bit#(1)     mdiomdc();
endinterface
(* always_ready, always_enabled *)
interface MacwrapPause;
    method Action      req(Bit#(1) v);
    method Action      val(Bit#(16) v);
endinterface
(* always_ready, always_enabled *)
interface MacwrapRx;
    method Action      dcm_locked(Bit#(1) v);
    method Bit#(1)     statistics_valid();
    method Bit#(30)     statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface MacwrapRx_axis;
    method Bit#(64)    tdata();
    method Bit#(8)     tkeep();
    method Bit#(1)     tlast();
    method Bit#(1)     tuser();
    method Bit#(1)     tvalid();
endinterface
(* always_ready, always_enabled *)
interface MacwrapS_axi;
    method Action      araddr(Bit#(11) v);
    method Bit#(1)     arready();
    method Action      arvalid(Bit#(1) v);
    method Action      awaddr(Bit#(11) v);
    method Bit#(1)     awready();
    method Action      awvalid(Bit#(1) v);
    method Action      bready(Bit#(1) v);
    method Bit#(2)     bresp();
    method Bit#(1)     bvalid();
    method Bit#(32)     rdata();
    method Action      rready(Bit#(1) v);
    method Bit#(2)     rresp();
    method Bit#(1)     rvalid();
    method Action      wdata(Bit#(32) v);
    method Bit#(1)     wready();
    method Action      wvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface MacwrapTx;
    method Action      dcm_locked(Bit#(1) v);
    method Action      ifg_delay(Bit#(8) v);
    method Bit#(1)     statistics_valid();
    method Bit#(26)    statistics_vector();
endinterface
(* always_ready, always_enabled *)
interface MacwrapTx_axis;
    method Action      tdata(Bit#(64) v);
    method Action      tkeep(Bit#(8) v);
    method Action      tlast(Bit#(1) v);
    method Bit#(1)     tready();
    method Action      tuser(Bit#(1) v);
    method Action      tvalid(Bit#(1) v);
endinterface
(* always_ready, always_enabled *)
interface MacwrapXgmii;
    method Action      rxc(Bit#(8) v);
    method Action      rxd(Bit#(64) v);
    method Bit#(8)     txc();
    method Bit#(64)     txd();
endinterface
(* always_ready, always_enabled *)
interface MacWrap;
    interface MacwrapMdio     mdio;
    interface MacwrapPause     pause;
    interface MacwrapRx_axis     rx_axis;
    interface MacwrapRx     rx;
    interface MacwrapS_axi     s_axi;
    interface MacwrapTx_axis     tx_axis;
    interface MacwrapTx     tx;
    method Bit#(1)     xgmacint();
    interface MacwrapXgmii     xgmii;
endinterface
import "BVI" ten_gig_eth_mac_0 =
module mkMacWrap#(Clock s_axi_aclk, Clock tx_clk0, Clock rx_clk0, Reset reset, Reset s_axi_aresetn, Reset tx_axis_aresetn, Reset rx_axis_aresetn)(MacWrap);
    default_clock clk();
    default_reset rst();
    input_reset reset(reset) clocked_by (s_axi_aclk) = reset;
    input_reset rx_axis_aresetn(rx_axis_aresetn) clocked_by (rx_clk0) = rx_axis_aresetn;
    input_clock s_axi_aclk(s_axi_aclk) = s_axi_aclk;
    input_reset s_axi_aresetn(s_axi_aresetn) clocked_by (s_axi_aclk)= s_axi_aresetn;
    input_reset tx_axis_aresetn(tx_axis_aresetn) clocked_by (tx_clk0) = tx_axis_aresetn;
    input_clock tx_clk0(tx_clk0) = tx_clk0;
    input_clock rx_clk0(rx_clk0) = rx_clk0;
    interface MacwrapMdio     mdio;
        method mdioin(mdio_in) enable((*inhigh*) EN_mdio_in);
        method mdio_out mdioout();
        method mdio_tri mdiotri();
        method mdc      mdiomdc();
    endinterface
    interface MacwrapPause     pause;
        method req(pause_req) enable((*inhigh*) EN_pause_req);
        method val(pause_val) enable((*inhigh*) EN_pause_val);
    endinterface
    interface MacwrapRx_axis     rx_axis;
        method rx_axis_tdata tdata() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_axis_tkeep tkeep() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_axis_tlast tlast() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_axis_tuser tuser() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_axis_tvalid tvalid() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
    endinterface
    interface MacwrapRx     rx;
        method dcm_locked(rx_dcm_locked) enable((*inhigh*) EN_rx_dcm_locked) clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_statistics_valid statistics_valid() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
        method rx_statistics_vector statistics_vector() clocked_by (rx_clk0) reset_by (rx_axis_aresetn);
    endinterface
    interface MacwrapS_axi     s_axi;
        method araddr(s_axi_araddr) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_araddr);
        method s_axi_arready arready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method arvalid(s_axi_arvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_arvalid);
        method awaddr(s_axi_awaddr) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_awaddr);
        method s_axi_awready awready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method awvalid(s_axi_awvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_awvalid);
        method bready(s_axi_bready) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_bready);
        method s_axi_bresp bresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_bvalid bvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_rdata rdata() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method rready(s_axi_rready) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_rready);
        method s_axi_rresp rresp() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method s_axi_rvalid rvalid() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wdata(s_axi_wdata) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_wdata);
        method s_axi_wready wready() clocked_by (s_axi_aclk) reset_by (s_axi_aresetn);
        method wvalid(s_axi_wvalid) clocked_by (s_axi_aclk) reset_by (s_axi_aresetn) enable((*inhigh*) EN_s_axi_wvalid);
    endinterface
    interface MacwrapTx_axis     tx_axis;
        method tdata(tx_axis_tdata) enable((*inhigh*) EN_tx_axis_tdata) clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tkeep(tx_axis_tkeep) enable((*inhigh*) EN_tx_axis_tkeep) clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tlast(tx_axis_tlast) enable((*inhigh*) EN_tx_axis_tlast) clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tx_axis_tready tready() clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tuser(tx_axis_tuser) enable((*inhigh*) EN_tx_axis_tuser) clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tvalid(tx_axis_tvalid) enable((*inhigh*) EN_tx_axis_tvalid) clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
    endinterface
    interface MacwrapTx     tx;
        method dcm_locked(tx_dcm_locked) clocked_by (tx_clk0) reset_by (tx_axis_aresetn) enable((*inhigh*) EN_tx_dcm_locked);
        method ifg_delay(tx_ifg_delay) clocked_by (tx_clk0) reset_by (tx_axis_aresetn) enable((*inhigh*) EN_tx_ifg_delay);
        method tx_statistics_valid statistics_valid() clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method tx_statistics_vector statistics_vector() clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
    endinterface
    method xgmacint xgmacint();
    interface MacwrapXgmii     xgmii;
        method rxc(xgmii_rxc) clocked_by (rx_clk0) reset_by (rx_axis_aresetn) enable((*inhigh*) EN_xgmii_rxc);
        method rxd(xgmii_rxd) clocked_by (rx_clk0) reset_by (rx_axis_aresetn) enable((*inhigh*) EN_xgmii_rxd);
        method xgmii_txc txc() clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
        method xgmii_txd txd() clocked_by (tx_clk0) reset_by (tx_axis_aresetn);
    endinterface
    schedule (mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pause.req, pause.val, rx_axis.tdata, rx_axis.tkeep, rx_axis.tlast, rx_axis.tuser, rx_axis.tvalid, rx.dcm_locked, rx.statistics_valid, rx.statistics_vector, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, tx_axis.tdata, tx_axis.tkeep, tx_axis.tlast, tx_axis.tready, tx_axis.tuser, tx_axis.tvalid, tx.dcm_locked, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector, xgmacint, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd) CF (mdio.mdiomdc, mdio.mdioin, mdio.mdioout, mdio.mdiotri, pause.req, pause.val, rx_axis.tdata, rx_axis.tkeep, rx_axis.tlast, rx_axis.tuser, rx_axis.tvalid, rx.dcm_locked, rx.statistics_valid, rx.statistics_vector, s_axi.araddr, s_axi.arready, s_axi.arvalid, s_axi.awaddr, s_axi.awready, s_axi.awvalid, s_axi.bready, s_axi.bresp, s_axi.bvalid, s_axi.rdata, s_axi.rready, s_axi.rresp, s_axi.rvalid, s_axi.wdata, s_axi.wready, s_axi.wvalid, tx_axis.tdata, tx_axis.tkeep, tx_axis.tlast, tx_axis.tready, tx_axis.tuser, tx_axis.tvalid, tx.dcm_locked, tx.ifg_delay, tx.statistics_valid, tx.statistics_vector, xgmacint, xgmii.rxc, xgmii.rxd, xgmii.txc, xgmii.txd);
endmodule
