// Copyright (c) 2016 Cornell University

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
import SpecialFIFOs::*;
import StmtFSM::*;
import Utils::*;
import Vector::*;
import TxRx::*;

import MainDefs::*;

typedef enum {
   StateParseStart,
   StateParseEthernet,
   StateParseIpv4
} ParserState deriving (Bits, Eq);


typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RoutingTableRequest;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardQueueRequest;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DefaultRequest;
} MetadataRequest deriving (Bits, Eq, FShow);

typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RoutingTableResponse;
} MetadataResponse deriving (Bits, Eq, FShow);

typedef Client#(MetadataRequest, MetadataResponse) MetadataClient;
typedef Server#(MetadataRequest, MetadataResponse) MetadataServer;

typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(9) egress_port;
  } BBForwardRequest;
  struct {
    PacketInstance pkt;
  } BBNopRequest;
} BBRequest deriving (Bits, Eq, FShow);

typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(9) egress_port;
  } BBForwardResponse;
  struct {
    PacketInstance pkt;
  } BBNopResponse;
} BBResponse deriving (Bits, Eq, FShow);

typedef Client#(BBRequest, BBResponse) BBClient;
typedef Server#(BBRequest, BBResponse) BBServer;

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

instance FShow#(EthernetT);
  function Fmt fshow(EthernetT p);
    return $format("EthernetT: dstAddr=%h, srcAddr=%h, etherType=%h", p.dstAddr, p.srcAddr, p.etherType);
  endfunction
endinstance

function EthernetT extract_ethernet_t(Bit#(112) data);
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
  RouteActionT p4_action;
  Bit#(9) port_;
} RoutingRespT deriving (Bits, Eq);

instance DefaultValue#(RoutingRespT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(RoutingRespT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(RoutingRespT);
  function Fmt fshow(RoutingRespT p);
    return $format("RoutingRespT: p4_action=%h, port_=%h", p.p4_action, p.port_);
  endfunction
endinstance

