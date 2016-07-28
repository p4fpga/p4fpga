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

// ====== UPDATE_FLOW_DUPACK ======

interface UpdateFlowDupack;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_dup;
  //interface Client#(RegRequest#(2, 32), RegResponse#(32)) flow_pkts_dup;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkUpdateFlowDupack  (UpdateFlowDupack);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_flow_pkts_dup <- mkTX;
  RX #(RegResponse#(32)) rx_flow_pkts_dup <- mkRX;
  let tx_info_flow_pkts_dup = tx_flow_pkts_dup.u;
  let rx_info_flow_pkts_dup = rx_flow_pkts_dup.u;
  //TX #(RegRequest#(2, 32)) tx_flow_pkts_dup <- mkTX;
  //RX #(RegResponse#(32)) rx_flow_pkts_dup <- mkRX;
  //let tx_info_flow_pkts_dup = tx_flow_pkts_dup.u;
  //let rx_info_flow_pkts_dup = rx_flow_pkts_dup.u;
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  rule update_flow_dupack_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UpdateFlowDupackReqT {pkt: .pkt, stats_metadata$dummy: .stats_metadata$dummy, stats_metadata$flow_map_index: .stats_metadata$flow_map_index}: begin
        let flow_pkts_dup_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: ?, write: False };
        tx_info_flow_pkts_dup.enq(flow_pkts_dup_req);
        //let flow_pkts_dup_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        //tx_info_flow_pkts_dup.enq(flow_pkts_dup_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule update_flow_dupack_response;
    let v_stats_metadata$dummy = rx_info_flow_pkts_dup.first;
    rx_info_flow_pkts_dup.deq;
    let stats_metadata$dummy = v_stats_metadata$dummy.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UpdateFlowDupackRspT {pkt: pkt, stats_metadata$dummy: stats_metadata$dummy};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface flow_pkts_dup = toClient(tx_flow_pkts_dup.e, rx_flow_pkts_dup.e);
  //interface flow_pkts_dup = toClient(tx_flow_pkts_dup.e, rx_flow_pkts_dup.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
