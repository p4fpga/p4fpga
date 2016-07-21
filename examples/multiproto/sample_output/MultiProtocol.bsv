
import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import Connectable::*;
import ConfigReg::*;
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
import PrintTrace::*;
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
  Bit#(3) pcp;
  Bit#(1) cfi;
  Bit#(12) vid;
  Bit#(16) etherType;
} VlanTagT deriving (Bits, Eq);
instance DefaultValue#(VlanTagT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(VlanTagT);
  defaultMask = unpack(maxBound);
endinstance
function VlanTagT extract_vlan_tag_t(Bit#(32) data);
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
  Bit#(16) typeCode;
  Bit#(16) hdrChecksum;
} IcmpT deriving (Bits, Eq);
instance DefaultValue#(IcmpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IcmpT);
  defaultMask = unpack(maxBound);
endinstance
function IcmpT extract_icmp_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) srcPort;
  Bit#(16) dstPort;
  Bit#(32) seqNo;
  Bit#(32) ackNo;
  Bit#(4) dataOffset;
  Bit#(4) res;
  Bit#(8) flags;
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
  Bit#(1) drop;
  Bit#(8) egress_port;
  Bit#(4) packet_type;
  Bit#(3) _padding;
} IngressMetadataT deriving (Bits, Eq);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IngressMetadataT extract_ingress_metadata_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EthertypeMatchL2PacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EthertypeMatchIpv4PacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EthertypeMatchIpv6PacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EthertypeMatchMplsPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EthertypeMatchMimPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MatchNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MatchSetEgressPortRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MatchNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MatchSetEgressPortRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L2MatchNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L2MatchSetEgressPortRspT;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
  Maybe#(Bit#(4)) ing_metadata$packet_type;
  Maybe#(Bit#(8)) ing_metadata$egress_port;
  Maybe#(Bit#(8)) runtime_egress_port;
  Maybe#(Bit#(16)) ethernet$etherType;
  Maybe#(Bit#(32)) ipv4$srcAddr;
  Maybe#(Bit#(128)) ipv6$srcAddr;
  Maybe#(Bit#(48)) ethernet$srcAddr;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
// ====== PARSER ======

typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseVlanTag,
  StateParseIpv4,
  StateParseIpv6,
  StateParseIcmp,
  StateParseTcp,
  StateParseUdp
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  PulseWire w_parse_ipv6_parse_tcp <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_icmp <- mkPulseWireOR();
  PulseWire w_parse_ipv4_start <- mkPulseWireOR();
  PulseWire w_parse_ipv6_start <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv6 <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_tcp_start <- mkPulseWireOR();
  PulseWire w_parse_udp_start <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_vlan_tag <- mkPulseWireOR();
  PulseWire w_parse_ethernet_start <- mkPulseWireOR();
  PulseWire w_parse_vlan_tag_start <- mkPulseWireOR();
  PulseWire w_start_parse_ethernet <- mkPulseWireOR();
  PulseWire w_parse_vlan_tag_parse_ipv6 <- mkPulseWireOR();
  PulseWire w_parse_vlan_tag_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_ipv6_parse_icmp <- mkPulseWireOR();
  PulseWire w_parse_ipv6_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_icmp_start <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
  PulseWire w_parse_done <- mkPulseWire();
  Reg#(Bool) parse_done[2] <- mkCReg(2, True);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFO#(ParserState) parse_state_ff <- mkPipelineFIFO();
  FIFOF#(Maybe#(Bit#(128))) data_ff <- printTimedTraceM("data_ff", mkDFIFOF(tagged Invalid));
  FIFOF#(Maybe#(EthernetT)) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(IcmpT)) icmp_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(Ipv6T)) ipv6_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(VlanTagT)) vlan_tag_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(TcpT)) tcp_out_ff <- mkDFIFOF(tagged Invalid);
  FIFOF#(Maybe#(UdpT)) udp_out_ff <- mkDFIFOF(tagged Invalid);

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- printTimedTraceM("metadata_ff", mkFIFOF);
  PulseWire w_parse_header_done <- mkPulseWireOR();
  PulseWire w_load_header <- mkPulseWireOR();
  Array#(Reg#(Bit#(32))) rg_next_header_len <- mkCReg(3, 0);
  Array#(Reg#(Bit#(32))) rg_buffered <- mkCReg(3, 0);
  Array#(Reg#(Bit#(32))) rg_shift_amt <- mkCReg(3, 0);
  Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);
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
      if (v == 'h8100) begin
        dbg3($format("transit to parse_vlan_tag"));
        w_parse_ethernet_parse_vlan_tag.send();
      end
      else if (v == 'h9100) begin
        dbg3($format("transit to parse_vlan_tag"));
        w_parse_ethernet_parse_vlan_tag.send();
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
  function Action compute_next_state_parse_vlan_tag(Bit#(16) etherType);
    action
      let v = {etherType};
      if (v == 'h0800) begin
        dbg3($format("transit to parse_ipv4"));
        w_parse_vlan_tag_parse_ipv4.send();
      end
      else if (v == 'h86dd) begin
        dbg3($format("transit to parse_ipv6"));
        w_parse_vlan_tag_parse_ipv6.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_vlan_tag_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_ipv4(Bit#(13) fragOffset, Bit#(4) ihl, Bit#(8) protocol);
    action
      let v = {fragOffset, ihl, protocol};
      if ((v & 'h00000fff) == 'h00000501) begin
        dbg3($format("transit to parse_icmp"));
        w_parse_ipv4_parse_icmp.send();
      end
      else if ((v & 'h00000fff) == 'h00000506) begin
        dbg3($format("transit to parse_tcp"));
        w_parse_ipv4_parse_tcp.send();
      end
      else if ((v & 'h00000fff) == 'h00000511) begin
        dbg3($format("transit to parse_udp"));
        w_parse_ipv4_parse_udp.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ipv4_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_ipv6(Bit#(8) nextHdr);
    action
      let v = {nextHdr};
      if (v == 'h01) begin
        dbg3($format("transit to parse_icmp"));
        w_parse_ipv6_parse_icmp.send();
      end
      else if (v == 'h06) begin
        dbg3($format("transit to parse_tcp"));
        w_parse_ipv6_parse_tcp.send();
      end
      else if (v == 'h11) begin
        dbg3($format("transit to parse_udp"));
        w_parse_ipv6_parse_udp.send();
      end
      else begin
        dbg3($format("transit to start"));
        w_parse_ipv6_start.send();
      end
    endaction
  endfunction
  function Action compute_next_state_parse_icmp();
    action
      dbg3($format("transit to start"));
      w_parse_icmp_start.send();
    endaction
  endfunction
  function Action compute_next_state_parse_tcp();
    action
      dbg3($format("transit to start"));
      w_parse_tcp_start.send();
    endaction
  endfunction
  function Action compute_next_state_parse_udp();
    action
      dbg3($format("transit to start"));
      w_parse_udp_start.send();
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
    parse_state_ff.enq(StateParseEthernet);
  endrule

  rule rl_start_state_idle if (parse_done[1] && (!sop_this_cycle || w_parse_header_done));
    data_in_ff.deq;
  endrule

  rule rl_parse_done if (w_parse_done);
    MetadataT meta = defaultValue;
    let ethernet <- toGet(ethernet_out_ff).get;
    let icmp <- toGet(icmp_out_ff).get;
    let ipv4 <- toGet(ipv4_out_ff).get;
    let ipv6 <- toGet(ipv6_out_ff).get;
    let vlan <- toGet(vlan_tag_out_ff).get;
    let tcp <- toGet(tcp_out_ff).get;
    let udp <- toGet(udp_out_ff).get;
    if (isValid(ethernet)) begin
      meta.ethernet$etherType = tagged Valid fromMaybe(?, ethernet).etherType;
      meta.ethernet$srcAddr = tagged Valid fromMaybe(?, ethernet).srcAddr;
    end
    if (isValid(ipv4)) begin
      meta.ipv4$srcAddr = tagged Valid fromMaybe(?, ipv4).srcAddr;
    end
    if (isValid(ipv6)) begin
      meta.ipv6$srcAddr = tagged Valid fromMaybe(?, ipv6).srcAddr;
    end
    meta_in_ff.enq(meta);
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
    ethernet_out_ff.enq(tagged Valid ethernet_t);
    rg_tmp[0] <= zeroExtend(data >> 112);
    succeed_and_next(112);
    dbg3($format("extract %s", "parse_ethernet"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_ethernet_parse_vlan_tag, rl_parse_ethernet_parse_ipv4, rl_parse_ethernet_parse_ipv6, rl_parse_ethernet_start" *)
  rule rl_parse_ethernet_parse_vlan_tag if ((w_parse_ethernet_parse_vlan_tag));
    parse_state_ff.enq(StateParseVlanTag);
    dbg3($format("%s -> %s", "parse_ethernet", "parse_vlan_tag"));
    fetch_next_header0(32);
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
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_ethernet", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_vlan_tag_load if ((parse_state_ff.first == StateParseVlanTag) && (rg_buffered[0] < 32));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_vlan_tag_extract if ((parse_state_ff.first == StateParseVlanTag) && (rg_buffered[0] >= 32));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let vlan_tag_t = extract_vlan_tag_t(truncate(data));
    compute_next_state_parse_vlan_tag(vlan_tag_t.etherType);
    rg_tmp[0] <= zeroExtend(data >> 32);
    succeed_and_next(32);
    dbg3($format("extract %s", "parse_vlan_tag"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_vlan_tag_parse_ipv4, rl_parse_vlan_tag_parse_ipv6, rl_parse_vlan_tag_start" *)
  rule rl_parse_vlan_tag_parse_ipv4 if ((w_parse_vlan_tag_parse_ipv4));
    parse_state_ff.enq(StateParseIpv4);
    dbg3($format("%s -> %s", "parse_vlan_tag", "parse_ipv4"));
    fetch_next_header0(160);
  endrule

  rule rl_parse_vlan_tag_parse_ipv6 if ((w_parse_vlan_tag_parse_ipv6));
    parse_state_ff.enq(StateParseIpv6);
    dbg3($format("%s -> %s", "parse_vlan_tag", "parse_ipv6"));
    fetch_next_header0(320);
  endrule

  rule rl_parse_vlan_tag_start if ((w_parse_vlan_tag_start));
    parse_done[0] <= True;
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_vlan_tag", "start"));
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
    compute_next_state_parse_ipv4(ipv4_t.fragOffset,ipv4_t.ihl,ipv4_t.protocol);
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(160);
    dbg3($format("extract %s", "parse_ipv4"));
    ipv4_out_ff.enq(tagged Valid ipv4_t);
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_ipv4_parse_icmp, rl_parse_ipv4_parse_tcp, rl_parse_ipv4_parse_udp, rl_parse_ipv4_start" *)
  rule rl_parse_ipv4_parse_icmp if ((w_parse_ipv4_parse_icmp));
    parse_state_ff.enq(StateParseIcmp);
    dbg3($format("%s -> %s", "parse_ipv4", "parse_icmp"));
    fetch_next_header0(32);
  endrule

  rule rl_parse_ipv4_parse_tcp if ((w_parse_ipv4_parse_tcp));
    parse_state_ff.enq(StateParseTcp);
    dbg3($format("%s -> %s", "parse_ipv4", "parse_tcp"));
    fetch_next_header0(160);
  endrule

  rule rl_parse_ipv4_parse_udp if ((w_parse_ipv4_parse_udp));
    parse_state_ff.enq(StateParseUdp);
    dbg3($format("%s -> %s", "parse_ipv4", "parse_udp"));
    fetch_next_header0(64);
  endrule

  rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
    parse_done[0] <= True;
    w_parse_done.send();
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
    let ipv6_t = extract_ipv6_t(truncate(data));
    compute_next_state_parse_ipv6(ipv6_t.nextHdr);
    rg_tmp[0] <= zeroExtend(data >> 320);
    succeed_and_next(320);
    dbg3($format("extract %s", "parse_ipv6"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_ipv6_parse_icmp, rl_parse_ipv6_parse_tcp, rl_parse_ipv6_parse_udp, rl_parse_ipv6_start" *)
  rule rl_parse_ipv6_parse_icmp if ((w_parse_ipv6_parse_icmp));
    parse_state_ff.enq(StateParseIcmp);
    dbg3($format("%s -> %s", "parse_ipv6", "parse_icmp"));
    fetch_next_header0(32);
  endrule

  rule rl_parse_ipv6_parse_tcp if ((w_parse_ipv6_parse_tcp));
    parse_state_ff.enq(StateParseTcp);
    dbg3($format("%s -> %s", "parse_ipv6", "parse_tcp"));
    fetch_next_header0(160);
  endrule

  rule rl_parse_ipv6_parse_udp if ((w_parse_ipv6_parse_udp));
    parse_state_ff.enq(StateParseUdp);
    dbg3($format("%s -> %s", "parse_ipv6", "parse_udp"));
    fetch_next_header0(64);
  endrule

  rule rl_parse_ipv6_start if ((w_parse_ipv6_start));
    parse_done[0] <= True;
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_ipv6", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_icmp_load if ((parse_state_ff.first == StateParseIcmp) && (rg_buffered[0] < 32));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_icmp_extract if ((parse_state_ff.first == StateParseIcmp) && (rg_buffered[0] >= 32));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_icmp();
    rg_tmp[0] <= zeroExtend(data >> 32);
    succeed_and_next(32);
    dbg3($format("extract %s", "parse_icmp"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_icmp_start" *)
  rule rl_parse_icmp_start if ((w_parse_icmp_start));
    parse_done[0] <= True;
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_icmp", "start"));
    fetch_next_header0(0);
  endrule

  (* fire_when_enabled *)
  rule rl_parse_tcp_load if ((parse_state_ff.first == StateParseTcp) && (rg_buffered[0] < 160));
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
      rg_tmp[0] <= zeroExtend(data);
      move_shift_amt(128);
    end
  endrule

  (* fire_when_enabled *)
  rule rl_parse_tcp_extract if ((parse_state_ff.first == StateParseTcp) && (rg_buffered[0] >= 160));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
      data_ff.deq;
      data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    compute_next_state_parse_tcp();
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(160);
    dbg3($format("extract %s", "parse_tcp"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_tcp_start" *)
  rule rl_parse_tcp_start if ((w_parse_tcp_start));
    parse_done[0] <= True;
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_tcp", "start"));
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
    compute_next_state_parse_udp();
    rg_tmp[0] <= zeroExtend(data >> 64);
    succeed_and_next(64);
    dbg3($format("extract %s", "parse_udp"));
    parse_state_ff.deq;
  endrule

  (* mutually_exclusive="rl_parse_udp_start" *)
  rule rl_parse_udp_start if ((w_parse_udp_start));
    parse_done[0] <= True;
    w_parse_done.send();
    dbg3($format("%s -> %s", "parse_udp", "start"));
    fetch_next_header0(0);
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule

// ====== DEPARSER ======

typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseVlanTag,
  StateDeparseIpv4,
  StateDeparseIpv6,
  StateDeparseTcp,
  StateDeparseUdp,
  StateDeparseIcmp
} DeparserState deriving (Bits, Eq);

typedef union tagged {
   Tuple2#(Bit#(112), Bit#(112)) UEthernetT;
   Tuple2#(Bit#(32), Bit#(32)) UVlanTagT;
   Tuple2#(Bit#(160), Bit#(160)) UIpv4T;
   Tuple2#(Bit#(320), Bit#(320)) UIpv6T;
   Tuple2#(Bit#(160), Bit#(160)) UTcpT;
   Tuple2#(Bit#(64), Bit#(64)) UUdpT;
} MetaT;

typeclass ToTuple#(type t, type d);
   function Tuple2#(t, t) toTuple(d arg);
endtypeclass

instance ToTuple#(EthernetT, MetadataT);
   function Tuple2#(EthernetT, EthernetT) toTuple (MetadataT t);
      EthernetT data = defaultValue;
      EthernetT mask = defaultMask;
      data.etherType = fromMaybe(?, t.ethernet$etherType);
      mask.etherType = 0;
      return tuple2(data, mask);
   endfunction
endinstance

interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  method DeparserPerfRec read_perf_info ();
  method Action set_verbosity (int verbosity);
endinterface
module mkDeparser  (Deparser);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbg3(Fmt msg);
    action
      if (cf_verbosity > 3) begin
        $display("(%0d) ", $time, msg);
      end
    endaction
  endfunction

  PulseWire w_deparse_ipv4 <- mkPulseWire();
  PulseWire w_deparse_tcp <- mkPulseWire();
  PulseWire w_deparse_tcp_start <- mkPulseWire();
  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(EtherData) data_out_ff <- printTraceM("depaser out", mkFIFOF);
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  FIFOF#(Maybe#(Bit#(128))) data_ff <- mkDFIFOF(tagged Invalid);
  FIFO#(DeparserState) deparse_state_ff <- mkPipelineFIFO();
  Array#(Reg#(Bit#(32))) rg_next_header_len <- mkCReg(3, 0);
  Array#(Reg#(Bit#(32))) rg_buffered <- mkCReg(3, 0);
  Array#(Reg#(Bit#(32))) rg_processed <- mkCReg(3, 0);
  Array#(Reg#(Bit#(32))) rg_shift_amt <- mkCReg(3, 0);
  Array#(Reg#(Bit#(512))) rg_tmp <- mkCReg(2, 0);
  Array#(Reg#(Bool)) deparse_done <- mkCReg(2, True);
  Array#(Reg#(Bool)) header_done <- mkCReg(2, True);
  PulseWire w_deparse_header_done <- mkPulseWire();
  let mask_this_cycle = data_in_ff.first.mask;
  let sop_this_cycle = data_in_ff.first.sop;
  let eop_this_cycle = data_in_ff.first.eop;
  let data_this_cycle = data_in_ff.first.data;
  let meta = meta_in_ff.first;
  function Action report_deparse_action(String msg, Bit#(32) buffered, Bit#(32) processed, Bit#(32) shift, Bit#(512) data);
    action
      if (cf_verbosity > 0) begin
        $display("(%0d) Deparse %s buffered %d %d %d data %h", $time, msg, buffered, processed, shift, data);
      end
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      rg_next_header_len[0] <= len;
    endaction
  endfunction
  function Action move_buffered_amt(Bit#(32) len);
    action
      rg_buffered[0] <= rg_buffered[0] + len;
      rg_shift_amt[0] <= rg_shift_amt[0] + len;
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) len);
    action
      rg_processed[0] <= rg_processed[0] + len;
      rg_buffered[0] <= rg_buffered[0] - len;
      rg_shift_amt[0] <= rg_buffered[0] - len;
      dbg3($format("succeed_and_next shift_amt = %d", rg_buffered[0] - len));
    endaction
  endfunction
  function DeparserState compute_next_state(DeparserState state);
    DeparserState nextState = StateDeparseStart;
    return nextState;
  endfunction

  rule rl_start_state if (deparse_done[1] && (sop_this_cycle));
    rg_buffered[2] <= 0;
    rg_shift_amt[2] <= 0;
    rg_processed[2] <= 0;
    deparse_done[1] <= False;
    header_done[1] <= False;
    deparse_state_ff.enq(StateDeparseEthernet);
    fetch_next_header(112);
    dbg3($format("start deparse"));
  endrule

  rule rl_deparse_payload if (deparse_done[1] && (!sop_this_cycle));
    let data = data_in_ff.first;
    data_in_ff.deq;
    data_out_ff.enq(data);
  endrule

  // phase 3
  rule rl_data_ff_load if ((!deparse_done[1] && rg_buffered[2] < rg_next_header_len[2]));
    dbg3($format("dequeue data_in_ff"));
    data_in_ff.deq;
  endrule

  // phase 2
  rule rl_deparse_send if (!deparse_done[1] && rg_processed[1] > 0);
    let data = EtherData { sop: sop_this_cycle,
                           eop: eop_this_cycle,
                           data: truncate(rg_tmp[1]),
                           mask: mask_this_cycle };
    data_out_ff.enq(data);
    dbg3($format("send rg_tmp %h", rg_tmp[1]));
    let amt = 128;
    if (rg_processed[1] < 128) begin
       amt = rg_processed[1];
    end
    rg_tmp[1] <= rg_tmp[1] >> amt;
    rg_processed[1] <= rg_processed[1] - amt;
    dbg3($format("send data ", fshow(data), amt));
  endrule

  // wait till all processed bits are sent, cont. to send payload.
  rule rl_wait_till_processed_done if (header_done[1] && rg_processed[1] == 0);
    deparse_done[1] <= True;
  endrule

  // phase 1
  rule rl_deparse_ethernet_load if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] < 112));
    dbg3($format("ether load"));
    rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    move_buffered_amt(128);
  endrule

  rule rl_deparse_ethernet_send if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] >= 112));
    dbg3($format("ethernet send tmp %h", rg_tmp[0]));
    succeed_and_next(112);
    w_deparse_ipv4.send();
    deparse_state_ff.deq;
  endrule

  rule rl_deparse_ethernet_deparse_ipv4 if (w_deparse_ipv4);
    dbg3($format("ethernet -> ipv4"));
    deparse_state_ff.enq(StateDeparseIpv4);
    fetch_next_header(160);
  endrule

  rule rl_deparse_ipv4_load if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] < 160));
    dbg3($format("ipv4 load %h", rg_tmp[0]));
    rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    move_buffered_amt(128);
  endrule

  rule rl_deparse_ipv4_send if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] >= 160));
    dbg3($format("ipv4 send %h", rg_tmp[0]));
    succeed_and_next(160);
    w_deparse_tcp.send();
    deparse_state_ff.deq;
  endrule

  rule rl_deparse_ipv4_deparse_tcp if (w_deparse_tcp);
    dbg3($format("ipv4 -> tcp"));
    deparse_state_ff.enq(StateDeparseTcp);
    fetch_next_header(160);
  endrule

  rule rl_deparse_tcp_load if ((deparse_state_ff.first == StateDeparseTcp) && (rg_buffered[0] < 160));
    dbg3($format("tcp load %h", rg_tmp[0]));
    rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    move_buffered_amt(128);
  endrule

  rule rl_deparse_tcp_send if ((deparse_state_ff.first == StateDeparseTcp) && (rg_buffered[0] >= 160));
    dbg3($format("tcp send %h", rg_tmp[0]));
    succeed_and_next(160);
    deparse_state_ff.deq;
    w_deparse_tcp_start.send();
  endrule

  rule rl_deparse_tcp_start if (w_deparse_tcp_start);
    dbg3($format("deparse_tcp -> start"));
    fetch_next_header(0);
    header_done[0] <= True;
  endrule

  interface metadata = toPipeIn(meta_in_ff);
  interface PktWriteServer writeServer;
    interface writeData = toPut(data_in_ff);
  endinterface
  interface PktWriteClient writeClient;
    interface writeData = toGet(data_out_ff);
  endinterface
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } Ipv4PacketReqT;
  struct {
    PacketInstance pkt;
  } Ipv6PacketReqT;
  struct {
    PacketInstance pkt;
  } L2PacketReqT;
  struct {
    PacketInstance pkt;
  } MimPacketReqT;
  struct {
    PacketInstance pkt;
  } MplsPacketReqT;
  struct {
    PacketInstance pkt;
  } NopReqT;
  struct {
    PacketInstance pkt;
    Bit#(8) runtime_egress_port;
  } SetEgressPortReqT;
} BBRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } Ipv4PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } Ipv6PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } L2PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } MimPacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } MplsPacketRspT;
  struct {
    PacketInstance pkt;
  } NopRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ing_metadata$egress_port;
  } SetEgressPortRspT;
} BBResponse deriving (Bits, Eq, FShow);

// ====== IPV4_PACKET ======

interface Ipv4Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
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

// ====== IPV6_PACKET ======

interface Ipv6Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
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

// ====== L2_PACKET ======

interface L2Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkL2Packet  (L2Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule l2_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged L2PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule l2_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged L2PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== MIM_PACKET ======

interface MimPacket;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkMimPacket  (MimPacket);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule mim_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged MimPacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h4;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mim_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged MimPacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== MPLS_PACKET ======

interface MplsPacket;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkMplsPacket  (MplsPacket);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule mpls_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged MplsPacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h3;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mpls_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged MplsPacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== NOP ======

interface Nop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkNop  (Nop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule nop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged NopReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule nop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged NopRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== SET_EGRESS_PORT ======

interface SetEgressPort;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkSetEgressPort  (SetEgressPort);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(8)) ing_metadata$egress_port <- mkReg(0);
  rule set_egress_port_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetEgressPortReqT {pkt: .pkt, runtime_egress_port: .runtime_egress_port}: begin
        ing_metadata$egress_port <= runtime_egress_port;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_egress_port_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetEgressPortRspT {pkt: pkt, ing_metadata$egress_port: ing_metadata$egress_port};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== L2_MATCH ======

typedef struct {
  Bit#(6) padding;
  Bit#(48) ethernet$srcAddr;
} L2MatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_L2_MATCH,
  NOP,
  SET_EGRESS_PORT
} L2MatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  L2MatchActionT _action;
  Bit#(8) runtime_egress_port;
} L2MatchRspT deriving (Bits, Eq, FShow);
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_l2_match(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_l2_match(Bit#(54) msgtype, Bit#(10) data);
instance MatchTableSim#(3, 54, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(3) id, Bit#(54) key);
    actionvalue
      let v <- matchtable_read_l2_match(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(3) id, Bit#(54) key, Bit#(10) data);
    action
      matchtable_write_l2_match(key, data);
    endaction
  endfunction
endinstance
interface L2Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkL2Match  (L2Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(printTraceM("bbreq", mkFIFOF));
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(printTraceM("bbrsp", mkFIFOF));
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(3, 256, SizeOf#(L2MatchReqT), SizeOf#(L2MatchRspT)) matchTable <- mkMatchTable("l2match.dat");
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
    let ethernet$srcAddr = fromMaybe(?, meta.ethernet$srcAddr);
    L2MatchReqT req = L2MatchReqT {padding: 0, ethernet$srcAddr: ethernet$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      L2MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
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
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged L2MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged L2MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== IPV4_MATCH ======

typedef struct {
  Bit#(4) padding;
  Bit#(32) ipv4$srcAddr;
} Ipv4MatchReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_IPV4_MATCH,
  NOP,
  SET_EGRESS_PORT
} Ipv4MatchActionT deriving (Bits, Eq);
typedef struct {
  Ipv4MatchActionT _action;
  Bit#(8) runtime_egress_port;
} Ipv4MatchRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_ipv4_match(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_ipv4_match(Bit#(36) msgtype, Bit#(10) data);
instance MatchTableSim#(1, 36, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(1) id, Bit#(36) key);
    actionvalue
      let v <- matchtable_read_ipv4_match(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(1) id, Bit#(36) key, Bit#(10) data);
    action
      matchtable_write_ipv4_match(key, data);
    endaction
  endfunction
endinstance
interface Ipv4Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkIpv4Match  (Ipv4Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1, 256, SizeOf#(Ipv4MatchReqT), SizeOf#(Ipv4MatchRspT)) matchTable <- mkMatchTable("ipv4match.dat");
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
    let ipv4$srcAddr = fromMaybe(?, meta.ipv4$srcAddr);
    Ipv4MatchReqT req = Ipv4MatchReqT {padding: 0, ipv4$srcAddr: ipv4$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv4MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
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
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged Ipv4MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged Ipv4MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== IPV6_MATCH ======

typedef struct {
  Bit#(7) padding;
  Bit#(128) ipv6$srcAddr;
} Ipv6MatchReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_IPV6_MATCH,
  NOP,
  SET_EGRESS_PORT
} Ipv6MatchActionT deriving (Bits, Eq);
typedef struct {
  Ipv6MatchActionT _action;
  Bit#(8) runtime_egress_port;
} Ipv6MatchRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_ipv6_match(Bit#(135) msgtype);
import "BDPI" function Action matchtable_write_ipv6_match(Bit#(135) msgtype, Bit#(10) data);
instance MatchTableSim#(2, 135, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(2) id, Bit#(135) key);
    actionvalue
      let v <- matchtable_read_ipv6_match(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(2) id, Bit#(135) key, Bit#(10) data);
    action
      matchtable_write_ipv6_match(key, data);
    endaction
  endfunction
endinstance
interface Ipv6Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkIpv6Match  (Ipv6Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(2, 256, SizeOf#(Ipv6MatchReqT), SizeOf#(Ipv6MatchRspT)) matchTable <- mkMatchTable("ipv6match.dat");
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
    let ipv6$srcAddr = fromMaybe(?, meta.ipv6$srcAddr);
    Ipv6MatchReqT req = Ipv6MatchReqT {padding: 0, ipv6$srcAddr: ipv6$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv6MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
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
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged Ipv6MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged Ipv6MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== ETHERTYPE_MATCH ======

typedef struct {
  Bit#(2) padding;
  Bit#(16) ethernet$etherType;
} EthertypeMatchReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_ETHERTYPE_MATCH,
  L2_PACKET,
  IPV4_PACKET,
  IPV6_PACKET,
  MPLS_PACKET,
  MIM_PACKET
} EthertypeMatchActionT deriving (Bits, Eq);
typedef struct {
  EthertypeMatchActionT _action;
} EthertypeMatchRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(3)) matchtable_read_ethertype_match(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_ethertype_match(Bit#(18) msgtype, Bit#(3) data);
instance MatchTableSim#(0, 18, 3);
  function ActionValue#(Bit#(3)) matchtable_read(Bit#(0) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_ethertype_match(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) id, Bit#(18) key, Bit#(3) data);
    action
      matchtable_write_ethertype_match(key, data);
    endaction
  endfunction
endinstance
interface EthertypeMatch;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
  interface Client #(BBRequest, BBResponse) next_control_state_3;
  interface Client #(BBRequest, BBResponse) next_control_state_4;
endinterface
module mkEthertypeMatch  (EthertypeMatch);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(5, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(5, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(0, 256, SizeOf#(EthertypeMatchReqT), SizeOf#(EthertypeMatchRspT)) matchTable <- mkMatchTable("ethermatch.dat");
  Vector#(5, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(5) readyChannel = -1;
  for (Integer i=4; i>=0; i=i-1) begin
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
    let ethernet$etherType = fromMaybe(?, meta.ethernet$etherType);
    EthertypeMatchReqT req = EthertypeMatchReqT {padding: 0, ethernet$etherType: ethernet$etherType};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      EthertypeMatchRspT resp = unpack(data);
      case (resp._action) matches
        L2_PACKET: begin
          BBRequest req = tagged L2PacketReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        IPV4_PACKET: begin
          BBRequest req = tagged Ipv4PacketReqT {pkt: pkt};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        IPV6_PACKET: begin
          BBRequest req = tagged Ipv6PacketReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
        end
        MPLS_PACKET: begin
          BBRequest req = tagged MplsPacketReqT {pkt: pkt};
          bbReqFifo[3].enq(req); //FIXME: replace with RXTX.
        end
        MIM_PACKET: begin
          BBRequest req = tagged MimPacketReqT {pkt: pkt};
          bbReqFifo[4].enq(req); //FIXME: replace with RXTX.
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
      tagged L2PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchL2PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv4PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchIpv4PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv6PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchIpv6PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MplsPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchMplsPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MimPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchMimPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
  interface next_control_state_3 = toClient(bbReqFifo[3], bbRspFifo[3]);
  interface next_control_state_4 = toClient(bbReqFifo[4], bbRspFifo[4]);
endmodule

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ethertype_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ethertype_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ipv4_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv6_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ipv6_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) l2_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) l2_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  EthertypeMatch ethertype_match <- mkEthertypeMatch();
  Ipv4Match ipv4_match <- mkIpv4Match();
  Ipv6Match ipv6_match <- mkIpv6Match();
  L2Match l2_match <- mkL2Match();
  mkConnection(toClient(ethertype_match_req_ff, ethertype_match_rsp_ff), ethertype_match.prev_control_state_0);
  mkConnection(toClient(ipv4_match_req_ff, ipv4_match_rsp_ff), ipv4_match.prev_control_state_0);
  mkConnection(toClient(ipv6_match_req_ff, ipv6_match_rsp_ff), ipv6_match.prev_control_state_0);
  mkConnection(toClient(l2_match_req_ff, l2_match_rsp_ff), l2_match.prev_control_state_0);
  // Basic Blocks
  L2Packet l2_packet_0 <- mkL2Packet();
  Ipv4Packet ipv4_packet_0 <- mkIpv4Packet();
  Ipv6Packet ipv6_packet_0 <- mkIpv6Packet();
  MplsPacket mpls_packet_0 <- mkMplsPacket();
  MimPacket mim_packet_0 <- mkMimPacket();
  Nop nop_0 <- mkNop();
  SetEgressPort set_egress_port_0 <- mkSetEgressPort();
  Nop nop_1 <- mkNop();
  SetEgressPort set_egress_port_1 <- mkSetEgressPort();
  Nop nop_2 <- mkNop();
  SetEgressPort set_egress_port_2 <- mkSetEgressPort();
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_0, l2_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_1, ipv4_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_2, ipv6_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_3, mpls_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_4, mim_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_0, nop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_1, set_egress_port_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_0, nop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_1, set_egress_port_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_0, nop_2.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_1, set_egress_port_2.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    ethertype_match_req_ff.enq(req);
  endrule

  rule ethertype_match_next_state if (ethertype_match_rsp_ff.notEmpty);
    ethertype_match_rsp_ff.deq;
    let _rsp = ethertype_match_rsp_ff.first;
    case (_rsp) matches
      tagged EthertypeMatchL2PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv4PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv6PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMplsPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMimPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv4_match_next_state if (ipv4_match_rsp_ff.notEmpty);
    ipv4_match_rsp_ff.deq;
    let _rsp = ipv4_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv4MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv4MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv6_match_next_state if (ipv6_match_rsp_ff.notEmpty);
    ipv6_match_rsp_ff.deq;
    let _rsp = ipv6_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv6MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv6MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule l2_match_next_state if (l2_match_rsp_ff.notEmpty);
    l2_match_rsp_ff.deq;
    let _rsp = l2_match_rsp_ff.first;
    case (_rsp) matches
      tagged L2MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged L2MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
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
    $display("Egress out", fshow(req));
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
