import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;

// ====== IPV6_PACKET ======

interface Ipv6Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkIpv6Packet  (Ipv6Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule ipv6_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Ipv6PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h2;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule ipv6_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Ipv6PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
