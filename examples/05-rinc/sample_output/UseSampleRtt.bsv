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

// ====== USE_SAMPLE_RTT ======

interface UseSampleRtt;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_time;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_seq;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_srtt;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_srtt;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) rtt_samples;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) rtt_samples;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkUseSampleRtt  (UseSampleRtt);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_time <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_time <- mkRX;
  let tx_info_flow_rtt_sample_time = tx_flow_rtt_sample_time.u;
  let rx_info_flow_rtt_sample_time = rx_flow_rtt_sample_time.u;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_seq <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_seq <- mkRX;
  let tx_info_flow_rtt_sample_seq = tx_flow_rtt_sample_seq.u;
  let rx_info_flow_rtt_sample_seq = rx_flow_rtt_sample_seq.u;
  TX #(RegRequest#(2, 32)) tx_flow_srtt <- mkTX;
  RX #(RegResponse#(32)) rx_flow_srtt <- mkRX;
  let tx_info_flow_srtt = tx_flow_srtt.u;
  let rx_info_flow_srtt = rx_flow_srtt.u;
  //TX #(RegRequest#(2, 32)) tx_flow_srtt <- mkTX;
  //RX #(RegResponse#(32)) rx_flow_srtt <- mkRX;
  //let tx_info_flow_srtt = tx_flow_srtt.u;
  //let rx_info_flow_srtt = rx_flow_srtt.u;
  TX #(RegRequest#(2, 32)) tx_rtt_samples <- mkTX;
  RX #(RegResponse#(32)) rx_rtt_samples <- mkRX;
  let tx_info_rtt_samples = tx_rtt_samples.u;
  let rx_info_rtt_samples = rx_rtt_samples.u;
  //TX #(RegRequest#(2, 32)) tx_rtt_samples <- mkTX;
  //RX #(RegResponse#(32)) rx_rtt_samples <- mkRX;
  //let tx_info_rtt_samples = tx_rtt_samples.u;
  //let rx_info_rtt_samples = rx_rtt_samples.u;
  Reg#(Bit#(32)) rg_0$x$0 <- mkReg(0);
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  Reg#(Bit#(32)) stats_metadata$dummy2 <- mkReg(0);
  Reg#(Bit#(32)) stats_metadata$dummy <- mkReg(0);
  //Reg#(Bit#(32)) stats_metadata$dummy <- mkReg(0);
  rule use_sample_rtt_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UseSampleRttReqT {pkt: .pkt, stats_metadata$dummy: .stats_metadata$dummy, stats_metadata$flow_map_index: .stats_metadata$flow_map_index, intrinsic_metadata$ingress_global_timestamp: .intrinsic_metadata$ingress_global_timestamp}: begin
        let flow_rtt_sample_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_rtt_sample_time.enq(flow_rtt_sample_time_req);
        stats_metadata$dummy2 <= truncate(intrinsic_metadata$ingress_global_timestamp);
        let flow_rtt_sample_seq_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: 0, write: True };
        tx_info_flow_rtt_sample_seq.enq(flow_rtt_sample_seq_req);
        //rg_0$x$0 <= 0$x$0;
        let flow_srtt_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        //tx_info_flow_srtt.enq(flow_srtt_req);
        //stats_metadata$dummy <= type$value;
        //stats_metadata$dummy <= type$value;
        //let flow_srtt_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        tx_info_flow_srtt.enq(flow_srtt_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        let rtt_samples_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_rtt_samples.enq(rtt_samples_req);
        //let rtt_samples_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_rtt_samples.enq(rtt_samples_req);
        //rg_stats_metadata$dummy <= stats_metadata$dummy;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule use_sample_rtt_response;
    let v_stats_metadata$dummy = rx_info_flow_rtt_sample_time.first;
    rx_info_flow_rtt_sample_time.deq;
    let stats_metadata$dummy = v_stats_metadata$dummy.data;
    //let v_stats_metadata$dummy = rx_info_flow_srtt.first;
    rx_info_flow_srtt.deq;
    //let stats_metadata$dummy = v_stats_metadata$dummy.data;
    //let v_stats_metadata$dummy = rx_info_rtt_samples.first;
    rx_info_rtt_samples.deq;
    //let stats_metadata$dummy = v_stats_metadata$dummy.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UseSampleRttRspT {pkt: pkt, stats_metadata$dummy: stats_metadata$dummy, stats_metadata$dummy2: stats_metadata$dummy2};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_rtt_sample_time = toClient(tx_flow_rtt_sample_time.e, rx_flow_rtt_sample_time.e);
  interface flow_rtt_sample_seq = toClient(tx_flow_rtt_sample_seq.e, rx_flow_rtt_sample_seq.e);
  interface flow_srtt = toClient(tx_flow_srtt.e, rx_flow_srtt.e);
  interface rtt_samples = toClient(tx_rtt_samples.e, rx_rtt_samples.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
