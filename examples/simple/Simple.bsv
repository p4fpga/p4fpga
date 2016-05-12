
typedef struct {
  Bit#(1) hit;
  Bit#(1) p4_action;
  Bit#(9) action_1_arg0;
} RoutingRespT deriving (Bits, Eq);

instance DefaultValue#(RoutingRespT);
  defaultValue = unpack(0);
endinstance

instance FShow#(RoutingRespT);
  function Fmt fshow(RoutingRespT p);
    return $format("RoutingRespT: hit=%h, p4_action=%h, action_1_arg0=%h", p.hit, p.p4_action, p.action_1_arg0);
  endfunction
endinstance

function RoutingRespT extract_RoutingRespT(Bit#(11) data);
  Vector#(11, Bit#(1)) dataVec = unpack(data);
  Vector#(1, Bit#(1)) hit = takeAt(0, dataVec);
  Vector#(1, Bit#(1)) p4_action = takeAt(1, dataVec);
  Vector#(9, Bit#(1)) action_1_arg0 = takeAt(2, dataVec);
  RoutingRespT hdr = defaultValue;
  hdr.hit = pack(hit);
  hdr.p4_action = pack(p4_action);
  hdr.action_1_arg0 = pack(action_1_arg0);
  return hdr;
endfunction

typedef struct {
  Bit#(32) dstAddr;
} RoutingReqT deriving (Bits, Eq);

instance DefaultValue#(RoutingReqT);
  defaultValue = unpack(0);
endinstance

instance FShow#(RoutingReqT);
  function Fmt fshow(RoutingReqT p);
    return $format("RoutingReqT: dstAddr=%h", p.dstAddr);
  endfunction
endinstance

function RoutingReqT extract_RoutingReqT(Bit#(32) data);
  Vector#(32, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) dstAddr = takeAt(0, dataVec);
  RoutingReqT hdr = defaultValue;
  hdr.dstAddr = pack(dstAddr);
  return hdr;
endfunction

typedef struct {
  Bit#(9) ingress_port;
  Bit#(32) packet_length;
  Bit#(9) egress_spec;
  Bit#(9) egress_port;
  Bit#(32) egress_instance;
  Bit#(32) instance_type;
  Bit#(32) clone_spec;
  Bit#(5) _padding;
} StandardMetadata deriving (Bits, Eq);

instance DefaultValue#(StandardMetadata);
  defaultValue = unpack(0);
endinstance

instance FShow#(StandardMetadata);
  function Fmt fshow(StandardMetadata p);
    return $format("StandardMetadata: ingress_port=%h, packet_length=%h, egress_spec=%h, egress_port=%h, egress_instance=%h, instance_type=%h, clone_spec=%h, _padding=%h", p.ingress_port, p.packet_length, p.egress_spec, p.egress_port, p.egress_instance, p.instance_type, p.clone_spec, p._padding);
  endfunction
endinstance

function StandardMetadata extract_StandardMetadata(Bit#(160) data);
  Vector#(160, Bit#(1)) dataVec = unpack(data);
  Vector#(9, Bit#(1)) ingress_port = takeAt(0, dataVec);
  Vector#(32, Bit#(1)) packet_length = takeAt(9, dataVec);
  Vector#(9, Bit#(1)) egress_spec = takeAt(41, dataVec);
  Vector#(9, Bit#(1)) egress_port = takeAt(50, dataVec);
  Vector#(32, Bit#(1)) egress_instance = takeAt(59, dataVec);
  Vector#(32, Bit#(1)) instance_type = takeAt(91, dataVec);
  Vector#(32, Bit#(1)) clone_spec = takeAt(123, dataVec);
  Vector#(5, Bit#(1)) _padding = takeAt(155, dataVec);
  StandardMetadata hdr = defaultValue;
  hdr.ingress_port = pack(ingress_port);
  hdr.packet_length = pack(packet_length);
  hdr.egress_spec = pack(egress_spec);
  hdr.egress_port = pack(egress_port);
  hdr.egress_instance = pack(egress_instance);
  hdr.instance_type = pack(instance_type);
  hdr.clone_spec = pack(clone_spec);
  hdr._padding = pack(_padding);
  return hdr;
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

instance FShow#(Ipv4T);
  function Fmt fshow(Ipv4T p);
    return $format("Ipv4T: version=%h, ihl=%h, diffserv=%h, totalLen=%h, identification=%h, flags=%h, fragOffset=%h, ttl=%h, protocol=%h, hdrChecksum=%h, srcAddr=%h, dstAddr=%h", p.version, p.ihl, p.diffserv, p.totalLen, p.identification, p.flags, p.fragOffset, p.ttl, p.protocol, p.hdrChecksum, p.srcAddr, p.dstAddr);
  endfunction
endinstance

function Ipv4T extract_Ipv4T(Bit#(160) data);
  Vector#(160, Bit#(1)) dataVec = unpack(data);
  Vector#(4, Bit#(1)) version = takeAt(0, dataVec);
  Vector#(4, Bit#(1)) ihl = takeAt(4, dataVec);
  Vector#(8, Bit#(1)) diffserv = takeAt(8, dataVec);
  Vector#(16, Bit#(1)) totalLen = takeAt(16, dataVec);
  Vector#(16, Bit#(1)) identification = takeAt(32, dataVec);
  Vector#(3, Bit#(1)) flags = takeAt(48, dataVec);
  Vector#(13, Bit#(1)) fragOffset = takeAt(51, dataVec);
  Vector#(8, Bit#(1)) ttl = takeAt(64, dataVec);
  Vector#(8, Bit#(1)) protocol = takeAt(72, dataVec);
  Vector#(16, Bit#(1)) hdrChecksum = takeAt(80, dataVec);
  Vector#(32, Bit#(1)) srcAddr = takeAt(96, dataVec);
  Vector#(32, Bit#(1)) dstAddr = takeAt(128, dataVec);
  Ipv4T hdr = defaultValue;
  hdr.version = pack(version);
  hdr.ihl = pack(ihl);
  hdr.diffserv = pack(diffserv);
  hdr.totalLen = pack(totalLen);
  hdr.identification = pack(identification);
  hdr.flags = pack(flags);
  hdr.fragOffset = pack(fragOffset);
  hdr.ttl = pack(ttl);
  hdr.protocol = pack(protocol);
  hdr.hdrChecksum = pack(hdrChecksum);
  hdr.srcAddr = pack(srcAddr);
  hdr.dstAddr = pack(dstAddr);
  return hdr;
endfunction

typedef struct {
  Bit#(48) dstAddr;
  Bit#(48) srcAddr;
  Bit#(16) etherType;
} EthernetT deriving (Bits, Eq);

instance DefaultValue#(EthernetT);
  defaultValue = unpack(0);
endinstance

instance FShow#(EthernetT);
  function Fmt fshow(EthernetT p);
    return $format("EthernetT: dstAddr=%h, srcAddr=%h, etherType=%h", p.dstAddr, p.srcAddr, p.etherType);
  endfunction
endinstance

function EthernetT extract_EthernetT(Bit#(112) data);
  Vector#(112, Bit#(1)) dataVec = unpack(data);
  Vector#(48, Bit#(1)) dstAddr = takeAt(0, dataVec);
  Vector#(48, Bit#(1)) srcAddr = takeAt(48, dataVec);
  Vector#(16, Bit#(1)) etherType = takeAt(96, dataVec);
  EthernetT hdr = defaultValue;
  hdr.dstAddr = pack(dstAddr);
  hdr.srcAddr = pack(srcAddr);
  hdr.etherType = pack(etherType);
  return hdr;
endfunction

typedef struct {
  Bit#(32) dstAddr;
  Bit#(16) etherType;
} MetaT deriving (Bits, Eq);

instance DefaultValue#(MetaT);
  defaultValue = unpack(0);
endinstance

instance FShow#(MetaT);
  function Fmt fshow(MetaT p);
    return $format("MetaT: dstAddr=%h, etherType=%h", p.dstAddr, p.etherType);
  endfunction
endinstance

function MetaT extract_MetaT(Bit#(48) data);
  Vector#(48, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) dstAddr = takeAt(0, dataVec);
  Vector#(16, Bit#(1)) etherType = takeAt(32, dataVec);
  MetaT hdr = defaultValue;
  hdr.dstAddr = pack(dstAddr);
  hdr.etherType = pack(etherType);
  return hdr;
endfunction

interface Routing;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface

module mkRouting#(Client#(MetadataRequest, MetadataResponse) md)(Routing);
  let verbose = True;

  FIFO#(MetadataRequest) outReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) inRespFifo <- mkFIFO;

  MatchTable#(512, RoutingReqT, RoutingRespT) matchTable <- mkMatchTable;

  rule handleRequest;
    let v <- md.request.get;
    case (v) matches
    endcase
  endrule

  rule handleResponse;

  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(outReqFifo);
    interface response = toPut(inRespFifo);
  endinterface);
endmodule


interface bb_forward
endinterface


module mkbb_forward(bb_forward);



endmodule



interface bb_nop
endinterface


module mkbb_nop(bb_nop);



endmodule


interface Ingress0;
endinterface

module mkIngress0#(Vector#(numClients, MetadataClient) mdc)(Ingress0);
  let verbose = True;
  FIFOF#(PacketInstance) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  Vector#(numClients, MetadataServer) mds = newVector;
  for (Integer i=0; i<valueOf(numClients); i=i+1) begin
    metadataServers[i] = (interface MetadataServer;
      interface Put request = toPut(defaultReqFifo);
      interface Get response = toGet(defaultRespFifo);
    endinterface);
  end
  mkConnection(mdc, mds);

  function MetadataClient toMetadataClient(FIFO#(MetadataRequest) reqFifo,
                                           FIFO#(MetadataResponse) respFifo);
    MetadataClient ret_ifc;
    ret_ifc = (interface MetadataClient;
      interface Get request = toGet(reqFifo);
      interface Put response = toPut(respFifo);
    endinterface);
  endfunction






  rule default_next_control_state:
    let v <- toGet(defaultReqFifo).get;
    case (v) matches
      tagged DefaultRequest {pkt: .pkt, meta: .meta} : begin

      end
    endcase
  endrule
endmodule

import Connectable::*;
import DefaultValue::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import StmtFSM::*;
import SpecicalFIFOs::*;
import Vector::*;
import Ethernet::*

interface ParseEthernet;

  interface Get#(Bit#(16)) parse_ipv4;
  method Action start;
  method Action clear;
endinterface
module mkStateParseEthernet#(Reg#(ParserState) state, FIFO#(EtherData) datain)(ParseEthernet);

  FIFOF#(Bit#(16)) unparsed_parse_ipv4_fifo <- mkSizedFIFOF(1);


  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(4, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire clear_wire <- mkPulseWire();
  (* fire_when_enabled *)
  rule arbitrate_outgoing_state if (state == StateParseEthernet);
    Vector#(4, Bool) next_state_valid = replicate(False);
    Bool stateSet = False;
    for (Integer port=0; port<4; port=port+1) begin
      next_state_valid[port] = isValid(next_state_wire[port]);
      if (!stateSet && next_state_valid[port]) begin
        stateSet = True;
        ParserState next_state = fromMaybe(?, next_state_wire[port]);
        state <= next_state;
      end
    end
  endrule

  function ParserState compute_next_state(Bit#(16) v);
    ParserState nextState = StateStart;
    case (v) matches
      0x800: begin
        nextState = StateParseIpv4;
      end
      default: begin
        nextState = StateStart;
      end
    endcase
    return nextState;
  endfunction

  rule load_packet if (state == StateParseEthernet);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
  endrule

  Stmt stmt_parse_ethernet =
  seq
  action
    let data_this_cycle = packet_in_wire;
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let hdr = extract_EthernetT(pack(takeAt(0, dataVec)));
    $display(fshow(hdr));
    Vector#(16, Bit#(1)) unparsed = takeAt(0, dataVec);
    let nextState = compute_next_state(hdr.etherType);
    if (verbose) $display("Goto state ", nextState);
    if (nextState == StateParseIpv4) begin
      unparsed_parse_ipv4_fifo.enq(pack(unparsed));
    end
    next_state_wire[0] <= tagged Valid nextState;
  endaction
  endseq;
  FSM fsm_parse_ethernet <- mkFSM(stmt_parse_ethernet);
  rule start_fsm if (start_wire);
    fsm_parse_ethernet.start;
  endrule
  rule clear_fsm if (clear_wire);
    fsm_parse_ethernet.abort;
  endrule

  method Action start();
    start_wire.send();
  endmethod
  method Action stop();
    clear_wire.send();
  endmethod
  interface parse_ipv4 = toGet(unparsed_parse_ipv4_fifo);

endmodule

interface ParseIpv4;
  interface Put#(Bit#(16)) parse_ethernet;

  method Action start;
  method Action clear;
endinterface
module mkStateParseIpv4#(Reg#(ParserState) state, FIFO#(EtherData) datain)(ParseIpv4);
  FIFOF#(Bit#(16)) unparsed_parse_ethernet_fifo <- mkBypassFIFOF;

  FIFOF#(Bit#(144)) internal_fifo_144 <- mkSizedFIFOF(1);

  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(4, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire clear_wire <- mkPulseWire();
  (* fire_when_enabled *)
  rule arbitrate_outgoing_state if (state == StateParseIpv4);
    Vector#(4, Bool) next_state_valid = replicate(False);
    Bool stateSet = False;
    for (Integer port=0; port<4; port=port+1) begin
      next_state_valid[port] = isValid(next_state_wire[port]);
      if (!stateSet && next_state_valid[port]) begin
        stateSet = True;
        ParserState next_state = fromMaybe(?, next_state_wire[port]);
        state <= next_state;
      end
    end
  endrule

  rule load_packet if (state == StateParseIpv4);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
  endrule

  Stmt stmt_parse_ipv4 =
  seq
  action
    let data_this_cycle = packet_in_wire;
    let data_last_cycle <- toGet(unparsed_parse_ethernet).get;
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    internal_fifo_144.enq(data);

  endaction
  action
    let data_this_cycle = packet_in_wire;
    let data_last_cycle <- toGet(internal_fifo_144).get;
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let hdr = extract_parse_ipv4(pack(takeAt(0, dataVec)));
    $display(fshow(hdr));
    Vector#(0, Bit#(1)) unparsed = takeAt(0, dataVec);
    next_state_wire[0] <= tagged Valid StateStart;
  endaction
  endseq;
  FSM fsm_parse_ipv4 <- mkFSM(stmt_parse_ipv4);
  rule start_fsm if (start_wire);
    fsm_parse_ipv4.start;
  endrule
  rule clear_fsm if (clear_wire);
    fsm_parse_ipv4.abort;
  endrule

  method Action start();
    start_wire.send();
  endmethod
  method Action stop();
    clear_wire.send();
  endmethod


endmodule

interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
endinterface
typedef 4 PortMax;
(* synthesize *)
module mkParser(Parser);
  Reg#(ParserState) curr_state <- mkReg(StateStart);
  Reg#(Bool) started <- mkReg(False);
  FIFOF#(EtherData) data_in_fifo <- mkFIFOF;
  Wire#(Bool) start_fsm <- mkDWire(False);

  Vector#(PortMax, FIFOF#(ParserState)) parse_state_in_fifo <- replicateM(mkGFIFOF(False, True)); // ungarded deq
  FIFOF#(ParserState) parse_state_out_fifo <- mkFIFOF;
  FIFOF#(MetadataT) metadata_out_fifo <- mkFIFOF;

  (* fire_when_enabled *)
  rule arbitrate_parse_state;
    Bool sentOne = False;
    for (Integer port=0; port<valueOf(PortMax); port=port+1) begin
      if (!sentOne && parse_state_in_fifo[port].notEmpty()) begin
        ParserState state <- toGet(parse_state_in_fifo[port]).get;
        sentOne = True;
        parse_state_out_fifo.enq(state);
      end
    end
  endrule

  Empty init_state <- mkStateStart(curr_state, data_in_fifo, start_fsm);
  ParseIpv4 parse_ipv4 <- mkStateParseIpv4(curr_state, data_in_fifo);
  ParseEthernet parse_ethernet <- mkStateParseEthernet(curr_state, data_in_fifo);
  mkConnection(parse_ipv4.parse_ethernet, parse_ethernet.parse_ipv4);
  rule start if (start_fsm);
    if (!started) begin
      parse_ipv4.start;
      parse_ethernet.start;
      started <= True;
    end
  endrule

  rule clear if (!start_fsm && curr_state == StateStart);
    if (started) begin
      parse_ipv4.stop;
      parse_ethernet.stop;
      started <= False;
    end
  endrule
  interface frameIn = toPut(data_in_fifo);
  interface meta = toGet(metadata_out_fifo);
endmodule
