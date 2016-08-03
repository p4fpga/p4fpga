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

// ====== SET_EGRESS_PORT ======

interface SetEgressPort;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkSetEgressPort  (SetEgressPort);
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
  Reg#(Bit#(64)) ing_metadata$egress_port <- mkReg(0);
  Reg#(Bit#(64)) runtime$egress_port <- mkReg(0);
  CPU cpu <- mkCPU(cons(ing_metadata$egress_port, cons(runtime$egress_port, nil)));
  IMem imem <- mkIMem("set_egress_port.hex");
  mkConnection(cpu.imem_client, imem.cpu_server);

  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['ing_metadata', 'egress_port'])]), OrderedDict([('type', 'runtime_data'), ('value', 0)])]
  rule set_egress_port_request if (cpu.not_running());
    dbprint(3, $format("set egress port"));
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetEgressPortReqT {pkt: .pkt, runtime_egress_port_8: .egress_port}: begin
        runtime$egress_port <= zeroExtend(egress_port);
        cpu.run();
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_egress_port_response;
    let pkt <- toGet(curr_packet_ff).get;
    Bit#(8) egress_port = truncate(ing_metadata$egress_port);
    BBResponse rsp = tagged SetEgressPortRspT {pkt: pkt, ing_metadata$egress_port: egress_port};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    cpu.set_verbosity(verbosity);
    imem.set_verbosity(verbosity);
  endmethod
endmodule
