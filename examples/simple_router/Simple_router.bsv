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

typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTableRequest;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SendFrameTableRequest;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4LpmTableRequest;
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
  } ForwardTableResponse;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SendFrameTableResponse;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4LpmTableResponse;
} MetadataResponse deriving (Bits, Eq, FShow);

typedef Client#(MetadataRequest, MetadataResponse) MetadataClient;
typedef Server#(MetadataRequest, MetadataResponse) MetadataServer;

typedef union tagged {
  struct {
    PacketInstance pkt;
  } BbRewriteMacRequest;
  struct {
    PacketInstance pkt;
  } BbDropRequest;
  struct {
    PacketInstance pkt;
  } BbSetNhopRequest;
  struct {
    PacketInstance pkt;
  } BbSetDmacRequest;
} BBRequest deriving (Bits, Eq, FShow);

typedef union tagged {
  struct {
    PacketInstance pkt;
  } BbRewriteMacResponse;
  struct {
    PacketInstance pkt;
  } BbDropResponse;
  struct {
    PacketInstance pkt;
  } BbSetNhopResponse;
  struct {
    PacketInstance pkt;
  } BbSetDmacResponse;
} BBResponse deriving (Bits, Eq, FShow);

typedef Client#(BBRequest, BBResponse) BBClient;
typedef Server#(BBRequest, BBResponse) BBServer;

typedef struct {
  Bit#(9) egress_port;
} SendFrameReqT deriving (Bits, Eq);

instance DefaultValue#(SendFrameReqT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(SendFrameReqT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(SendFrameReqT);
  function Fmt fshow(SendFrameReqT p);
    return $format("SendFrameReqT: egress_port=%h", p.egress_port);
  endfunction
endinstance

