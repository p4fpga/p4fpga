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

// ====== SAMPLE_NEW_RTT ======

interface SampleNewRtt;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_seq;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_time;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkSampleNewRtt  (SampleNewRtt);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_seq <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_seq <- mkRX;
  let tx_info_flow_rtt_sample_seq = tx_flow_rtt_sample_seq.u;
  let rx_info_flow_rtt_sample_seq = rx_flow_rtt_sample_seq.u;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_time <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_time <- mkRX;
  let tx_info_flow_rtt_sample_time = tx_flow_rtt_sample_time.u;
  let rx_info_flow_rtt_sample_time = rx_flow_rtt_sample_time.u;
  Reg#(Bit#(32)) rg_intrinsic_metadata$ingress_global_timestamp <- mkReg(0);
  Reg#(Bit#(32)) rg_tcp$seqNo <- mkReg(0);
  rule sample_new_rtt_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SampleNewRttReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, tcp$seqNo: .tcp$seqNo, intrinsic_metadata$ingress_global_timestamp: .intrinsic_metadata$ingress_global_timestamp}: begin
        let flow_rtt_sample_seq_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: tcp$seqNo, write: True };
        tx_info_flow_rtt_sample_seq.enq(flow_rtt_sample_seq_req);
        rg_tcp$seqNo <= tcp$seqNo;
        let flow_rtt_sample_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: truncate(intrinsic_metadata$ingress_global_timestamp), write: True };
        tx_info_flow_rtt_sample_time.enq(flow_rtt_sample_time_req);
        rg_intrinsic_metadata$ingress_global_timestamp <= truncate(intrinsic_metadata$ingress_global_timestamp);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule sample_new_rtt_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SampleNewRttRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_rtt_sample_seq = toClient(tx_flow_rtt_sample_seq.e, rx_flow_rtt_sample_seq.e);
  interface flow_rtt_sample_time = toClient(tx_flow_rtt_sample_time.e, rx_flow_rtt_sample_time.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
