import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;

// ====== SET_DMAC ======

interface SetDmac;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkSetDmac  (SetDmac);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(48)) ethernet$dstAddr <- mkReg(0);
  rule set_dmac_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetDmacReqT {pkt: .pkt, runtime_dmac_48: .runtime_dmac_48}: begin
        ethernet$dstAddr <= runtime_dmac_48;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_dmac_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetDmacRspT {pkt: pkt, ethernet$dstAddr: ethernet$dstAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
