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

// ====== INCREASE_MINCWND ======

interface IncreaseMincwnd;
  interface Client#(RegRequest#(2, 32), RegResponse#(32)) mincwnd;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkIncreaseMincwnd  (IncreaseMincwnd);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(2, 32)) tx_mincwnd <- mkTX;
  RX #(RegResponse#(32)) rx_mincwnd <- mkRX;
  let tx_info_mincwnd = tx_mincwnd.u;
  let rx_info_mincwnd = rx_mincwnd.u;
  Reg#(Bit#(32)) rg_stats_metadata$dummy <- mkReg(0);
  rule increase_mincwnd_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged IncreaseMincwndReqT {pkt: .pkt, stats_metadata$dummy: .stats_metadata$dummy, stats_metadata$flow_map_index: .stats_metadata$flow_map_index}: begin
        let mincwnd_req = RegRequest { addr: truncate(stats_metadata$flow_map_index), data: stats_metadata$dummy, write: True };
        tx_info_mincwnd.enq(mincwnd_req);
        rg_stats_metadata$dummy <= stats_metadata$dummy;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule increase_mincwnd_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged IncreaseMincwndRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface mincwnd = toClient(tx_mincwnd.e, rx_mincwnd.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
