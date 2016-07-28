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

// ====== UPDATE_FLOW_RETX_3DUPACK ======

interface UpdateFlowRetx3Dupack;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_retx;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_retx;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_seq;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_rtt_sample_time;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) mincwnd;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) mincwnd;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkUpdateFlowRetx3Dupack  (UpdateFlowRetx3Dupack);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_retx <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_retx <- mkRX;
  let tx_info_flow_pkts_retx = tx_flow_pkts_retx.u;
  let rx_info_flow_pkts_retx = rx_flow_pkts_retx.u;
  //TX #(RegRequest#(2, 32)) tx_flow_pkts_retx <- mkTX;
  //RX #(RegResponse#(32)) rx_flow_pkts_retx <- mkRX;
  //let tx_info_flow_pkts_retx = tx_flow_pkts_retx.u;
  //let rx_info_flow_pkts_retx = rx_flow_pkts_retx.u;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_seq <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_seq <- mkRX;
  let tx_info_flow_rtt_sample_seq = tx_flow_rtt_sample_seq.u;
  let rx_info_flow_rtt_sample_seq = rx_flow_rtt_sample_seq.u;
  TX #(RegRequest#(2, 32)) tx_flow_rtt_sample_time <- mkTX;
  RX #(RegResponse#(32)) rx_flow_rtt_sample_time <- mkRX;
  let tx_info_flow_rtt_sample_time = tx_flow_rtt_sample_time.u;
  let rx_info_flow_rtt_sample_time = rx_flow_rtt_sample_time.u;
  TX #(RegRequest#(2, 32)) tx_mincwnd <- mkTX;
  RX #(RegResponse#(32)) rx_mincwnd <- mkRX;
  let tx_info_mincwnd = tx_mincwnd.u;
  let rx_info_mincwnd = rx_mincwnd.u;
  //TX #(RegRequest#(2, 32)) tx_mincwnd <- mkTX;
  //RX #(RegResponse#(32)) rx_mincwnd <- mkRX;
  //let tx_info_mincwnd = tx_mincwnd.u;
  //let rx_info_mincwnd = rx_mincwnd.u;
  //Reg#(Bit#(32)) rg_0$x$0 <- mkReg(0);
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  Reg#(Bit#(32)) stats_metadata$dummy <- mkReg(0);
  rule update_flow_retx_3dupack_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UpdateFlowRetx3DupackReqT {pkt: .pkt, stats_metadata$dummy: .stats_metadata$dummy, stats_metadata$flow_map_index: .stats_metadata$flow_map_index}: begin
        let flow_pkts_retx_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_pkts_retx.enq(flow_pkts_retx_req);
        //let flow_pkts_retx_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_flow_pkts_retx.enq(flow_pkts_retx_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        let flow_rtt_sample_seq_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: 0, write: True };
        tx_info_flow_rtt_sample_seq.enq(flow_rtt_sample_seq_req);
        //rg_0$x$0 <= 0$x$0;
        let flow_rtt_sample_time_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: 0, write: True };
        tx_info_flow_rtt_sample_time.enq(flow_rtt_sample_time_req);
        //rg_0$x$0 <= 0$x$0;
        let mincwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_mincwnd.enq(mincwnd_req);
        //stats_metadata$dummy <= 0; //FIXME
        //let mincwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_mincwnd.enq(mincwnd_req);
        //rg_stats_metadata$dummy <= stats_metadata$dummy;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule update_flow_retx_3dupack_response;
    let v_stats_metadata$dummy = rx_info_flow_pkts_retx.first;
    rx_info_flow_pkts_retx.deq;
    let stats_metadata$dummy = v_stats_metadata$dummy.data;
    //let v_stats_metadata$dummy = rx_info_mincwnd.first;
    rx_info_mincwnd.deq;
    //let stats_metadata$dummy = v_stats_metadata$dummy.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UpdateFlowRetx3DupackRspT {pkt: pkt, stats_metadata$dummy: stats_metadata$dummy};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_pkts_retx = toClient(tx_flow_pkts_retx.e, rx_flow_pkts_retx.e);
  //interface flow_pkts_retx = toClient(tx_flow_pkts_retx.e, rx_flow_pkts_retx.e);
  interface flow_rtt_sample_seq = toClient(tx_flow_rtt_sample_seq.e, rx_flow_rtt_sample_seq.e);
  interface flow_rtt_sample_time = toClient(tx_flow_rtt_sample_time.e, rx_flow_rtt_sample_time.e);
  interface mincwnd = toClient(tx_mincwnd.e, rx_mincwnd.e);
  //interface mincwnd = toClient(tx_mincwnd.e, rx_mincwnd.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
