
import BuildVector::*;
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
  Bit#(32) nhop_ipv4;
} RoutingMetadataT deriving (Bits, Eq);
instance DefaultValue#(RoutingMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(RoutingMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function RoutingMetadataT extract_routing_metadata_t(Bit#(32) data);
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
  Maybe#(Bit#(48)) ethernet$srcAddr;
  Maybe#(Bit#(48)) runtime_smac;
  Maybe#(Bit#(48)) ethernet$dstAddr;
  Maybe#(Bit#(48)) runtime_dmac;
  Maybe#(Bit#(8)) ipv4$ttl;
  Maybe#(Bit#(9)) standard_metadata$egress_port;
  Maybe#(Bit#(32)) routing_metadata$nhop_ipv4;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(32)) runtime_nhop_ipv4;
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(0)) valid_ethernet;
  Maybe#(Bit#(0)) valid_ipv4;
} MetadataT deriving (Bits, Eq);
typedef enum {
  StateParseStart,
  StateParseEthernet,
  StateParseIpv4
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
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
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
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

  rule start_state if (rg_parse_state == StateParseStart);
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
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    parse_state_w <= StateParseIpv4;
    succeed_and_next(rg_offset + 128);
  endrule

endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
    Bit#(48) runtime_smac;
  } RewriteMacReqT;
  struct {
    PacketInstance pkt;
    Bit#(48) runtime_dmac;
  } SetDmacReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
    Bit#(32) runtime_nhop_ipv4;
  } SetNhopReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
    Bit#(48) ethernet$srcAddr;
  } RewriteMacRspT;
  struct {
    PacketInstance pkt;
    Bit#(48) ethernet$dstAddr;
  } SetDmacRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ipv4$ttl;
    Bit#(9) standard_metadata$egress_port;
    Bit#(32) routing_metadata$nhop_ipv4;
  } SetNhopRspT;
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
interface RewriteMac;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkRewriteMac(RewriteMac);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule rewrite_mac_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged RewriteMacReqT {pkt: .pkt, runtime_smac: .runtime_smac}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule rewrite_mac_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged RewriteMacRspT {pkt: pkt, ethernet$srcAddr: ethernet$srcAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface SetDmac;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkSetDmac(SetDmac);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule set_dmac_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetDmacReqT {pkt: .pkt, runtime_dmac: .runtime_dmac}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_dmac_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetDmacRspT {pkt: pkt, ethernet$dstAddr: ethernet$dstAddr};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface SetNhop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkSetNhop(SetNhop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule set_nhop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetNhopReqT {pkt: .pkt, runtime_port: .runtime_port, runtime_nhop_ipv4: .runtime_nhop_ipv4}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_nhop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetNhopRspT {pkt: pkt, ipv4$ttl: ipv4$ttl, standard_metadata$egress_port: standard_metadata$egress_port, routing_metadata$nhop_ipv4: routing_metadata$nhop_ipv4};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
typedef struct {
  Bit#(32) routing_metadata$nhop_ipv4;
  Bit#(4) padding;
} ForwardReqT deriving (Bits, Eq);
typedef enum {
  SETDMAC,
  DROP
} ForwardActionT deriving (Bits, Eq);
typedef struct {
  ForwardActionT _action;
  Bit#(48) runtime_dmac;
} ForwardRspT deriving (Bits, Eq);
interface Forward;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkForward(Forward);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(512, SizeOf#(ForwardReqT), SizeOf#(ForwardRspT)) matchTable <- mkMatchTable();
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
    let routing_metadata$nhop_ipv4 = fromMaybe(?, meta.routing_metadata$nhop_ipv4);
    ForwardReqT req = ForwardReqT {routing_metadata$nhop_ipv4: routing_metadata$nhop_ipv4};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ForwardRspT resp = unpack(data);
      case (resp._action) matches
        SET_DMAC: begin
          BBRequest req = tagged SetDmacReqT {pkt: pkt, runtime_dmac: resp.runtime_dmac};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
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
      tagged SetDmacRspT {pkt: .pkt, ethernet$dstAddr: .ethernet$dstAddr}: begin
        meta.ethernet$dstAddr = tagged Valid ethernet$dstAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
typedef struct {
  Bit#(32) ipv4$dstAddr;
  Bit#(4) padding;
} Ipv4LpmReqT deriving (Bits, Eq);
typedef enum {
  SETNHOP,
  DROP
} Ipv4LpmActionT deriving (Bits, Eq);
typedef struct {
  Ipv4LpmActionT _action;
  Bit#(32) runtime_nhop_ipv4;
  Bit#(9) runtime_port;
} Ipv4LpmRspT deriving (Bits, Eq);
interface Ipv4Lpm;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkIpv4Lpm(Ipv4Lpm);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1024, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRspT)) matchTable <- mkMatchTable();
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
    let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
    Ipv4LpmReqT req = Ipv4LpmReqT {ipv4$dstAddr: ipv4$dstAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv4LpmRspT resp = unpack(data);
      case (resp._action) matches
        SET_NHOP: begin
          BBRequest req = tagged SetNhopReqT {pkt: pkt, runtime_port: resp.runtime_port, runtime_nhop_ipv4: resp.runtime_nhop_ipv4};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
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
      tagged SetNhopRspT {pkt: .pkt, ipv4$ttl: .ipv4$ttl, standard_metadata$egress_port: .standard_metadata$egress_port, routing_metadata$nhop_ipv4: .routing_metadata$nhop_ipv4}: begin
        meta.ipv4$ttl = tagged Valid ipv4$ttl;
        meta.standard_metadata$egress_port = tagged Valid standard_metadata$egress_port;
        meta.routing_metadata$nhop_ipv4 = tagged Valid routing_metadata$nhop_ipv4;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
interface Ingress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkIngress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) forward_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ipv4_lpm_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  Forward forward <- mkForward();
  Ipv4Lpm ipv4_lpm <- mkIpv4Lpm();
  mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state_0);
  mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state_0);
  // Basic Blocks
  SetDmac set_dmac <- mkSetDmac();
  Drop _drop <- mkDrop();
  SetNhop set_nhop <- mkSetNhop();
  Drop _drop <- mkDrop();
  mkConnection(forward.next_control_state_0, set_dmac.prev_control_state);
  mkConnection(forward.next_control_state_1, _drop.prev_control_state);
  mkConnection(ipv4_lpm.next_control_state_0, set_nhop.prev_control_state);
  mkConnection(ipv4_lpm.next_control_state_1, _drop.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (( ( valid ipv4 ) and ( ipv4$ttl > 0x0 ) )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ipv4_lpm_req_ff.enq(req);
    end
  endrule

  rule forward_next_state if (forward_rsp_ff.notEmpty);
    forward_rsp_ff.deq;
    let _req = forward_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule ipv4_lpm_next_state if (ipv4_lpm_rsp_ff.notEmpty);
    ipv4_lpm_rsp_ff.deq;
    let _req = ipv4_lpm_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

endmodule
typedef struct {
  Bit#(9) standard_metadata$egress_port;
} SendFrameReqT deriving (Bits, Eq);
typedef enum {
  REWRITEMAC,
  DROP
} SendFrameActionT deriving (Bits, Eq);
typedef struct {
  SendFrameActionT _action;
  Bit#(48) runtime_smac;
} SendFrameRspT deriving (Bits, Eq);
interface SendFrame;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkSendFrame(SendFrame);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRspT)) matchTable <- mkMatchTable();
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
    let standard_metadata$egress_port = fromMaybe(?, meta.standard_metadata$egress_port);
    SendFrameReqT req = SendFrameReqT {standard_metadata$egress_port: standard_metadata$egress_port};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      SendFrameRspT resp = unpack(data);
      case (resp._action) matches
        REWRITE_MAC: begin
          BBRequest req = tagged RewriteMacReqT {pkt: pkt, runtime_smac: resp.runtime_smac};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        _DROP: begin
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
      tagged RewriteMacRspT {pkt: .pkt, ethernet$srcAddr: .ethernet$srcAddr}: begin
        meta.ethernet$srcAddr = tagged Valid ethernet$srcAddr;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
interface Egress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkEgress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) send_frame_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) send_frame_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  SendFrame send_frame <- mkSendFrame();
  mkConnection(toClient(send_frame_req_ff, send_frame_rsp_ff), send_frame.prev_control_state_0);
  // Basic Blocks
  RewriteMac rewrite_mac <- mkRewriteMac();
  Drop _drop <- mkDrop();
  mkConnection(send_frame.next_control_state_0, rewrite_mac.prev_control_state);
  mkConnection(send_frame.next_control_state_1, _drop.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule send_frame_next_state if (send_frame_rsp_ff.notEmpty);
    send_frame_rsp_ff.deq;
    let _req = send_frame_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
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
