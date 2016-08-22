import DefaultValue::*;
import Utils::*;
import Ethernet::*;
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
  Bit#(32) msgSeqNum;
  Bit#(64) sendingTime;
} MdpPacketT deriving (Bits, Eq, FShow);
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
} MdpMessageT deriving (Bits, Eq, FShow);
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
} MdpSbeT deriving (Bits, Eq, FShow);
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
} EventMetadataT deriving (Bits, Eq, FShow);
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
  Bit#(1) notPresent;
  Bit#(7) _padding;
} DedupT deriving (Bits, Eq, FShow);
instance DefaultValue#(DedupT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(DedupT);
  defaultMask = unpack(maxBound);
endinstance

function DedupT extract_dedup_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(64) transactTime;
  Bit#(16) matchEventIndicator;
  Bit#(16) blockLength;
  Bit#(16) noMDEntries;
} Mdincrementalrefreshbook32 deriving (Bits, Eq, FShow);
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
  Bit#(64) mdEntryPx;
  Bit#(32) mdEntrySize;
  Bit#(32) securityID;
  Bit#(32) rptReq;
  Bit#(32) numberOfOrders;
  Bit#(8) mdPriceLevel;
  Bit#(8) mdUpdateAction;
  Bit#(8) mdEntryType;
  Bit#(40) padding;
} Mdincrementalrefreshbook32Group deriving (Bits, Eq, FShow);
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
} MetadataRequest deriving (Bits, Eq, FShow);
typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataResponse deriving (Bits, Eq, FShow);

typedef union tagged {
  void NotPresent;
  void Forward;
  void Delete;
  void Insert;
  void Processed;
  } HeaderState
deriving (Bits, Eq, FShow);

typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TblBloomfilterDedupRspT;
} TblBloomfilterResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TblDropDropRspT;
} TblDropResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TblForwardForwardRspT;
} TblForwardResponse deriving (Bits, Eq, FShow);
typedef struct {
  Maybe#(Bit#(1)) dedup$notPresent;
  Maybe#(Bit#(32)) mdp$msgSeqNum;
  HeaderState ethernet;
  HeaderState ipv4;
  HeaderState udp;
  HeaderState mdp;
  HeaderState mdp_msg;
  HeaderState mdp_sbe;
  HeaderState mdp_refreshbook;
  Vector#(10, HeaderState) group;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
