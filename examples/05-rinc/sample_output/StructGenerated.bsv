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
  Bit#(16) srcPort;
  Bit#(16) dstPort;
  Bit#(32) seqNo;
  Bit#(32) ackNo;
  Bit#(4) dataOffset;
  Bit#(3) res;
  Bit#(3) ecn;
  Bit#(1) urg;
  Bit#(1) ack;
  Bit#(1) push;
  Bit#(1) rst;
  Bit#(1) syn;
  Bit#(1) fin;
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
  Bit#(8) kind;
} OptionsEndT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsEndT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsEndT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsEndT extract_options_end_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) kind;
} OptionsNopT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsNopT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsNopT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsNopT extract_options_nop_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(16) mss;
} OptionsMssT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsMssT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsMssT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsMssT extract_options_mss_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(8) wscale;
} OptionsWscaleT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsWscaleT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsWscaleT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsWscaleT extract_options_wscale_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
} OptionsSackT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsSackT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsSackT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsSackT extract_options_sack_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) kind;
  Bit#(8) len;
  Bit#(64) ttee;
} OptionsTsT deriving (Bits, Eq, FShow);
instance DefaultValue#(OptionsTsT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(OptionsTsT);
  defaultMask = unpack(maxBound);
endinstance

function OptionsTsT extract_options_ts_t(Bit#(80) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) parse_tcp_options_counter;
} MyMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MyMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(MyMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function MyMetadataT extract_my_metadata_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(48) ingress_global_timestamp;
  Bit#(32) lf_field_list;
  Bit#(16) mcast_grp;
  Bit#(16) egress_rid;
} IntrinsicMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntrinsicMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntrinsicMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function IntrinsicMetadataT extract_intrinsic_metadata_t(Bit#(112) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(32) dummy;
  Bit#(32) dummy2;
  Bit#(2) flow_map_index;
  Bit#(32) senderIP;
  Bit#(32) seqNo;
  Bit#(32) ackNo;
  Bit#(32) sample_rtt_seq;
  Bit#(32) rtt_samples;
  Bit#(32) mincwnd;
  Bit#(32) dupack;
  Bit#(6) _padding;
} StatsMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(StatsMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(StatsMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function StatsMetadataT extract_stats_metadata_t(Bit#(296) data);
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
  } DebugSaveSourceIpRspT;
} DebugResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DirectionGetSenderIpRspT;
} DirectionResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FirstRttSampleUseSampleRttFirstRspT;
} FirstRttSampleResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FlowDupackUpdateFlowDupackRspT;
} FlowDupackResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FlowRcvdUpdateFlowRcvdRspT;
} FlowRcvdResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FlowRetx3DupackUpdateFlowRetx3DupackRspT;
} FlowRetx3DupackResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FlowRetxTimeoutUpdateFlowRetxTimeoutRspT;
} FlowRetxTimeoutResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FlowSentUpdateFlowSentRspT;
} FlowSentResponse deriving (Bits, Eq, FShow);
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
  } IncreaseCwndIncreaseMincwndRspT;
} IncreaseCwndResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } InitRecordIpRspT;
} InitResponse deriving (Bits, Eq, FShow);
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
  } LookupLookupFlowMapRspT;
} LookupResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LookupReverseLookupFlowMapReverseRspT;
} LookupReverseResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SampleRttRcvdUseSampleRttRspT;
} SampleRttRcvdResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SampleRttSentSampleNewRttRspT;
} SampleRttSentResponse deriving (Bits, Eq, FShow);
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
  Maybe#(Bit#(2)) stats_metadata$flow_map_index;
  Maybe#(Bit#(32)) stats_metadata$sample_rtt_seq;
  Maybe#(Bit#(32)) stats_metadata$seqNo;
  Maybe#(Bit#(32)) stats_metadata$dupack;
  Maybe#(Bit#(32)) stats_metadata$rtt_samples;
  Maybe#(Bit#(32)) stats_metadata$ackNo;
  Maybe#(Bit#(32)) stats_metadata$senderIP;
  Maybe#(Bit#(32)) stats_metadata$mincwnd;
  Maybe#(Bit#(32)) stats_metadata$dummy;
  Maybe#(Bit#(8)) options_wscale$wscale;
  Maybe#(Bit#(16)) options_mss$mss;
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(48)) ethernet$srcAddr;
  Maybe#(Bit#(48)) runtime_smac_48;
  Maybe#(Bit#(32)) tcp$seqNo;
  Maybe#(Bit#(48)) intrinsic_metadata$ingress_global_timestamp;
  Maybe#(Bit#(32)) ipv4$srcAddr;
  Maybe#(Bit#(4)) ipv4$protocol;
  Maybe#(Bit#(1)) tcp$ack;
  Maybe#(Bit#(1)) tcp$syn;
  Maybe#(Bit#(48)) ethernet$dstAddr;
  Maybe#(Bit#(48)) runtime_dmac_48;
  Maybe#(Bit#(8)) ipv4$ttl;
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(32)) routing_metadata$nhop_ipv4;
  Maybe#(Bit#(9)) runtime_port_9;
  Maybe#(Bit#(32)) runtime_nhop_ipv4_32;
  Maybe#(Bit#(16)) tcp$window;
  Maybe#(Bit#(32)) tcp$ackNo;
  Maybe#(Bit#(32)) stats_metadata$dummy2;
  Maybe#(Bit#(9)) standard_metadata$egress_port;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
