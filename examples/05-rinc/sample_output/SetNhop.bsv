import ClientServer::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;

// ====== SET_NHOP ======

interface SetNhop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
(* synthesize *)
module mkSetNhop  (SetNhop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(32)) routing_metadata$nhop_ipv4 <- mkReg(0);
  Reg#(Bit#(9)) standard_metadata$egress_spec <- mkReg(0);
  Reg#(Bit#(8)) ipv4$ttl <- mkReg(0);
  rule set_nhop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetNhopReqT {pkt: .pkt, runtime_port_9: .runtime_port_9, runtime_nhop_ipv4_32: .runtime_nhop_ipv4_32}: begin
        routing_metadata$nhop_ipv4 <= runtime_nhop_ipv4_32;
        standard_metadata$egress_spec <= runtime_port_9;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_nhop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetNhopRspT {pkt: pkt, ipv4$ttl: ipv4$ttl, standard_metadata$egress_spec: standard_metadata$egress_spec, routing_metadata$nhop_ipv4: routing_metadata$nhop_ipv4};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
