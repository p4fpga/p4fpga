import DefaultValue::*;
import Utils::*;
import Ethernet::*;
typedef struct {
  Bit#(9) ingress_port;
  Bit#(32) packet_length;
  Bit#(9) egress_spec;
  Bit#(9) egress_port;
  Bit#(32) egress_instance;
  Bit#(32) instance_type;
  Bit#(32) clone_spec;
  Bit#(5) _padding;
} StandardMetadataT deriving (Bits, Eq, FShow);
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
} EthernetT deriving (Bits, Eq, FShow);
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
} Ipv4T deriving (Bits, Eq, FShow);
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
  Bit#(32) nhop_ipv4;
} RoutingMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(RoutingMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(RoutingMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function RoutingMetadataT extract_routing_metadata_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq, FShow);
typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardSetDmacRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardDropRspT;
} ForwardResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4LpmSetNhopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4LpmDropRspT;
} Ipv4LpmResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SendFrameRewriteMacRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SendFrameDropRspT;
} SendFrameResponse deriving (Bits, Eq, FShow);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_port;
  Maybe#(Bit#(48)) ethernet$dstAddr;
  Maybe#(Bit#(48)) ethernet$srcAddr;
  Maybe#(Bit#(32)) routing_metadata$nhop_ipv4;
  Maybe#(Bit#(9)) runtime$port_9;
  Maybe#(Bit#(48)) runtime$dmac_48;
  Maybe#(Bit#(48)) runtime$smac_48;
  Maybe#(Bit#(32)) runtime$nhop_ipv4_32;
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(8)) ipv4$ttl;
  Maybe#(void) valid_ipv4;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
