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

// ====== UPDATE_FLOW_RCVD ======

interface UpdateFlowRcvd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_rcvd;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_rcvd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_last_ack_rcvd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_dup;
  interface Client#(RegRequest#(2, 16), RegResponse#(16)) flow_rwnd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) ack_time;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkUpdateFlowRcvd  (UpdateFlowRcvd);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_rcvd <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_rcvd <- mkRX;
  let tx_info_flow_pkts_rcvd = tx_flow_pkts_rcvd.u;
  let rx_info_flow_pkts_rcvd = rx_flow_pkts_rcvd.u;
  //TX #(RegRequest#(2, 32)) tx_flow_pkts_rcvd <- mkTX;
  //RX #(RegResponse#(32)) rx_flow_pkts_rcvd <- mkRX;
  //let tx_info_flow_pkts_rcvd = tx_flow_pkts_rcvd.u;
  //let rx_info_flow_pkts_rcvd = rx_flow_pkts_rcvd.u;
  TX #(RegRequest#(2, 32)) tx_flow_last_ack_rcvd <- mkTX;
  RX #(RegResponse#(32)) rx_flow_last_ack_rcvd <- mkRX;
  let tx_info_flow_last_ack_rcvd = tx_flow_last_ack_rcvd.u;
  let rx_info_flow_last_ack_rcvd = rx_flow_last_ack_rcvd.u;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_dup <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_dup <- mkRX;
  let tx_info_flow_pkts_dup = tx_flow_pkts_dup.u;
  let rx_info_flow_pkts_dup = rx_flow_pkts_dup.u;
  TX #(RegRequest#(2, 16)) tx_flow_rwnd <- mkTX;
  RX #(RegResponse#(16)) rx_flow_rwnd <- mkRX;
  let tx_info_flow_rwnd = tx_flow_rwnd.u;
  let rx_info_flow_rwnd = rx_flow_rwnd.u;
  TX #(RegRequest#(2, 32)) tx_ack_time <- mkTX;
  RX #(RegResponse#(32)) rx_ack_time <- mkRX;
  let tx_info_ack_time = tx_ack_time.u;
  let rx_info_ack_time = rx_ack_time.u;
  Reg#(Bit#(16)) rg_tcp$window <- mkReg(0);
  Reg#(Bit#(32)) rg_tcp$ackNo <- mkReg(0);
  Reg#(Bit#(32)) rg_0$x$0 <- mkReg(0);
  Reg#(Bit#(32)) rg_intrinsic_metadata$ingress_global_timestamp <- mkReg(0);
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  rule update_flow_rcvd_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UpdateFlowRcvdReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, intrinsic_metadata$ingress_global_timestamp: .intrinsic_metadata$ingress_global_timestamp, stats_metadata$dummy: .stats_metadata$dummy, tcp$window: .tcp$window, tcp$ackNo: .tcp$ackNo}: begin
        let flow_pkts_rcvd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_pkts_rcvd.enq(flow_pkts_rcvd_req);
        //let flow_pkts_rcvd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_flow_pkts_rcvd.enq(flow_pkts_rcvd_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        let flow_last_ack_rcvd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: tcp$ackNo, write: True };
        tx_info_flow_last_ack_rcvd.enq(flow_last_ack_rcvd_req);
        rg_tcp$ackNo <= tcp$ackNo;
        let flow_pkts_dup_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: 0, write: True };
        tx_info_flow_pkts_dup.enq(flow_pkts_dup_req);
        //rg_0$x$0 <= 0$x$0;
        let flow_rwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: tcp$window, write: True };
        tx_info_flow_rwnd.enq(flow_rwnd_req);
        rg_tcp$window <= tcp$window;
        let ack_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: truncate(intrinsic_metadata$ingress_global_timestamp), write: True };
        tx_info_ack_time.enq(ack_time_req);
        rg_intrinsic_metadata$ingress_global_timestamp <= truncate(intrinsic_metadata$ingress_global_timestamp);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule update_flow_rcvd_response;
    let v_stats_metadata$dummy = rx_info_flow_pkts_rcvd.first;
    rx_info_flow_pkts_rcvd.deq;
    let stats_metadata$dummy = v_stats_metadata$dummy.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UpdateFlowRcvdRspT {pkt: pkt, stats_metadata$dummy: stats_metadata$dummy};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_pkts_rcvd = toClient(tx_flow_pkts_rcvd.e, rx_flow_pkts_rcvd.e);
  //interface flow_pkts_rcvd = toClient(tx_flow_pkts_rcvd.e, rx_flow_pkts_rcvd.e);
  interface flow_last_ack_rcvd = toClient(tx_flow_last_ack_rcvd.e, rx_flow_last_ack_rcvd.e);
  interface flow_pkts_dup = toClient(tx_flow_pkts_dup.e, rx_flow_pkts_dup.e);
  interface flow_rwnd = toClient(tx_flow_rwnd.e, rx_flow_rwnd.e);
  interface ack_time = toClient(tx_ack_time.e, rx_ack_time.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
