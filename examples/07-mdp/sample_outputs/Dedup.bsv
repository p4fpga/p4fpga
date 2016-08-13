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
import CountingFilter::*;
import Lists::*;

// ====== DEDUP ======

interface Dedup;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkDedup  (Dedup);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(64)) mdp$msgSeqNum <- mkReg('hfff);
  CPU cpu <- mkCPU("dedup", list1(mdp$msgSeqNum));
  COUNTING_FILTER#(Bit#(32), 1) filter <- mkCountingFilter();

  IMem imem <- mkIMem("dedup.hex");
  mkConnection(cpu.imem_client, imem.cpu_server);

  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['mdp', 'msgSeqNum'])]), OrderedDict([('type', 'hexstr'), ('value', '0x0')])]
  rule dedup_request if (cpu.not_running());
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DedupReqT {pkt: .pkt, mdp$msgSeqNum: .msgSeqNum}: begin
        cpu.run();
        curr_packet_ff.enq(pkt);
        let present = filter.test(msgSeqNum);
        if (present matches tagged Valid .hash) begin
           dbprint(3, $format("set bloom filter ", fshow(present)));
           filter.set(hash);
        end
        mdp$msgSeqNum <= zeroExtend(msgSeqNum);
      end
    endcase
  endrule

  rule dedup_response if (cpu.not_running());
    let pkt <- toGet(curr_packet_ff).get;
    Bit#(32) msgSeqNum = truncate(mdp$msgSeqNum);
    BBResponse rsp = tagged DedupRspT {pkt: pkt, mdp$msgSeqNum: msgSeqNum};
    let notSet = filter.notSet(truncate(mdp$msgSeqNum));
    dbprint(3, $format("entry not set? ", fshow(notSet)));
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    cpu.set_verbosity(verbosity);
    imem.set_verbosity(verbosity);
    filter.set_verbosity(verbosity);
  endmethod
endmodule
