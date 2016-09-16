// ====== PARSER ======
import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import Connectable::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import MIMO::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import Register::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;
import l2forwarding::*;

typedef enum {
  StateDefault,
  StateStart
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  FIFO#(ParserState) parse_state_ethernet_ff <- mkPipelineFIFO();
  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(Bool) parse_done[2] <- mkCReg(2, True);
  PulseWire w_parse_header_done <- mkPulseWireOR();
  PulseWire w_start_default <- mkPulseWireOR();
  Reg#(Bit#(32)) rg_next_header_len[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_shift_amt[3] <- mkCReg(3, 0);
  Reg#(Bit#(512)) rg_tmp <- mkReg(0);
  FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);

  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  function Action dbg3(Fmt msg);
    action
      if (cr_verbosity[0] > 3) begin
        $display("(%0d) ", $time, msg);
      end
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) offset);
    action
      rg_buffered[0] <= rg_buffered[0] - offset;
      rg_shift_amt[0] <= rg_buffered[0] - offset;
      dbg3($format("succeed_and_next subtract offset = %d shift_amt/buffered = %d", offset, rg_buffered[0] - offset));
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      rg_next_header_len[0] <= len;
      w_parse_header_done.send();
    endaction
  endfunction
  function Action move_shift_amt(Bit#(32) len);
    action
      rg_shift_amt[0] <= rg_shift_amt[0] + len;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      rg_buffered[0] <= 0;
    endaction
  endfunction
  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data, Bit#(512) buff);
    action
      if (cr_verbosity[0] > 3) begin
        $display("(%0d) Parser State %h buffered %d, %h, %h", $time, state, offset, data, buff);
      end
    endaction
  endfunction
  let sop_this_cycle = data_in_ff.first.sop;
  let eop_this_cycle = data_in_ff.first.eop;
  let data_this_cycle = data_in_ff.first.data;
  function Action compute_next_state_start();
    action
      dbg3($format("transit to default"));
      w_start_default.send();
    endaction
  endfunction

  // Rules to manage data_in_ff
  rule rl_data_ff_load if (!parse_done[1] && (rg_buffered[1] < rg_next_header_len[1]) && (w_parse_header_done));
    rg_buffered[1] <= rg_buffered[1] + 128;
    data_in_ff.deq;
    data_ff.enq(tagged Valid data_this_cycle);
    dbg3($format("dequeue data %d %d", rg_buffered[1], rg_next_header_len[1]));
  endrule

  rule rl_start_state_deq if (parse_done[1] && sop_this_cycle && !w_parse_header_done);
    data_ff.enq(tagged Valid data_this_cycle);
    rg_buffered[1] <= 128;
    rg_shift_amt[1] <= 0;
    parse_state_ethernet_ff.enq(StateStart);
    parse_done[1] <= False;
    dbg3($format("start state deq"));
  endrule

  rule rl_start_state_idle if (parse_done[1] && (!sop_this_cycle || w_parse_header_done));
    data_in_ff.deq;
  endrule

  // Rules to manage ethernet parser
  (* fire_when_enabled *)
  rule rl_ethernet_load if ((parse_state_ethernet_ff.first == StateStart) && (rg_buffered[0] < 112));
    report_parse_action(parse_state_ethernet_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
    if (isValid(data_ff.first)) begin
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;
      data_ff.deq;
      rg_tmp <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_ethernet_extract if ((parse_state_ethernet_ff.first == StateStart) && (rg_buffered[0] >= 112));
    let data = rg_tmp;
    // unguarded fifo
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;
    end
    report_parse_action(parse_state_ethernet_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_start();
    rg_tmp <= zeroExtend(data >> 112);
    succeed_and_next(112);
    dbg3($format("extract %s %h", "start", data));
  endrule

  (* mutually_exclusive="rl_ethernet_default" *)
  rule rl_ethernet_default if ((parse_state_ethernet_ff.first == StateStart) && (w_start_default));
    parse_state_ethernet_ff.deq;
    dbg3($format("%s -> %s", "start", "default"));
    fetch_next_header(0);
    parse_done[0] <= True;
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule
