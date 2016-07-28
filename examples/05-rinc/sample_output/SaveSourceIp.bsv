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

// ====== SAVE_SOURCE_IP ======

interface SaveSourceIp;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) srcIP;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) dstIP;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) metaIP;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkSaveSourceIp  (SaveSourceIp);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_srcIP <- mkTX;
  RX #(RegResponse#(32)) rx_srcIP <- mkRX;
  let tx_info_srcIP = tx_srcIP.u;
  let rx_info_srcIP = rx_srcIP.u;
  TX #(RegRequest#(2, 32)) tx_dstIP <- mkTX;
  RX #(RegResponse#(32)) rx_dstIP <- mkRX;
  let tx_info_dstIP = tx_dstIP.u;
  let rx_info_dstIP = rx_dstIP.u;
  TX #(RegRequest#(2, 32)) tx_metaIP <- mkTX;
  RX #(RegResponse#(32)) rx_metaIP <- mkRX;
  let tx_info_metaIP = tx_metaIP.u;
  let rx_info_metaIP = rx_metaIP.u;
  Reg#(Bit#(32)) rg_ipv4$dstAddr <- mkReg(0);
  Reg#(Bit#(32)) rg_ipv4$srcAddr <- mkReg(0);
  Reg#(Bit#(32)) rg_stats_metadata$senderIP <- mkReg(0);
  rule save_source_IP_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SaveSourceIpReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, stats_metadata$senderIP: .stats_metadata$senderIP, ipv4$srcAddr: .ipv4$srcAddr, ipv4$dstAddr: .ipv4$dstAddr}: begin
        let srcIP_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ipv4$srcAddr, write: True };
        tx_info_srcIP.enq(srcIP_req);
        rg_ipv4$srcAddr <= ipv4$srcAddr;
        let dstIP_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ipv4$dstAddr, write: True };
        tx_info_dstIP.enq(dstIP_req);
        rg_ipv4$dstAddr <= ipv4$dstAddr;
        let metaIP_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$senderIP, write: True };
        tx_info_metaIP.enq(metaIP_req);
        rg_stats_metadata$senderIP <= stats_metadata$senderIP;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule save_source_IP_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SaveSourceIpRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface srcIP = toClient(tx_srcIP.e, rx_srcIP.e);
  interface dstIP = toClient(tx_dstIP.e, rx_dstIP.e);
  interface metaIP = toClient(tx_metaIP.e, rx_metaIP.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
