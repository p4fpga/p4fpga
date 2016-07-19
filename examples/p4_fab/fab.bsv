
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
  Bit#(16) appid;
  Bit#(8) msgtype;
  Bit#(32) inst;
  Bit#(16) replica;
} FabT deriving (Bits, Eq);
instance DefaultValue#(FabT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(FabT);
  defaultMask = unpack(maxBound);
endinstance
function FabT extract_fab_t(Bit#(72) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(4) mcast_grp;
  Bit#(4) egress_rid;
  Bit#(16) mcast_hash;
  Bit#(32) lf_field_list;
} IntrinsicMetadataT deriving (Bits, Eq);
instance DefaultValue#(IntrinsicMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IntrinsicMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IntrinsicMetadataT extract_intrinsic_metadata_t(Bit#(56) data);
  return unpack(data);
endfunction

typedef struct {
  Bit#(8) accept_count;
  Bit#(32) commit_inst;
  Bit#(32) curr_inst;
  Bit#(16) inst_index;
  Bit#(8) committed;
  Bit#(8) next_count;
  Bit#(32) temporary;
} IngressMetadataT deriving (Bits, Eq);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IngressMetadataT extract_ingress_metadata_t(Bit#(136) data);
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
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(4)) intrinsic_metadata$mcast_grp;
  Maybe#(Bit#(16)) ingress_data$inst_index;
  Maybe#(Bit#(16)) fab$replica;
  Maybe#(Bit#(8)) ingress_data$committed;
  Maybe#(Bit#(8)) fab$msgtype;
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(8)) ingress_data$accept_count;
  Maybe#(Bit#(32)) fab$inst;
  Maybe#(Bit#(32)) ingress_data$temporary;
  Maybe#(Bit#(8)) ingress_data$next_count;
  Maybe#(Bit#(32)) ingress_data$curr_inst;
  Maybe#(Bit#(32)) ingress_data$commit_inst;
  Maybe#(Bit#(0)) valid_ethernet;
  Maybe#(Bit#(0)) valid_ipv4;
  Maybe#(Bit#(0)) valid_udp;
  Maybe#(Bit#(0)) valid_fab;
} MetadataT deriving (Bits, Eq);
typedef enum {
  StateParseStart,
  StateParseEthernet,
  StateParseIpv4,
  StateParseUdp,
  StateParseFab
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
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
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
  Reg#(Bit#(240)) rg_tmp_parse_udp <- mkReg(0);
  Reg#(Bit#(304)) rg_tmp_parse_fab <- mkReg(0);
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
      'h55f0: begin
        nextState = StateParseFab;
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
    rg_tmp_parse_ipv4 <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParseEthernet;
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
    rg_tmp_parse_fab <= zeroExtend(pack(unparsed));
    parse_state_w <= StateParseUdp;
    succeed_and_next(rg_offset + 128);
  endrule

  rule rl_parse_parse_fab_0 if ((rg_parse_state == StateParseFab) && (rg_offset == 512));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(176, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_fab));
    Bit#(176) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(304) data = {data_this_cycle, data_last_cycle};
    Vector#(304, Bit#(1)) dataVec = unpack(data);
    let parse_fab = extract_fab_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(232, Bit#(1)) unparsed = takeAt(72, dataVec);
    parse_state_w <= StateParseFab;
    succeed_and_next(rg_offset + 128);
  endrule

endmodule
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4,
  StateDeparseUdp,
  StateDeparseFab
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
      rg_deparse_state <= StateDeparseEthernet;
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
endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
  } BcastReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
  } BroadcastCommitReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
  } BroadcastNoopReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
    Bit#(8) ingress_data$accept_count;
  } IncreaseAcceptReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
    Bit#(32) fab$inst;
  } IncreaseInstanceReqT;
  struct {
    PacketInstance pkt;
  } McastReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
  } ReadAcceptReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) ingress_data$temporary;
  } ReadNextCountReqT;
  struct {
    PacketInstance pkt;
  } ReadRegisterReqT;
  struct {
    PacketInstance pkt;
  } ResendCommitReqT;
  struct {
    PacketInstance pkt;
  } ResendNoopReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) ingress_data$commit_inst;
  } UpdateCommittedInstReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(32) ipv4$dstAddr;
  } DropRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) intrinsic_metadata$mcast_grp;
  } BcastRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) fab$replica;
    Bit#(8) ingress_data$committed;
    Bit#(16) ingress_data$inst_index;
    Bit#(8) fab$msgtype;
  } BroadcastCommitRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ingress_data$committed;
    Bit#(16) ingress_data$inst_index;
    Bit#(8) fab$msgtype;
  } BroadcastNoopRspT;
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
  struct {
    PacketInstance pkt;
    Bit#(32) ipv4$dstAddr;
    Bit#(16) ingress_data$inst_index;
    Bit#(8) ingress_data$accept_count;
  } IncreaseAcceptRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) fab$msgtype;
    Bit#(16) ingress_data$inst_index;
    Bit#(32) fab$inst;
  } IncreaseInstanceRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) intrinsic_metadata$mcast_grp;
  } McastRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) ingress_data$inst_index;
    Bit#(8) ingress_data$accept_count;
  } ReadAcceptRspT;
  struct {
    PacketInstance pkt;
    Bit#(32) ingress_data$temporary;
    Bit#(8) ingress_data$next_count;
  } ReadNextCountRspT;
  struct {
    PacketInstance pkt;
    Bit#(32) ingress_data$curr_inst;
    Bit#(32) ingress_data$commit_inst;
  } ReadRegisterRspT;
  struct {
    PacketInstance pkt;
  } ResendCommitRspT;
  struct {
    PacketInstance pkt;
    Bit#(32) ipv4$dstAddr;
  } ResendNoopRspT;
  struct {
    PacketInstance pkt;
    Bit#(32) ingress_data$commit_inst;
  } UpdateCommittedInstRspT;
} BBResponse deriving (Bits, Eq);
interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkDrop  (Drop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(32)) ipv4$dstAddr <- mkReg(0);
  rule _drop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DropReqT {pkt: .pkt}: begin
        ipv4$dstAddr <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule _drop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged DropRspT {pkt: pkt, ipv4$dstAddr: ipv4$dstAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface Bcast;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkBcast  (Bcast);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) intrinsic_metadata$mcast_grp <- mkReg(0);
  rule bcast_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged BcastReqT {pkt: .pkt}: begin
        intrinsic_metadata$mcast_grp <= 'h5;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule bcast_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged BcastRspT {pkt: pkt, intrinsic_metadata$mcast_grp: intrinsic_metadata$mcast_grp};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface BroadcastCommit;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkBroadcastCommit  (BroadcastCommit);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(8)) rg_0$x$f$f <- mkReg(0);
  Reg#(Bit#(16)) ingress_data$inst_index <- mkReg(0);
  Reg#(Bit#(8)) fab$msgtype <- mkReg(0);
  Reg#(Bit#(16)) fab$replica <- mkReg(0);
  Reg#(Bit#(8)) ingress_data$committed <- mkReg(0);
  rule broadcast_commit_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged BroadcastCommitReqT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index}: begin
        ingress_data$inst_index <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$inst_index), data: 0, write: True };
        tx_info_accept_count.enq(accept_count_req);
        rg_0$x$f$f <= 0$x$f$f;
        fab$msgtype <= 'h3;
        fab$replica <= 'h0;
        ingress_data$committed <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule broadcast_commit_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged BroadcastCommitRspT {pkt: pkt, fab$replica: fab$replica, ingress_data$committed: ingress_data$committed, ingress_data$inst_index: ingress_data$inst_index, fab$msgtype: fab$msgtype};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface BroadcastNoop;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkBroadcastNoop  (BroadcastNoop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(8)) rg_0$x$f$e <- mkReg(0);
  Reg#(Bit#(16)) ingress_data$inst_index <- mkReg(0);
  Reg#(Bit#(8)) fab$msgtype <- mkReg(0);
  Reg#(Bit#(8)) ingress_data$committed <- mkReg(0);
  rule broadcast_noop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged BroadcastNoopReqT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index}: begin
        ingress_data$inst_index <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$inst_index), data: 0, write: True };
        tx_info_accept_count.enq(accept_count_req);
        rg_0$x$f$e <= 0$x$f$e;
        fab$msgtype <= 'h5;
        ingress_data$committed <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule broadcast_noop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged BroadcastNoopRspT {pkt: pkt, ingress_data$committed: ingress_data$committed, ingress_data$inst_index: ingress_data$inst_index, fab$msgtype: fab$msgtype};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
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
interface IncreaseAccept;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIncreaseAccept  (IncreaseAccept);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(8)) rg_ingress_data$accept_count <- mkReg(0);
  Reg#(Bit#(16)) ingress_data$inst_index <- mkReg(0);
  Reg#(Bit#(32)) ipv4$dstAddr <- mkReg(0);
  rule increase_accept_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged IncreaseAcceptReqT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index, ingress_data$accept_count: .ingress_data$accept_count}: begin
        ingress_data$inst_index <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$inst_index), data: ingress_data$accept_count, write: True };
        tx_info_accept_count.enq(accept_count_req);
        rg_ingress_data$accept_count <= ingress_data$accept_count;
        ipv4$dstAddr <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule increase_accept_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged IncreaseAcceptRspT {pkt: pkt, ipv4$dstAddr: ipv4$dstAddr, ingress_data$inst_index: ingress_data$inst_index, ingress_data$accept_count: ingress_data$accept_count};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface IncreaseInstance;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) instance_register;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) instance_register;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIncreaseInstance  (IncreaseInstance);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(1, 32)) tx_instance_register <- mkTX;
  RX #(RegResponse#(32)) rx_instance_register <- mkRX;
  let tx_info_instance_register = tx_instance_register.u;
  let rx_info_instance_register = rx_instance_register.u;
  TX #(RegRequest#(1, 32)) tx_instance_register <- mkTX;
  RX #(RegResponse#(32)) rx_instance_register <- mkRX;
  let tx_info_instance_register = tx_instance_register.u;
  let rx_info_instance_register = rx_instance_register.u;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(32)) rg_fab$inst <- mkReg(0);
  Reg#(Bit#(8)) rg_0$x$1 <- mkReg(0);
  Reg#(Bit#(8)) fab$msgtype <- mkReg(0);
  Reg#(Bit#(16)) ingress_data$inst_index <- mkReg(0);
  rule increase_instance_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged IncreaseInstanceReqT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index, fab$inst: .fab$inst}: begin
        let instance_register_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_instance_register.enq(instance_register_req);
        let instance_register_req = RegRequest { addr: truncate(0), data: fab$inst, write: True };
        tx_info_instance_register.enq(instance_register_req);
        rg_fab$inst <= fab$inst;
        fab$msgtype <= 'h1;
        ingress_data$inst_index <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$inst_index), data: 0, write: True };
        tx_info_accept_count.enq(accept_count_req);
        rg_0$x$1 <= 0$x$1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule increase_instance_response;
    let v_fab$inst = rx_info_instance_register.first;
    rx_info_instance_register.deq;
    let fab$inst = v_fab$inst.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged IncreaseInstanceRspT {pkt: pkt, fab$msgtype: fab$msgtype, ingress_data$inst_index: ingress_data$inst_index, fab$inst: fab$inst};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface instance_register = toClient(tx_instance_register.e, rx_instance_register.e);
  interface instance_register = toClient(tx_instance_register.e, rx_instance_register.e);
  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface Mcast;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkMcast  (Mcast);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) intrinsic_metadata$mcast_grp <- mkReg(0);
  rule mcast_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged McastReqT {pkt: .pkt}: begin
        intrinsic_metadata$mcast_grp <= type$value;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mcast_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged McastRspT {pkt: pkt, intrinsic_metadata$mcast_grp: intrinsic_metadata$mcast_grp};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ReadAccept;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadAccept  (ReadAccept);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(16)) ingress_data$inst_index <- mkReg(0);
  rule read_accept_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadAcceptReqT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index}: begin
        ingress_data$inst_index <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$inst_index), data: ?, write: False };
        tx_info_accept_count.enq(accept_count_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_accept_response;
    let v_ingress_data$accept_count = rx_info_accept_count.first;
    rx_info_accept_count.deq;
    let ingress_data$accept_count = v_ingress_data$accept_count.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadAcceptRspT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index, ingress_data$accept_count: ingress_data$accept_count};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ReadNextCount;
  interface Client#(RegRequest#(8, 8), RegResponse#(8)) accept_count;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadNextCount  (ReadNextCount);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(8, 8)) tx_accept_count <- mkTX;
  RX #(RegResponse#(8)) rx_accept_count <- mkRX;
  let tx_info_accept_count = tx_accept_count.u;
  let rx_info_accept_count = rx_accept_count.u;
  Reg#(Bit#(8)) ingress_data$next_count <- mkReg(0);
  Reg#(Bit#(32)) ingress_data$temporary <- mkReg(0);
  rule read_next_count_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadNextCountReqT {pkt: .pkt, ingress_data$temporary: .ingress_data$temporary}: begin
        ingress_data$next_count <= type$value;
        ingress_data$temporary <= type$value;
        let accept_count_req = RegRequest { addr: truncate(ingress_data$temporary), data: ?, write: False };
        tx_info_accept_count.enq(accept_count_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_next_count_response;
    let v_ingress_data$next_count = rx_info_accept_count.first;
    rx_info_accept_count.deq;
    let ingress_data$next_count = v_ingress_data$next_count.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadNextCountRspT {pkt: pkt, ingress_data$temporary: ingress_data$temporary, ingress_data$next_count: ingress_data$next_count};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface accept_count = toClient(tx_accept_count.e, rx_accept_count.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ReadRegister;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) instance_register;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) committed_inst;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadRegister  (ReadRegister);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(1, 32)) tx_instance_register <- mkTX;
  RX #(RegResponse#(32)) rx_instance_register <- mkRX;
  let tx_info_instance_register = tx_instance_register.u;
  let rx_info_instance_register = rx_instance_register.u;
  TX #(RegRequest#(1, 32)) tx_committed_inst <- mkTX;
  RX #(RegResponse#(32)) rx_committed_inst <- mkRX;
  let tx_info_committed_inst = tx_committed_inst.u;
  let rx_info_committed_inst = rx_committed_inst.u;
  rule read_register_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadRegisterReqT {pkt: .pkt}: begin
        let instance_register_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_instance_register.enq(instance_register_req);
        let committed_inst_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_committed_inst.enq(committed_inst_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_register_response;
    let v_ingress_data$curr_inst = rx_info_instance_register.first;
    rx_info_instance_register.deq;
    let ingress_data$curr_inst = v_ingress_data$curr_inst.data;
    let v_ingress_data$commit_inst = rx_info_committed_inst.first;
    rx_info_committed_inst.deq;
    let ingress_data$commit_inst = v_ingress_data$commit_inst.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadRegisterRspT {pkt: pkt, ingress_data$curr_inst: ingress_data$curr_inst, ingress_data$commit_inst: ingress_data$commit_inst};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface instance_register = toClient(tx_instance_register.e, rx_instance_register.e);
  interface committed_inst = toClient(tx_committed_inst.e, rx_committed_inst.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ResendCommit;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkResendCommit  (ResendCommit);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule resend_commit_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ResendCommitReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule resend_commit_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ResendCommitRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ResendNoop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkResendNoop  (ResendNoop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(32)) ipv4$dstAddr <- mkReg(0);
  rule resend_noop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ResendNoopReqT {pkt: .pkt}: begin
        ipv4$dstAddr <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule resend_noop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ResendNoopRspT {pkt: pkt, ipv4$dstAddr: ipv4$dstAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface UpdateCommittedInst;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) committed_inst;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkUpdateCommittedInst  (UpdateCommittedInst);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(1, 32)) tx_committed_inst <- mkTX;
  RX #(RegResponse#(32)) rx_committed_inst <- mkRX;
  let tx_info_committed_inst = tx_committed_inst.u;
  let rx_info_committed_inst = rx_committed_inst.u;
  Reg#(Bit#(32)) rg_ingress_data$commit_inst <- mkReg(0);
  rule update_committed_inst_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged UpdateCommittedInstReqT {pkt: .pkt, ingress_data$commit_inst: .ingress_data$commit_inst}: begin
        let committed_inst_req = RegRequest { addr: truncate(0), data: ingress_data$commit_inst, write: True };
        tx_info_committed_inst.enq(committed_inst_req);
        rg_ingress_data$commit_inst <= ingress_data$commit_inst;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule update_committed_inst_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged UpdateCommittedInstRspT {pkt: pkt, ingress_data$commit_inst: ingress_data$commit_inst};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface committed_inst = toClient(tx_committed_inst.e, rx_committed_inst.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
typedef struct {
  Bit#(8) ingress_data$accept_count;
  Bit#(1) padding;
} AcceptTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_ACCEPT_TABLE,
  INCREASE_ACCEPT,
  BROADCAST_COMMIT,
  _DROP
} AcceptTableActionT deriving (Bits, Eq);
typedef struct {
  AcceptTableActionT _action;
} AcceptTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(3)) matchtable_read_9_3(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_9_3(Bit#(9) msgtype, Bit#(3) data);
instance MatchTableSim#(9, 3);
  function ActionValue#(Bit#(3)) matchtable_read(Bit#(9) key);
    actionvalue
      let v <- matchtable_read_9_3(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(9) key, Bit#(3) data);
    action
      matchtable_write_9_3(key, data);
    endaction
  endfunction
endinstance
interface AcceptTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
endinterface
module mkAcceptTable  (AcceptTable);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(3, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(3, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(AcceptTableReqT), SizeOf#(AcceptTableRspT)) matchTable <- mkMatchTable();
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
    let ingress_data$accept_count = fromMaybe(?, meta.ingress_data$accept_count);
    AcceptTableReqT req = AcceptTableReqT {ingress_data$accept_count: ingress_data$accept_count};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      AcceptTableRspT resp = unpack(data);
      case (resp._action) matches
        INCREASE_ACCEPT: begin
          BBRequest req = tagged IncreaseAcceptReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index, ingress_data$accept_count: ingress_data$accept_count};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        BROADCAST_COMMIT: begin
          BBRequest req = tagged BroadcastCommitReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
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
      tagged IncreaseAcceptRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr, ingress_data$inst_index: .ingress_data$inst_index, ingress_data$accept_count: .ingress_data$accept_count}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.ingress_data$accept_count = tagged Valid ingress_data$accept_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged BroadcastCommitRspT {pkt: .pkt, fab$replica: .fab$replica, ingress_data$committed: .ingress_data$committed, ingress_data$inst_index: .ingress_data$inst_index, fab$msgtype: .fab$msgtype}: begin
        meta.fab$replica = tagged Valid fab$replica;
        meta.ingress_data$committed = tagged Valid ingress_data$committed;
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.fab$msgtype = tagged Valid fab$msgtype;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
endmodule
typedef struct {
} DropTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_DROP_TABLE,
  _DROP
} DropTableActionT deriving (Bits, Eq);
typedef struct {
  DropTableActionT _action;
} DropTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface DropTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkDropTable  (DropTable);
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
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(32) ipv4$dstAddr;
  Bit#(8) ingress_data$committed;
  Bit#(5) padding;
} FwdTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_FWD_TABLE,
  MCAST,
  FORWARD,
  BCAST,
  _DROP
} FwdTableActionT deriving (Bits, Eq);
typedef struct {
  FwdTableActionT _action;
  Bit#(9) runtime_port;
} FwdTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(13)) matchtable_read_45_13(Bit#(45) msgtype);
import "BDPI" function Action matchtable_write_45_13(Bit#(45) msgtype, Bit#(13) data);
instance MatchTableSim#(45, 13);
  function ActionValue#(Bit#(13)) matchtable_read(Bit#(45) key);
    actionvalue
      let v <- matchtable_read_45_13(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(45) key, Bit#(13) data);
    action
      matchtable_write_45_13(key, data);
    endaction
  endfunction
endinstance
interface FwdTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
  interface Client #(BBRequest, BBResponse) next_control_state_3;
endinterface
module mkFwdTable  (FwdTable);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(4, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(4, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(FwdTableReqT), SizeOf#(FwdTableRspT)) matchTable <- mkMatchTable();
  Vector#(4, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(4) readyChannel = -1;
  for (Integer i=3; i>=0; i=i-1) begin
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
    let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
    let ingress_data$committed = fromMaybe(?, meta.ingress_data$committed);
    FwdTableReqT req = FwdTableReqT {ipv4$dstAddr: ipv4$dstAddr,ingress_data$committed: ingress_data$committed};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      FwdTableRspT resp = unpack(data);
      case (resp._action) matches
        MCAST: begin
          BBRequest req = tagged McastReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        FORWARD: begin
          BBRequest req = tagged ForwardReqT {pkt: pkt, runtime_port: resp.runtime_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        BCAST: begin
          BBRequest req = tagged BcastReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[3].enq(req); //FIXME: replace with RXTX.
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
      tagged McastRspT {pkt: .pkt, intrinsic_metadata$mcast_grp: .intrinsic_metadata$mcast_grp}: begin
        meta.intrinsic_metadata$mcast_grp = tagged Valid intrinsic_metadata$mcast_grp;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged ForwardRspT {pkt: .pkt, standard_metadata$egress_spec: .standard_metadata$egress_spec}: begin
        meta.standard_metadata$egress_spec = tagged Valid standard_metadata$egress_spec;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged BcastRspT {pkt: .pkt, intrinsic_metadata$mcast_grp: .intrinsic_metadata$mcast_grp}: begin
        meta.intrinsic_metadata$mcast_grp = tagged Valid intrinsic_metadata$mcast_grp;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
  interface next_control_state_3 = toClient(bbReqFifo[3], bbRspFifo[3]);
endmodule
typedef struct {
} FlowControlDropReqT deriving (Bits, Eq);
typedef enum {
  NOOP_FLOW_CONTROL_DROP,
  _DROP
} FlowControlDropActionT deriving (Bits, Eq);
typedef struct {
  FlowControlDropActionT _action;
} FlowControlDropRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface FlowControlDrop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkFlowControlDrop  (FlowControlDrop);
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
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadAcceptTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_ACCEPT_TABLE,
  READ_ACCEPT
} ReadAcceptTableActionT deriving (Bits, Eq);
typedef struct {
  ReadAcceptTableActionT _action;
} ReadAcceptTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadAcceptTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadAcceptTable  (ReadAcceptTable);
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
    let ingress_data$inst_index = fromMaybe(?, meta.ingress_data$inst_index);
    BBRequest req = tagged ReadAcceptReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadAcceptRspT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index, ingress_data$accept_count: .ingress_data$accept_count}: begin
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.ingress_data$accept_count = tagged Valid ingress_data$accept_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} OldAcceptDropReqT deriving (Bits, Eq);
typedef enum {
  NOOP_OLD_ACCEPT_DROP,
  _DROP
} OldAcceptDropActionT deriving (Bits, Eq);
typedef struct {
  OldAcceptDropActionT _action;
} OldAcceptDropRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface OldAcceptDrop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkOldAcceptDrop  (OldAcceptDrop);
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
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} OutdateQueryDropReqT deriving (Bits, Eq);
typedef enum {
  NOOP_OUTDATE_QUERY_DROP,
  _DROP
} OutdateQueryDropActionT deriving (Bits, Eq);
typedef struct {
  OutdateQueryDropActionT _action;
} OutdateQueryDropRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface OutdateQueryDrop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkOutdateQueryDrop  (OutdateQueryDrop);
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
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadAcceptTableQueryReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_ACCEPT_TABLE_QUERY,
  READ_ACCEPT
} ReadAcceptTableQueryActionT deriving (Bits, Eq);
typedef struct {
  ReadAcceptTableQueryActionT _action;
} ReadAcceptTableQueryRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadAcceptTableQuery;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadAcceptTableQuery  (ReadAcceptTableQuery);
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
    let ingress_data$inst_index = fromMaybe(?, meta.ingress_data$inst_index);
    BBRequest req = tagged ReadAcceptReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadAcceptRspT {pkt: .pkt, ingress_data$inst_index: .ingress_data$inst_index, ingress_data$accept_count: .ingress_data$accept_count}: begin
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.ingress_data$accept_count = tagged Valid ingress_data$accept_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadNextcountTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_NEXTCOUNT_TABLE,
  READ_NEXT_COUNT
} ReadNextcountTableActionT deriving (Bits, Eq);
typedef struct {
  ReadNextcountTableActionT _action;
} ReadNextcountTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadNextcountTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadNextcountTable  (ReadNextcountTable);
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
    let ingress_data$temporary = fromMaybe(?, meta.ingress_data$temporary);
    BBRequest req = tagged ReadNextCountReqT {pkt: pkt, ingress_data$temporary: ingress_data$temporary};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadNextCountRspT {pkt: .pkt, ingress_data$temporary: .ingress_data$temporary, ingress_data$next_count: .ingress_data$next_count}: begin
        meta.ingress_data$temporary = tagged Valid ingress_data$temporary;
        meta.ingress_data$next_count = tagged Valid ingress_data$next_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadNextcountTableAftercommitReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_NEXTCOUNT_TABLE_AFTERCOMMIT,
  READ_NEXT_COUNT
} ReadNextcountTableAftercommitActionT deriving (Bits, Eq);
typedef struct {
  ReadNextcountTableAftercommitActionT _action;
} ReadNextcountTableAftercommitRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadNextcountTableAftercommit;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadNextcountTableAftercommit  (ReadNextcountTableAftercommit);
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
    let ingress_data$temporary = fromMaybe(?, meta.ingress_data$temporary);
    BBRequest req = tagged ReadNextCountReqT {pkt: pkt, ingress_data$temporary: ingress_data$temporary};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadNextCountRspT {pkt: .pkt, ingress_data$temporary: .ingress_data$temporary, ingress_data$next_count: .ingress_data$next_count}: begin
        meta.ingress_data$temporary = tagged Valid ingress_data$temporary;
        meta.ingress_data$next_count = tagged Valid ingress_data$next_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadNextcountTableAfternoopReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_NEXTCOUNT_TABLE_AFTERNOOP,
  READ_NEXT_COUNT
} ReadNextcountTableAfternoopActionT deriving (Bits, Eq);
typedef struct {
  ReadNextcountTableAfternoopActionT _action;
} ReadNextcountTableAfternoopRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadNextcountTableAfternoop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadNextcountTableAfternoop  (ReadNextcountTableAfternoop);
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
    let ingress_data$temporary = fromMaybe(?, meta.ingress_data$temporary);
    BBRequest req = tagged ReadNextCountReqT {pkt: pkt, ingress_data$temporary: ingress_data$temporary};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadNextCountRspT {pkt: .pkt, ingress_data$temporary: .ingress_data$temporary, ingress_data$next_count: .ingress_data$next_count}: begin
        meta.ingress_data$temporary = tagged Valid ingress_data$temporary;
        meta.ingress_data$next_count = tagged Valid ingress_data$next_count;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} ReadRegTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_READ_REG_TABLE,
  READ_REGISTER
} ReadRegTableActionT deriving (Bits, Eq);
typedef struct {
  ReadRegTableActionT _action;
} ReadRegTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface ReadRegTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkReadRegTable  (ReadRegTable);
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
    BBRequest req = tagged ReadRegisterReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadRegisterRspT {pkt: .pkt, ingress_data$curr_inst: .ingress_data$curr_inst, ingress_data$commit_inst: .ingress_data$commit_inst}: begin
        meta.ingress_data$curr_inst = tagged Valid ingress_data$curr_inst;
        meta.ingress_data$commit_inst = tagged Valid ingress_data$commit_inst;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(8) ingress_data$accept_count;
  Bit#(1) padding;
} ReplyQueryTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_REPLY_QUERY_TABLE,
  RESEND_COMMIT,
  BROADCAST_NOOP,
  RESEND_NOOP,
  _DROP
} ReplyQueryTableActionT deriving (Bits, Eq);
typedef struct {
  ReplyQueryTableActionT _action;
} ReplyQueryTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(4)) matchtable_read_9_4(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_9_4(Bit#(9) msgtype, Bit#(4) data);
instance MatchTableSim#(9, 4);
  function ActionValue#(Bit#(4)) matchtable_read(Bit#(9) key);
    actionvalue
      let v <- matchtable_read_9_4(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(9) key, Bit#(4) data);
    action
      matchtable_write_9_4(key, data);
    endaction
  endfunction
endinstance
interface ReplyQueryTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
  interface Client #(BBRequest, BBResponse) next_control_state_3;
endinterface
module mkReplyQueryTable  (ReplyQueryTable);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(4, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(4, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(16384, SizeOf#(ReplyQueryTableReqT), SizeOf#(ReplyQueryTableRspT)) matchTable <- mkMatchTable();
  Vector#(4, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(4) readyChannel = -1;
  for (Integer i=3; i>=0; i=i-1) begin
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
    let ingress_data$accept_count = fromMaybe(?, meta.ingress_data$accept_count);
    ReplyQueryTableReqT req = ReplyQueryTableReqT {ingress_data$accept_count: ingress_data$accept_count};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ReplyQueryTableRspT resp = unpack(data);
      case (resp._action) matches
        RESEND_COMMIT: begin
          BBRequest req = tagged ResendCommitReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        BROADCAST_NOOP: begin
          BBRequest req = tagged BroadcastNoopReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        RESEND_NOOP: begin
          BBRequest req = tagged ResendNoopReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[3].enq(req); //FIXME: replace with RXTX.
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
      tagged ResendCommitRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged BroadcastNoopRspT {pkt: .pkt, ingress_data$committed: .ingress_data$committed, ingress_data$inst_index: .ingress_data$inst_index, fab$msgtype: .fab$msgtype}: begin
        meta.ingress_data$committed = tagged Valid ingress_data$committed;
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.fab$msgtype = tagged Valid fab$msgtype;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged ResendNoopRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt, ipv4$dstAddr: .ipv4$dstAddr}: begin
        meta.ipv4$dstAddr = tagged Valid ipv4$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
  interface next_control_state_3 = toClient(bbReqFifo[3], bbRspFifo[3]);
endmodule
typedef struct {
} SequencerTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_SEQUENCER_TABLE,
  INCREASE_INSTANCE
} SequencerTableActionT deriving (Bits, Eq);
typedef struct {
  SequencerTableActionT _action;
} SequencerTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface SequencerTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkSequencerTable  (SequencerTable);
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
    let ingress_data$inst_index = fromMaybe(?, meta.ingress_data$inst_index);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    BBRequest req = tagged IncreaseInstanceReqT {pkt: pkt, ingress_data$inst_index: ingress_data$inst_index, fab$inst: fab$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged IncreaseInstanceRspT {pkt: .pkt, fab$msgtype: .fab$msgtype, ingress_data$inst_index: .ingress_data$inst_index, fab$inst: .fab$inst}: begin
        meta.fab$msgtype = tagged Valid fab$msgtype;
        meta.ingress_data$inst_index = tagged Valid ingress_data$inst_index;
        meta.fab$inst = tagged Valid fab$inst;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} UpdateCommitTableReqT deriving (Bits, Eq);
typedef enum {
  NOOP_UPDATE_COMMIT_TABLE,
  UPDATE_COMMITTED_INST
} UpdateCommitTableActionT deriving (Bits, Eq);
typedef struct {
  UpdateCommitTableActionT _action;
} UpdateCommitTableRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface UpdateCommitTable;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkUpdateCommitTable  (UpdateCommitTable);
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
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    BBRequest req = tagged UpdateCommittedInstReqT {pkt: pkt, ingress_data$commit_inst: ingress_data$commit_inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged UpdateCommittedInstRspT {pkt: .pkt, ingress_data$commit_inst: .ingress_data$commit_inst}: begin
        meta.ingress_data$commit_inst = tagged Valid ingress_data$commit_inst;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} UpdateCommitTableAftercommitReqT deriving (Bits, Eq);
typedef enum {
  NOOP_UPDATE_COMMIT_TABLE_AFTERCOMMIT,
  UPDATE_COMMITTED_INST
} UpdateCommitTableAftercommitActionT deriving (Bits, Eq);
typedef struct {
  UpdateCommitTableAftercommitActionT _action;
} UpdateCommitTableAftercommitRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface UpdateCommitTableAftercommit;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkUpdateCommitTableAftercommit  (UpdateCommitTableAftercommit);
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
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    BBRequest req = tagged UpdateCommittedInstReqT {pkt: pkt, ingress_data$commit_inst: ingress_data$commit_inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged UpdateCommittedInstRspT {pkt: .pkt, ingress_data$commit_inst: .ingress_data$commit_inst}: begin
        meta.ingress_data$commit_inst = tagged Valid ingress_data$commit_inst;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
} UpdateCommitTableAfternoopReqT deriving (Bits, Eq);
typedef enum {
  NOOP_UPDATE_COMMIT_TABLE_AFTERNOOP,
  UPDATE_COMMITTED_INST
} UpdateCommitTableAfternoopActionT deriving (Bits, Eq);
typedef struct {
  UpdateCommitTableAfternoopActionT _action;
} UpdateCommitTableAfternoopRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_0_1(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_0_1(Bit#(0) msgtype, Bit#(1) data);
instance MatchTableSim#(0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) key);
    actionvalue
      let v <- matchtable_read_0_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_0_1(key, data);
    endaction
  endfunction
endinstance
interface UpdateCommitTableAfternoop;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkUpdateCommitTableAfternoop  (UpdateCommitTableAfternoop);
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
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    BBRequest req = tagged UpdateCommittedInstReqT {pkt: pkt, ingress_data$commit_inst: ingress_data$commit_inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged UpdateCommittedInstRspT {pkt: .pkt, ingress_data$commit_inst: .ingress_data$commit_inst}: begin
        meta.ingress_data$commit_inst = tagged Valid ingress_data$commit_inst;
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
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) accept_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) accept_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) drop_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_control_drop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) flow_control_drop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) fwd_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) fwd_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) old_accept_drop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) old_accept_drop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) outdate_query_drop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) outdate_query_drop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_accept_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_accept_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_accept_table_query_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_accept_table_query_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_nextcount_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_nextcount_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_nextcount_table_aftercommit_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_nextcount_table_aftercommit_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_nextcount_table_afternoop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_nextcount_table_afternoop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) read_reg_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) read_reg_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) reply_query_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) reply_query_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) sequencer_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) sequencer_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) update_commit_table_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) update_commit_table_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) update_commit_table_aftercommit_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) update_commit_table_aftercommit_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) update_commit_table_afternoop_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) update_commit_table_afternoop_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  AcceptTable accept_table <- mkAcceptTable();
  DropTable drop_table <- mkDropTable();
  FlowControlDrop flow_control_drop <- mkFlowControlDrop();
  FwdTable fwd_table <- mkFwdTable();
  OldAcceptDrop old_accept_drop <- mkOldAcceptDrop();
  OutdateQueryDrop outdate_query_drop <- mkOutdateQueryDrop();
  ReadAcceptTable read_accept_table <- mkReadAcceptTable();
  ReadAcceptTableQuery read_accept_table_query <- mkReadAcceptTableQuery();
  ReadNextcountTable read_nextcount_table <- mkReadNextcountTable();
  ReadNextcountTableAftercommit read_nextcount_table_aftercommit <- mkReadNextcountTableAftercommit();
  ReadNextcountTableAfternoop read_nextcount_table_afternoop <- mkReadNextcountTableAfternoop();
  ReadRegTable read_reg_table <- mkReadRegTable();
  ReplyQueryTable reply_query_table <- mkReplyQueryTable();
  SequencerTable sequencer_table <- mkSequencerTable();
  UpdateCommitTable update_commit_table <- mkUpdateCommitTable();
  UpdateCommitTableAftercommit update_commit_table_aftercommit <- mkUpdateCommitTableAftercommit();
  UpdateCommitTableAfternoop update_commit_table_afternoop <- mkUpdateCommitTableAfternoop();
  mkConnection(toClient(accept_table_req_ff, accept_table_rsp_ff), accept_table.prev_control_state_0);
  mkConnection(toClient(drop_table_req_ff, drop_table_rsp_ff), drop_table.prev_control_state_0);
  mkConnection(toClient(flow_control_drop_req_ff, flow_control_drop_rsp_ff), flow_control_drop.prev_control_state_0);
  mkConnection(toClient(fwd_table_req_ff, fwd_table_rsp_ff), fwd_table.prev_control_state_0);
  mkConnection(toClient(old_accept_drop_req_ff, old_accept_drop_rsp_ff), old_accept_drop.prev_control_state_0);
  mkConnection(toClient(outdate_query_drop_req_ff, outdate_query_drop_rsp_ff), outdate_query_drop.prev_control_state_0);
  mkConnection(toClient(read_accept_table_req_ff, read_accept_table_rsp_ff), read_accept_table.prev_control_state_0);
  mkConnection(toClient(read_accept_table_query_req_ff, read_accept_table_query_rsp_ff), read_accept_table_query.prev_control_state_0);
  mkConnection(toClient(read_nextcount_table_req_ff, read_nextcount_table_rsp_ff), read_nextcount_table.prev_control_state_0);
  mkConnection(toClient(read_nextcount_table_aftercommit_req_ff, read_nextcount_table_aftercommit_rsp_ff), read_nextcount_table_aftercommit.prev_control_state_0);
  mkConnection(toClient(read_nextcount_table_afternoop_req_ff, read_nextcount_table_afternoop_rsp_ff), read_nextcount_table_afternoop.prev_control_state_0);
  mkConnection(toClient(read_reg_table_req_ff, read_reg_table_rsp_ff), read_reg_table.prev_control_state_0);
  mkConnection(toClient(reply_query_table_req_ff, reply_query_table_rsp_ff), reply_query_table.prev_control_state_0);
  mkConnection(toClient(sequencer_table_req_ff, sequencer_table_rsp_ff), sequencer_table.prev_control_state_0);
  mkConnection(toClient(update_commit_table_req_ff, update_commit_table_rsp_ff), update_commit_table.prev_control_state_0);
  mkConnection(toClient(update_commit_table_aftercommit_req_ff, update_commit_table_aftercommit_rsp_ff), update_commit_table_aftercommit.prev_control_state_0);
  mkConnection(toClient(update_commit_table_afternoop_req_ff, update_commit_table_afternoop_rsp_ff), update_commit_table_afternoop.prev_control_state_0);
  // Basic Blocks
  IncreaseAccept increase_accept_0 <- mkIncreaseAccept();
  BroadcastCommit broadcast_commit_0 <- mkBroadcastCommit();
  Drop _drop_0 <- mkDrop();
  Drop _drop_1 <- mkDrop();
  Drop _drop_2 <- mkDrop();
  Mcast mcast_0 <- mkMcast();
  Forward forward_0 <- mkForward();
  Bcast bcast_0 <- mkBcast();
  Drop _drop_3 <- mkDrop();
  Drop _drop_4 <- mkDrop();
  Drop _drop_5 <- mkDrop();
  ReadAccept read_accept_0 <- mkReadAccept();
  ReadAccept read_accept_1 <- mkReadAccept();
  ReadNextCount read_next_count_0 <- mkReadNextCount();
  ReadNextCount read_next_count_1 <- mkReadNextCount();
  ReadNextCount read_next_count_2 <- mkReadNextCount();
  ReadRegister read_register_0 <- mkReadRegister();
  ResendCommit resend_commit_0 <- mkResendCommit();
  BroadcastNoop broadcast_noop_0 <- mkBroadcastNoop();
  ResendNoop resend_noop_0 <- mkResendNoop();
  Drop _drop_6 <- mkDrop();
  IncreaseInstance increase_instance_0 <- mkIncreaseInstance();
  UpdateCommittedInst update_committed_inst_0 <- mkUpdateCommittedInst();
  UpdateCommittedInst update_committed_inst_1 <- mkUpdateCommittedInst();
  UpdateCommittedInst update_committed_inst_2 <- mkUpdateCommittedInst();
  RegisterIfc#(1, 32) instance_register <- mkP4Register(nil);
  RegisterIfc#(1, 32) committed_inst <- mkP4Register(nil);
  RegisterIfc#(8, 8) accept_count <- mkP4Register(nil);
  mkChan(mkFIFOF, mkFIFOF, accept_table.next_control_state_0, increase_accept_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, accept_table.next_control_state_1, broadcast_commit_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, accept_table.next_control_state_2, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, drop_table.next_control_state_0, _drop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_control_drop.next_control_state_0, _drop_2.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, fwd_table.next_control_state_0, mcast_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, fwd_table.next_control_state_1, forward_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, fwd_table.next_control_state_2, bcast_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, fwd_table.next_control_state_3, _drop_3.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, old_accept_drop.next_control_state_0, _drop_4.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, outdate_query_drop.next_control_state_0, _drop_5.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_accept_table.next_control_state_0, read_accept_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_accept_table_query.next_control_state_0, read_accept_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_nextcount_table.next_control_state_0, read_next_count_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_nextcount_table_aftercommit.next_control_state_0, read_next_count_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_nextcount_table_afternoop.next_control_state_0, read_next_count_2.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, read_reg_table.next_control_state_0, read_register_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, reply_query_table.next_control_state_0, resend_commit_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, reply_query_table.next_control_state_1, broadcast_noop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, reply_query_table.next_control_state_2, resend_noop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, reply_query_table.next_control_state_3, _drop_6.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, sequencer_table.next_control_state_0, increase_instance_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, update_commit_table.next_control_state_0, update_committed_inst_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, update_commit_table_aftercommit.next_control_state_0, update_committed_inst_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, update_commit_table_afternoop.next_control_state_0, update_committed_inst_2.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_fab)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_reg_table_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      drop_table_req_ff.enq(req);
    end
  endrule

  rule accept_table_next_state if (accept_table_rsp_ff.notEmpty);
    accept_table_rsp_ff.deq;
    let _req = accept_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$committed = fromMaybe(?, meta.ingress_data$committed);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
  endrule

  rule drop_table_next_state if (drop_table_rsp_ff.notEmpty);
    drop_table_rsp_ff.deq;
    let _req = drop_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule flow_control_drop_next_state if (flow_control_drop_rsp_ff.notEmpty);
    flow_control_drop_rsp_ff.deq;
    let _req = flow_control_drop_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$curr_inst = fromMaybe(?, meta.ingress_data$curr_inst);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( fab$msgtype == 0x2 )) begin
      if (( ( fab$inst <= ingress_data$commit_inst ) or ( fab$inst > ingress_data$curr_inst ) )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        old_accept_drop_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        read_accept_table_req_ff.enq(req);
      end
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
  endrule

  rule fwd_table_next_state if (fwd_table_rsp_ff.notEmpty);
    fwd_table_rsp_ff.deq;
    let _req = fwd_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule old_accept_drop_next_state if (old_accept_drop_rsp_ff.notEmpty);
    old_accept_drop_rsp_ff.deq;
    let _req = old_accept_drop_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( fab$msgtype == 0x4 )) begin
      if (( fab$inst <= ingress_data$commit_inst )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        outdate_query_drop_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        read_accept_table_query_req_ff.enq(req);
      end
    end
  endrule

  rule outdate_query_drop_next_state if (outdate_query_drop_rsp_ff.notEmpty);
    outdate_query_drop_rsp_ff.deq;
    let _req = outdate_query_drop_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule read_accept_table_next_state if (read_accept_table_rsp_ff.notEmpty);
    read_accept_table_rsp_ff.deq;
    let _req = read_accept_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$committed = fromMaybe(?, meta.ingress_data$committed);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
  endrule

  rule read_accept_table_query_next_state if (read_accept_table_query_rsp_ff.notEmpty);
    read_accept_table_query_rsp_ff.deq;
    let _req = read_accept_table_query_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$committed = fromMaybe(?, meta.ingress_data$committed);
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
  endrule

  rule read_nextcount_table_next_state if (read_nextcount_table_rsp_ff.notEmpty);
    read_nextcount_table_rsp_ff.deq;
    let _req = read_nextcount_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$curr_inst = fromMaybe(?, meta.ingress_data$curr_inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let ingress_data$next_count = fromMaybe(?, meta.ingress_data$next_count);
    if (( ingress_data$commit_inst < ingress_data$curr_inst )) begin
      if (( ( ingress_data$next_count == 0xff ) or ( ingress_data$next_count == 0xfe ) )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        update_commit_table_req_ff.enq(req);
      end
      else begin
        if (( ingress_data$curr_inst >= ( ingress_data$commit_inst + 0x8 ) )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          flow_control_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          sequencer_table_req_ff.enq(req);
        end
      end
    end
    else begin
      if (( ingress_data$curr_inst >= ( ingress_data$commit_inst + 0x8 ) )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        flow_control_drop_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        sequencer_table_req_ff.enq(req);
      end
    end
  endrule

  rule read_nextcount_table_aftercommit_next_state if (read_nextcount_table_aftercommit_rsp_ff.notEmpty);
    read_nextcount_table_aftercommit_rsp_ff.deq;
    let _req = read_nextcount_table_aftercommit_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$next_count = fromMaybe(?, meta.ingress_data$next_count);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( ingress_data$next_count == 0xff )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      update_commit_table_aftercommit_req_ff.enq(req);
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
  endrule

  rule read_nextcount_table_afternoop_next_state if (read_nextcount_table_afternoop_rsp_ff.notEmpty);
    read_nextcount_table_afternoop_rsp_ff.deq;
    let _req = read_nextcount_table_afternoop_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$next_count = fromMaybe(?, meta.ingress_data$next_count);
    if (( ( ingress_data$next_count == 0xff ) or ( ingress_data$next_count == 0xfe ) )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      update_commit_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
  endrule

  rule read_reg_table_next_state if (read_reg_table_rsp_ff.notEmpty);
    read_reg_table_rsp_ff.deq;
    let _req = read_reg_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$curr_inst = fromMaybe(?, meta.ingress_data$curr_inst);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( fab$msgtype == 0x0 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_req_ff.enq(req);
    end
    else begin
      if (( fab$msgtype == 0x2 )) begin
        if (( ( fab$inst <= ingress_data$commit_inst ) or ( fab$inst > ingress_data$curr_inst ) )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          old_accept_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_req_ff.enq(req);
        end
      end
      else begin
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          fwd_table_req_ff.enq(req);
        end
        if (( fab$msgtype == 0x4 )) begin
          if (( fab$inst <= ingress_data$commit_inst )) begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            outdate_query_drop_req_ff.enq(req);
          end
          else begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            read_accept_table_query_req_ff.enq(req);
          end
        end
      end
    end
  endrule

  rule reply_query_table_next_state if (reply_query_table_rsp_ff.notEmpty);
    reply_query_table_rsp_ff.deq;
    let _req = reply_query_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$committed = fromMaybe(?, meta.ingress_data$committed);
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( ingress_data$committed == 0x1 )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      read_nextcount_table_afternoop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
  endrule

  rule sequencer_table_next_state if (sequencer_table_rsp_ff.notEmpty);
    sequencer_table_rsp_ff.deq;
    let _req = sequencer_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$curr_inst = fromMaybe(?, meta.ingress_data$curr_inst);
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    if (( fab$msgtype == 0x2 )) begin
      if (( ( fab$inst <= ingress_data$commit_inst ) or ( fab$inst > ingress_data$curr_inst ) )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        old_accept_drop_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        read_accept_table_req_ff.enq(req);
      end
    end
    else begin
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        fwd_table_req_ff.enq(req);
      end
      if (( fab$msgtype == 0x4 )) begin
        if (( fab$inst <= ingress_data$commit_inst )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          outdate_query_drop_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          read_accept_table_query_req_ff.enq(req);
        end
      end
    end
  endrule

  rule update_commit_table_next_state if (update_commit_table_rsp_ff.notEmpty);
    update_commit_table_rsp_ff.deq;
    let _req = update_commit_table_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ingress_data$curr_inst = fromMaybe(?, meta.ingress_data$curr_inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    if (( ingress_data$curr_inst >= ( ingress_data$commit_inst + 0x8 ) )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      flow_control_drop_req_ff.enq(req);
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      sequencer_table_req_ff.enq(req);
    end
  endrule

  rule update_commit_table_aftercommit_next_state if (update_commit_table_aftercommit_rsp_ff.notEmpty);
    update_commit_table_aftercommit_rsp_ff.deq;
    let _req = update_commit_table_aftercommit_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let fab$inst = fromMaybe(?, meta.fab$inst);
    let ingress_data$commit_inst = fromMaybe(?, meta.ingress_data$commit_inst);
    let fab$msgtype = fromMaybe(?, meta.fab$msgtype);
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_table_req_ff.enq(req);
    end
    if (( fab$msgtype == 0x4 )) begin
      if (( fab$inst <= ingress_data$commit_inst )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        outdate_query_drop_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        read_accept_table_query_req_ff.enq(req);
      end
    end
  endrule

  rule update_commit_table_afternoop_next_state if (update_commit_table_afternoop_rsp_ff.notEmpty);
    update_commit_table_afternoop_rsp_ff.deq;
    let _req = update_commit_table_afternoop_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

endmodule
interface Egress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  RegisterIfc#(1, 32) instance_register <- mkP4Register(nil);
  RegisterIfc#(1, 32) committed_inst <- mkP4Register(nil);
  RegisterIfc#(8, 8) accept_count <- mkP4Register(nil);
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
