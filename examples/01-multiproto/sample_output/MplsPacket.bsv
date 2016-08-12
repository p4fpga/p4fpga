import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import UnionGenerated::*;
import TxRx::*;
import FIFOF::*;
import GetPut::*;
import Ethernet::*;
import Pipe::*;
import Utils::*;
import DefaultValue::*;
import CPU::*;
import IMem::*;

// ====== MPLS_PACKET ======

interface MplsPacket;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkMplsPacket  (MplsPacket);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(64)) ing_metadata$packet_type <- mkReg(0);
  CPU cpu <- mkCPU("mpls", cons(ing_metadata$packet_type, nil));
  IMem imem <- mkIMem("mpls_packet.hex");
  mkConnection(cpu.imem_client, imem.cpu_server);

  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['ing_metadata', 'packet_type'])]), OrderedDict([('type', 'hexstr'), ('value', '0x3')])]
  rule mpls_packet_request if (cpu.not_running());
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged MplsPacketReqT {pkt: .pkt}: begin
        cpu.run();
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mpls_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    Bit#(4) packet_type = truncate(ing_metadata$packet_type);
    BBResponse rsp = tagged MplsPacketRspT {pkt: pkt, ing_metadata$packet_type: packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    cpu.set_verbosity(verbosity);
    imem.set_verbosity(verbosity);
  endmethod
endmodule
