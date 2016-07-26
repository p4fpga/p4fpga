
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
import MatchTableSim::*;
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
  return unpack(data);
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
  return unpack(data);
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
  return unpack(data);
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
  return unpack(data);
endfunction

typedef struct {
  Bit#(8) icmptype;
  Bit#(8) code;
  Bit#(16) checksum;
  Bit#(32) quench;
} IcmpT deriving (Bits, Eq);
instance DefaultValue#(IcmpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IcmpT);
  defaultMask = unpack(maxBound);
endinstance
function IcmpT extract_icmp_t(Bit#(64) data);
  return unpack(data);
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
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) msgtype;
  Bit#(32) inst;
} PaxosT deriving (Bits, Eq);
instance DefaultValue#(PaxosT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(PaxosT);
  defaultMask = unpack(maxBound);
endinstance
function PaxosT extract_paxos_t(Bit#(48) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) ballot;
} Phase1AT deriving (Bits, Eq);
instance DefaultValue#(Phase1AT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase1AT);
  defaultMask = unpack(maxBound);
endinstance
function Phase1AT extract_phase1a_t(Bit#(16) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) ballot;
  Bit#(16) vballot;
  Bit#(256) paxosval;
  Bit#(16) acptid;
} Phase1BT deriving (Bits, Eq);
instance DefaultValue#(Phase1BT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase1BT);
  defaultMask = unpack(maxBound);
endinstance
function Phase1BT extract_phase1b_t(Bit#(304) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) ballot;
  Bit#(256) paxosval;
} Phase2AT deriving (Bits, Eq);
instance DefaultValue#(Phase2AT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase2AT);
  defaultMask = unpack(maxBound);
endinstance
function Phase2AT extract_phase2a_t(Bit#(272) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) ballot;
  Bit#(256) paxosval;
  Bit#(16) acptid;
} Phase2BT deriving (Bits, Eq);
instance DefaultValue#(Phase2BT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase2BT);
  defaultMask = unpack(maxBound);
endinstance
function Phase2BT extract_phase2b_t(Bit#(288) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(16) ballot;
} LocalMetadataT deriving (Bits, Eq);
instance DefaultValue#(LocalMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(LocalMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function LocalMetadataT extract_local_metadata_t(Bit#(16) data);
  return unpack(data);
endfunction

typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq);
typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(32)) paxos$inst;
  Maybe#(Bit#(16)) paxos1a$ballot;
  Maybe#(Bit#(16)) paxos1b$vballot;
  Maybe#(Bit#(16)) paxos1b$ballot;
  Maybe#(Bit#(16)) udp$checksum;
  Maybe#(Bit#(256)) paxos1b$paxosval;
  Maybe#(Bit#(16)) paxos1b$acptid;
  Maybe#(Bit#(256)) paxos2a$paxosval;
  Maybe#(Bit#(16)) paxos2a$ballot;
  Maybe#(Bit#(16)) paxos2b$ballot;
  Maybe#(Bit#(16)) paxos2b$acptid;
  Maybe#(Bit#(256)) paxos2b$paxosval;
  Maybe#(Bit#(16)) paxos_ballot$ballot;
  Maybe#(Bit#(9)) standard_metadata$ingress_port;
  Maybe#(Bit#(0)) valid_ethernet;
  Maybe#(Bit#(0)) valid_arp;
  Maybe#(Bit#(0)) valid_icmp;
  Maybe#(Bit#(0)) valid_ipv4;
  Maybe#(Bit#(0)) valid_udp;
  Maybe#(Bit#(0)) valid_paxos;
  Maybe#(Bit#(0)) valid_paxos1a;
  Maybe#(Bit#(0)) valid_paxos1b;
  Maybe#(Bit#(0)) valid_paxos2a;
  Maybe#(Bit#(0)) valid_paxos2b;
} MetadataT deriving (Bits, Eq);
typedef enum {
  StateParseStart,
  StateParseEthernet,
  StateParseArp,
  StateParseIcmp,
  StateParseIpv4,
  StateParseUdp,
  StateParsePaxos,
  StateParse1A,
  StateParse1B,
  StateParse2A,
  StateParse2B
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info;
endinterface
module mkParser(Parser);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(ParserState) rg_parse_state <- mkReg(StateParseStart);
  Wire#(ParserState) parse_state_w <- mkDWire(StateParseStart);
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  PulseWire parse_done <- mkPulseWire();
  Reg#(Bit#(128)) rg_tmp_parse_ethernet <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_arp <- mkReg(0);
  Reg#(Bit#(144)) rg_tmp_parse_icmp <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
  Reg#(Bit#(240)) rg_tmp_parse_udp <- mkReg(0);
  Reg#(Bit#(304)) rg_tmp_parse_paxos <- mkReg(0);
  Reg#(Bit#(384)) rg_tmp_parse_1a <- mkReg(0);
  Reg#(Bit#(384)) rg_tmp_parse_1b <- mkReg(0);
  Reg#(Bit#(384)) rg_tmp_parse_2a <- mkReg(0);
  Reg#(Bit#(384)) rg_tmp_parse_2b <- mkReg(0);
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

  function Action push_phv(ParserState ty);
    action
    endaction
  endfunction

  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%d) Parser State %h offset %h, %h", $time, state, offset, data);
      end
    endaction
  endfunction

  function ParserState compute_next_state_parse_ethernet(Bit#(16) v);
    ParserState nextState = StateParseStart;
    case (byteSwap(v)) matches
      'h0806: begin
        nextState = StateParseArp;
      end
      'h0001: begin
        nextState = StateParseIcmp;
      end
      'h0800: begin
        nextState = StateParseIpv4;
      end
      default: begin
        nextState = StateParseStart;
      end
    endcase
    return nextState;
  endfunction

  function ParserState compute_next_state_parse_ipv4(Bit#(8) v);
    ParserState nextState = StateParseStart;
    case (byteSwap(v)) matches
      'h11: begin
        nextState = StateParseUdp;
      end
      default: begin
        nextState = StateParseStart;
      end
    endcase
    return nextState;
  endfunction

  function ParserState compute_next_state_parse_udp(Bit#(16) v);
    ParserState nextState = StateParseStart;
    case (byteSwap(v)) matches
      'h8887: begin
        nextState = StateParsePaxos;
      end
      'h8888: begin
        nextState = StateParsePaxos;
      end
      default: begin
        nextState = StateParseStart;
      end
    endcase
    return nextState;
  endfunction

  function ParserState compute_next_state_parse_paxos(Bit#(16) v);
    ParserState nextState = StateParseStart;
    case (byteSwap(v)) matches
      'h0000: begin
        nextState = StateParse1A;
      end
      'h0001: begin
        nextState = StateParse1B;
      end
      'h0002: begin
        nextState = StateParse2A;
      end
      'h0003: begin
        nextState = StateParse2B;
      end
      default: begin
        nextState = StateParseStart;
      end
    endcase
    return nextState;
  endfunction

  rule rl_start_state if (rg_parse_state == StateParseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state <= StateParseEthernet;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  let data_this_cycle = data_in_ff.first.data;
  rule rl_parse_parse_ethernet_0 if ((rg_parse_state == StateParseEthernet) && (rg_offset == 0));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(0, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ethernet));
    Bit#(0) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(128) data = {data_this_cycle, data_last_cycle};
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let parse_ethernet = extract_ethernet_t(pack(takeAt(0, dataVec)));
    let next_state = compute_next_state_parse_ethernet(parse_ethernet.etherType);
    rg_parse_state <= next_state;
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    rg_tmp_parse_arp <= zeroExtend(pack(unparsed));
    rg_tmp_parse_ipv4 <= zeroExtend(pack(unparsed));
    rg_tmp_parse_icmp <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParseEthernet;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_arp_0 if ((rg_parse_state == StateParseArp) && (rg_offset == 128));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_arp));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_arp <= zeroExtend(data);
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_arp_1 if ((rg_parse_state == StateParseArp) && (rg_offset == 256));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_arp));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let parse_arp = extract_arp_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(48, Bit#(1)) unparsed = takeAt(224, dataVec);
    parse_state_w <= StateParseArp;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_icmp_0 if ((rg_parse_state == StateParseIcmp) && (rg_offset == 128));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_icmp));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    Vector#(144, Bit#(1)) dataVec = unpack(data);
    let parse_icmp = extract_icmp_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(80, Bit#(1)) unparsed = takeAt(64, dataVec);
    parse_state_w <= StateParseIcmp;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_ipv4_0 if ((rg_parse_state == StateParseIpv4) && (rg_offset == 128));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_ipv4 <= zeroExtend(data);
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_ipv4_1 if ((rg_parse_state == StateParseIpv4) && (rg_offset == 256));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let parse_ipv4 = extract_ipv4_t(pack(takeAt(0, dataVec)));
    let next_state = compute_next_state_parse_ipv4(parse_ipv4.protocol);
    rg_parse_state <= next_state;
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    rg_tmp_parse_udp <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParseIpv4;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_udp_0 if ((rg_parse_state == StateParseUdp) && (rg_offset == 384));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(112, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_udp));
    Bit#(112) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(240) data = {data_this_cycle, data_last_cycle};
    Vector#(240, Bit#(1)) dataVec = unpack(data);
    let parse_udp = extract_udp_t(pack(takeAt(0, dataVec)));
    let next_state = compute_next_state_parse_udp(parse_udp.dstPort);
    rg_parse_state <= next_state;
    Vector#(176, Bit#(1)) unparsed = takeAt(64, dataVec);
    rg_tmp_parse_paxos <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParseUdp;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_paxos_0 if ((rg_parse_state == StateParsePaxos) && (rg_offset == 512));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(176, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_paxos));
    Bit#(176) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(304) data = {data_this_cycle, data_last_cycle};
    Vector#(304, Bit#(1)) dataVec = unpack(data);
    let parse_paxos = extract_paxos_t(pack(takeAt(0, dataVec)));
    let next_state = compute_next_state_parse_paxos(parse_paxos.msgtype);
    rg_parse_state <= next_state;
    Vector#(256, Bit#(1)) unparsed = takeAt(48, dataVec);
    rg_tmp_parse_1b <= zeroExtend(pack(unparsed));
    rg_tmp_parse_1a <= zeroExtend(pack(unparsed));
    rg_tmp_parse_2b <= zeroExtend(pack(unparsed));
    rg_tmp_parse_2a <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParsePaxos;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_1a_0 if ((rg_parse_state == StateParse1A) && (rg_offset == 640));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(256, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_1a));
    Bit#(256) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(384) data = {data_this_cycle, data_last_cycle};
    Vector#(384, Bit#(1)) dataVec = unpack(data);
    let parse_1a = extract_phase1a_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(368, Bit#(1)) unparsed = takeAt(16, dataVec);
    parse_state_w <= StateParse1A;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_1b_0 if ((rg_parse_state == StateParse1B) && (rg_offset == 640));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(256, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_1b));
    Bit#(256) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(384) data = {data_this_cycle, data_last_cycle};
    Vector#(384, Bit#(1)) dataVec = unpack(data);
    let parse_1b = extract_phase1b_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(80, Bit#(1)) unparsed = takeAt(304, dataVec);
    parse_state_w <= StateParse1B;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_2a_0 if ((rg_parse_state == StateParse2A) && (rg_offset == 640));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(256, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_2a));
    Bit#(256) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(384) data = {data_this_cycle, data_last_cycle};
    Vector#(384, Bit#(1)) dataVec = unpack(data);
    let parse_2a = extract_phase2a_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(112, Bit#(1)) unparsed = takeAt(272, dataVec);
    parse_state_w <= StateParse2A;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_2b_0 if ((rg_parse_state == StateParse2B) && (rg_offset == 640));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(256, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_2b));
    Bit#(256) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(384) data = {data_this_cycle, data_last_cycle};
    Vector#(384, Bit#(1)) dataVec = unpack(data);
    let parse_2b = extract_phase2b_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(96, Bit#(1)) unparsed = takeAt(288, dataVec);
    parse_state_w <= StateParse2B;
    succeed_and_next(rg_offset + 128);
  endrule

endmodule
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4,
  StateDeparseUdp,
  StateDeparseArp,
  StateDeparseIcmp,
  StateDeparsePaxos,
  StateDeparsePaxos1B,
  StateDeparsePaxos1A,
  StateDeparsePaxos2A,
  StateDeparsePaxos2B
} DeparserState deriving (Bits, Eq);
interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  interface Put#(int) verbosity;
  method DeparserPerfRec read_perf_info;
