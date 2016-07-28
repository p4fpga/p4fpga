import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;
import Register::*;

// ====== RECORD_IP ======

interface RecordIp;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) sendIP;
  interface Client#(RegRequest#(2, 16), RegResponse#(16)) mss;
  interface Client#(RegRequest#(2, 8), RegResponse#(8)) wscale;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) mincwnd;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkRecordIp  (RecordIp);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_sendIP <- mkTX;
  RX #(RegResponse#(32)) rx_sendIP <- mkRX;
  let tx_info_sendIP = tx_sendIP.u;
  let rx_info_sendIP = rx_sendIP.u;
  TX #(RegRequest#(2, 16)) tx_mss <- mkTX;
  RX #(RegResponse#(16)) rx_mss <- mkRX;
  let tx_info_mss = tx_mss.u;
  let rx_info_mss = rx_mss.u;
  TX #(RegRequest#(2, 8)) tx_wscale <- mkTX;
  RX #(RegResponse#(8)) rx_wscale <- mkRX;
  let tx_info_wscale = tx_wscale.u;
  let rx_info_wscale = rx_wscale.u;
  TX #(RegRequest#(2, 32)) tx_mincwnd <- mkTX;
  RX #(RegResponse#(32)) rx_mincwnd <- mkRX;
  let tx_info_mincwnd = tx_mincwnd.u;
  let rx_info_mincwnd = rx_mincwnd.u;
  Reg#(Bit#(32)) rg_ipv4$dstAddr <- mkReg(0);
  Reg#(Bit#(8)) rg_options_wscale$wscale <- mkReg(0);
  Reg#(Bit#(32)) rg_0$x$3$9$0$8 <- mkReg(0);
  Reg#(Bit#(16)) rg_options_mss$mss <- mkReg(0);
  Reg#(Bit#(32)) stats_metadata$senderIP <- mkReg(0);
  rule record_IP_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged RecordIpReqT {pkt: .pkt, options_wscale$wscale: .options_wscale$wscale, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, options_mss$mss: .options_mss$mss, ipv4$dstAddr: .ipv4$dstAddr}: begin
        let sendIP_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ipv4$dstAddr, write: True };
        tx_info_sendIP.enq(sendIP_req);
        rg_ipv4$dstAddr <= ipv4$dstAddr;
        stats_metadata$senderIP <= ipv4$dstAddr;
        let mss_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: options_mss$mss, write: True };
        tx_info_mss.enq(mss_req);
        rg_options_mss$mss <= options_mss$mss;
        let wscale_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: options_wscale$wscale, write: True };
        tx_info_wscale.enq(wscale_req);
        rg_options_wscale$wscale <= options_wscale$wscale;
        let mincwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: 0, write: True };
        tx_info_mincwnd.enq(mincwnd_req);
        //rg_0$x$3$9$0$8 <= 0$x$3$9$0$8;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule record_IP_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged RecordIpRspT {pkt: pkt, stats_metadata$senderIP: stats_metadata$senderIP};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface sendIP = toClient(tx_sendIP.e, rx_sendIP.e);
  interface mss = toClient(tx_mss.e, rx_mss.e);
  interface wscale = toClient(tx_wscale.e, rx_wscale.e);
  interface mincwnd = toClient(tx_mincwnd.e, rx_mincwnd.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