function RoutingRespT extract_RoutingRespT(Bit#(10) data);
  Vector#(10, Bit#(1)) dataVec = unpack(data);
  Vector#(1, Bit#(1)) p4_action = takeAt(0, dataVec);
  Vector#(9, Bit#(1)) port_ = takeAt(1, dataVec);
  RoutingRespT hdr = defaultValue;
  hdr.p4_action = unpack(pack(p4_action));
  hdr.port_ = pack(port_);
  return hdr;
endfunction

typedef struct {
  Bit#(4) padding;
  Bit#(32) dstAddr;
} RoutingReqT deriving (Bits, Eq);

instance DefaultValue#(RoutingReqT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(RoutingReqT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(RoutingReqT);
  function Fmt fshow(RoutingReqT p);
    return $format("RoutingReqT: dstAddr=%h", p.dstAddr);
  endfunction
endinstance

function RoutingReqT extract_routing_req_t(Bit#(32) data);
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
instance DefaultMask#(StandardMetadata);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(StandardMetadata);
  function Fmt fshow(StandardMetadata p);
    return $format("StandardMetadata: ingress_port=%h, packet_length=%h, egress_spec=%h, egress_port=%h, egress_instance=%h, instance_type=%h, clone_spec=%h, _padding=%h", p.ingress_port, p.packet_length, p.egress_spec, p.egress_port, p.egress_instance, p.instance_type, p.clone_spec, p._padding);
  endfunction
endinstance

function StandardMetadata extract_standard_metadata(Bit#(160) data);
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
   Bit#(32) dstAddr;
} M_Ipv4T deriving (Bits, Eq);

typedef struct {
   Bit#(16) etherType;
} M_EthernetT deriving (Bits, Eq);

typedef struct {
   Bit#(9) egress_port;
} M_StandardMetadata deriving (Bits, Eq);

typedef union tagged {
   struct {
      RouteActionT e;
   } Routing;
} M_TableAction deriving (Bits, Eq);

typedef struct {
  Maybe#(M_Ipv4T) ipv4;
  Maybe#(M_EthernetT) ethernet;
  Maybe#(M_StandardMetadata) standard_metadata;
  Maybe#(M_TableAction) table_action;
} MetadataT deriving (Bits, Eq);

instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MetadataT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(MetadataT);
  function Fmt fshow(MetadataT p);
    return $format("MetadataT: ipv4=%h, ethernet=%h, standard_metadata=%h", p.ipv4, p.ethernet, p.standard_metadata);
  endfunction
endinstance

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

instance FShow#(Ipv4T);
  function Fmt fshow(Ipv4T p);
    return $format("Ipv4T: version=%h, ihl=%h, diffserv=%h, totalLen=%h, identification=%h, flags=%h, fragOffset=%h, ttl=%h, protocol=%h, hdrChecksum=%h, srcAddr=%h, dstAddr=%h", p.version, p.ihl, p.diffserv, p.totalLen, p.identification, p.flags, p.fragOffset, p.ttl, p.protocol, p.hdrChecksum, p.srcAddr, p.dstAddr);
  endfunction
endinstance

function Ipv4T extract_ipv4_t(Bit#(160) data);
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

// Template for Table??
(* synthesize *)
module mkMatchTable_512_RoutingTable(MatchTable#(512, SizeOf#(RoutingReqT), SizeOf#(RoutingRespT)));
  MatchTable#(512, SizeOf#(RoutingReqT), SizeOf#(RoutingRespT)) ifc <- mkMatchTable();
  return ifc;
endmodule

interface RoutingTable;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  method Action add_entry(Bit#(32) dstAddr, RouteActionT action_, Bit#(9) port_);
endinterface
module mkRoutingTable#(MetadataClient md)(RoutingTable);
  let verbose = True;
  MatchTable#(512, SizeOf#(RoutingReqT), SizeOf#(RoutingRespT)) matchTable <- mkMatchTable_512_RoutingTable();
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRespFifo <- replicateM(mkFIFOF);

  Vector#(2, Bool) readyBits = map(fifoNotEmpty, bbRespFifo);
  Bool interruptStatus = False;
  Bit#(16) readyChannel = -1;
  for (Integer i = 1; i>=0; i=i-1) begin
    if (readyBits[i]) begin
      interruptStatus = True;
      readyChannel = fromInteger(i);
    end
  end

  FIFO#(PacketInstance) packetPipelineFifo <- mkFIFO;
  Vector#(2, FIFO#(MetadataT)) metadataPipelineFifo <- replicateM(mkFIFO);

  rule handle_Routing_request;
    let v <- md.request.get;
    case (v) matches
      tagged RoutingTableRequest {pkt: .pkt, meta: .meta}: begin
        let ipv4 = fromMaybe(?, meta.ipv4);
        RoutingReqT req = RoutingReqT {padding: 0, dstAddr: ipv4.dstAddr};
        matchTable.lookupPort.request.put(pack(req));
        packetPipelineFifo.enq(pkt);
        metadataPipelineFifo[0].enq(meta);
        $display("(%0d) forward routing request %h", $time, ipv4.dstAddr);
      end
    endcase
  endrule

  rule handle_Routing_response;
    let v <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packetPipelineFifo).get;
    let meta <- toGet(metadataPipelineFifo[0]).get;
    if (v matches tagged Valid .data) begin
      RoutingRespT resp = unpack(data);
      case (resp.p4_action) matches
        NOP: begin
          BBRequest req = tagged BBNopRequest {pkt: pkt};
          bbReqFifo[0].enq(req);
        end
        FORWARD: begin
          BBRequest req = tagged BBForwardRequest {pkt: pkt, egress_port: resp.port_};
          bbReqFifo[1].enq(req);
        end
      endcase
      let _act = tagged Routing {e: resp.p4_action};
      $display("(%0d) response %h", $time, _act);
      meta.table_action = tagged Valid _act;
      metadataPipelineFifo[1].enq(meta);
    end
  endrule

  rule bb_response if (interruptStatus);
    let v <- toGet(bbRespFifo[readyChannel]).get;
    let meta <- toGet(metadataPipelineFifo[1]).get;
    case (v) matches
      tagged BBNopResponse {pkt: .pkt}: begin
        MetadataResponse resp = tagged RoutingTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
      tagged BBForwardResponse {pkt: .pkt, egress_port: .egress_port}: begin
        let std_metadata = M_StandardMetadata { egress_port: egress_port };
        meta.standard_metadata = tagged Valid std_metadata;
        MetadataResponse resp = tagged RoutingTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
        $display("(%0d) forward response", $time);
      end
    endcase
  endrule

  interface next_control_state_0 = toClient(bbReqFifo[0], bbRespFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRespFifo[1]);

  method Action add_entry(Bit#(32) dstAddr, RouteActionT action_, Bit#(9) port_);
     RoutingReqT req = RoutingReqT {dstAddr: dstAddr, padding: 0};
     RoutingRespT resp = RoutingRespT {p4_action: action_, port_: port_};
     if (verbose) $display("(%0d) routing table resp=%h", $time, pack(resp));
     matchTable.add_entry.put(tuple2(pack(req), pack(resp)));
  endmethod
endmodule

// template for BB??
interface BbForward;
  interface Server #(BBRequest, BBResponse) prev_control_state;
endinterface
module mkBbForward(BbForward);

   RX #(BBRequest) rx_t1_b1 <- mkRX();
   let rx_info_t1_b1 = rx_t1_b1.u;

   TX #(BBResponse) tx_b1_t1 <- mkTX();
   let tx_info_b1_t1 = tx_b1_t1.u;

   FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);
   Reg#(Bit#(9)) rg_egress_port <- mkReg(0);

   rule handle_bb_request;
      let req = rx_info_t1_b1.first;
      case (req) matches
         tagged BBForwardRequest {pkt: .pkt, egress_port: .egress_port}: begin
            // ALURequest req = tagged ALUAdd {a: egress, b: 0};
            $display("(%0d) handle forward", $time);
            rg_egress_port <= egress_port;
         end
      endcase
      rx_info_t1_b1.deq;
   endrule

   rule handle_bb_resp;
      let pkt <- toGet(packetPipelineFifo).get;
      BBResponse resp = tagged BBForwardResponse {pkt: pkt, egress_port: rg_egress_port};
      tx_info_b1_t1.enq(resp);
   endrule

   interface prev_control_state = toServer(rx_t1_b1.e, tx_b1_t1.e);
endmodule

interface BbNop;
   interface Server #(BBRequest, BBResponse) prev_control_state;
endinterface
module mkBbNop(BbNop);

   RX #(BBRequest) rx_t1_b2 <- mkRX();
   let rx_info_t1_b2 = rx_t1_b2.u;

   TX #(BBResponse) tx_b2_t1 <- mkTX();
   let tx_info_b2_t1 = tx_b2_t1.u;

   FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);

   rule handle_bb_request;
      let req = rx_info_t1_b2.first;
      case (req) matches
         tagged BBNopRequest {pkt: .pkt}: begin
            packetPipelineFifo.enq(pkt);
         end
      endcase
      rx_info_t1_b2.deq;
   endrule

   rule handle_bb_resp;
      let pkt <- toGet(packetPipelineFifo).get;
      BBResponse resp = tagged BBNopResponse {pkt: pkt};
      tx_info_b2_t1.enq(resp);
   endrule

   interface prev_control_state = toServer (rx_t1_b2.e, tx_b2_t1.e);
endmodule

interface Ingress0;
  interface PipeOut#(MetadataRequest) eventPktSend;
  method Action routingTable_add_entry(Bit#(32) dstAddr, RouteActionT act, Bit#(9) port_);
endinterface

module mkIngress0#(Vector#(numClients, MetadataClient) mdc)(Ingress0);
  let verbose = True;
  FIFOF#(MetadataRequest) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) routingReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) routingRespFifo <- mkFIFO;
  Vector#(numClients, MetadataServer) mds = newVector;
  for (Integer i=0; i<valueOf(numClients); i=i+1) begin
    mds[i] = (interface MetadataServer;
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
    return ret_ifc;
  endfunction
  RoutingTable routingTable <- mkRoutingTable(toGPClient(routingReqFifo, routingRespFifo));
  BbForward bb_forward <- mkBbForward();
  BbNop bb_nop <- mkBbNop();
  mkConnection(routingTable.next_control_state_0, bb_nop.prev_control_state);
  mkConnection(routingTable.next_control_state_1, bb_forward.prev_control_state);
  rule default_next_control_state if (defaultReqFifo.first matches tagged DefaultRequest {pkt: .pkt, meta: .meta});
    defaultReqFifo.deq;
    MetadataRequest req = tagged RoutingTableRequest {pkt: pkt, meta: meta};
    routingReqFifo.enq(req);
  endrule
  rule routing_next_control_state if (routingRespFifo.first matches tagged RoutingTableResponse {pkt: .pkt, meta: .meta});
    routingRespFifo.deq;
    if (meta.table_action matches tagged Valid .data) begin
      case (data) matches
         tagged Routing { e: .act }: begin
           if (act == FORWARD) begin
              MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
              currPacketFifo.enq(req);
           end
           else if (act == NOP) begin
              MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
              currPacketFifo.enq(req);
           end
         end
      endcase
    end
  endrule

  interface eventPktSend = toPipeOut(currPacketFifo);
  method routingTable_add_entry = routingTable.add_entry;
endmodule
