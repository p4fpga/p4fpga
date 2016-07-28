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
  Bit#(16) hrd;
  Bit#(16) pro;
  Bit#(8) hln;
  Bit#(8) pln;
  Bit#(16) op;
  Bit#(48) sha;
  Bit#(32) spa;
  Bit#(48) tha;
  Bit#(32) tpa;
} ArpT deriving (Bits, Eq, FShow);
instance DefaultValue#(ArpT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(ArpT);
  defaultMask = unpack(maxBound);
endinstance

function ArpT extract_arp_t(Bit#(224) data);
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
  Bit#(16) msgtype;
  Bit#(32) inst;
  Bit#(16) rnd;
  Bit#(16) vrnd;
  Bit#(16) acptid;
  Bit#(256) paxosval;
} PaxosT deriving (Bits, Eq, FShow);
instance DefaultValue#(PaxosT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(PaxosT);
  defaultMask = unpack(maxBound);
endinstance

function PaxosT extract_paxos_t(Bit#(352) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) round;
  Bit#(1) set_drop;
  Bit#(7) _padding;
} IngressMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function IngressMetadataT extract_ingress_metadata_t(Bit#(24) data);
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
  } AcceptorTblHandle1ARspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } AcceptorTblHandle2ARspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } AcceptorTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblForwardRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RoundTblReadRoundRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DropTblDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DropTblNopRspT;
} MetadataResponse deriving (Bits, Eq, FShow);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(16)) paxos$rnd;
  Maybe#(Bit#(32)) paxos$inst;
  Maybe#(Bit#(16)) paxos$msgtype;
  Maybe#(Bit#(16)) udp$checksum;
  Maybe#(Bit#(16)) paxos$acptid;
  Maybe#(Bit#(16)) paxos$vrnd;
  Maybe#(Bit#(16)) udp$dstPort;
  Maybe#(Bit#(256)) paxos$paxosval;
  Maybe#(Bit#(16)) runtime_learner_port;
  Maybe#(Bit#(1)) local_metadata$set_drop;
  Maybe#(Bit#(16)) local_metadata$round;
  Maybe#(Bit#(9)) standard_metadata$ingress_port;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
