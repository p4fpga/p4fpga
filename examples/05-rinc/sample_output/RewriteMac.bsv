import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;

// ====== REWRITE_MAC ======

interface RewriteMac;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkRewriteMac  (RewriteMac);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(48)) ethernet$srcAddr <- mkReg(0);
  rule rewrite_mac_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged RewriteMacReqT {pkt: .pkt, runtime_smac_48: .runtime_smac_48}: begin
        ethernet$srcAddr <= runtime_smac_48;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule rewrite_mac_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged RewriteMacRspT {pkt: pkt, ethernet$srcAddr: ethernet$srcAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
