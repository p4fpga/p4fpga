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

// ====== GET_SENDER_IP ======

interface GetSenderIp;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) sendIP;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_last_seq_sent;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_last_ack_rcvd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_seq;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) rtt_samples;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) mincwnd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_dup;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkGetSenderIp  (GetSenderIp);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_sendIP <- mkTX;
  RX #(RegResponse#(32)) rx_sendIP <- mkRX;
  let tx_info_sendIP = tx_sendIP.u;
  let rx_info_sendIP = rx_sendIP.u;
  TX #(RegRequest#(2, 32)) tx_flow_last_seq_sent <- mkTX;
  RX #(RegResponse#(32)) rx_flow_last_seq_sent <- mkRX;
  let tx_info_flow_last_seq_sent = tx_flow_last_seq_sent.u;
  let rx_info_flow_last_seq_sent = rx_flow_last_seq_sent.u;
  TX #(RegRequest#(2, 32)) tx_flow_last_ack_rcvd <- mkTX;
  RX #(RegResponse#(32)) rx_flow_last_ack_rcvd <- mkRX;
  let tx_info_flow_last_ack_rcvd = tx_flow_last_ack_rcvd.u;
  let rx_info_flow_last_ack_rcvd = rx_flow_last_ack_rcvd.u;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_seq <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_seq <- mkRX;
  let tx_info_flow_rtt_sample_seq = tx_flow_rtt_sample_seq.u;
  let rx_info_flow_rtt_sample_seq = rx_flow_rtt_sample_seq.u;
  TX #(RegRequest#(2, 32)) tx_rtt_samples <- mkTX;
  RX #(RegResponse#(32)) rx_rtt_samples <- mkRX;
  let tx_info_rtt_samples = tx_rtt_samples.u;
  let rx_info_rtt_samples = rx_rtt_samples.u;
  TX #(RegRequest#(2, 32)) tx_mincwnd <- mkTX;
  RX #(RegResponse#(32)) rx_mincwnd <- mkRX;
  let tx_info_mincwnd = tx_mincwnd.u;
  let rx_info_mincwnd = rx_mincwnd.u;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_dup <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_dup <- mkRX;
  let tx_info_flow_pkts_dup = tx_flow_pkts_dup.u;
  let rx_info_flow_pkts_dup = rx_flow_pkts_dup.u;
  rule get_sender_IP_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged GetSenderIpReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index}: begin
        let sendIP_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_sendIP.enq(sendIP_req);
        let flow_last_seq_sent_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_last_seq_sent.enq(flow_last_seq_sent_req);
        let flow_last_ack_rcvd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_last_ack_rcvd.enq(flow_last_ack_rcvd_req);
        let flow_rtt_sample_seq_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_rtt_sample_seq.enq(flow_rtt_sample_seq_req);
        let rtt_samples_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_rtt_samples.enq(rtt_samples_req);
        let mincwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_mincwnd.enq(mincwnd_req);
        let flow_pkts_dup_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_pkts_dup.enq(flow_pkts_dup_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule get_sender_IP_response;
    let v_stats_metadata$senderIP = rx_info_sendIP.first;
    rx_info_sendIP.deq;
    let stats_metadata$senderIP = v_stats_metadata$senderIP.data;
    let v_stats_metadata$seqNo = rx_info_flow_last_seq_sent.first;
    rx_info_flow_last_seq_sent.deq;
    let stats_metadata$seqNo = v_stats_metadata$seqNo.data;
    let v_stats_metadata$ackNo = rx_info_flow_last_ack_rcvd.first;
    rx_info_flow_last_ack_rcvd.deq;
    let stats_metadata$ackNo = v_stats_metadata$ackNo.data;
    let v_stats_metadata$sample_rtt_seq = rx_info_flow_rtt_sample_seq.first;
    rx_info_flow_rtt_sample_seq.deq;
    let stats_metadata$sample_rtt_seq = v_stats_metadata$sample_rtt_seq.data;
    let v_stats_metadata$rtt_samples = rx_info_rtt_samples.first;
    rx_info_rtt_samples.deq;
    let stats_metadata$rtt_samples = v_stats_metadata$rtt_samples.data;
    let v_stats_metadata$mincwnd = rx_info_mincwnd.first;
    rx_info_mincwnd.deq;
    let stats_metadata$mincwnd = v_stats_metadata$mincwnd.data;
    let v_stats_metadata$dupack = rx_info_flow_pkts_dup.first;
    rx_info_flow_pkts_dup.deq;
    let stats_metadata$dupack = v_stats_metadata$dupack.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged GetSenderIpRspT {pkt: pkt, stats_metadata$sample_rtt_seq: stats_metadata$sample_rtt_seq, stats_metadata$seqNo: stats_metadata$seqNo, stats_metadata$dupack: stats_metadata$dupack, stats_metadata$rtt_samples: stats_metadata$rtt_samples, stats_metadata$ackNo: stats_metadata$ackNo, stats_metadata$senderIP: stats_metadata$senderIP, stats_metadata$mincwnd: stats_metadata$mincwnd};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface sendIP = toClient(tx_sendIP.e, rx_sendIP.e);
  interface flow_last_seq_sent = toClient(tx_flow_last_seq_sent.e, rx_flow_last_seq_sent.e);
  interface flow_last_ack_rcvd = toClient(tx_flow_last_ack_rcvd.e, rx_flow_last_ack_rcvd.e);
  interface flow_rtt_sample_seq = toClient(tx_flow_rtt_sample_seq.e, rx_flow_rtt_sample_seq.e);
  interface rtt_samples = toClient(tx_rtt_samples.e, rx_rtt_samples.e);
  interface mincwnd = toClient(tx_mincwnd.e, rx_mincwnd.e);
  interface flow_pkts_dup = toClient(tx_flow_pkts_dup.e, rx_flow_pkts_dup.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
