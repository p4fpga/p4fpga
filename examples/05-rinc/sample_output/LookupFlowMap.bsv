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

// ====== LOOKUP_FLOW_MAP ======

interface LookupFlowMap;
  interface Client#(RegRequest#(1, 2), RegResponse#(2)) check_map;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkLookupFlowMap  (LookupFlowMap);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(1, 2)) tx_check_map <- mkTX;
  RX #(RegResponse#(2)) rx_check_map <- mkRX;
  let tx_info_check_map = tx_check_map.u;
  let rx_info_check_map = rx_check_map.u;
  Reg#(Bit#(2)) rg_stats_metadata$flow_map_index <- mkReg(0);
  rule lookup_flow_map_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged LookupFlowMapReqT {pkt: .pkt, stats_metadata$flow_map_index: .stats_metadata$flow_map_index}: begin
        let check_map_req = RegRequest { addr: 0, data: stats_metadata$flow_map_index, write: True };
        tx_info_check_map.enq(check_map_req);
        rg_stats_metadata$flow_map_index <= stats_metadata$flow_map_index;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule lookup_flow_map_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged LookupFlowMapRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface check_map = toClient(tx_check_map.e, rx_check_map.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