function SendFrameReqT extract_send_frame_req_t(Bit#(9) data);
  Vector#(9, Bit#(1)) dataVec = unpack(data);
  Vector#(9, Bit#(1)) egress_port = takeAt(0, dataVec);
  SendFrameReqT hdr = defaultValue;
  hdr.egress_port = pack(egress_port);
  return hdr;
endfunction

typedef struct {
  Bit#(1) p4_action;
  Bit#(32) nhop_ipv4;
  Bit#(9) port;
} Ipv4LpmRespT deriving (Bits, Eq);

instance DefaultValue#(Ipv4LpmRespT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Ipv4LpmRespT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(Ipv4LpmRespT);
  function Fmt fshow(Ipv4LpmRespT p);
    return $format("Ipv4LpmRespT: p4_action=%h, nhop_ipv4=%h, port=%h", p.p4_action, p.nhop_ipv4, p.port);
  endfunction
endinstance

function Ipv4LpmRespT extract_ipv4_lpm_resp_t(Bit#(42) data);
  Vector#(42, Bit#(1)) dataVec = unpack(data);
  Vector#(1, Bit#(1)) p4_action = takeAt(0, dataVec);
  Vector#(32, Bit#(1)) nhop_ipv4 = takeAt(1, dataVec);
  Vector#(9, Bit#(1)) port = takeAt(33, dataVec);
  Ipv4LpmRespT hdr = defaultValue;
  hdr.p4_action = pack(p4_action);
  hdr.nhop_ipv4 = pack(nhop_ipv4);
  hdr.port = pack(port);
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
  Bit#(32) nhop_ipv4;
} ForwardReqT deriving (Bits, Eq);

instance DefaultValue#(ForwardReqT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(ForwardReqT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(ForwardReqT);
  function Fmt fshow(ForwardReqT p);
    return $format("ForwardReqT: nhop_ipv4=%h", p.nhop_ipv4);
  endfunction
endinstance

function ForwardReqT extract_forward_req_t(Bit#(32) data);
  Vector#(32, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) nhop_ipv4 = takeAt(0, dataVec);
  ForwardReqT hdr = defaultValue;
  hdr.nhop_ipv4 = pack(nhop_ipv4);
  return hdr;
endfunction

typedef struct {
  Bit#(32) dstAddr;
} Ipv4LpmReqT deriving (Bits, Eq);

instance DefaultValue#(Ipv4LpmReqT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Ipv4LpmReqT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(Ipv4LpmReqT);
  function Fmt fshow(Ipv4LpmReqT p);
    return $format("Ipv4LpmReqT: dstAddr=%h", p.dstAddr);
  endfunction
endinstance

function Ipv4LpmReqT extract_ipv4_lpm_req_t(Bit#(32) data);
  Vector#(32, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) dstAddr = takeAt(0, dataVec);
  Ipv4LpmReqT hdr = defaultValue;
  hdr.dstAddr = pack(dstAddr);
  return hdr;
endfunction

typedef struct {
  Bit#(32) ipv4$dstAddr;
  Bit#(32) routing_metadata$nhop_ipv4;
  Bit#(9) standard_metadata$egress_port;
  Bit#(16) ethernet$etherType;
  Bit#(8) ipv4$ttl;
  Bit#(48) ethernet$dstAddr;
  Bit#(48) ethernet$srcAddr;
} MetadataT deriving (Bits, Eq);

instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(MetadataT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(MetadataT);
  function Fmt fshow(MetadataT p);
    return $format("MetadataT: ipv4$dstAddr=%h, routing_metadata$nhop_ipv4=%h, standard_metadata$egress_port=%h, ethernet$etherType=%h, ipv4$ttl=%h, ethernet$dstAddr=%h, ethernet$srcAddr=%h", p.ipv4$dstAddr, p.routing_metadata$nhop_ipv4, p.standard_metadata$egress_port, p.ethernet$etherType, p.ipv4$ttl, p.ethernet$dstAddr, p.ethernet$srcAddr);
  endfunction
endinstance

function MetadataT extract_metadata_t(Bit#(193) data);
  Vector#(193, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) ipv4$dstAddr = takeAt(0, dataVec);
  Vector#(32, Bit#(1)) routing_metadata$nhop_ipv4 = takeAt(32, dataVec);
  Vector#(9, Bit#(1)) standard_metadata$egress_port = takeAt(64, dataVec);
  Vector#(16, Bit#(1)) ethernet$etherType = takeAt(73, dataVec);
  Vector#(8, Bit#(1)) ipv4$ttl = takeAt(89, dataVec);
  Vector#(48, Bit#(1)) ethernet$dstAddr = takeAt(97, dataVec);
  Vector#(48, Bit#(1)) ethernet$srcAddr = takeAt(145, dataVec);
  MetadataT hdr = defaultValue;
  hdr.ipv4$dstAddr = pack(ipv4$dstAddr);
  hdr.routing_metadata$nhop_ipv4 = pack(routing_metadata$nhop_ipv4);
  hdr.standard_metadata$egress_port = pack(standard_metadata$egress_port);
  hdr.ethernet$etherType = pack(ethernet$etherType);
  hdr.ipv4$ttl = pack(ipv4$ttl);
  hdr.ethernet$dstAddr = pack(ethernet$dstAddr);
  hdr.ethernet$srcAddr = pack(ethernet$srcAddr);
  return hdr;
endfunction

typedef struct {
  Bit#(32) nhop_ipv4;
} RoutingMetadata deriving (Bits, Eq);

instance DefaultValue#(RoutingMetadata);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(RoutingMetadata);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(RoutingMetadata);
  function Fmt fshow(RoutingMetadata p);
    return $format("RoutingMetadata: nhop_ipv4=%h", p.nhop_ipv4);
  endfunction
endinstance

function RoutingMetadata extract_routing_metadata(Bit#(32) data);
  Vector#(32, Bit#(1)) dataVec = unpack(data);
  Vector#(32, Bit#(1)) nhop_ipv4 = takeAt(0, dataVec);
  RoutingMetadata hdr = defaultValue;
  hdr.nhop_ipv4 = pack(nhop_ipv4);
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

typedef struct {
  Bit#(1) p4_action;
  Bit#(48) smac;
} SendFrameRespT deriving (Bits, Eq);

instance DefaultValue#(SendFrameRespT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(SendFrameRespT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(SendFrameRespT);
  function Fmt fshow(SendFrameRespT p);
    return $format("SendFrameRespT: p4_action=%h, smac=%h", p.p4_action, p.smac);
  endfunction
endinstance

function SendFrameRespT extract_send_frame_resp_t(Bit#(49) data);
  Vector#(49, Bit#(1)) dataVec = unpack(data);
  Vector#(1, Bit#(1)) p4_action = takeAt(0, dataVec);
  Vector#(48, Bit#(1)) smac = takeAt(1, dataVec);
  SendFrameRespT hdr = defaultValue;
  hdr.p4_action = pack(p4_action);
  hdr.smac = pack(smac);
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
  Bit#(1) p4_action;
  Bit#(48) dmac;
} ForwardRespT deriving (Bits, Eq);

instance DefaultValue#(ForwardRespT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(ForwardRespT);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(ForwardRespT);
  function Fmt fshow(ForwardRespT p);
    return $format("ForwardRespT: p4_action=%h, dmac=%h", p.p4_action, p.dmac);
  endfunction
endinstance

function ForwardRespT extract_forward_resp_t(Bit#(49) data);
  Vector#(49, Bit#(1)) dataVec = unpack(data);
  Vector#(1, Bit#(1)) p4_action = takeAt(0, dataVec);
  Vector#(48, Bit#(1)) dmac = takeAt(1, dataVec);
  ForwardRespT hdr = defaultValue;
  hdr.p4_action = pack(p4_action);
  hdr.dmac = pack(dmac);
  return hdr;
endfunction


(* synthesize *)
module mkMatchTable_512_forwardTable(MatchTable#(512, SizeOf#(ForwardReqT), SizeOf#(ForwardRespT)));
  MatchTable#(512, SizeOf#(ForwardReqT), SizeOf#(ForwardRespT)) ifc <- mkMatchTable();
  return ifc;
endmodule

interface forwardTable;
  interface BBClient next_control_state_0;
  interface BBClient next_control_state_1;
  method Action {}({})
endinterface

module mkForwardTable#(MetadataClient md)(ForwardTable);
  let verbose = True;
  MatchTable#(512, SizeOf#(ForwardReqT), SizeOf#(ForwardRespT)) matchTable <- mkMatchTable_512_ForwardTable();
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

  rule handle_Forward_request;
    let v <- md.request.get;
    case (v) matches
      tagged ForwardTableRequest {pkt: .pkt, meta: .meta}: begin

        matchTable.lookupPort.request.put(pack(req));
        packetPipelineFifo.enq(pkt);
        metadataPipelineFifo[0].enq(meta);
      end
    endcase
  endrule

  rule handle_Forward_response;
    let v <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packetPipelineFifo).get;
    let meta <- toGet(metadataPipelineFifo).get;
    if (v matches tagged Valid .data) begin
      ForwardRespT resp = unpack(data);
      case (resp.p4_action) matches
        SET_DMAC: begin
          BBRequest req = tagged BbSetDmacRequest {pkt: pkt, dmac: resp.dmac};
          bbReqFifo[0].enq(req);
        end
        _DROP: begin
          BBRequest req = tagged BbDropRequest {pkt: pkt, dmac: resp.dmac};
          bbReqFifo[1].enq(req);
        end
      endcase
      meta.forward$p4_action = tagged Valid resp.p4_action;
      metadataPipelineFifo[1].enq(meta);
    end
  endrule

  rule bb_response if (interruptStatus);
    let v <- toGet(bbRespFifo[readyChannel]).get;
    let meta <- toGet(metadataPipelineFifo[1]).get;
    case (v) matches
      tagged BbSetDmacResponse {pkt: .pkt, dmac: .dmac}: begin
        meta.ethernet$dstAddr = dmac;
        MetadataResponse resp = tagged ForwardTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
      tagged BbDropResponse {}: begin
        MetadataResponse resp = tagged ForwardTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
    endcase
  endrule
  interface next_control_state_0 = (interface BBClient;
    interface request = toGet(bbReqFifo[0]);
    interface response = toPut(bbRespFifo[0]);
  endinterface);
  interface next_control_state_1 = (interface BBClient;
    interface request = toGet(bbReqFifo[1]);
    interface response = toPut(bbRespFifo[1]);
  endinterface);
endmodule


(* synthesize *)
module mkMatchTable_256_send_frameTable(MatchTable#(256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRespT)));
  MatchTable#(256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRespT)) ifc <- mkMatchTable();
  return ifc;
endmodule

interface send_frameTable;
  interface BBClient next_control_state_0;
  interface BBClient next_control_state_1;
  method Action {}({})
endinterface

module mkSendFrameTable#(MetadataClient md)(SendFrameTable);
  let verbose = True;
  MatchTable#(256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRespT)) matchTable <- mkMatchTable_256_SendFrameTable();
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

  rule handle_SendFrame_request;
    let v <- md.request.get;
    case (v) matches
      tagged SendFrameTableRequest {pkt: .pkt, meta: .meta}: begin

        matchTable.lookupPort.request.put(pack(req));
        packetPipelineFifo.enq(pkt);
        metadataPipelineFifo[0].enq(meta);
      end
    endcase
  endrule

  rule handle_SendFrame_response;
    let v <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packetPipelineFifo).get;
    let meta <- toGet(metadataPipelineFifo).get;
    if (v matches tagged Valid .data) begin
      SendFrameRespT resp = unpack(data);
      case (resp.p4_action) matches
        REWRITE_MAC: begin
          BBRequest req = tagged BbRewriteMacRequest {pkt: pkt, smac: resp.smac};
          bbReqFifo[0].enq(req);
        end
        _DROP: begin
          BBRequest req = tagged BbDropRequest {pkt: pkt, smac: resp.smac};
          bbReqFifo[1].enq(req);
        end
      endcase
      meta.send_frame$p4_action = tagged Valid resp.p4_action;
      metadataPipelineFifo[1].enq(meta);
    end
  endrule

  rule bb_response if (interruptStatus);
    let v <- toGet(bbRespFifo[readyChannel]).get;
    let meta <- toGet(metadataPipelineFifo[1]).get;
    case (v) matches
      tagged BbRewriteMacResponse {}: begin
        MetadataResponse resp = tagged SendFrameTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
      tagged BbDropResponse {}: begin
        MetadataResponse resp = tagged SendFrameTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
    endcase
  endrule
  interface next_control_state_0 = (interface BBClient;
    interface request = toGet(bbReqFifo[0]);
    interface response = toPut(bbRespFifo[0]);
  endinterface);
  interface next_control_state_1 = (interface BBClient;
    interface request = toGet(bbReqFifo[1]);
    interface response = toPut(bbRespFifo[1]);
  endinterface);
endmodule


(* synthesize *)
module mkMatchTable_1024_ipv4_lpmTable(MatchTable#(1024, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRespT)));
  MatchTable#(1024, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRespT)) ifc <- mkMatchTable();
  return ifc;
endmodule

interface ipv4_lpmTable;
  interface BBClient next_control_state_0;
  interface BBClient next_control_state_1;
  method Action {}({})
endinterface

module mkIpv4LpmTable#(MetadataClient md)(Ipv4LpmTable);
  let verbose = True;
  MatchTable#(1024, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRespT)) matchTable <- mkMatchTable_1024_Ipv4LpmTable();
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

  rule handle_Ipv4Lpm_request;
    let v <- md.request.get;
    case (v) matches
      tagged Ipv4LpmTableRequest {pkt: .pkt, meta: .meta}: begin

        matchTable.lookupPort.request.put(pack(req));
        packetPipelineFifo.enq(pkt);
        metadataPipelineFifo[0].enq(meta);
      end
    endcase
  endrule

  rule handle_Ipv4Lpm_response;
    let v <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packetPipelineFifo).get;
    let meta <- toGet(metadataPipelineFifo).get;
    if (v matches tagged Valid .data) begin
      Ipv4LpmRespT resp = unpack(data);
      case (resp.p4_action) matches
        SET_NHOP: begin
          BBRequest req = tagged BbSetNhopRequest {pkt: pkt, nhop_ipv4: resp.nhop_ipv4, port: resp.port};
          bbReqFifo[0].enq(req);
        end
        _DROP: begin
          BBRequest req = tagged BbDropRequest {pkt: pkt, nhop_ipv4: resp.nhop_ipv4, port: resp.port};
          bbReqFifo[1].enq(req);
        end
      endcase
      meta.ipv4_lpm$p4_action = tagged Valid resp.p4_action;
      metadataPipelineFifo[1].enq(meta);
    end
  endrule

  rule bb_response if (interruptStatus);
    let v <- toGet(bbRespFifo[readyChannel]).get;
    let meta <- toGet(metadataPipelineFifo[1]).get;
    case (v) matches
      tagged BbSetNhopResponse {}: begin
        MetadataResponse resp = tagged Ipv4LpmTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
      tagged BbDropResponse {}: begin
        MetadataResponse resp = tagged Ipv4LpmTableResponse {pkt: pkt, meta: meta};
        md.response.put(resp);
      end
    endcase
  endrule
  interface next_control_state_0 = (interface BBClient;
    interface request = toGet(bbReqFifo[0]);
    interface response = toPut(bbRespFifo[0]);
  endinterface);
  interface next_control_state_1 = (interface BBClient;
    interface request = toGet(bbReqFifo[1]);
    interface response = toPut(bbRespFifo[1]);
  endinterface);
endmodule

interface BbRewriteMac;
  interface BBServer prev_control_state;
endinterface
module mkBbRewriteMac(BbRewriteMac);
  FIFO#(BBRequest) bb_rewrite_mac_request_fifo <- mkSizedFIFO(1);
  FIFO#(BBResponse) bb_rewrite_mac_response_fifo <- mkSizedFIFO(1);
  FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);



  rule handle_bb_request;
    let req <- toGet(bb_rewrite_mac_request_fifo).get;
    packetPipelineFifo.enq(pkt);
  endrule

  rule handle_bb_resp;
    let pkt <- toGet(packetPipelineFifo).get;

    bb_rewrite_mac_response_fifo.enq(resp);
  endrule

  interface prev_control_state = (interface BBServer;
    interface request = toPut(bb_rewrite_mac_request_fifo);
    interface response = toGet(bb_rewrite_mac_response_fifo);
  endinterface);
endmodule

interface BbDrop;
  interface BBServer prev_control_state;
endinterface
module mkBbDrop(BbDrop);
  FIFO#(BBRequest) bb__drop_request_fifo <- mkSizedFIFO(1);
  FIFO#(BBResponse) bb__drop_response_fifo <- mkSizedFIFO(1);
  FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);



  rule handle_bb_request;
    let req <- toGet(bb__drop_request_fifo).get;
    packetPipelineFifo.enq(pkt);
  endrule

  rule handle_bb_resp;
    let pkt <- toGet(packetPipelineFifo).get;

    bb__drop_response_fifo.enq(resp);
  endrule

  interface prev_control_state = (interface BBServer;
    interface request = toPut(bb__drop_request_fifo);
    interface response = toGet(bb__drop_response_fifo);
  endinterface);
endmodule

interface BbSetNhop;
  interface BBServer prev_control_state;
endinterface
module mkBbSetNhop(BbSetNhop);
  FIFO#(BBRequest) bb_set_nhop_request_fifo <- mkSizedFIFO(1);
  FIFO#(BBResponse) bb_set_nhop_response_fifo <- mkSizedFIFO(1);
  FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);



  rule handle_bb_request;
    let req <- toGet(bb_set_nhop_request_fifo).get;
    packetPipelineFifo.enq(pkt);
  endrule

  rule handle_bb_resp;
    let pkt <- toGet(packetPipelineFifo).get;

    bb_set_nhop_response_fifo.enq(resp);
  endrule

  interface prev_control_state = (interface BBServer;
    interface request = toPut(bb_set_nhop_request_fifo);
    interface response = toGet(bb_set_nhop_response_fifo);
  endinterface);
endmodule

interface BbSetDmac;
  interface BBServer prev_control_state;
endinterface
module mkBbSetDmac(BbSetDmac);
  FIFO#(BBRequest) bb_set_dmac_request_fifo <- mkSizedFIFO(1);
  FIFO#(BBResponse) bb_set_dmac_response_fifo <- mkSizedFIFO(1);
  FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);

  ALU#(BBRequest, BBResponse) alu <- mkALU();

  rule handle_bb_request;
    let req <- toGet(bb_set_dmac_request_fifo).get;
    case (req) matches
       tagged BbSetDmacRequest {pkt: .pkt, dmac: .dmac} : begin
         alu.put(tagged ASSIGN dmac);
       end
    endcase
  endrule

  rule handle_bb_response;
    let out <- alu.get;
    BbSetDmacResponse resp = tagged BbSetDmacResponse {pkt: pkt, dmac: out};
    bb_set_dmac_response_fifo.enq(resp);
  endrule

  interface prev_control_state = (interface BBServer;
    interface request = toPut(bb_set_dmac_request_fifo);
    interface response = toGet(bb_set_dmac_response_fifo);
  endinterface);
endmodule

interface Ingress1;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface

module mkIngress1#(Vector#(numClients, MetadataClient) mdc)(Ingress1);
  let verbose = True;
  FIFOF#(MetadataRequest) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) forwardReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) forwardRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) sendFrameReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) sendFrameRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) ipv4LpmReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) ipv4LpmRespFifo <- mkFIFO;
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
  ForwardTable forwardTable <- mkForwardTable(toGPClient(forwardReqFifo, forwardRespFifo));
  SendFrameTable sendFrameTable <- mkSendFrameTable(toGPClient(sendFrameReqFifo, sendFrameRespFifo));
  Ipv4LpmTable ipv4LpmTable <- mkIpv4LpmTable(toGPClient(ipv4LpmReqFifo, ipv4LpmRespFifo));
  BbRewriteMac bb_rewrite_mac <- mkBbRewriteMac();
  BbDrop bb__drop <- mkBbDrop();
  BbSetNhop bb_set_nhop <- mkBbSetNhop();
  BbSetDmac bb_set_dmac <- mkBbSetDmac();
  mkConnection(forwardTable.next_control_state_0, bb_set_dmac.prev_control_state);
  mkConnection(forwardTable.next_control_state_1, bb__drop.prev_control_state);
  mkConnection(sendFrameTable.next_control_state_0, bb_rewrite_mac.prev_control_state);
  mkConnection(sendFrameTable.next_control_state_1, bb__drop.prev_control_state);
  mkConnection(ipv4LpmTable.next_control_state_0, bb_set_nhop.prev_control_state);
  mkConnection(ipv4LpmTable.next_control_state_1, bb__drop.prev_control_state);
  rule default_next_control_state if (defaultReqFifo.first matches tagged DefaultRequest {pkt: .pkt, meta: .meta});
    defaultReqFifo.deq;
    MetadataRequest req = tagged SendFrameTableRequest {pkt: pkt, meta: meta};
    send_frameReqFifo.enq(req);
  endrule
  rule send_frame_next_control_state if (send_frameRespFifo.first matches tagged SendFrameTableResponse {pkt: .pkt, meta: .meta});
    send_frameRespFifo.deq;
    if (meta.send_frame$p4_action matches tagged Valid .data) begin
      case (data) matches
         1: begin
          MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
          currPacketFifo.enq(req);
        end
         2: begin
          MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
          currPacketFifo.enq(req);
        end
      endcase
    end
  endrule
  interface eventPktSend = toPipeOut(currPacketFifo);

endmodule

interface Ingress0;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface

module mkIngress0#(Vector#(numClients, MetadataClient) mdc)(Ingress0);
  let verbose = True;
  FIFOF#(MetadataRequest) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) forwardReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) forwardRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) sendFrameReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) sendFrameRespFifo <- mkFIFO;
  FIFO#(MetadataRequest) ipv4LpmReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) ipv4LpmRespFifo <- mkFIFO;
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
  ForwardTable forwardTable <- mkForwardTable(toGPClient(forwardReqFifo, forwardRespFifo));
  SendFrameTable sendFrameTable <- mkSendFrameTable(toGPClient(sendFrameReqFifo, sendFrameRespFifo));
  Ipv4LpmTable ipv4LpmTable <- mkIpv4LpmTable(toGPClient(ipv4LpmReqFifo, ipv4LpmRespFifo));
  BbRewriteMac bb_rewrite_mac <- mkBbRewriteMac();
  BbDrop bb__drop <- mkBbDrop();
  BbSetNhop bb_set_nhop <- mkBbSetNhop();
  BbSetDmac bb_set_dmac <- mkBbSetDmac();
  mkConnection(forwardTable.next_control_state_0, bb_set_dmac.prev_control_state);
  mkConnection(forwardTable.next_control_state_1, bb__drop.prev_control_state);
  mkConnection(sendFrameTable.next_control_state_0, bb_rewrite_mac.prev_control_state);
  mkConnection(sendFrameTable.next_control_state_1, bb__drop.prev_control_state);
  mkConnection(ipv4LpmTable.next_control_state_0, bb_set_nhop.prev_control_state);
  mkConnection(ipv4LpmTable.next_control_state_1, bb__drop.prev_control_state);
  rule default_next_control_state if (defaultReqFifo.first matches tagged DefaultRequest {pkt: .pkt, meta: .meta});
    defaultReqFifo.deq;
    MetadataRequest req = tagged Ipv4LpmTableRequest {pkt: pkt, meta: meta};
    ipv4_lpmReqFifo.enq(req);
  endrule
  rule ipv4_lpm_next_control_state if (ipv4_lpmRespFifo.first matches tagged Ipv4LpmTableResponse {pkt: .pkt, meta: .meta});
    ipv4_lpmRespFifo.deq;
    if (meta.ipv4_lpm$p4_action matches tagged Valid .data) begin
      case (data) matches
         1: begin
          MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
          currPacketFifo.enq(req);
        end
         2: begin
          MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};
          currPacketFifo.enq(req);
        end
      endcase
    end
  endrule
  interface eventPktSend = toPipeOut(currPacketFifo);

endmodule
typedef enum {
  StateParseStart,
  StateParseEthernet,
  StateParseIpv4
} ParserState deriving (Bits, Eq, FShow);
module mkStateParseStart#(Reg#(ParserState) state, FIFOF#(EtherData) datain, Wire#(Bool) start_fsm)(Empty);
  rule load_packet if (state == StateParseStart);
    let v = datain.first;
    if (v.sop) begin
      state <= StateParseEthernet;
      start_fsm <= True;
    end
    else begin
      datain.deq;
      start_fsm <= False;
    end
  endrule
endmodule

interface ParseEthernet;

  interface Get#(Bit#(16)) parse_ipv4;
  method Action start;
  method Action stop;
endinterface
module mkStateParseEthernet#(Reg#(ParserState) state, FIFOF#(EtherData) datain, FIFOF#(ParserState) parseStateFifo)(ParseEthernet);
  let verbose = False;

  FIFO#(Bit#(16)) unparsed_parse_ipv4_fifo <- mkFIFO;
  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(4, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire stop_wire <- mkPulseWire();
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
    ParserState nextState = StateParseStart;
    case (byteSwap(v)) matches
      'h800: begin
        nextState = StateParseIpv4;
      end
      default: begin
        nextState = StateParseStart;
      end
    endcase
    return nextState;
  endfunction

  rule load_packet if (state == StateParseEthernet);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
  endrule
  Stmt parse_ethernet =
  seq
  action
    let data_this_cycle = packet_in_wire;



    Vector#(128, Bit#(1)) dataVec = unpack(data_this_cycle);
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    let ethernet_t = extract_ethernet_t(pack(takeAt(0, dataVec)));
    let nextState = compute_next_state(ethernet_t.etherType);
    if (nextState == StateParseIpv4) begin
      unparsed_parse_ipv4_fifo.enq(pack(unparsed));
    end
    state <= nextState;
  endaction
  endseq;
  FSM fsm_parse_ethernet <- mkFSM(parse_ethernet);
  rule start_fsm if (start_wire);
    fsm_parse_ethernet.start;
  endrule
  rule stop_fsm if (stop_wire);
    fsm_parse_ethernet.abort;
  endrule
  method start = start_wire.send;
  method stop = stop_wire.send;
  interface parse_ipv4 = toGet(unparsed_parse_ipv4_fifo);

endmodule

interface ParseIpv4;
  interface Put#(Bit#(16)) parse_ethernet;

  method Action start;
  method Action stop;
endinterface
module mkStateParseIpv4#(Reg#(ParserState) state, FIFOF#(EtherData) datain, FIFOF#(ParserState) parseStateFifo)(ParseIpv4);
  let verbose = False;
  FIFOF#(Bit#(16)) unparsed_parse_ethernet_fifo <- mkBypassFIFOF;

  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(4, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire stop_wire <- mkPulseWire();
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
  Stmt parse_ipv4 =
  seq
  action
    let data_this_cycle = packet_in_wire;
    let data_last_cycle <- toGet(unparsed_parse_ethernet_fifo).get;
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    internal_fifo_144.enq(data);




  endaction
  action
    let data_this_cycle = packet_in_wire;
    let data_last_cycle <- toGet(internal_fifo_144).get;
    Bit#(272) data = {data_this_cycle, data_last_cycle};

    Vector#(272, Bit#(1)) dataVec = unpack(data);
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    let ipv4_t = extract_ipv4_t(pack(takeAt(0, dataVec)));
    state <= StateParseStart;
  endaction
  endseq;
  FSM fsm_parse_ipv4 <- mkFSM(parse_ipv4);
  rule start_fsm if (start_wire);
    fsm_parse_ipv4.start;
  endrule
  rule stop_fsm if (stop_wire);
    fsm_parse_ipv4.abort;
  endrule
  method start = start_wire.send;
  method stop = stop_wire.send;

  interface parse_ethernet = toPut(unparsed_parse_ethernet_fifo);
endmodule

interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
endinterface
typedef 4 PortMax;
(* synthesize *)
module mkParser(Parser);
  Reg#(ParserState) curr_state <- mkReg(StateParseStart);
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

  Empty init_state <- mkStateParseStart(curr_state, data_in_fifo, start_fsm);
  ParseEthernet parse_ethernet <- mkStateParseEthernet(curr_state, data_in_fifo);
  ParseIpv4 parse_ipv4 <- mkStateParseIpv4(curr_state, data_in_fifo);
  mkConnection(parse_ethernet.parse_ipv4, parse_ipv4.parse_ethernet);
  rule start if (start_fsm);
    if (!started) begin
      parse_ethernet.start;
      parse_ipv4.start;
      started <= True;
    end
  endrule

  rule stop if (!start_fsm && curr_state == StateParseStart);
    if (started) begin
      parse_ethernet.stop;
      parse_ipv4.stop;
      started <= False;
    end
  endrule
  interface frameIn = toPut(data_in_fifo);
  interface meta = toGet(metadata_out_fifo);
endmodule
typedef enum {
  StateDeparseIdle,
  StateDeparseEthernet,
  StateDeparseIpv4
} DeparserState deriving (Bits, Eq, FShow);

module mkStateDeparseIdle#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, Wire#(Bool) start_fsm)(Empty);

   rule load_packet if (state == StateDeparseIdle);
      let v = datain.first;
      if (v.sop) begin
         state <= StateDeparseEthernet;
         start_fsm <= True;
         $display("(%0d) Deparse Ethernet Start", $time);
      end
      else begin
         datain.deq;
         dataout.enq(v);
         $display("(%0d) payload ", $time, fshow(v));
         start_fsm <= False;
      end
   endrule
endmodule

interface DeparseEthernet;

  interface Get#(EtherData) deparse_ipv4;
  method Action start;
  method Action stop;
endinterface
module mkStateDeparseEthernet#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, FIFOF#(EthernetT) meta_fifo, FIFOF#(EthernetT) mask_fifo)(DeparseEthernet);
  let verbose = False;
  Wire#(EtherData) packet_in_wire <- mkDWire(defaultValue);

  FIFO#(EtherData) deparse_ipv4_fifo <- mkFIFO;
  PulseWire start_wire <- mkPulseWire;
  PulseWire stop_wire <- mkPulseWire;

  function DeparserState compute_next_state(Bit#(16) v);
    DeparserState nextState = StateDeparseIdle;
    case (byteSwap(v)) matches
      'h800: begin
        nextState = StateDeparseIpv4;
      end
      default: begin
        nextState = StateDeparseIdle;
      end
    endcase
    return nextState;
  endfunction

  rule load_packet if (state == StateDeparseEthernet);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current;
  endrule
  Stmt deparse_ethernet =
  seq
  action
    let data_this_cycle = packet_in_wire;
    Vector#(16, Bit#(1)) unused = takeAt(112, unpack(data_this_cycle.data));
    Vector#(112, Bit#(1)) data = takeAt(0, unpack(data_this_cycle.data));
    Vector#(112, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(pack(meta_fifo.first))));
    Vector#(112, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(pack(mask_fifo.first))));
    let masked_data = pack(data) & pack(curr_mask);
    let curr_data = masked_data | pack(curr_meta);
    EthernetT ethernet_t = unpack(pack(masked_data));
    data_this_cycle.data = {pack(unused), pack(curr_data)};

    let nextState = compute_next_state(ethernet_t.etherType);
    state <= nextState;
    if (nextState == StateDeparseIpv4) begin
      deparse_ipv4_fifo.enq(data_this_cycle);
    end
    meta_fifo.deq;
    mask_fifo.deq;
  endaction
  endseq;

  FSM fsm_deparse_ethernet <- mkFSM(deparse_ethernet);
  rule start_fsm if (start_wire);
    fsm_deparse_ethernet.start;
  endrule
  rule stop_fsm if (stop_wire);
    fsm_deparse_ethernet.abort;
  endrule
  method start = start_wire.send;
  method stop = stop_wire.send;
  interface deparse_ipv4 = toGet(deparse_ipv4_fifo);

endmodule

interface DeparseIpv4;
  interface Put#(EtherData) deparse_ethernet;

  method Action start;
  method Action stop;
endinterface
module mkStateDeparseIpv4#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, FIFOF#(Ipv4T) meta_fifo, FIFOF#(Ipv4T) mask_fifo)(DeparseIpv4);
  let verbose = False;
  Wire#(EtherData) packet_in_wire <- mkDWire(defaultValue);
  FIFOF#(EtherData) deparse_ethernet_fifo <- mkBypassFIFOF;

  PulseWire start_wire <- mkPulseWire;
  PulseWire stop_wire <- mkPulseWire;

  rule load_packet if (state == StateDeparseIpv4);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current;
  endrule
  Stmt deparse_ipv4 =
  seq
  action
    let data_this_cycle <- toGet(deparse_ethernet_fifo).get;
    Vector#(112, Bit#(1)) unused = takeAt(0, unpack(data_this_cycle.data));
    Vector#(16, Bit#(1)) data = takeAt(112, unpack(data_this_cycle.data));
    Vector#(16, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(pack(meta_fifo.first))));
    Vector#(16, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(pack(mask_fifo.first))));
    let masked_data = pack(data) & pack(curr_mask);
    let curr_data = masked_data | pack(curr_meta);
    data_this_cycle.data = {pack(curr_data), pack(unused)};
    dataout.enq(data_this_cycle);


  endaction
  action
    let data_this_cycle = packet_in_wire;
    Vector#(128, Bit#(1)) data = takeAt(0, unpack(data_this_cycle.data));
    Vector#(128, Bit#(1)) curr_meta = takeAt(16, unpack(byteSwap(pack(meta_fifo.first))));
    Vector#(128, Bit#(1)) curr_mask = takeAt(16, unpack(byteSwap(pack(mask_fifo.first))));
    let masked_data = pack(data) & pack(curr_mask);
    let curr_data = masked_data | pack(curr_meta);
    data_this_cycle.data = {pack(curr_data)};
    dataout.enq(data_this_cycle);


  endaction
  action
    let data_this_cycle = packet_in_wire;
    Vector#(112, Bit#(1)) unused = takeAt(16, unpack(data_this_cycle.data));
    Vector#(16, Bit#(1)) data = takeAt(0, unpack(data_this_cycle.data));
    Vector#(16, Bit#(1)) curr_meta = takeAt(144, unpack(byteSwap(pack(meta_fifo.first))));
    Vector#(16, Bit#(1)) curr_mask = takeAt(144, unpack(byteSwap(pack(mask_fifo.first))));
    let masked_data = pack(data) & pack(curr_mask);
    let curr_data = masked_data | pack(curr_meta);
    Ipv4T ipv4_t = unpack(pack(masked_data));
    data_this_cycle.data = {pack(unused), pack(curr_data)};

    dataout.enq(data_this_cycle);
    state <= StateDeparseIdle;
    meta_fifo.deq;
    mask_fifo.deq;
  endaction
  endseq;

  FSM fsm_deparse_ipv4 <- mkFSM(deparse_ipv4);
  rule start_fsm if (start_wire);
    fsm_deparse_ipv4.start;
  endrule
  rule stop_fsm if (stop_wire);
    fsm_deparse_ipv4.abort;
  endrule
  method start = start_wire.send;
  method stop = stop_wire.send;

  interface deparse_ethernet = toPut(deparse_ethernet_fifo);
endmodule

interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  method DeparserPerfRec read_perf_info;
endinterface
(* synthesize *)
module mkDeparser(Deparser);
  let verbose = False;
  FIFOF#(EtherData) data_in_fifo <- mkSizedFIFOF(4);
  FIFOF#(EtherData) data_out_fifo <- mkFIFOF;
  FIFOF#(MetadataT) metadata_in_fifo <- mkFIFOF;
  Reg#(Bool) started <- mkReg(False);
  Wire#(Bool) start_fsm <- mkDWire(False);
  Reg#(DeparserState) curr_state <- mkReg(StateDeparseIdle);

  Vector#(PortMax, FIFOF#(DeparserState)) deparse_state_in_fifo <- replicateM(mkGFIFOF(False, True));
  FIFOF#(DeparserState) deparse_state_out_fifo <- mkFIFOF;
  FIFOF#(EthernetT) deparse_ethernet_meta_fifo <- mkFIFOF;
  FIFOF#(Ipv4T) deparse_ipv4_meta_fifo <- mkFIFOF;
  FIFOF#(EthernetT) deparse_ethernet_mask_fifo <- mkFIFOF;
  FIFOF#(Ipv4T) deparse_ipv4_mask_fifo <- mkFIFOF;
  (* fire_when_enabled *)
  rule arbitrate_deparse_state;
    Bool sentOne = False;
    for (Integer port = 0; port < valueOf(PortMax); port = port+1) begin
      if (!sentOne && deparse_state_in_fifo[port].notEmpty()) begin
        DeparserState state <- toGet(deparse_state_in_fifo[port]).get();
        sentOne = True;
        deparse_state_out_fifo.enq(state);
      end
    end
  endrule
  rule get_meta;
    let v <- toGet(metadata_in_fifo).get;

  endrule
  Empty init_state <- mkStateDeparseIdle(curr_state, data_in_fifo, data_out_fifo, start_fsm);
  DeparseEthernet deparse_ethernet <- mkStateDeparseEthernet(curr_state, data_in_fifo, data_out_fifo, deparse_ethernet_meta_fifo, deparse_ethernet_mask_fifo);
  DeparseIpv4 deparse_ipv4 <- mkStateDeparseIpv4(curr_state, data_in_fifo, data_out_fifo, deparse_ipv4_meta_fifo, deparse_ipv4_mask_fifo);
  mkConnection(deparse_ethernet.deparse_ipv4, deparse_ipv4.deparse_ethernet);
  rule start if (start_fsm);
    if (!started) begin
      deparse_ethernet.start;
      deparse_ipv4.start;
      started <= True;
    end
  endrule
  rule stop if (!start_fsm && curr_state == StateDeparseIdle);
    if (started) begin
      deparse_ethernet.stop;
      deparse_ipv4.stop;
      started <= False;
    end
  endrule
  interface PktWriteServer writeServer;
    interface writeData = toPut(data_in_fifo);
  endinterface
  interface PktWriteClient writeClient;
    interface writeData = toGet(data_out_fifo);
  endinterface
  interface metadata = toPipeIn(metadata_in_fifo);
endmodule
