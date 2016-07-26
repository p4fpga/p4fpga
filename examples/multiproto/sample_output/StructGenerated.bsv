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
  Bit#(3) pcp;
  Bit#(1) cfi;
  Bit#(12) vid;
  Bit#(16) etherType;
} VlanTagT deriving (Bits, Eq, FShow);
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
  Bit#(4) version;
  Bit#(8) trafficClass;
  Bit#(20) flowLabel;
  Bit#(16) payloadLen;
  Bit#(8) nextHdr;
  Bit#(8) hopLimit;
  Bit#(128) srcAddr;
  Bit#(128) dstAddr;
} Ipv6T deriving (Bits, Eq, FShow);
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
} IcmpT deriving (Bits, Eq, FShow);
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
} TcpT deriving (Bits, Eq, FShow);
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
} UdpT deriving (Bits, Eq, FShow);
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
} IngressMetadataT deriving (Bits, Eq, FShow);
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
} MetadataResponse deriving (Bits, Eq, FShow);
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
