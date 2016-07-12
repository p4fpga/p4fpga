
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
typedef struct {
  Bit#(9) ingress_port;
  Bit#(32) packet_length;
  Bit#(9) egress_spec;
  Bit#(9) egress_port;
  Bit#(32) egress_instance;
  Bit#(32) instance_type;
  Bit#(32) clone_spec;
  Bit#(5) _padding;
} StandardMetadataT deriving (Bits, Eq);
instance DefaultValue#(StandardMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(StandardMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function StandardMetadataT extract_standard_metadata_t(Bit#(160) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(48) dstAddr;
  Bit#(48) srcAddr;
  Bit#(16) etherType;
} EthernetT deriving (Bits, Eq);
instance DefaultValue#(EthernetT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(EthernetT);
  defaultMask = unpack(maxBound);
endinstance
function EthernetT extract_ethernet_t(Bit#(112) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(4) version;
  Bit#(4) ihl;
  Bit#(8) diffserv;
  Bit#(16) totalLen;
  Bit#(16) identification;
  Bit#(3) flags;
  Bit#(13) fragOffset;
  Bit#(8) ttl;
  Bit#(8) protocol;
  Bit#(16) hdrChecksum;
  Bit#(32) srcAddr;
  Bit#(32) dstAddr;
} Ipv4T deriving (Bits, Eq);
instance DefaultValue#(Ipv4T);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Ipv4T);
  defaultMask = unpack(maxBound);
endinstance
function Ipv4T extract_ipv4_t(Bit#(160) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) srcPort;
  Bit#(16) dstPort;
  Bit#(32) seqNo;
  Bit#(32) ackNo;
  Bit#(4) dataOffset;
  Bit#(3) res;
  Bit#(3) ecn;
  Bit#(1) urg;
  Bit#(1) ack;
  Bit#(1) push;
  Bit#(1) rst;
  Bit#(1) syn;
  Bit#(1) fin;
  Bit#(16) window;
  Bit#(16) checksum;
  Bit#(16) urgentPtr;
} TcpT deriving (Bits, Eq);
instance DefaultValue#(TcpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(TcpT);
  defaultMask = unpack(maxBound);
endinstance
function TcpT extract_tcp_t(Bit#(160) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
} OptionsEndT deriving (Bits, Eq);
instance DefaultValue#(OptionsEndT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsEndT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsEndT extract_options_end_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
} OptionsNopT deriving (Bits, Eq);
instance DefaultValue#(OptionsNopT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsNopT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsNopT extract_options_nop_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(16) mss;
} OptionsMssT deriving (Bits, Eq);
instance DefaultValue#(OptionsMssT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsMssT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsMssT extract_options_mss_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(8) wscale;
} OptionsWscaleT deriving (Bits, Eq);
instance DefaultValue#(OptionsWscaleT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsWscaleT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsWscaleT extract_options_wscale_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
} OptionsSackT deriving (Bits, Eq);
instance DefaultValue#(OptionsSackT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsSackT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsSackT extract_options_sack_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(64) ttee;
} OptionsTsT deriving (Bits, Eq);
instance DefaultValue#(OptionsTsT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(OptionsTsT);
  defaultMask = unpack(maxBound);
endinstance
function OptionsTsT extract_options_ts_t(Bit#(80) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(8) parse_tcp_options_counter;
} MyMetadataT deriving (Bits, Eq);
instance DefaultValue#(MyMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MyMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function MyMetadataT extract_my_metadata_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(48) ingress_global_timestamp;
  Bit#(32) lf_field_list;
  Bit#(16) mcast_grp;
  Bit#(16) egress_rid;
} IntrinsicMetadataT deriving (Bits, Eq);
instance DefaultValue#(IntrinsicMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IntrinsicMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IntrinsicMetadataT extract_intrinsic_metadata_t(Bit#(112) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblForwardRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblDropRspT;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(48)) ethernet$dstAddr;
} MetadataT deriving (Bits, Eq);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
// ====== PARSER ======

typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseIpv4,
  StateParseTcp,
  StateParseTcpOptions,
  StateParseEnd,
  StateParseNop,
  StateParseMss,
  StateParseWscale,
  StateParseSack,
  StateParseTs
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  PulseWire w_parse_tcp_options_parse_mss <- mkPulseWireOR();
  PulseWire w_parse_mss_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_ipv4_start <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_sack <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_nop <- mkPulseWireOR();
  PulseWire w_parse_sack_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_nop_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_ts_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_ethernet_start <- mkPulseWireOR();
  PulseWire w_parse_end_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_wscale_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_wscale <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_start <- mkPulseWireOR();
  PulseWire w_parse_tcp_start <- mkPulseWireOR();
  PulseWire w_parse_tcp_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_ts <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_end <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
  Reg#(Bit#(8)) my_metadata$parse_tcp_options_counter[2] <- mkCReg(2, 0);
  Wire#(Bit#(8)) w_parse_tcp_options <- mkDWire(0);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  PulseWire parse_done <- mkPulseWire();
  PulseWire w_parse_header_done <- mkPulseWireOR();
  PulseWire w_load_header <- mkPulseWireOR();
  Reg#(ParserState) rg_parse_state[3] <- mkCReg(3, StateStart);
  Reg#(Bit#(32)) rg_next_header_len[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_shift_amt[3] <- mkCReg(3, 0);
  //Reg#(Bit#(512)) rg_tmp <- mkReg(0);
  Reg#(Bit#(512)) rg_tmp[2] <- mkCReg(2, 0);
  Reg#(Bool) rg_dequeue_data[3] <- mkCReg(3, False);
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
  function Action fetch_next_header1(Bit#(32) len);
    action
      rg_next_header_len[1] <= len;
      w_parse_header_done.send();
    endaction
  endfunction
  function Action move_shift_amt(Bit#(32) len);
    action
      rg_shift_amt[0] <= rg_shift_amt[0] + len;
      w_load_header.send();
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
  function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
    action
      let v = {etherType};
      if (v == 'h0800) begin
        dbg3($format("transit to parse_ipv4"));
        w_parse_ethernet_parse_ipv4.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ethernet_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
    action
      let v = {protocol};
      if (v == 'h06) begin
        dbg3($format("transit to parse_tcp"));
        w_parse_ipv4_parse_tcp.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ipv4_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_tcp(Bit#(1) syn);
    action
      let v = {syn};
      if (v == 'h01) begin
        dbg3($format("transit to parse_tcp_options"));
        w_parse_tcp_parse_tcp_options.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_tcp_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_tcp_options(Bit#(8) parse_tcp_options_counter, Bit#(8) current);
    action
      let v = {parse_tcp_options_counter, current};
      dbg3($format("%h", v));
      if ((v & 'hff00) == 'h0000) begin
        dbg3($format("transit to start"));
        w_parse_tcp_options_start.send();
      end
      else if ((v & 'h00ff) == 'h0000) begin
        dbg3($format("transit to parse_end"));
        w_parse_tcp_options_parse_end.send();
      end
      else if ((v & 'h00ff) == 'h0001) begin
        dbg3($format("transit to parse_nop"));
        w_parse_tcp_options_parse_nop.send();
      end
      else if ((v & 'h00ff) == 'h0002) begin
        dbg3($format("transit to parse_mss"));
        w_parse_tcp_options_parse_mss.send();
      end
      else if ((v & 'h00ff) == 'h0003) begin
        dbg3($format("transit to parse_wscale"));
        w_parse_tcp_options_parse_wscale.send();
      end
      else if ((v & 'h00ff) == 'h0004) begin
        dbg3($format("transit to parse_sack"));
        w_parse_tcp_options_parse_sack.send();
      end
      else if ((v & 'h00ff) == 'h0008) begin
        dbg3($format("transit to parse_ts"));
        w_parse_tcp_options_parse_ts.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_end();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_end_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_nop();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_nop_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_mss();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_mss_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_wscale();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_wscale_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_sack();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_sack_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_ts();
    action
      dbg3($format("transit to parse_tcp_options"));
      w_parse_ts_parse_tcp_options.send();
    endaction
  endfunction
  rule rl_data_ff_load if ((rg_buffered[2] < rg_next_header_len[2] + 8) && (rg_parse_state[2] != StateStart) && (w_parse_header_done || w_load_header));
    rg_buffered[2] <= rg_buffered[2] + 128;
    data_in_ff.deq;
    rg_dequeue_data[2] <= True;
    dbg3($format("dequeue data %d %d", rg_buffered[2], rg_next_header_len[2]));
  endrule

  rule rl_data_ff_idle if ((rg_buffered[2] > rg_next_header_len[2]) && (rg_parse_state[2] != StateStart) && (w_parse_header_done || w_load_header));
    rg_dequeue_data[2] <= False;
  endrule

  rule rl_start_state_deq if (rg_parse_state[2] == StateStart && sop_this_cycle && !w_parse_header_done);
    let v = data_in_ff.first;
    rg_parse_state[2] <= StateParseEthernet;
    rg_buffered[2] <= 128;
    rg_shift_amt[2] <= 0;
    rg_dequeue_data[2] <= True;
  endrule

  rule rl_start_state_idle if (rg_parse_state[2] == StateStart && (!sop_this_cycle || w_parse_header_done));
    data_in_ff.deq;
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ethernet_load if ((rg_parse_state[0] == StateParseEthernet) && (rg_buffered[0] < 112));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ethernet_extract if ((rg_parse_state[0] == StateParseEthernet) && (rg_buffered[0] >= 112));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    let ethernet_t = extract_ethernet_t(truncate(data));
    compute_next_state_parse_ethernet(ethernet_t.etherType);
    rg_tmp[0] <= zeroExtend(data >> 112);
    succeed_and_next(112);
    dbg3($format("extract %s %h", "parse_ethernet", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_ethernet_parse_ipv4, rl_parse_ethernet_start" *)
  rule rl_parse_ethernet_parse_ipv4 if ((rg_parse_state[0] == StateParseEthernet) && (w_parse_ethernet_parse_ipv4));
    rg_parse_state[0] <= StateParseIpv4;
    dbg3($format("%s -> %s", "parse_ethernet", "parse_ipv4"));
    fetch_next_header(160);
  endrule

  rule rl_parse_ethernet_start if ((rg_parse_state[0] == StateParseEthernet) && (w_parse_ethernet_start));
    rg_parse_state[0] <= StateStart;
    dbg3($format("%s -> %s", "parse_ethernet", "start"));
    fetch_next_header(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv4_load if ((rg_parse_state[0] == StateParseIpv4) && (rg_buffered[0] < 160));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv4_extract if ((rg_parse_state[0] == StateParseIpv4) && (rg_buffered[0] >= 160));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    let ipv4_t = extract_ipv4_t(truncate(data));
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(160);
    dbg3($format("extract %s %h", "parse_ipv4", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_ipv4_parse_tcp, rl_parse_ipv4_start" *)
  rule rl_parse_ipv4_parse_tcp if ((rg_parse_state[0] == StateParseIpv4) && (w_parse_ipv4_parse_tcp));
    rg_parse_state[0] <= StateParseTcp;
    dbg3($format("%s -> %s", "parse_ipv4", "parse_tcp"));
    fetch_next_header(160);
  endrule

  rule rl_parse_ipv4_start if ((rg_parse_state[0] == StateParseIpv4) && (w_parse_ipv4_start));
    rg_parse_state[0] <= StateStart;
    dbg3($format("%s -> %s", "parse_ipv4", "start"));
    fetch_next_header(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_tcp_load if ((rg_parse_state[0] == StateParseTcp) && (rg_buffered[0] < 160));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_tcp_extract if ((rg_parse_state[0] == StateParseTcp) && (rg_buffered[0] >= 160));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    let tcp_t = extract_tcp_t(truncate(data));
    Bit#(8) tcp$dataOffset = zeroExtend(tcp_t.dataOffset);
    let v = ( ( tcp$dataOffset * 'h4 ) - 20 );
    my_metadata$parse_tcp_options_counter[0] <= zeroExtend(v);
    compute_next_state_parse_tcp(tcp_t.syn);
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(160);
    dbg3($format("extract %s %h", "parse_tcp", rg_dequeue_data[0]));
  endrule

  //(* mutually_exclusive="rl_parse_tcp_parse_tcp_options, rl_parse_tcp_start" *)
  rule rl_parse_tcp_parse_tcp_options if ((w_parse_tcp_parse_tcp_options));
    Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
    Bit#(8) lookahead = pack(takeAt(0, buffer));
    dbg3($format("look ahead %h, %h", lookahead, rg_tmp[1]));
    compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
    rg_parse_state[0] <= StateParseTcpOptions;
    dbg3($format("metadata counter %h", my_metadata$parse_tcp_options_counter[1]));
    dbg3($format("%s -> %s", "parse_tcp", "parse_tcp_options"));
    fetch_next_header(0);
  endrule

  //rule rl_parse_tcp_start if ((w_parse_tcp_start));
  //  rg_parse_state[0] <= StateStart;
  //  dbg3($format("%s -> %s", "parse_tcp", "start"));
  //  fetch_next_header(0);
  //endrule

  (* mutually_exclusive="rl_parse_tcp_options_start, rl_parse_tcp_options_parse_end, rl_parse_tcp_options_parse_nop, rl_parse_tcp_options_parse_mss, rl_parse_tcp_options_parse_wscale, rl_parse_tcp_options_parse_sack, rl_parse_tcp_options_parse_ts" *)
  rule rl_parse_tcp_options_start if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_start));
    rg_parse_state[1] <= StateStart;
    dbg3($format("%s -> %s", "parse_tcp_options", "start"));
    fetch_next_header1(0);
  endrule

  rule rl_parse_tcp_options_parse_end if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_end));
    rg_parse_state[1] <= StateParseEnd;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_end"));
    fetch_next_header1(8);
  endrule

  rule rl_parse_tcp_options_parse_nop if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_nop));
    rg_parse_state[1] <= StateParseNop;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_nop"));
    fetch_next_header1(8);
  endrule

  rule rl_parse_tcp_options_parse_mss if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_mss));
    rg_parse_state[1] <= StateParseMss;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_mss"));
    fetch_next_header1(32);
  endrule

  rule rl_parse_tcp_options_parse_wscale if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_wscale));
    rg_parse_state[1] <= StateParseWscale;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_wscale"));
    fetch_next_header1(24);
  endrule

  rule rl_parse_tcp_options_parse_sack if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_sack));
    rg_parse_state[1] <= StateParseSack;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_sack"));
    fetch_next_header1(16);
  endrule

  rule rl_parse_tcp_options_parse_ts if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_ts));
    rg_parse_state[1] <= StateParseTs;
    dbg3($format("%s -> %s", "parse_tcp_options", "parse_ts"));
    fetch_next_header1(80);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_end_load if ((rg_parse_state[0] == StateParseEnd) && (rg_buffered[0] < 8 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_end_extract if ((rg_parse_state[0] == StateParseEnd) && (rg_buffered[0] >= 8 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_end();
    rg_tmp[0] <= zeroExtend(data >> 8);
    succeed_and_next(8);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 1;
    dbg3($format("extract %s %h", "parse_end", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_end_parse_tcp_options" *)
  rule rl_parse_end_parse_tcp_options if ((rg_parse_state[0] == StateParseEnd) && (w_parse_end_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_end", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_nop_load if ((rg_parse_state[0] == StateParseNop) && (rg_buffered[0] < 8 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_nop_extract if ((rg_parse_state[0] == StateParseNop) && (rg_buffered[0] >= 8 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_nop();
    rg_tmp[0] <= zeroExtend(data >> 8);
    succeed_and_next(8);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 1;
    dbg3($format("extract %s %h", "parse_nop", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_nop_parse_tcp_options" *)
  rule rl_parse_nop_parse_tcp_options if ((rg_parse_state[0] == StateParseNop) && (w_parse_nop_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_nop", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_mss_load if ((rg_parse_state[0] == StateParseMss) && (rg_buffered[0] < 32 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_mss_extract if ((rg_parse_state[0] == StateParseMss) && (rg_buffered[0] >= 32 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_mss();
    rg_tmp[0] <= zeroExtend(data >> 32);
    succeed_and_next(32);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 4;
    dbg3($format("extract %s %h", "parse_mss", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_mss_parse_tcp_options" *)
  rule rl_parse_mss_parse_tcp_options if ((rg_parse_state[0] == StateParseMss) && (w_parse_mss_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_mss", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_wscale_load if ((rg_parse_state[0] == StateParseWscale) && (rg_buffered[0] < 24 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_wscale_extract if ((rg_parse_state[0] == StateParseWscale) && (rg_buffered[0] >= 24 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_wscale();
    rg_tmp[0] <= zeroExtend(data >> 24);
    succeed_and_next(24);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 3;
    dbg3($format("extract %s %h", "parse_wscale", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_wscale_parse_tcp_options" *)
  rule rl_parse_wscale_parse_tcp_options if ((rg_parse_state[0] == StateParseWscale) && (w_parse_wscale_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_wscale", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_sack_load if ((rg_parse_state[0] == StateParseSack) && (rg_buffered[0] < 16 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_sack_extract if ((rg_parse_state[0] == StateParseSack) && (rg_buffered[0] >= 16 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_sack();
    rg_tmp[0] <= zeroExtend(data >> 16);
    succeed_and_next(16);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 2;
    dbg3($format("extract %s %h", "parse_sack", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_sack_parse_tcp_options" *)
  rule rl_parse_sack_parse_tcp_options if ((rg_parse_state[0] == StateParseSack) && (w_parse_sack_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_sack", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ts_load if ((rg_parse_state[0] == StateParseTs) && (rg_buffered[0] < 80 + 8));
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, rg_tmp[0]);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
    dbg3($format("load tcp option ts %h", data));
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ts_extract if ((rg_parse_state[0] == StateParseTs) && (rg_buffered[0] >= 80 + 8));
    let data = rg_tmp[0];
    if (rg_dequeue_data[0] == True) begin
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(rg_parse_state[0], rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_ts();
    rg_tmp[0] <= zeroExtend(data >> 80);
    succeed_and_next(80);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 10;
    dbg3($format("extract %s %h", "parse_ts", rg_dequeue_data[0]));
  endrule

  (* mutually_exclusive="rl_parse_ts_parse_tcp_options" *)
  rule rl_parse_ts_parse_tcp_options if ((rg_parse_state[0] == StateParseTs) && (w_parse_ts_parse_tcp_options));
    w_parse_tcp_parse_tcp_options.send();
    dbg3($format("%s -> %s", "parse_ts", "parse_tcp_options"));
    //fetch_next_header(8);
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule

// ====== DEPARSER ======

typedef enum {
  StateDeparseStart,
  StateEthernet,
  StateIpv4,
  StateTcp,
  StateOptionsMss,
  StateOptionsSack,
  StateOptionsTs,
  StateOptionsNop0,
  StateOptionsNop1,
  StateOptionsNop2,
  StateOptionsWscale,
  StateOptionsEnd
} DeparserState deriving (Bits, Eq);
interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  interface Put#(int) verbosity;
  method DeparserPerfRec read_perf_info ();
endinterface
module mkDeparser  (Deparser);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(EtherData) data_out_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  Reg#(Bit#(128)) rg_buff <- mkReg(0);
  Reg#(DeparserState) rg_deparse_state <- mkReg(StateDeparseStart);
  let din = data_in_ff.first;
  let meta = meta_in_ff.first;
  function Action report_deparse_action(DeparserState state, Bit#(32) offset);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%d) Deparse State %h offset %h", $time, state, offset);
      end
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= offset;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= 0;
    endaction
  endfunction
  function DeparserState compute_next_state(DeparserState state);
    DeparserState nextState = StateDeparseStart;
    return nextState;
  endfunction
  function Bit#(l) read_data(UInt#(8) lhs, UInt#(8) rhs)
   provisos (Add#(a__, l, 128));
    Bit#(l) ldata = truncate(din.data) << (fromInteger(valueOf(l))-lhs);
    Bit#(l) rdata = truncate(rg_buff) >> (fromInteger(valueOf(l))-rhs);
    Bit#(l) cdata = ldata | rdata;
    return cdata;
  endfunction
  function Bit#(max) create_mask(UInt#(max) count);
    Bit#(max) v = 1 << count - 1;
    return v;
  endfunction
  rule rl_start_state if (rg_deparse_state == StateDeparseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_deparse_state <= StateEthernet;
    end
    else begin
      data_in_ff.deq;
      data_out_ff.enq(v);
    end
  endrule

  function Rules build_deparse_rule_no_opt(DeparserState state, int offset, Tuple2#(Bit#(n), Bit#(n)) m, UInt#(8) clen, UInt#(8) plen)
   provisos (Mul#(TDiv#(n, 8), 8, n), Add#(a__, n, 128));
    Rules d = 
    rules
      rule rl_deparse if ((rg_deparse_state == state) && (rg_offset == unpack(pack(offset))));
        report_deparse_action(rg_deparse_state, rg_offset);
        match {.meta, .mask} = m;
        Vector#(n, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(meta)));
        Vector#(n, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(mask)));
        Bit#(n) curr_data = read_data (clen, plen);
        $display ("read_data %h", curr_data);
        let data = apply_changes (curr_data, pack(curr_meta), pack(curr_mask));
        let data_this_cycle = EtherData { sop: din.sop, eop: din.eop, data: zeroExtend(data), mask: create_mask(cExtend(fromInteger(valueOf(n)))) };
        data_out_ff.enq (data_this_cycle);
        DeparserState next_state = compute_next_state(state);
        $display ("next_state %h", next_state);
        rg_deparse_state <= next_state;
        rg_buff <= din.data;
        // apply header removal by marking mask zero
        // apply added header by setting field at offset.
        succeed_and_next (rg_offset + cExtend(clen) + cExtend(plen));
      endrule

    endrules;
    return d;
  endfunction
  interface metadata = toPipeIn(meta_in_ff);
  interface PktWriteServer writeServer;
    interface writeData = toPut(data_in_ff);
  endinterface
  interface PktWriteClient writeClient;
    interface writeData = toGet(data_out_ff);
  endinterface
  interface verbosity = toPut(cr_verbosity_ff);
endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
} BBResponse deriving (Bits, Eq);

// ====== _DROP ======

interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkDrop  (Drop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule _drop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DropReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule _drop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged DropRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== FORWARD ======

interface Forward;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkForward  (Forward);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(9)) standard_metadata$egress_spec <- mkReg(0);
  rule forward_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ForwardReqT {pkt: .pkt, runtime_port: .runtime_port}: begin
        standard_metadata$egress_spec <= runtime_port;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule forward_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ForwardRspT {pkt: pkt, standard_metadata$egress_spec: standard_metadata$egress_spec};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== FORWARD_TBL ======

typedef struct {
  Bit#(48) ethernet$dstAddr;
  Bit#(6) padding;
} ForwardTblReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_FORWARD_TBL,
  FORWARD,
  DROP
} ForwardTblActionT deriving (Bits, Eq);
typedef struct {
  ForwardTblActionT _action;
  Bit#(9) runtime_port;
} ForwardTblRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(11)) matchtable_read_forward_tbl(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_forward_tbl(Bit#(54) msgtype, Bit#(11) data);
instance MatchTableSim#(0, 54, 11);
  function ActionValue#(Bit#(11)) matchtable_read(Bit#(0) id, Bit#(54) key);
    actionvalue
      let v <- matchtable_read_forward_tbl(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) id, Bit#(54) key, Bit#(11) data);
    action
      matchtable_write_forward_tbl(key, data);
    endaction
  endfunction
endinstance
interface ForwardTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkForwardTbl  (ForwardTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(0, 1024, SizeOf#(ForwardTblReqT), SizeOf#(ForwardTblRspT)) matchTable <- mkMatchTable();
  Vector#(2, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(2) readyChannel = -1;
  for (Integer i=1; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
  rule rl_handle_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    let ethernet$dstAddr = fromMaybe(?, meta.ethernet$dstAddr);
    ForwardTblReqT req = ForwardTblReqT {ethernet$dstAddr: ethernet$dstAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ForwardTblRspT resp = unpack(data);
      case (resp._action) matches
        FORWARD: begin
          BBRequest req = tagged ForwardReqT {pkt: pkt, runtime_port: resp.runtime_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
      endcase
      // forward metadata to next stage.
      metadata_ff[1].enq(meta);
    end
  endrule

  rule rl_handle_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff[1]).get;
    case (v) matches
      tagged ForwardRspT {pkt: .pkt, standard_metadata$egress_spec: .standard_metadata$egress_spec}: begin
        meta.standard_metadata$egress_spec = tagged Valid standard_metadata$egress_spec;
        MetadataResponse rsp = tagged ForwardTblForwardRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged ForwardTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) forward_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  ForwardTbl forward_tbl <- mkForwardTbl();
  mkConnection(toClient(forward_tbl_req_ff, forward_tbl_rsp_ff), forward_tbl.prev_control_state_0);
  // Basic Blocks
  Forward forward_0 <- mkForward();
  Drop _drop_0 <- mkDrop();
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_0, forward_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_1, _drop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    forward_tbl_req_ff.enq(req);
  endrule

  rule forward_tbl_next_state if (forward_tbl_rsp_ff.notEmpty);
    forward_tbl_rsp_ff.deq;
    let _rsp = forward_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged ForwardTblForwardRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged ForwardTblDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule

// ====== EGRESS ======

interface Egress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    next_req_ff.enq(req);
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule
// Copyright (c) 2016 P4FPGA Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
