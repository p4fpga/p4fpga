
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
  Bit#(32) msgSeqNum;
  Bit#(64) sendingTime;
} MdpPacketT deriving (Bits, Eq);
instance DefaultValue#(MdpPacketT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MdpPacketT);
  defaultMask = unpack(maxBound);
endinstance
function MdpPacketT extract_mdp_packet_t(Bit#(96) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) msgSize;
} MdpMessageT deriving (Bits, Eq);
instance DefaultValue#(MdpMessageT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MdpMessageT);
  defaultMask = unpack(maxBound);
endinstance
function MdpMessageT extract_mdp_message_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) blockLength;
  Bit#(16) templateID;
  Bit#(16) schemaID;
  Bit#(16) version;
} MdpSbeT deriving (Bits, Eq);
instance DefaultValue#(MdpSbeT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MdpSbeT);
  defaultMask = unpack(maxBound);
endinstance
function MdpSbeT extract_mdp_sbe_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(16) group_size;
} EventMetadataT deriving (Bits, Eq);
instance DefaultValue#(EventMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(EventMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function EventMetadataT extract_event_metadata_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(64) transactTime;
  Bit#(16) matchEventIndicator;
  Bit#(16) blockLength;
  Bit#(16) noMDEntries;
} Mdincrementalrefreshbook32 deriving (Bits, Eq);
instance DefaultValue#(Mdincrementalrefreshbook32);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Mdincrementalrefreshbook32);
  defaultMask = unpack(maxBound);
endinstance
function Mdincrementalrefreshbook32 extract_mdIncrementalRefreshBook32(Bit#(112) data);
  return unpack(byteSwap(data));
endfunction

typedef struct {
  Bit#(64) mDEntryPx;
  Bit#(32) mDEntrySize;
  Bit#(32) securityID;
  Bit#(32) rptReq;
  Bit#(32) numberOfOrders;
  Bit#(8) mDPriceLevel;
  Bit#(8) mDUpdateAction;
  Bit#(8) mDEntryType;
  Bit#(40) padding;
} Mdincrementalrefreshbook32Group deriving (Bits, Eq);
instance DefaultValue#(Mdincrementalrefreshbook32Group);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Mdincrementalrefreshbook32Group);
  defaultMask = unpack(maxBound);
endinstance
function Mdincrementalrefreshbook32Group extract_mdIncrementalRefreshBook32Group(Bit#(256) data);
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
  } DropNopRspT;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
} MetadataT deriving (Bits, Eq);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
// ====== PARSER ======