endinterface
module mkDeparser(Deparser);
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
  Reg#(Bit#(11)) deparse_vec <- mkReg(0);
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
      rg_deparse_state <= StateDeparseEthernet;
    end
    else begin
      data_in_ff.deq;
      data_out_ff.enq(v);
    end
  endrule

  function DeparserState compute_next_state (DeparserState state);
    UInt#(4) pos = countZerosMSB(deparse_vec);
    DeparserState next_state = unpack(pack(pos));
    return next_state;
  endfunction

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

endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
    Bit#(16) paxos1a$ballot;
  } HandlePhase1AReqT;
  struct {
    PacketInstance pkt;
    Bit#(256) paxos2a$paxosval;
    Bit#(16) paxos2a$ballot;
    Bit#(32) paxos$inst;
  } HandlePhase2AReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
  } ReadBallotReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos1b$vballot;
    Bit#(16) paxos1b$ballot;
    Bit#(16) udp$checksum;
    Bit#(256) paxos1b$paxosval;
    Bit#(16) paxos1b$acptid;
  } HandlePhase1ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos2b$ballot;
    Bit#(16) udp$checksum;
    Bit#(16) paxos2b$acptid;
    Bit#(256) paxos2b$paxosval;
  } HandlePhase2ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos_ballot$ballot;
  } ReadBallotRspT;
} BBResponse deriving (Bits, Eq);
interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkDrop(Drop);
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
interface Forward;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkForward(Forward);
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
interface HandlePhase1A;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) vballots_register;
  interface Client#(RegRequest#(10, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) acceptor_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandlePhase1A(HandlePhase1A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  TX #(RegRequest#(10, 16)) tx_vballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_vballots_register <- mkRX;
  let tx_info_vballots_register = tx_vballots_register.u;
  let rx_info_vballots_register = rx_vballots_register.u;
  TX #(RegRequest#(10, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_acceptor_id <- mkTX;
  RX #(RegResponse#(16)) rx_acceptor_id <- mkRX;
  let tx_info_acceptor_id = tx_acceptor_id.u;
  let rx_info_acceptor_id = rx_acceptor_id.u;
  Reg#(Bit#(16)) rg_paxos1a$ballot <- mkReg(0);
  Reg#(Bit#(16)) paxos1b$ballot <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_phase1a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged HandlePhase1AReqT {pkt: .pkt, paxos$inst: .paxos$inst, paxos1a$ballot: .paxos1a$ballot}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos1a$ballot, write: True };
        tx_info_ballots_register.enq(ballots_register_req);
        rg_paxos1a$ballot <= paxos1a$ballot;
        paxos1b$ballot <= paxos1a$ballot;
        let vballots_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_vballots_register.enq(vballots_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_values_register.enq(values_register_req);
        let acceptor_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_acceptor_id.enq(acceptor_id_req);
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_phase1a_response;
    let v_paxos1b$vballot = rx_info_vballots_register.first;
    rx_info_vballots_register.deq;
    let paxos1b$vballot = v_paxos1b$vballot.data;
    let v_paxos1b$paxosval = rx_info_values_register.first;
    rx_info_values_register.deq;
    let paxos1b$paxosval = v_paxos1b$paxosval.data;
    let v_paxos1b$acptid = rx_info_acceptor_id.first;
    rx_info_acceptor_id.deq;
    let paxos1b$acptid = v_paxos1b$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged HandlePhase1ARspT {pkt: pkt, paxos1b$vballot: paxos1b$vballot, paxos1b$ballot: rg_paxos1a$ballot, udp$checksum: udp$checksum, paxos1b$paxosval: paxos1b$paxosval, paxos1b$acptid: paxos1b$acptid};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface vballots_register = toClient(tx_vballots_register.e, rx_vballots_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface acceptor_id = toClient(tx_acceptor_id.e, rx_acceptor_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface HandlePhase2A;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) vballots_register;
  interface Client#(RegRequest#(10, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) acceptor_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandlePhase2A(HandlePhase2A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  TX #(RegRequest#(10, 16)) tx_vballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_vballots_register <- mkRX;
  let tx_info_vballots_register = tx_vballots_register.u;
  let rx_info_vballots_register = rx_vballots_register.u;
  TX #(RegRequest#(10, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_acceptor_id <- mkTX;
  RX #(RegResponse#(16)) rx_acceptor_id <- mkRX;
  let tx_info_acceptor_id = tx_acceptor_id.u;
  let rx_info_acceptor_id = rx_acceptor_id.u;
  Reg#(Bit#(16)) rg_paxos2a$ballot <- mkReg(0);
  Reg#(Bit#(256)) rg_paxos2a$paxosval <- mkReg(0);
  Reg#(Bit#(16)) paxos2b$ballot <- mkReg(0);
  Reg#(Bit#(256)) paxos2b$paxosval <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_phase2a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged HandlePhase2AReqT {pkt: .pkt, paxos2a$paxosval: .paxos2a$paxosval, paxos2a$ballot: .paxos2a$ballot, paxos$inst: .paxos$inst}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$ballot, write: True };
        tx_info_ballots_register.enq(ballots_register_req);
        rg_paxos2a$ballot <= paxos2a$ballot;
        let vballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$ballot, write: True };
        tx_info_vballots_register.enq(vballots_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$paxosval, write: True };
        tx_info_values_register.enq(values_register_req);
        rg_paxos2a$paxosval <= paxos2a$paxosval;
        paxos2b$ballot <= paxos2a$ballot;
        paxos2b$paxosval <= paxos2a$paxosval;
        let acceptor_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_acceptor_id.enq(acceptor_id_req);
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_phase2a_response;
    let v_paxos2b$acptid = rx_info_acceptor_id.first;
    rx_info_acceptor_id.deq;
    let paxos2b$acptid = v_paxos2b$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged HandlePhase2ARspT {pkt: pkt, paxos2b$ballot: rg_paxos2a$ballot, udp$checksum: udp$checksum, paxos2b$acptid: paxos2b$acptid, paxos2b$paxosval: rg_paxos2a$paxosval};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface vballots_register = toClient(tx_vballots_register.e, rx_vballots_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface acceptor_id = toClient(tx_acceptor_id.e, rx_acceptor_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ReadBallot;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadBallot(ReadBallot);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  rule read_ballot_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadBallotReqT {pkt: .pkt, paxos$inst: .paxos$inst}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_ballots_register.enq(ballots_register_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_ballot_response;
    let v_paxos_ballot$ballot = rx_info_ballots_register.first;
    rx_info_ballots_register.deq;
    let paxos_ballot$ballot = v_paxos_ballot$ballot.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadBallotRspT {pkt: pkt, paxos_ballot$ballot: paxos_ballot$ballot};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
typedef struct {
} DropTblReqT deriving (Bits, Eq);
typedef enum {
  NOOP_DROP_TBL,
  DROP
} DropTblActionT deriving (Bits, Eq);
typedef struct {
  DropTblActionT _action;
} DropTblRspT deriving (Bits, Eq);
interface DropTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkDropTbl(DropTbl);
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
    BBRequest req = tagged DropReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} BallotTblReqT deriving (Bits, Eq);
typedef enum {
  NOOP_BALLOT_TBL,
  READBALLOT
} BallotTblActionT deriving (Bits, Eq);
typedef struct {
  BallotTblActionT _action;
} BallotTblRspT deriving (Bits, Eq);
interface BallotTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkBallotTbl(BallotTbl);
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
    BBRequest req = tagged ReadBallotReqT {pkt: pkt, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadBallotRspT {pkt: .pkt, paxos_ballot$ballot: .paxos_ballot$ballot}: begin
        meta.paxos_ballot$ballot = tagged Valid paxos_ballot$ballot;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(9) standard_metadata$ingress_port;
} FwdTblReqT deriving (Bits, Eq);
typedef enum {
  NOOP_FWD_TBL,
  FORWARD
} FwdTblActionT deriving (Bits, Eq);
typedef struct {
  FwdTblActionT _action;
  Bit#(9) runtime_port;
} FwdTblRspT deriving (Bits, Eq);
interface FwdTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkFwdTbl(FwdTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(FwdTblReqT), SizeOf#(FwdTblRspT)) matchTable <- mkMatchTable();
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
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
    FwdTblReqT req = FwdTblReqT {standard_metadata$ingress_port: standard_metadata$ingress_port};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      FwdTblRspT resp = unpack(data);
      case (resp._action) matches
        FORWARD: begin
          BBRequest req = tagged ForwardReqT {pkt: pkt, runtime_port: resp.runtime_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
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
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} Paxos1ATblReqT deriving (Bits, Eq);
typedef enum {
  NOOP_PAXOS1A_TBL,
  HANDLEPHASE1A
} Paxos1ATblActionT deriving (Bits, Eq);
typedef struct {
  Paxos1ATblActionT _action;
} Paxos1ATblRspT deriving (Bits, Eq);
interface Paxos1ATbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkPaxos1ATbl(Paxos1ATbl);
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
    let paxos1a$ballot = fromMaybe(?, meta.paxos1a$ballot);
    BBRequest req = tagged HandlePhase1AReqT {pkt: pkt, paxos$inst: paxos$inst, paxos1a$ballot: paxos1a$ballot};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged HandlePhase1ARspT {pkt: .pkt, paxos1b$vballot: .paxos1b$vballot, paxos1b$ballot: .paxos1b$ballot, udp$checksum: .udp$checksum, paxos1b$paxosval: .paxos1b$paxosval, paxos1b$acptid: .paxos1b$acptid}: begin
        meta.paxos1b$vballot = tagged Valid paxos1b$vballot;
        meta.paxos1b$ballot = tagged Valid paxos1b$ballot;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos1b$paxosval = tagged Valid paxos1b$paxosval;
        meta.paxos1b$acptid = tagged Valid paxos1b$acptid;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} Paxos2ATblReqT deriving (Bits, Eq);
typedef enum {
  NOOP_PAXOS2A_TBL,
  HANDLEPHASE2A
} Paxos2ATblActionT deriving (Bits, Eq);
typedef struct {
  Paxos2ATblActionT _action;
} Paxos2ATblRspT deriving (Bits, Eq);
interface Paxos2ATbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkPaxos2ATbl(Paxos2ATbl);
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
    let paxos2a$paxosval = fromMaybe(?, meta.paxos2a$paxosval);
    let paxos2a$ballot = fromMaybe(?, meta.paxos2a$ballot);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    BBRequest req = tagged HandlePhase2AReqT {pkt: pkt, paxos2a$paxosval: paxos2a$paxosval, paxos2a$ballot: paxos2a$ballot, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged HandlePhase2ARspT {pkt: .pkt, paxos2b$ballot: .paxos2b$ballot, udp$checksum: .udp$checksum, paxos2b$acptid: .paxos2b$acptid, paxos2b$paxosval: .paxos2b$paxosval}: begin
        meta.paxos2b$ballot = tagged Valid paxos2b$ballot;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos2b$acptid = tagged Valid paxos2b$acptid;
        meta.paxos2b$paxosval = tagged Valid paxos2b$paxosval;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
interface Ingress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkIngress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ballot_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ballot_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) drop_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) fwd_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) fwd_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) paxos1a_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) paxos1a_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) paxos2a_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) paxos2a_tbl_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  BallotTbl ballot_tbl <- mkBallotTbl();
  DropTbl drop_tbl <- mkDropTbl();
  FwdTbl fwd_tbl <- mkFwdTbl();
  Paxos1ATbl paxos1a_tbl <- mkPaxos1ATbl();
  Paxos2ATbl paxos2a_tbl <- mkPaxos2ATbl();
  mkConnection(toClient(ballot_tbl_req_ff, ballot_tbl_rsp_ff), ballot_tbl.prev_control_state_0);
  mkConnection(toClient(drop_tbl_req_ff, drop_tbl_rsp_ff), drop_tbl.prev_control_state_0);
  mkConnection(toClient(fwd_tbl_req_ff, fwd_tbl_rsp_ff), fwd_tbl.prev_control_state_0);
  mkConnection(toClient(paxos1a_tbl_req_ff, paxos1a_tbl_rsp_ff), paxos1a_tbl.prev_control_state_0);
  mkConnection(toClient(paxos2a_tbl_req_ff, paxos2a_tbl_rsp_ff), paxos2a_tbl.prev_control_state_0);
  // Basic Blocks
  ReadBallot read_ballot <- mkReadBallot();
  Drop _drop <- mkDrop();
  Forward forward <- mkForward();
  HandlePhase1A handle_phase1a <- mkHandlePhase1A();
  HandlePhase2A handle_phase2a <- mkHandlePhase2A();
  RegisterIfc#(1, 16) acceptor_id <- mkP4Register(vec(handle_phase1a.acceptor_id));
  RegisterIfc#(10, 16) ballots_register <- mkP4Register(vec(handle_phase1a.ballots_register));
  RegisterIfc#(10, 16) vballots_register <- mkP4Register(vec(handle_phase1a.vballots_register));
  RegisterIfc#(10, 256) values_register <- mkP4Register(vec(handle_phase1a.values_register));
  mkChan(mkFIFOF, mkFIFOF, ballot_tbl.next_control_state_0, read_ballot.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, drop_tbl.next_control_state_0, _drop.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, fwd_tbl.next_control_state_0, forward.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, paxos1a_tbl.next_control_state_0, handle_phase1a.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, paxos2a_tbl.next_control_state_0, handle_phase2a.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_ipv4)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_tbl_req_ff.enq(req);
    end
  endrule

  rule ballot_tbl_next_state if (ballot_tbl_rsp_ff.notEmpty);
    ballot_tbl_rsp_ff.deq;
    let _rsp = ballot_tbl_rsp_ff.first;
    case (_rsp) begin
       tagged BallotTblReadBallot {meta: .meta, pkt: .pkt} begin
          let paxos2a$ballot = fromMaybe(?, meta.paxos2a$ballot);
          let paxos_ballot$ballot = fromMaybe(?, meta.paxos_ballot$ballot);
          let paxos1a$ballot = fromMaybe(?, meta.paxos1a$ballot);
          if (isValid(meta.valid_paxos1a)) begin
            if (( paxos_ballot$ballot <= paxos1a$ballot )) begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              paxos1a_tbl_req_ff.enq(req);
            end
            else begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              drop_tbl_req_ff.enq(req);
            end
          end
          else begin
            if (isValid(meta.valid_paxos2a)) begin
              if (( paxos_ballot$ballot <= paxos2a$ballot )) begin
                MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
                paxos2a_tbl_req_ff.enq(req);
              end
            end
          end
       end
    endcase
  endrule

  rule drop_tbl_next_state if (drop_tbl_rsp_ff.notEmpty);
    drop_tbl_rsp_ff.deq;
    let _req = drop_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule fwd_tbl_next_state if (fwd_tbl_rsp_ff.notEmpty);
    fwd_tbl_rsp_ff.deq;
    let _req = fwd_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_paxos)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ballot_tbl_req_ff.enq(req);
    end
  endrule

  rule paxos1a_tbl_next_state if (paxos1a_tbl_rsp_ff.notEmpty);
    paxos1a_tbl_rsp_ff.deq;
    let _req = paxos1a_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule paxos2a_tbl_next_state if (paxos2a_tbl_rsp_ff.notEmpty);
    paxos2a_tbl_rsp_ff.deq;
    let _req = paxos2a_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

endmodule
interface Egress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkEgress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest request = MetadataRequest {pkt: pkt, meta: meta};
  endrule

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
