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

// ====== SET_NHOP ======

interface SetNhop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkSetNhop  (SetNhop);
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
  Reg#(Bit#(64)) routing_metadata$nhop_ipv4 <- mkReg(0);
  Reg#(Bit#(64)) standard_metadata$egress_port <- mkReg(0);
  Reg#(Bit#(64)) ipv4$ttl <- mkReg(0);
  CPU cpu <- mkCPU("set_nhop", cons(routing_metadata$nhop_ipv4,cons(standard_metadata$egress_port,cons(ipv4$ttl, nil))));
  IMem imem <- mkIMem("set_nhop.hex");
  mkConnection(cpu.imem_client, imem.cpu_server);

  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['routing_metadata', 'nhop_ipv4'])]), OrderedDict([('type', 'runtime_data'), ('value', 0)])]
  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['standard_metadata', 'egress_port'])]), OrderedDict([('type', 'runtime_data'), ('value', 1)])]
  // INST: <primitives.AddToField object at 0x2b28dd5f2910>
  rule set_nhop_request if (cpu.not_running());
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetNhopReqT {pkt: .pkt, runtime_port_9: .runtime_port, runtime_nhop_ipv4_32: .runtime_nhop_ipv4}: begin
        cpu.run();
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_nhop_response;
    let pkt <- toGet(curr_packet_ff).get;
    Bit#(32) nhop_ipv4 = truncate(routing_metadata$nhop_ipv4);
    Bit#(9) egress_port = truncate(standard_metadata$egress_port);
    Bit#(8) ttl = truncate(ipv4$ttl);
    BBResponse rsp = tagged SetNhopRspT {pkt: pkt, ipv4$ttl: ttl, standard_metadata$egress_port: egress_port, routing_metadata$nhop_ipv4: nhop_ipv4};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    cpu.set_verbosity(verbosity);
    imem.set_verbosity(verbosity);
  endmethod
endmodule
