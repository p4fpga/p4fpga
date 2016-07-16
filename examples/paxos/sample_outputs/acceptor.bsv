
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
  Bit#(16) hrd;
  Bit#(16) pro;
  Bit#(8) hln;
  Bit#(8) pln;
  Bit#(16) op;
  Bit#(48) sha;
  Bit#(32) spa;
  Bit#(48) tha;
  Bit#(32) tpa;
} ArpT deriving (Bits, Eq);
instance DefaultValue#(ArpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(ArpT);
  defaultMask = unpack(maxBound);
endinstance
function ArpT extract_arp_t(Bit#(224) data);
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
  Bit#(4) version;
  Bit#(8) trafficClass;
  Bit#(20) flowLabel;
  Bit#(16) payloadLen;
  Bit#(8) nextHdr;
  Bit#(8) hopLimit;
  Bit#(128) srcAddr;
  Bit#(128) dstAddr;
} Ipv6T deriving (Bits, Eq);
instance DefaultValue#(Ipv6T);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Ipv6T);
  defaultMask = unpack(maxBound);
endinstance
function Ipv6T extract_ipv6_t(Bit#(320) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) srcPort;
  Bit#(16) dstPort;
  Bit#(16) length_;
  Bit#(16) checksum;
} UdpT deriving (Bits, Eq);
instance DefaultValue#(UdpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(UdpT);
  defaultMask = unpack(maxBound);
endinstance
function UdpT extract_udp_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) msgtype;
  Bit#(32) inst;
  Bit#(16) rnd;
  Bit#(16) vrnd;
  Bit#(16) acptid;
  Bit#(256) paxosval;
} PaxosT deriving (Bits, Eq);
instance DefaultValue#(PaxosT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(PaxosT);
  defaultMask = unpack(maxBound);
endinstance
function PaxosT extract_paxos_t(Bit#(352) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) round;
  Bit#(1) set_drop;
  Bit#(7) _padding;
} IngressMetadataT deriving (Bits, Eq);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IngressMetadataT extract_ingress_metadata_t(Bit#(24) data);
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
  } AcceptorTblHandle1ARspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } AcceptorTblHandle2ARspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } AcceptorTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblForwardRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RoundTblReadRoundRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DropTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DropTblNopRspT;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(16)) paxos$rnd;
  Maybe#(Bit#(32)) paxos$inst;
  Maybe#(Bit#(16)) paxos$msgtype;
  Maybe#(Bit#(16)) udp$checksum;
  Maybe#(Bit#(16)) paxos$acptid;
  Maybe#(Bit#(16)) paxos$vrnd;
  Maybe#(Bit#(16)) udp$dstPort;
  Maybe#(Bit#(256)) paxos$paxosval;
  Maybe#(Bit#(16)) runtime_learner_port;
  Maybe#(Bit#(1)) local_metadata$set_drop;
  Maybe#(Bit#(16)) local_metadata$round;
  Maybe#(Bit#(9)) standard_metadata$ingress_port;
  Maybe#(void) valid_ipv4;
  Maybe#(void) valid_paxos;
} MetadataT deriving (Bits, Eq);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
// ====== PARSER ======

typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseArp,
  StateParseIpv4,
  StateParseIpv6,
  StateParseUdp,
  StateParsePaxos
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  PulseWire w_parse_ipv6_start <- mkPulseWireOR();
  PulseWire w_parse_ipv4_start <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv6 <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_arp <- mkPulseWireOR();
  PulseWire w_parse_udp_parse_paxos <- mkPulseWireOR();
  PulseWire w_parse_paxos_start <- mkPulseWireOR();
  PulseWire w_parse_ethernet_start <- mkPulseWireOR();
  PulseWire w_start_parse_ethernet <- mkPulseWireOR();
  PulseWire w_parse_udp_start <- mkPulseWireOR();
  PulseWire w_parse_arp_start <- mkPulseWireOR();
  Reg#(Bool) parse_done[2] <- mkCReg(2, True);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFO#(ParserState) parse_state_ff <- mkPipelineFIFO();
  FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  PulseWire w_parse_header_done <- mkPulseWireOR();
  PulseWire w_load_header <- mkPulseWireOR();
  Reg#(Bit#(32)) rg_next_header_len[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_shift_amt[3] <- mkCReg(3, 0);
  Reg#(Bit#(512)) rg_tmp[2] <- mkCReg(2, 0);
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
  function Action fetch_next_header0(Bit#(32) len);
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
      if (v == 'h0806) begin
        dbg3($format("transit to parse_arp"));
        w_parse_ethernet_parse_arp.send();
      end
      else if (v == 'h0800) begin
        dbg3($format("transit to parse_ipv4"));
        w_parse_ethernet_parse_ipv4.send();
      end
      else if (v == 'h86dd) begin
        dbg3($format("transit to parse_ipv6"));
        w_parse_ethernet_parse_ipv6.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ethernet_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_arp();
    action
      dbg3($format("transit to start"));
      w_parse_arp_start.send();
    endaction
  endfunction
  function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
    action
      let v = {protocol};
      if (v == 'h11) begin
        dbg3($format("transit to parse_udp"));
        w_parse_ipv4_parse_udp.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ipv4_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_ipv6();
    action
      dbg3($format("transit to start"));
      w_parse_ipv6_start.send();
    endaction
  endfunction
  function Action compute_next_state_parse_udp(Bit#(16) dstPort);
    action
      let v = {dstPort};
      if (v == 'h8888) begin
        dbg3($format("transit to parse_paxos"));
        w_parse_udp_parse_paxos.send();
      end
      else if (v == 'h8889) begin
        dbg3($format("transit to parse_paxos"));
        w_parse_udp_parse_paxos.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_udp_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_paxos();
    action
      dbg3($format("transit to start"));
      w_parse_paxos_start.send();
    endaction
  endfunction
  rule rl_data_ff_load if ((!parse_done[1] && rg_buffered[2] < rg_next_header_len[2]) && (w_parse_header_done || w_load_header));
    let v = data_in_ff.first.data;
    data_in_ff.deq;
    rg_buffered[2] <= rg_buffered[2] + 128;
    data_ff.enq(tagged Valid v);
    dbg3($format("dequeue data %d %d", rg_buffered[2], rg_next_header_len[2]));
  endrule

  rule rl_start_state_deq if (parse_done[1] && sop_this_cycle && !w_parse_header_done);
    let v = data_in_ff.first.data;
    data_ff.enq(tagged Valid v);
    rg_buffered[2] <= 128;
    rg_shift_amt[2] <= 0;
    parse_done[1] <= False;
    parse_state_ff.enq(StateStart);
  endrule

  rule rl_start_state_idle if (parse_done[1] && (!sop_this_cycle || w_parse_header_done));
    data_in_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_ethernet_parse_arp, \
                         rl_parse_ethernet_parse_ipv4, \
                         rl_parse_ethernet_parse_ipv6, \
                         rl_parse_ethernet_start, \
                         rl_parse_arp_start, \
                         rl_parse_paxos_start, \
                         rl_parse_ipv4_parse_udp, \
                         rl_parse_ipv4_start, \
                         rl_parse_ipv6_start, \
                         rl_parse_udp_parse_paxos, \
                         rl_parse_udp_parse_paxos, \
                         rl_parse_udp_start" *)
  rule rl_start_parse_ethernet if ((w_start_parse_ethernet));
    parse_state_ff.enq(StateParseEthernet);
    dbg3($format("%s -> %s", "start", "parse_ethernet"));
    fetch_next_header1(112);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ethernet_load if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] < 112));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ethernet_extract if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] >= 112));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let ethernet_t = extract_ethernet_t(truncate(data));
    compute_next_state_parse_ethernet(ethernet_t.etherType);
    rg_tmp[0] <= zeroExtend(data >> 112);
    succeed_and_next(112);
    dbg3($format("extract %s", "parse_ethernet"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_ethernet_parse_arp if ((w_parse_ethernet_parse_arp));
    parse_state_ff.enq(StateParseArp);
    dbg3($format("%s -> %s", "parse_ethernet", "parse_arp"));
    fetch_next_header0(224);
  endrule

  rule rl_parse_ethernet_parse_ipv4 if ((w_parse_ethernet_parse_ipv4));
    parse_state_ff.enq(StateParseIpv4);
    dbg3($format("%s -> %s", "parse_ethernet", "parse_ipv4"));
    fetch_next_header0(160);
  endrule

  rule rl_parse_ethernet_parse_ipv6 if ((w_parse_ethernet_parse_ipv6));
    parse_state_ff.enq(StateParseIpv6);
    dbg3($format("%s -> %s", "parse_ethernet", "parse_ipv6"));
    fetch_next_header0(320);
  endrule

  rule rl_parse_ethernet_start if ((w_parse_ethernet_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_ethernet", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_arp_load if ((parse_state_ff.first == StateParseArp) && (rg_buffered[0] < 224));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_arp_extract if ((parse_state_ff.first == StateParseArp) && (rg_buffered[0] >= 224));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_arp();
    rg_tmp[0] <= zeroExtend(data >> 224);
    succeed_and_next(224);
    dbg3($format("extract %s", "parse_arp"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_arp_start if ((w_parse_arp_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_arp", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv4_load if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] < 160));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv4_extract if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] >= 160));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let ipv4_t = extract_ipv4_t(truncate(data));
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(160);
    dbg3($format("extract %s", "parse_ipv4"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_ipv4_parse_udp if ((w_parse_ipv4_parse_udp));
    parse_state_ff.enq(StateParseUdp);
    dbg3($format("%s -> %s", "parse_ipv4", "parse_udp"));
    fetch_next_header0(64);
  endrule

  rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_ipv4", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv6_load if ((parse_state_ff.first == StateParseIpv6) && (rg_buffered[0] < 320));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_ipv6_extract if ((parse_state_ff.first == StateParseIpv6) && (rg_buffered[0] >= 320));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_ipv6();
    rg_tmp[0] <= zeroExtend(data >> 320);
    succeed_and_next(320);
    dbg3($format("extract %s", "parse_ipv6"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_ipv6_start if ((w_parse_ipv6_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_ipv6", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_udp_load if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] < 64));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_udp_extract if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] >= 64));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let udp_t = extract_udp_t(truncate(data));
    compute_next_state_parse_udp(udp_t.dstPort);
    rg_tmp[0] <= zeroExtend(data >> 64);
    succeed_and_next(64);
    dbg3($format("extract %s", "parse_udp"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_udp_parse_paxos if ((w_parse_udp_parse_paxos));
    parse_state_ff.enq(StateParsePaxos);
    dbg3($format("%s -> %s", "parse_udp", "parse_paxos"));
    fetch_next_header0(352);
  endrule

  rule rl_parse_udp_start if ((w_parse_udp_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_udp", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_paxos_load if ((parse_state_ff.first == StateParsePaxos) && (rg_buffered[0] < 352));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_paxos_extract if ((parse_state_ff.first == StateParsePaxos) && (rg_buffered[0] >= 352));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_paxos();
    rg_tmp[0] <= zeroExtend(data >> 352);
    succeed_and_next(352);
    dbg3($format("extract %s", "parse_paxos"));
    parse_state_ff.deq;
  endrule

  rule rl_parse_paxos_start if ((w_parse_paxos_start));
    parse_done[0] <= True;
    dbg3($format("%s -> %s", "parse_paxos", "start"));
    fetch_next_header0(0);
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
  StateUdp,
  StateArp,
  StatePaxos,
  StateIpv6
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
  } NopReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$rnd;
    Bit#(32) paxos$inst;
    Bit#(16) runtime_learner_port;
  } Handle1AReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$rnd;
    Bit#(32) paxos$inst;
    Bit#(256) paxos$paxosval;
    Bit#(16) runtime_learner_port;
  } Handle2AReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
  } ReadRoundReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
  } NopRspT;
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$msgtype;
    Bit#(16) udp$checksum;
    Bit#(16) paxos$acptid;
    Bit#(16) paxos$vrnd;
    Bit#(16) udp$dstPort;
    Bit#(256) paxos$paxosval;
  } Handle1ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$acptid;
    Bit#(16) paxos$msgtype;
    Bit#(16) udp$dstPort;
    Bit#(16) udp$checksum;
  } Handle2ARspT;
  struct {
    PacketInstance pkt;
    Bit#(1) local_metadata$set_drop;
    Bit#(16) local_metadata$round;
  } ReadRoundRspT;
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

// ====== _NOP ======

interface Nop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkNop  (Nop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule _nop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged NopReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule _nop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged NopRspT {pkt: pkt};
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

// ====== HANDLE_1A ======

interface Handle1A;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) vrounds_register;
  interface Client#(RegRequest#(16, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) datapath_id;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandle1A  (Handle1A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_vrounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_vrounds_register <- mkRX;
  let tx_info_vrounds_register = tx_vrounds_register.u;
  let rx_info_vrounds_register = rx_vrounds_register.u;
  TX #(RegRequest#(16, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_datapath_id <- mkTX;
  RX #(RegResponse#(16)) rx_datapath_id <- mkRX;
  let tx_info_datapath_id = tx_datapath_id.u;
  let rx_info_datapath_id = rx_datapath_id.u;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  Reg#(Bit#(16)) rg_paxos$rnd <- mkReg(0);
  Reg#(Bit#(16)) paxos$msgtype <- mkReg(0);
  Reg#(Bit#(16)) udp$dstPort <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_1a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Handle1AReqT {pkt: .pkt, paxos$rnd: .paxos$rnd, paxos$inst: .paxos$inst, runtime_learner_port: .runtime_learner_port}: begin
        paxos$msgtype <= 'h1;
        let vrounds_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_vrounds_register.enq(vrounds_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_values_register.enq(values_register_req);
        let datapath_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_datapath_id.enq(datapath_id_req);
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_rounds_register.enq(rounds_register_req);
        rg_paxos$rnd <= paxos$rnd;
        udp$dstPort <= runtime_learner_port;
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_1a_response;
    let v_paxos$vrnd = rx_info_vrounds_register.first;
    rx_info_vrounds_register.deq;
    let paxos$vrnd = v_paxos$vrnd.data;
    let v_paxos$paxosval = rx_info_values_register.first;
    rx_info_values_register.deq;
    let paxos$paxosval = v_paxos$paxosval.data;
    let v_paxos$acptid = rx_info_datapath_id.first;
    rx_info_datapath_id.deq;
    let paxos$acptid = v_paxos$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Handle1ARspT {pkt: pkt, paxos$msgtype: paxos$msgtype, udp$checksum: udp$checksum, paxos$acptid: paxos$acptid, paxos$vrnd: paxos$vrnd, udp$dstPort: udp$dstPort, paxos$paxosval: paxos$paxosval};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface vrounds_register = toClient(tx_vrounds_register.e, rx_vrounds_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface datapath_id = toClient(tx_datapath_id.e, rx_datapath_id.e);
  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== HANDLE_2A ======

interface Handle2A;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) vrounds_register;
  interface Client#(RegRequest#(16, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) datapath_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandle2A  (Handle2A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  TX #(RegRequest#(16, 16)) tx_vrounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_vrounds_register <- mkRX;
  let tx_info_vrounds_register = tx_vrounds_register.u;
  let rx_info_vrounds_register = rx_vrounds_register.u;
  TX #(RegRequest#(16, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_datapath_id <- mkTX;
  RX #(RegResponse#(16)) rx_datapath_id <- mkRX;
  let tx_info_datapath_id = tx_datapath_id.u;
  let rx_info_datapath_id = rx_datapath_id.u;
  Reg#(Bit#(256)) rg_paxos$paxosval <- mkReg(0);
  Reg#(Bit#(16)) rg_paxos$rnd <- mkReg(0);
  Reg#(Bit#(16)) paxos$msgtype <- mkReg(0);
  Reg#(Bit#(16)) udp$dstPort <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_2a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Handle2AReqT {pkt: .pkt, paxos$rnd: .paxos$rnd, paxos$inst: .paxos$inst, paxos$paxosval: .paxos$paxosval, runtime_learner_port: .runtime_learner_port}: begin
        paxos$msgtype <= 'h3;
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_rounds_register.enq(rounds_register_req);
        rg_paxos$rnd <= paxos$rnd;
        let vrounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_vrounds_register.enq(vrounds_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$paxosval, write: True };
        tx_info_values_register.enq(values_register_req);
        rg_paxos$paxosval <= paxos$paxosval;
        let datapath_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_datapath_id.enq(datapath_id_req);
        udp$dstPort <= runtime_learner_port;
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_2a_response;
    let v_paxos$acptid = rx_info_datapath_id.first;
    rx_info_datapath_id.deq;
    let paxos$acptid = v_paxos$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Handle2ARspT {pkt: pkt, paxos$acptid: paxos$acptid, paxos$msgtype: paxos$msgtype, udp$dstPort: udp$dstPort, udp$checksum: udp$checksum};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface vrounds_register = toClient(tx_vrounds_register.e, rx_vrounds_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface datapath_id = toClient(tx_datapath_id.e, rx_datapath_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== READ_ROUND ======

interface ReadRound;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadRound  (ReadRound);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  Reg#(Bit#(1)) local_metadata$set_drop <- mkReg(0);
  rule read_round_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadRoundReqT {pkt: .pkt, paxos$inst: .paxos$inst}: begin
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_rounds_register.enq(rounds_register_req);
        local_metadata$set_drop <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_round_response;
    let v_local_metadata$round = rx_info_rounds_register.first;
    rx_info_rounds_register.deq;
    let local_metadata$round = v_local_metadata$round.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadRoundRspT {pkt: pkt, local_metadata$set_drop: local_metadata$set_drop, local_metadata$round: local_metadata$round};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== FORWARD_TBL ======

typedef struct {
  Bit#(9) standard_metadata$ingress_port;
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
import "BDPI" function ActionValue#(Bit#(11)) matchtable_read_forward_tbl(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_forward_tbl(Bit#(9) msgtype, Bit#(11) data);
instance MatchTableSim#(2, 9, 11);
  function ActionValue#(Bit#(11)) matchtable_read(Bit#(2) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_forward_tbl(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(2) id, Bit#(9) key, Bit#(11) data);
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
  MatchTable#(2, 256, SizeOf#(ForwardTblReqT), SizeOf#(ForwardTblRspT)) matchTable <- mkMatchTable();
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
    let standard_metadata$ingress_port = fromMaybe(?, meta.standard_metadata$ingress_port);
    ForwardTblReqT req = ForwardTblReqT {standard_metadata$ingress_port: standard_metadata$ingress_port};
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

// ====== ACCEPTOR_TBL ======

typedef struct {
  Bit#(16) paxos$msgtype;
  Bit#(2) padding;
} AcceptorTblReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_ACCEPTOR_TBL,
  HANDLE_1A,
  HANDLE_2A,
  DROP
} AcceptorTblActionT deriving (Bits, Eq);
typedef struct {
  AcceptorTblActionT _action;
  Bit#(16) runtime_learner_port;
} AcceptorTblRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(18)) matchtable_read_acceptor_tbl(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_acceptor_tbl(Bit#(18) msgtype, Bit#(18) data);
instance MatchTableSim#(1, 18, 18);
  function ActionValue#(Bit#(18)) matchtable_read(Bit#(1) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_acceptor_tbl(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(1) id, Bit#(18) key, Bit#(18) data);
    action
      matchtable_write_acceptor_tbl(key, data);
    endaction
  endfunction
endinstance
interface AcceptorTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
endinterface
module mkAcceptorTbl  (AcceptorTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(3, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(3, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1, 256, SizeOf#(AcceptorTblReqT), SizeOf#(AcceptorTblRspT)) matchTable <- mkMatchTable();
  Vector#(3, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(3) readyChannel = -1;
  for (Integer i=2; i>=0; i=i-1) begin
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
    let paxos$msgtype = fromMaybe(?, meta.paxos$msgtype);
    AcceptorTblReqT req = AcceptorTblReqT {paxos$msgtype: paxos$msgtype};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    let paxos$rnd = fromMaybe(?, meta.paxos$rnd);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    let paxos$paxosval = fromMaybe(?, meta.paxos$paxosval);
    if (rsp matches tagged Valid .data) begin
      AcceptorTblRspT resp = unpack(data);
      case (resp._action) matches
        HANDLE_1A: begin
          BBRequest req = tagged Handle1AReqT {pkt: pkt, paxos$rnd: paxos$rnd, paxos$inst: paxos$inst, runtime_learner_port: resp.runtime_learner_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        HANDLE_2A: begin
          BBRequest req = tagged Handle2AReqT {pkt: pkt, paxos$rnd: paxos$rnd, paxos$inst: paxos$inst, paxos$paxosval: paxos$paxosval, runtime_learner_port: resp.runtime_learner_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
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
      tagged Handle1ARspT {pkt: .pkt, paxos$msgtype: .paxos$msgtype, udp$checksum: .udp$checksum, paxos$acptid: .paxos$acptid, paxos$vrnd: .paxos$vrnd, udp$dstPort: .udp$dstPort, paxos$paxosval: .paxos$paxosval}: begin
        meta.paxos$msgtype = tagged Valid paxos$msgtype;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos$acptid = tagged Valid paxos$acptid;
        meta.paxos$vrnd = tagged Valid paxos$vrnd;
        meta.udp$dstPort = tagged Valid udp$dstPort;
        meta.paxos$paxosval = tagged Valid paxos$paxosval;
        MetadataResponse rsp = tagged AcceptorTblHandle1ARspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Handle2ARspT {pkt: .pkt, paxos$acptid: .paxos$acptid, paxos$msgtype: .paxos$msgtype, udp$dstPort: .udp$dstPort, udp$checksum: .udp$checksum}: begin
        meta.paxos$acptid = tagged Valid paxos$acptid;
        meta.paxos$msgtype = tagged Valid paxos$msgtype;
        meta.udp$dstPort = tagged Valid udp$dstPort;
        meta.udp$checksum = tagged Valid udp$checksum;
        MetadataResponse rsp = tagged AcceptorTblHandle2ARspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged AcceptorTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
endmodule

// ====== ROUND_TBL ======

typedef struct {
} RoundTblReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_ROUND_TBL,
  READ_ROUND
} RoundTblActionT deriving (Bits, Eq);
typedef struct {
  RoundTblActionT _action;
} RoundTblRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_round_tbl(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_round_tbl(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_round_tbl(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_round_tbl(key, data);
    endaction
  endfunction
endinstance
interface RoundTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkRoundTbl  (RoundTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkFIFOF;
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    BBRequest req = tagged ReadRoundReqT {pkt: pkt, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadRoundRspT {pkt: .pkt, local_metadata$set_drop: .local_metadata$set_drop, local_metadata$round: .local_metadata$round}: begin
        meta.local_metadata$set_drop = tagged Valid local_metadata$set_drop;
        meta.local_metadata$round = tagged Valid local_metadata$round;
        MetadataResponse rsp = tagged RoundTblReadRoundRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) acceptor_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) acceptor_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) forward_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) round_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) round_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  AcceptorTbl acceptor_tbl <- mkAcceptorTbl();
  ForwardTbl forward_tbl <- mkForwardTbl();
  RoundTbl round_tbl <- mkRoundTbl();
  mkConnection(toClient(acceptor_tbl_req_ff, acceptor_tbl_rsp_ff), acceptor_tbl.prev_control_state_0);
  mkConnection(toClient(forward_tbl_req_ff, forward_tbl_rsp_ff), forward_tbl.prev_control_state_0);
  mkConnection(toClient(round_tbl_req_ff, round_tbl_rsp_ff), round_tbl.prev_control_state_0);
  // Basic Blocks
  Handle1A handle_1a_0 <- mkHandle1A();
  Handle2A handle_2a_0 <- mkHandle2A();
  Drop _drop_0 <- mkDrop();
  Forward forward_0 <- mkForward();
  Drop _drop_1 <- mkDrop();
  ReadRound read_round_0 <- mkReadRound();
  RegisterIfc#(1, 16) datapath_id <- mkP4Register(vec(handle_1a_0.datapath_id));
  RegisterIfc#(16, 16) rounds_register <- mkP4Register(vec(handle_1a_0.rounds_register));
  RegisterIfc#(16, 16) vrounds_register <- mkP4Register(vec(handle_1a_0.vrounds_register));
  RegisterIfc#(16, 256) values_register <- mkP4Register(vec(handle_1a_0.values_register));
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_0, handle_1a_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_1, handle_2a_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_2, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_0, forward_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_1, _drop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, round_tbl.next_control_state_0, read_round_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_ipv4)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      forward_tbl_req_ff.enq(req);
    end
  endrule

  rule acceptor_tbl_next_state if (acceptor_tbl_rsp_ff.notEmpty);
    acceptor_tbl_rsp_ff.deq;
    let _rsp = acceptor_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged AcceptorTblHandle1ARspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged AcceptorTblHandle2ARspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged AcceptorTblDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule forward_tbl_next_state if (forward_tbl_rsp_ff.notEmpty);
    forward_tbl_rsp_ff.deq;
    let _rsp = forward_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged ForwardTblForwardRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          round_tbl_req_ff.enq(req);
        end
      end
      tagged ForwardTblDropRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          round_tbl_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule round_tbl_next_state if (round_tbl_rsp_ff.notEmpty);
    round_tbl_rsp_ff.deq;
    let _rsp = round_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged RoundTblReadRoundRspT {meta: .meta, pkt: .pkt}: begin
        let paxos$rnd = fromMaybe(?, meta.paxos$rnd);
        let local_metadata$round = fromMaybe(?, meta.local_metadata$round);
        if (( local_metadata$round <= paxos$rnd )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          acceptor_tbl_req_ff.enq(req);
        end
      end
    endcase
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule

// ====== DROP_TBL ======

typedef struct {
  Bit#(1) local_metadata$set_drop;
  Bit#(8) padding;
} DropTblReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_DROP_TBL,
  DROP,
  NOP
} DropTblActionT deriving (Bits, Eq);
typedef struct {
  DropTblActionT _action;
} DropTblRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(2)) matchtable_read_drop_tbl(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_drop_tbl(Bit#(9) msgtype, Bit#(2) data);
instance MatchTableSim#(3, 9, 2);
  function ActionValue#(Bit#(2)) matchtable_read(Bit#(3) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_drop_tbl(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(3) id, Bit#(9) key, Bit#(2) data);
    action
      matchtable_write_drop_tbl(key, data);
    endaction
  endfunction
endinstance
interface DropTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkDropTbl  (DropTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(3, 256, SizeOf#(DropTblReqT), SizeOf#(DropTblRspT)) matchTable <- mkMatchTable();
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
    let local_metadata$set_drop = fromMaybe(?, meta.local_metadata$set_drop);
    DropTblReqT req = DropTblReqT {local_metadata$set_drop: local_metadata$set_drop};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      DropTblRspT resp = unpack(data);
      case (resp._action) matches
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
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
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged DropTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged DropTblNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== EGRESS ======

interface Egress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) drop_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  DropTbl drop_tbl <- mkDropTbl();
  mkConnection(toClient(drop_tbl_req_ff, drop_tbl_rsp_ff), drop_tbl.prev_control_state_0);
  // Basic Blocks
  Drop _drop_0 <- mkDrop();
  Nop _nop_0 <- mkNop();
  mkChan(mkFIFOF, mkFIFOF, drop_tbl.next_control_state_0, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, drop_tbl.next_control_state_1, _nop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    drop_tbl_req_ff.enq(req);
  endrule

  rule drop_tbl_next_state if (drop_tbl_rsp_ff.notEmpty);
    drop_tbl_rsp_ff.deq;
    let _rsp = drop_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged DropTblDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged DropTblNopRspT {meta: .meta, pkt: .pkt}: begin
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
