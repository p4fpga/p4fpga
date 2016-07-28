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

// ====== UPDATE_FLOW_SENT ======

interface UpdateFlowSent;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_sent;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_sent;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_last_seq_sent;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) ack_time;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) app_reaction_time;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_last_ack_rcvd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flight_size;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkUpdateFlowSent  (UpdateFlowSent);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_sent <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_sent <- mkRX;
  let tx_info_flow_pkts_sent = tx_flow_pkts_sent.u;
  let rx_info_flow_pkts_sent = rx_flow_pkts_sent.u;
  //TX #(RegRequest#(2, 32)) tx_flow_pkts_sent <- mkTX;
  //RX #(RegResponse#(32)) rx_flow_pkts_sent <- mkRX;
  //let tx_info_flow_pkts_sent = tx_flow_pkts_sent.u;
  //let rx_info_flow_pkts_sent = rx_flow_pkts_sent.u;
  TX #(RegRequest#(2, 32)) tx_flow_last_seq_sent <- mkTX;
  RX #(RegResponse#(32)) rx_flow_last_seq_sent <- mkRX;
  let tx_info_flow_last_seq_sent = tx_flow_last_seq_sent.u;
  let rx_info_flow_last_seq_sent = rx_flow_last_seq_sent.u;
  TX #(RegRequest#(2, 32)) tx_ack_time <- mkTX;
  RX #(RegResponse#(32)) rx_ack_time <- mkRX;
  let tx_info_ack_time = tx_ack_time.u;
  let rx_info_ack_time = rx_ack_time.u;
  TX #(RegRequest#(2, 32)) tx_app_reaction_time <- mkTX;
  RX #(RegResponse#(32)) rx_app_reaction_time <- mkRX;
  let tx_info_app_reaction_time = tx_app_reaction_time.u;
  let rx_info_app_reaction_time = rx_app_reaction_time.u;
  TX #(RegRequest#(2, 32)) tx_flow_last_ack_rcvd <- mkTX;
  RX #(RegResponse#(32)) rx_flow_last_ack_rcvd <- mkRX;
  let tx_info_flow_last_ack_rcvd = tx_flow_last_ack_rcvd.u;
  let rx_info_flow_last_ack_rcvd = rx_flow_last_ack_rcvd.u;
  TX #(RegRequest#(2, 32)) tx_flight_size <- mkTX;
  RX #(RegResponse#(32)) rx_flight_size <- mkRX;
  let tx_info_flight_size = tx_flight_size.u;
  let rx_info_flight_size = rx_flight_size.u;
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  Reg#(Bit#(32)) rg_tcp$seqNo <- mkReg(0);
  Reg#(Bit#(32)) stats_metadata$dummy <- mkReg(0);
  //Reg#(Bit#(32)) stats_metadata$dummy <- mkReg(0);
  rule update_flow_sent_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UpdateFlowSentReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, intrinsic_metadata$ingress_global_timestamp: .intrinsic_metadata$ingress_global_timestamp, stats_metadata$dummy: .stats_metadata$dummy, tcp$seqNo: .tcp$seqNo, stats_metadata$dummy2: .stats_metadata$dummy2}: begin
        let flow_pkts_sent_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_pkts_sent.enq(flow_pkts_sent_req);
        //let flow_pkts_sent_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_flow_pkts_sent.enq(flow_pkts_sent_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        let flow_last_seq_sent_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: tcp$seqNo, write: True };
        tx_info_flow_last_seq_sent.enq(flow_last_seq_sent_req);
        //rg_tcp$seqNo <= tcp$seqNo;
        //stats_metadata$dummy <= intrinsic_metadata$ingress_global_timestamp;
        let ack_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_ack_time.enq(ack_time_req);
        let app_reaction_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        tx_info_app_reaction_time.enq(app_reaction_time_req);
        //rg_stats_metadata$dummy <= stats_metadata$dummy;
        //stats_metadata$dummy <= tcp$seqNo;
        let flow_last_ack_rcvd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_last_ack_rcvd.enq(flow_last_ack_rcvd_req);
        let flight_size_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        tx_info_flight_size.enq(flight_size_req);
        //rg_stats_metadata$dummy <= stats_metadata$dummy;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule update_flow_sent_response;
    let v_stats_metadata$dummy = rx_info_flow_pkts_sent.first;
    rx_info_flow_pkts_sent.deq;
    let stats_metadata$dummy = v_stats_metadata$dummy.data;
    let v_stats_metadata$dummy2 = rx_info_ack_time.first;
    rx_info_ack_time.deq;
    let stats_metadata$dummy2 = v_stats_metadata$dummy2.data;
    //let v_stats_metadata$dummy2 = rx_info_flow_last_ack_rcvd.first;
    rx_info_flow_last_ack_rcvd.deq;
    //let stats_metadata$dummy2 = v_stats_metadata$dummy2.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UpdateFlowSentRspT {pkt: pkt, stats_metadata$dummy: rg_tcp$seqNo, stats_metadata$dummy2: stats_metadata$dummy2};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_pkts_sent = toClient(tx_flow_pkts_sent.e, rx_flow_pkts_sent.e);
  //interface flow_pkts_sent = toClient(tx_flow_pkts_sent.e, rx_flow_pkts_sent.e);
  interface flow_last_seq_sent = toClient(tx_flow_last_seq_sent.e, rx_flow_last_seq_sent.e);
  interface ack_time = toClient(tx_ack_time.e, rx_ack_time.e);
  interface app_reaction_time = toClient(tx_app_reaction_time.e, rx_app_reaction_time.e);
  interface flow_last_ack_rcvd = toClient(tx_flow_last_ack_rcvd.e, rx_flow_last_ack_rcvd.e);
  interface flight_size = toClient(tx_flight_size.e, rx_flight_size.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
