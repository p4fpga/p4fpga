import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;

// ====== IPV4_PACKET ======

interface Ipv4Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkIpv4Packet  (Ipv4Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule ipv4_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Ipv4PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule ipv4_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Ipv4PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