typedef enum {
  StateDefault,
  StateStart,
  StateParseIpv4,
  StateParseUdp,
  StateParseMdp,
  StateParseMdp2,
  StateParseMdpGroup
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  Wire#(Bit#(32)) w_curr_unparsed_bits <- mkDWire(0);
  Reg#(Bit#(32)) w_next_header_len[2] <- mkCReg(2, 0);
  Wire#(Bit#(272)) w_parse_udp_data <- mkDWire(0);
  Wire#(Bit#(304)) w_parse_mdp2_data <- mkDWire(0);
  //Wire#(Bit#(272)) w_parse_mdp2_data <- mkDWire(0);
  PulseWire w_parse_udp_parse_mdp <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_mdp_group_parse_mdp2 <- mkPulseWireOR();
  PulseWire w_start_default <- mkPulseWireOR();
  PulseWire w_parse_ipv4_default <- mkPulseWireOR();
  PulseWire w_parse_mdp2_parse_mdp_group <- mkPulseWireOR();
  PulseWire w_start_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_mdp2_default <- mkPulseWireOR();
  PulseWire w_parse_mdp_parse_mdp2 <- mkPulseWireOR();
  PulseWire w_parse_mdp_parse_mdp_group <- mkPulseWireOR();
  Reg#(Bit#(16)) event_metadata$group_size[2] <- mkCReg(2, 0);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(ParserState) rg_parse_state[3] <- mkCReg(3, StateDefault);
  Wire#(ParserState) parse_state_w <- mkDWire(StateDefault);
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  PulseWire parse_done <- mkPulseWire();
  Reg#(Bit#(128)) rg_tmp_start <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_udp <- mkReg(0);
  Reg#(Bit#(304)) rg_tmp_parse_mdp <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_mdp2 <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_mdp_group <- mkReg(0);
  function Action succeed_and_next(Bit#(32) offset);
    action
      w_curr_unparsed_bits <= offset;
      rg_offset <= offset;
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      w_next_header_len[0] <= len;
      $display("nextheader = %h", len);
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      w_curr_unparsed_bits <= offset;
      rg_offset <= 0;
    endaction
  endfunction
  function Action push_phv(ParserState ty);
    action
      MetadataT meta = defaultValue;
      meta_in_ff.enq(meta);
    endaction
  endfunction
  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%0d) Parser State %h offset %h, %h", $time, state, offset, data);
      end
    endaction
  endfunction
  function Action compute_next_state_start(Bit#(16) etherType);
    action
      let v = {etherType};
      case (v) matches
        'h0800: begin
          w_start_parse_ipv4.send();
        end
        default: begin
          w_start_default.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
    action
      let v = {protocol};
      case (v) matches
        'h11: begin
          w_parse_ipv4_parse_udp.send();
        end
        default: begin
          w_parse_ipv4_default.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_udp(Bit#(16) dstPort);
    action
      let v = {dstPort};
      case (v) matches
        default: begin
          w_parse_udp_parse_mdp.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_mdp();
    action
      w_parse_mdp_parse_mdp2.send();
    endaction
  endfunction
  function Action compute_next_state_parse_mdp2(Bit#(16) group_size);
    action
      let v = {group_size};
      case (v) matches
        'h0000: begin
          w_parse_mdp2_default.send();
        end
        default: begin
           $display("(%0d) parse group", $time);
          w_parse_mdp2_parse_mdp_group.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_mdp_group();
    action
      w_parse_mdp_group_parse_mdp2.send();
    endaction
  endfunction
  rule rl_start_state if (rg_parse_state[0] == StateDefault);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state[0] <= StateStart;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  rule rl_deq_data_in_ff (w_curr_unparsed_bits < w_next_header_len[1]);
     $display("(%0d) deq %h %h", $time, w_curr_unparsed_bits, w_next_header_len[1]);
    data_in_ff.deq;
  endrule

  let data_this_cycle = data_in_ff.first.data;
  rule rl_parse_start_0 if ((rg_parse_state[0] == StateStart) && (rg_offset == 0));
    $display("start state");
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(0, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_start));
    Bit#(0) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(128) data = {data_this_cycle, data_last_cycle};
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let ethernet_t = extract_ethernet_t(pack(takeAt(0, dataVec)));
    compute_next_state_start(ethernet_t.etherType);
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    rg_tmp_parse_ipv4 <= zeroExtend(pack(unparsed));
    succeed_and_next(16);
  endrule

  (* mutually_exclusive = "rl_start_parse_ipv4,rl_start_default" *)
  rule rl_start_parse_ipv4 if ((rg_parse_state[1] == StateStart) && (w_start_parse_ipv4));
    rg_parse_state[1] <= StateParseIpv4;
    fetch_next_header(160);
  endrule

  rule rl_start_default if ((rg_parse_state[1] == StateStart) && (w_start_default));
    rg_parse_state[1] <= StateDefault;
    fetch_next_header(0);
  endrule

  (* mutually_exclusive = "rl_parse_parse_ipv4_0, rl_parse_ipv4_parse_mdp" *)
  rule rl_parse_parse_ipv4_0 if ((rg_parse_state[0] == StateParseIpv4) && (rg_offset == 16));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_ipv4 <= zeroExtend(data);
    succeed_and_next(144);
  endrule

  rule rl_parse_parse_ipv4_1 if ((rg_parse_state[0] == StateParseIpv4) && (rg_offset == 144));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let ipv4_t = extract_ipv4_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    w_parse_udp_data <= data;
  endrule

  (* mutually_exclusive = "rl_parse_ipv4_default, rl_parse_ipv4_parse_mdp" *)
  rule rl_parse_ipv4_default if ((rg_parse_state[1] == StateParseIpv4) && (w_parse_ipv4_default));
    rg_parse_state[1] <= StateDefault;
    fetch_next_header(0);
  endrule

  rule rl_parse_udp if ((rg_parse_state[0] == StateParseIpv4) && (rg_offset == 144) && (w_parse_ipv4_parse_udp));
    Vector#(272, Bit#(1)) dataVec = unpack(w_parse_udp_data);
    let udp_t = extract_udp_t(pack(takeAt(160, dataVec)));
    compute_next_state_parse_udp(udp_t.dstPort);
    Vector#(48, Bit#(1)) unparsed = takeAt(224, dataVec);
    rg_tmp_parse_mdp <= zeroExtend(pack(unparsed));
  endrule

  rule rl_parse_ipv4_parse_mdp if ((rg_parse_state[1] == StateParseIpv4) && (w_parse_udp_parse_mdp));
    rg_parse_state[1] <= StateParseMdp;
    succeed_and_next(48);
    fetch_next_header(288);
  endrule

  (* mutually_exclusive = "rl_parse_parse_mdp_0, rl_parse_mdp2" *)
  rule rl_parse_parse_mdp_0 if ((rg_parse_state[0] == StateParseMdp) && (rg_offset == 48));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(48, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp));
    Bit#(48) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(176) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_mdp <= zeroExtend(data);
    succeed_and_next(176);
  endrule

  rule rl_parse_parse_mdp_1 if ((rg_parse_state[0] == StateParseMdp) && (rg_offset == 176));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(176, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp));
    Bit#(176) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(304) data = {data_this_cycle, data_last_cycle};
    Vector#(304, Bit#(1)) dataVec = unpack(data);
    let mdp_packet_t = extract_mdp_packet_t(pack(takeAt(0, dataVec)));
    let mdp_message_t = extract_mdp_message_t(pack(takeAt(96, dataVec)));
    let mdp_sbe_t = extract_mdp_sbe_t(pack(takeAt(112, dataVec)));
    let mdIncrementalRefreshBook32 = extract_mdIncrementalRefreshBook32(pack(takeAt(176, dataVec)));
    let v = mdIncrementalRefreshBook32.noMDEntries;
    event_metadata$group_size[0] <= v;
    compute_next_state_parse_mdp();
    Vector#(16, Bit#(1)) unparsed = takeAt(288, dataVec);
    $display("(%0d) mdp_1 %h", $time, v);
    w_parse_mdp2_data <= data;
  endrule

  rule rl_parse_mdp2 if ((rg_parse_state[0] == StateParseMdp) && (w_parse_mdp_parse_mdp2));
    compute_next_state_parse_mdp2(event_metadata$group_size[1]);
    $display("(%0d) mdp2 %h", $time, event_metadata$group_size[1]);
    rg_parse_state[0] <= StateParseMdp2;
    succeed_and_next(16);
  endrule

  rule rl_parse_mdp2_1 if ((rg_parse_state[0] == StateParseMdpGroup) && (w_parse_mdp_parse_mdp2));
    compute_next_state_parse_mdp2(event_metadata$group_size[1]);
    $display("(%0d) mdp2 %h", $time, event_metadata$group_size[1]);
    rg_parse_state[0] <= StateParseMdp2;
    succeed_and_next(16);
  endrule

  (* mutually_exclusive = "rl_parse_mdp2_parse_mdp_group, rl_parse_mdp2_default" *)
  rule rl_parse_mdp2_default if ((rg_parse_state[1] == StateParseMdp2) && (w_parse_mdp2_default));
    rg_parse_state[1] <= StateDefault;
    fetch_next_header(0);
    $display("(%0d) to default", $time);
  endrule

  rule rl_parse_mdp2_parse_mdp_group if ((rg_parse_state[1] == StateParseMdp2) && (w_parse_mdp2_parse_mdp_group));
    rg_parse_state[1] <= StateParseMdpGroup;
    fetch_next_header(256);
    $display("(%0d) parse group", $time);
  endrule

  (* mutually_exclusive = "rl_parse_parse_mdp_group_0, rl_parse_mdp2_1" *)
  rule rl_parse_parse_mdp_group_0 if ((rg_parse_state[0] == StateParseMdpGroup) && (rg_offset == 16));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp_group));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_mdp_group <= zeroExtend(data);
    succeed_and_next(144);
  endrule

  rule rl_parse_parse_mdp_group_1 if ((rg_parse_state[0] == StateParseMdpGroup) && (rg_offset == 144));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp_group));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let mdIncrementalRefreshBook32Group = extract_mdIncrementalRefreshBook32Group(pack(takeAt(0, dataVec)));
    let v = ( event_metadata$group_size[0] - 'h1 );
    event_metadata$group_size[0] <= v;
    compute_next_state_parse_mdp_group();
    Vector#(16, Bit#(1)) unparsed = takeAt(256, dataVec);
    w_parse_mdp2_data <= zeroExtend(data);
  endrule

  rule rl_parse_mdp_group_parse_mdp_group if ((rg_parse_state[0] == StateParseMdpGroup) && (w_parse_mdp_group_parse_mdp2));
    w_parse_mdp_parse_mdp2.send();
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
  StateMdp,
  StateMdpMsg,
  StateMdpSbe,
  StateMdpRefreshbook,
  StateGroup0,
  StateGroup1,
  StateGroup2,
  StateGroup3,
  StateGroup4,
  StateGroup5,
  StateGroup6,
  StateGroup7,
  StateGroup8,
  StateGroup9
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
  } NopReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } NopRspT;
} BBResponse deriving (Bits, Eq);

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

// ====== DROP ======

typedef struct {
} DropReqT deriving (Bits, Eq);
typedef enum {
  DEFAULT_DROP,
  NOP
} DropActionT deriving (Bits, Eq);
typedef struct {
  DropActionT _action;
} DropRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_drop(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_drop(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_drop(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_drop(key, data);
    endaction
  endfunction
endinstance
interface Drop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkDrop  (Drop);
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
    BBRequest req = tagged NopReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged DropNopRspT {pkt: pkt, meta: meta};
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
  FIFOF#(MetadataRequest) drop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  Drop drop <- mkDrop();
  mkConnection(toClient(drop_req_ff, drop_rsp_ff), drop.prev_control_state_0);
  // Basic Blocks
  Nop nop_0 <- mkNop();
  mkChan(mkFIFOF, mkFIFOF, drop.next_control_state_0, nop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    drop_req_ff.enq(req);
  endrule

  rule drop_next_state if (drop_rsp_ff.notEmpty);
    drop_rsp_ff.deq;
    let _rsp = drop_rsp_ff.first;
    case (_rsp) matches
      tagged DropNopRspT {meta: .meta, pkt: .pkt}: begin
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
