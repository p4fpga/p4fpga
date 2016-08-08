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
  Bit#(8) dsap;
  Bit#(8) ssap;
  Bit#(8) control_;
} LlcHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(LlcHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(LlcHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function LlcHeaderT extract_llc_header_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(24) oui;
  Bit#(16) type_;
} SnapHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(SnapHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(SnapHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function SnapHeaderT extract_snap_header_t(Bit#(40) data);
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
  Bit#(20) label;
  Bit#(3) exp;
  Bit#(1) bos;
  Bit#(8) ttl;
} MplsT deriving (Bits, Eq, FShow);
instance DefaultValue#(MplsT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(MplsT);
  defaultMask = unpack(maxBound);
endinstance

function MplsT extract_mpls_t(Bit#(32) data);
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
  Bit#(1) cC;
  Bit#(1) rR;
  Bit#(1) kK;
  Bit#(1) sS;
  Bit#(1) s;
  Bit#(3) recurse;
  Bit#(5) flags;
  Bit#(3) ver;
  Bit#(16) proto;
} GreT deriving (Bits, Eq, FShow);
instance DefaultValue#(GreT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(GreT);
  defaultMask = unpack(maxBound);
endinstance

function GreT extract_gre_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(24) tni;
  Bit#(8) flow_id;
} NvgreT deriving (Bits, Eq, FShow);
instance DefaultValue#(NvgreT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(NvgreT);
  defaultMask = unpack(maxBound);
endinstance

function NvgreT extract_nvgre_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(4) version;
  Bit#(12) vlan;
  Bit#(6) _priority;
  Bit#(10) span_id;
  Bit#(32) timestamp;
  Bit#(32) sgt_other;
} ErspanHeaderT3T deriving (Bits, Eq, FShow);
instance DefaultValue#(ErspanHeaderT3T);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(ErspanHeaderT3T);
  defaultMask = unpack(maxBound);
endinstance

function ErspanHeaderT3T extract_erspan_header_t3_t(Bit#(96) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) hwType;
  Bit#(16) protoType;
  Bit#(8) hwAddrLen;
  Bit#(8) protoAddrLen;
  Bit#(16) opcode;
} ArpRarpT deriving (Bits, Eq, FShow);
instance DefaultValue#(ArpRarpT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(ArpRarpT);
  defaultMask = unpack(maxBound);
endinstance

function ArpRarpT extract_arp_rarp_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(48) srcHwAddr;
  Bit#(32) srcProtoAddr;
  Bit#(48) dstHwAddr;
  Bit#(32) dstProtoAddr;
} ArpRarpIpv4T deriving (Bits, Eq, FShow);
instance DefaultValue#(ArpRarpIpv4T);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(ArpRarpIpv4T);
  defaultMask = unpack(maxBound);
endinstance

function ArpRarpIpv4T extract_arp_rarp_ipv4_t(Bit#(160) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) flags;
  Bit#(24) reserved;
  Bit#(24) vni;
  Bit#(8) reserved2;
} VxlanT deriving (Bits, Eq, FShow);
instance DefaultValue#(VxlanT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(VxlanT);
  defaultMask = unpack(maxBound);
endinstance

function VxlanT extract_vxlan_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) flags;
  Bit#(16) reserved;
  Bit#(8) next_proto;
  Bit#(24) vni;
  Bit#(8) reserved2;
} VxlanGpeT deriving (Bits, Eq, FShow);
instance DefaultValue#(VxlanGpeT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(VxlanGpeT);
  defaultMask = unpack(maxBound);
endinstance

function VxlanGpeT extract_vxlan_gpe_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) int_type;
  Bit#(8) rsvd;
  Bit#(8) len;
  Bit#(8) next_proto;
} VxlanGpeIntHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(VxlanGpeIntHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(VxlanGpeIntHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function VxlanGpeIntHeaderT extract_vxlan_gpe_int_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(2) ver;
  Bit#(6) optLen;
  Bit#(1) oam;
  Bit#(1) critical;
  Bit#(6) reserved;
  Bit#(16) protoType;
  Bit#(24) vni;
  Bit#(8) reserved2;
} GenvT deriving (Bits, Eq, FShow);
instance DefaultValue#(GenvT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(GenvT);
  defaultMask = unpack(maxBound);
endinstance

function GenvT extract_genv_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(32) version;
  Bit#(32) addrType;
  Bit#(32) ipAddress;
  Bit#(32) subAgentId;
  Bit#(32) seqNumber;
  Bit#(32) uptime;
  Bit#(32) numSamples;
} SflowHdrT deriving (Bits, Eq, FShow);
instance DefaultValue#(SflowHdrT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(SflowHdrT);
  defaultMask = unpack(maxBound);
endinstance

function SflowHdrT extract_sflow_hdr_t(Bit#(224) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(3) packetType;
  Bit#(2) headerVersion;
  Bit#(2) packetVersion;
  Bit#(1) pad1;
  Bit#(3) fabricColor;
  Bit#(5) fabricQos;
  Bit#(8) dstDevice;
  Bit#(16) dstPortOrGroup;
} FabricHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderT extract_fabric_header_t(Bit#(40) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) routed;
  Bit#(1) outerRouted;
  Bit#(1) tunnelTerminate;
  Bit#(5) ingressTunnelType;
  Bit#(16) nexthopIndex;
} FabricHeaderUnicastT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderUnicastT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderUnicastT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderUnicastT extract_fabric_header_unicast_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) routed;
  Bit#(1) outerRouted;
  Bit#(1) tunnelTerminate;
  Bit#(5) ingressTunnelType;
  Bit#(16) ingressIfindex;
  Bit#(16) ingressBd;
  Bit#(16) mcastGrp;
} FabricHeaderMulticastT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderMulticastT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderMulticastT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderMulticastT extract_fabric_header_multicast_t(Bit#(56) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) rewriteIndex;
  Bit#(10) egressPort;
  Bit#(5) egressQueue;
  Bit#(1) pad;
} FabricHeaderMirrorT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderMirrorT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderMirrorT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderMirrorT extract_fabric_header_mirror_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(5) egressQueue;
  Bit#(1) txBypass;
  Bit#(2) reserved;
  Bit#(16) ingressPort;
  Bit#(16) ingressIfindex;
  Bit#(16) ingressBd;
  Bit#(16) reasonCode;
} FabricHeaderCpuT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderCpuT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderCpuT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderCpuT extract_fabric_header_cpu_t(Bit#(72) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) sflow_session_id;
} FabricHeaderSflowT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricHeaderSflowT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricHeaderSflowT);
  defaultMask = unpack(maxBound);
endinstance

function FabricHeaderSflowT extract_fabric_header_sflow_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) etherType;
} FabricPayloadHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricPayloadHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricPayloadHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function FabricPayloadHeaderT extract_fabric_payload_header_t(Bit#(16) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(2) ver;
  Bit#(2) rep;
  Bit#(1) c;
  Bit#(1) e;
  Bit#(5) rsvd1;
  Bit#(5) ins_cnt;
  Bit#(8) max_hop_cnt;
  Bit#(8) total_hop_cnt;
  Bit#(4) instruction_mask_0003;
  Bit#(4) instruction_mask_0407;
  Bit#(4) instruction_mask_0811;
  Bit#(4) instruction_mask_1215;
  Bit#(16) rsvd2;
} IntHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntHeaderT extract_int_header_t(Bit#(64) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) switch_id;
} IntSwitchIdHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntSwitchIdHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntSwitchIdHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntSwitchIdHeaderT extract_int_switch_id_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(15) ingress_port_id_1;
  Bit#(16) ingress_port_id_0;
} IntIngressPortIdHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntIngressPortIdHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntIngressPortIdHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntIngressPortIdHeaderT extract_int_ingress_port_id_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) hop_latency;
} IntHopLatencyHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntHopLatencyHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntHopLatencyHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntHopLatencyHeaderT extract_int_hop_latency_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(7) q_occupancy1;
  Bit#(24) q_occupancy0;
} IntQOccupancyHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntQOccupancyHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntQOccupancyHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntQOccupancyHeaderT extract_int_q_occupancy_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) ingress_tstamp;
} IntIngressTstampHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntIngressTstampHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntIngressTstampHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntIngressTstampHeaderT extract_int_ingress_tstamp_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) egress_port_id;
} IntEgressPortIdHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntEgressPortIdHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntEgressPortIdHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntEgressPortIdHeaderT extract_int_egress_port_id_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) q_congestion;
} IntQCongestionHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntQCongestionHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntQCongestionHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntQCongestionHeaderT extract_int_q_congestion_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) egress_port_tx_utilization;
} IntEgressPortTxUtilizationHeaderT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntEgressPortTxUtilizationHeaderT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntEgressPortTxUtilizationHeaderT);
  defaultMask = unpack(maxBound);
endinstance

function IntEgressPortTxUtilizationHeaderT extract_int_egress_port_tx_utilization_header_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bos;
  Bit#(31) val;
} IntValueT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntValueT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntValueT);
  defaultMask = unpack(maxBound);
endinstance

function IntValueT extract_int_value_t(Bit#(32) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) resubmit_flag;
  Bit#(48) ingress_global_tstamp;
  Bit#(16) mcast_grp;
  Bit#(1) deflection_flag;
  Bit#(1) deflect_on_drop;
  Bit#(19) enq_qdepth;
  Bit#(32) enq_tstamp;
  Bit#(2) enq_congest_stat;
  Bit#(19) deq_qdepth;
  Bit#(2) deq_congest_stat;
  Bit#(32) deq_timedelta;
  Bit#(13) mcast_hash;
  Bit#(16) egress_rid;
  Bit#(32) lf_field_list;
  Bit#(3) _priority;
  Bit#(3) _padding;
} IngressIntrinsicMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IngressIntrinsicMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IngressIntrinsicMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function IngressIntrinsicMetadataT extract_ingress_intrinsic_metadata_t(Bit#(240) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(9) ingress_port;
  Bit#(16) ifindex;
  Bit#(16) egress_ifindex;
  Bit#(2) port_type;
  Bit#(16) outer_bd;
  Bit#(16) bd;
  Bit#(1) drop_flag;
  Bit#(8) drop_reason;
  Bit#(1) control_frame;
  Bit#(16) bypass_lookups;
  Bit#(32) sflow_take_sample;
  Bit#(3) _padding;
} IngressMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function IngressMetadataT extract_ingress_metadata_t(Bit#(136) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) bypass;
  Bit#(2) port_type;
  Bit#(16) payload_length;
  Bit#(9) smac_idx;
  Bit#(16) bd;
  Bit#(16) outer_bd;
  Bit#(48) mac_da;
  Bit#(1) routed;
  Bit#(16) same_bd_check;
  Bit#(8) drop_reason;
  Bit#(16) ifindex;
  Bit#(3) _padding;
} EgressMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(EgressMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(EgressMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function EgressMetadataT extract_egress_metadata_t(Bit#(152) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(48) lkp_mac_sa;
  Bit#(48) lkp_mac_da;
  Bit#(3) lkp_pkt_type;
  Bit#(16) lkp_mac_type;
  Bit#(16) l2_nexthop;
  Bit#(1) l2_nexthop_type;
  Bit#(1) l2_redirect;
  Bit#(1) l2_src_miss;
  Bit#(16) l2_src_move;
  Bit#(10) stp_group;
  Bit#(3) stp_state;
  Bit#(16) bd_stats_idx;
  Bit#(1) learning_enabled;
  Bit#(1) port_vlan_mapping_miss;
  Bit#(16) same_if_check;
  Bit#(3) _padding;
} L2MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(L2MetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(L2MetadataT);
  defaultMask = unpack(maxBound);
endinstance

function L2MetadataT extract_l2_metadata_t(Bit#(200) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(2) lkp_ip_type;
  Bit#(4) lkp_ip_version;
  Bit#(8) lkp_ip_proto;
  Bit#(8) lkp_ip_tc;
  Bit#(8) lkp_ip_ttl;
  Bit#(16) lkp_l4_sport;
  Bit#(16) lkp_l4_dport;
  Bit#(16) lkp_outer_l4_sport;
  Bit#(16) lkp_outer_l4_dport;
  Bit#(16) vrf;
  Bit#(10) rmac_group;
  Bit#(1) rmac_hit;
  Bit#(2) urpf_mode;
  Bit#(1) urpf_hit;
  Bit#(1) urpf_check_fail;
  Bit#(16) urpf_bd_group;
  Bit#(1) fib_hit;
  Bit#(16) fib_nexthop;
  Bit#(1) fib_nexthop_type;
  Bit#(16) same_bd_check;
  Bit#(16) nexthop_index;
  Bit#(1) routed;
  Bit#(1) outer_routed;
  Bit#(8) mtu_index;
  Bit#(1) l3_copy;
  Bit#(16) l3_mtu_check;
  Bit#(6) _padding;
} L3MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(L3MetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(L3MetadataT);
  defaultMask = unpack(maxBound);
endinstance

function L3MetadataT extract_l3_metadata_t(Bit#(224) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(32) lkp_ipv4_sa;
  Bit#(32) lkp_ipv4_da;
  Bit#(1) ipv4_unicast_enabled;
  Bit#(2) ipv4_urpf_mode;
  Bit#(5) _padding;
} Ipv4MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(Ipv4MetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(Ipv4MetadataT);
  defaultMask = unpack(maxBound);
endinstance

function Ipv4MetadataT extract_ipv4_metadata_t(Bit#(72) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(128) lkp_ipv6_sa;
  Bit#(128) lkp_ipv6_da;
  Bit#(1) ipv6_unicast_enabled;
  Bit#(1) ipv6_src_is_link_local;
  Bit#(2) ipv6_urpf_mode;
  Bit#(4) _padding;
} Ipv6MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(Ipv6MetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(Ipv6MetadataT);
  defaultMask = unpack(maxBound);
endinstance

function Ipv6MetadataT extract_ipv6_metadata_t(Bit#(264) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(5) ingress_tunnel_type;
  Bit#(24) tunnel_vni;
  Bit#(1) mpls_enabled;
  Bit#(20) mpls_label;
  Bit#(3) mpls_exp;
  Bit#(8) mpls_ttl;
  Bit#(5) egress_tunnel_type;
  Bit#(14) tunnel_index;
  Bit#(9) tunnel_src_index;
  Bit#(9) tunnel_smac_index;
  Bit#(14) tunnel_dst_index;
  Bit#(14) tunnel_dmac_index;
  Bit#(24) vnid;
  Bit#(1) tunnel_terminate;
  Bit#(1) tunnel_if_check;
  Bit#(4) egress_header_count;
  Bit#(8) inner_ip_proto;
  Bit#(4) _padding;
} TunnelMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(TunnelMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(TunnelMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function TunnelMetadataT extract_tunnel_metadata_t(Bit#(168) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) acl_deny;
  Bit#(1) acl_copy;
  Bit#(1) racl_deny;
  Bit#(16) acl_nexthop;
  Bit#(16) racl_nexthop;
  Bit#(1) acl_nexthop_type;
  Bit#(1) racl_nexthop_type;
  Bit#(1) acl_redirect;
  Bit#(1) racl_redirect;
  Bit#(16) if_label;
  Bit#(16) bd_label;
  Bit#(14) acl_stats_index;
  Bit#(3) _padding;
} AclMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(AclMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(AclMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function AclMetadataT extract_acl_metadata_t(Bit#(88) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(8) outer_dscp;
  Bit#(3) marked_cos;
  Bit#(8) marked_dscp;
  Bit#(3) marked_exp;
  Bit#(2) _padding;
} QosMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(QosMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(QosMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function QosMetadataT extract_qos_metadata_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(32) ingress_tstamp;
  Bit#(16) mirror_session_id;
} I2EMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(I2EMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(I2EMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function I2EMetadataT extract_i2e_metadata_t(Bit#(48) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) ipv4_mcast_key_type;
  Bit#(16) ipv4_mcast_key;
  Bit#(1) ipv6_mcast_key_type;
  Bit#(16) ipv6_mcast_key;
  Bit#(1) outer_mcast_route_hit;
  Bit#(2) outer_mcast_mode;
  Bit#(1) mcast_route_hit;
  Bit#(1) mcast_bridge_hit;
  Bit#(1) ipv4_multicast_enabled;
  Bit#(1) ipv6_multicast_enabled;
  Bit#(1) igmp_snooping_enabled;
  Bit#(1) mld_snooping_enabled;
  Bit#(16) bd_mrpf_group;
  Bit#(16) mcast_rpf_group;
  Bit#(2) mcast_mode;
  Bit#(16) multicast_route_mc_index;
  Bit#(16) multicast_bridge_mc_index;
  Bit#(1) inner_replica;
  Bit#(1) replica;
  Bit#(16) mcast_grp;
  Bit#(1) _padding;
} MulticastMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MulticastMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(MulticastMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function MulticastMetadataT extract_multicast_metadata_t(Bit#(128) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) nexthop_type;
  Bit#(7) _padding;
} NexthopMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(NexthopMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(NexthopMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function NexthopMetadataT extract_nexthop_metadata_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) storm_control_color;
  Bit#(1) ipsg_enabled;
  Bit#(1) ipsg_check_fail;
  Bit#(5) _padding;
} SecurityMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(SecurityMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(SecurityMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function SecurityMetadataT extract_security_metadata_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(3) packetType;
  Bit#(1) fabric_header_present;
  Bit#(16) reason_code;
  Bit#(8) dst_device;
  Bit#(16) dst_port;
  Bit#(4) _padding;
} FabricMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(FabricMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(FabricMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function FabricMetadataT extract_fabric_metadata_t(Bit#(48) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) ifindex_check;
  Bit#(16) bd;
  Bit#(16) inner_bd;
} EgressFilterMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(EgressFilterMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(EgressFilterMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function EgressFilterMetadataT extract_egress_filter_metadata_t(Bit#(48) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(32) switch_id;
  Bit#(8) insert_cnt;
  Bit#(16) insert_byte_cnt;
  Bit#(16) gpe_int_hdr_len;
  Bit#(8) gpe_int_hdr_len8;
  Bit#(16) instruction_cnt;
} IntMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function IntMetadataT extract_int_metadata_t(Bit#(96) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(1) sink;
  Bit#(1) source;
  Bit#(6) _padding;
} IntMetadataI2ET deriving (Bits, Eq, FShow);
instance DefaultValue#(IntMetadataI2ET);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(IntMetadataI2ET);
  defaultMask = unpack(maxBound);
endinstance

function IntMetadataI2ET extract_int_metadata_i2e_t(Bit#(8) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) hash1;
  Bit#(16) hash2;
  Bit#(16) entropy_hash;
} HashMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(HashMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(HashMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function HashMetadataT extract_hash_metadata_t(Bit#(48) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(2) meter_color;
  Bit#(16) meter_index;
  Bit#(6) _padding;
} MeterMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MeterMetadataT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(MeterMetadataT);
  defaultMask = unpack(maxBound);
endinstance

function MeterMetadataT extract_meter_metadata_t(Bit#(24) data);
  return unpack(byteSwap(data));
endfunction


typedef struct {
  Bit#(16) sflow_session_id;
} SflowMetaT deriving (Bits, Eq, FShow);
instance DefaultValue#(SflowMetaT);
  defaultValue = unpack(0);
endinstance

instance DefaultMask#(SflowMetaT);
  defaultMask = unpack(maxBound);
endinstance

function SflowMetaT extract_sflow_meta_t(Bit#(16) data);
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
  } AclStatsAclStatsUpdateRspT;
} AclStatsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } BdFloodNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } BdFloodSetBdFloodMcIndexRspT;
} BdFloodResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ComputeIpv4HashesComputeLkpIpv4HashRspT;
} ComputeIpv4HashesResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ComputeIpv6HashesComputeLkpIpv6HashRspT;
} ComputeIpv6HashesResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ComputeNonIpHashesComputeLkpNonIpHashRspT;
} ComputeNonIpHashesResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ComputeOtherHashesComputedTwoHashesRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ComputeOtherHashesComputedOneHashRspT;
} ComputeOtherHashesResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacMulticastHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacRedirectEcmpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DmacDmacDropRspT;
} DmacResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DropStatsDropStatsUpdateRspT;
} DropStatsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EcmpGroupNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EcmpGroupSetEcmpNexthopDetailsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EcmpGroupSetEcmpNexthopDetailsForPostRoutedFloodRspT;
} EcmpGroupResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpTerminateCpuPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpSwitchFabricUnicastPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpTerminateFabricUnicastPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpSwitchFabricMulticastPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressDstLkpTerminateFabricMulticastPacketRspT;
} FabricIngressDstLkpResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressSrcLkpNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricIngressSrcLkpSetIngressIfindexPropertiesRspT;
} FabricIngressSrcLkpResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricLagNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricLagSetFabricLagPortRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FabricLagSetFabricMulticastRspT;
} FabricLagResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetL2RedirectActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetFibRedirectActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetCpuRedirectActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetAclRedirectActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetRaclRedirectActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetMulticastRouteActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetMulticastBridgeActionRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetMulticastFloodRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } FwdResultSetMulticastDropRspT;
} FwdResultResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IngressBdStatsUpdateIngressBdStatsRspT;
} IngressBdStatsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IngressPortMappingSetIfindexRspT;
} IngressPortMappingResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IngressPortPropertiesSetIngressPortPropertiesRspT;
} IngressPortPropertiesResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntSinkUpdateOuterIntSinkUpdateVxlanGpeV4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntSinkUpdateOuterNopRspT;
} IntSinkUpdateOuterResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntSourceIntSetSrcRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntSourceIntSetNoSrcRspT;
} IntSourceResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntTerminateIntSinkGpeRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntTerminateIntNoSinkRspT;
} IntTerminateResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclAclDenyRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclAclPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclAclMirrorRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclAclRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpAclAclRedirectEcmpRspT;
} IpAclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpsgOnMissRspT;
} IpsgResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IpsgPermitSpecialIpsgMissRspT;
} IpsgPermitSpecialResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4DestVtepNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4DestVtepSetTunnelTerminationFlagRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4DestVtepSetTunnelVniAndTerminationFlagRspT;
} Ipv4DestVtepResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibFibHitNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibFibHitEcmpRspT;
} Ipv4FibResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibLpmOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibLpmFibHitNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4FibLpmFibHitEcmpRspT;
} Ipv4FibLpmResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastBridgeOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastBridgeMulticastBridgeSGHitRspT;
} Ipv4MulticastBridgeResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastBridgeStarGNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastBridgeStarGMulticastBridgeStarGHitRspT;
} Ipv4MulticastBridgeStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastRouteOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastRouteMulticastRouteSGHitRspT;
} Ipv4MulticastRouteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastRouteStarGMulticastRouteStarGMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastRouteStarGMulticastRouteSmStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4MulticastRouteStarGMulticastRouteBidirStarGHitRspT;
} Ipv4MulticastRouteStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4RaclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4RaclRaclDenyRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4RaclRaclPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4RaclRaclRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4RaclRaclRedirectEcmpRspT;
} Ipv4RaclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4SrcVtepOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4SrcVtepSrcVtepHitRspT;
} Ipv4SrcVtepResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4UrpfOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4UrpfIpv4UrpfHitRspT;
} Ipv4UrpfResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4UrpfLpmIpv4UrpfHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv4UrpfLpmUrpfMissRspT;
} Ipv4UrpfLpmResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclAclDenyRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclAclPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclAclMirrorRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclAclRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6AclAclRedirectEcmpRspT;
} Ipv6AclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6DestVtepNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6DestVtepSetTunnelTerminationFlagRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6DestVtepSetTunnelVniAndTerminationFlagRspT;
} Ipv6DestVtepResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibFibHitNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibFibHitEcmpRspT;
} Ipv6FibResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibLpmOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibLpmFibHitNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6FibLpmFibHitEcmpRspT;
} Ipv6FibLpmResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastBridgeOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastBridgeMulticastBridgeSGHitRspT;
} Ipv6MulticastBridgeResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastBridgeStarGNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastBridgeStarGMulticastBridgeStarGHitRspT;
} Ipv6MulticastBridgeStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastRouteOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastRouteMulticastRouteSGHitRspT;
} Ipv6MulticastRouteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastRouteStarGMulticastRouteStarGMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastRouteStarGMulticastRouteSmStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6MulticastRouteStarGMulticastRouteBidirStarGHitRspT;
} Ipv6MulticastRouteStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6RaclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6RaclRaclDenyRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6RaclRaclPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6RaclRaclRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6RaclRaclRedirectEcmpRspT;
} Ipv6RaclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6SrcVtepOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6SrcVtepSrcVtepHitRspT;
} Ipv6SrcVtepResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6UrpfOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6UrpfIpv6UrpfHitRspT;
} Ipv6UrpfResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6UrpfLpmIpv6UrpfHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } Ipv6UrpfLpmUrpfMissRspT;
} Ipv6UrpfLpmResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LagGroupSetLagMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LagGroupSetLagPortRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LagGroupSetLagRemotePortRspT;
} LagGroupResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LearnNotifyNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } LearnNotifyGenerateLearnNotifyRspT;
} LearnNotifyResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclAclDenyRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclAclPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclAclMirrorRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclAclRedirectNexthopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MacAclAclRedirectEcmpRspT;
} MacAclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MeterActionMeterPermitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MeterActionMeterDenyRspT;
} MeterActionResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MeterIndexNopRspT;
} MeterIndexResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsTerminateEomplsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsTerminateVplsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsTerminateIpv4OverMplsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsTerminateIpv6OverMplsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsTerminatePwRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MplsForwardMplsRspT;
} MplsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NativePacketOverFabricNonIpOverFabricRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NativePacketOverFabricIpv4OverFabricRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NativePacketOverFabricIpv6OverFabricRspT;
} NativePacketOverFabricResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NexthopNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NexthopSetNexthopDetailsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } NexthopSetNexthopDetailsForPostRoutedFloodRspT;
} NexthopResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastOuterMulticastRouteSGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastOuterMulticastBridgeSGHitRspT;
} OuterIpv4MulticastResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastStarGNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastStarGOuterMulticastRouteSmStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastStarGOuterMulticastRouteBidirStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv4MulticastStarGOuterMulticastBridgeStarGHitRspT;
} OuterIpv4MulticastStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastOuterMulticastRouteSGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastOuterMulticastBridgeSGHitRspT;
} OuterIpv6MulticastResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastStarGNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastStarGOuterMulticastRouteSmStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastStarGOuterMulticastRouteBidirStarGHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterIpv6MulticastStarGOuterMulticastBridgeStarGHitRspT;
} OuterIpv6MulticastStarGResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterRmacOnMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } OuterRmacOuterRmacHitRspT;
} OuterRmacResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } PortVlanMappingSetBdPropertiesRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } PortVlanMappingPortVlanMappingMissRspT;
} PortVlanMappingResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } QosNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } QosApplyCosMarkingRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } QosApplyDscpMarkingRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } QosApplyTcMarkingRspT;
} QosResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RmacRmacHitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RmacRmacMissRspT;
} RmacResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SflowIngTakeSampleNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SflowIngTakeSampleSflowIngPktToCpuRspT;
} SflowIngTakeSampleResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SflowIngressNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SflowIngressSflowIngSessionEnableRspT;
} SflowIngressResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SmacNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SmacSmacMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SmacSmacHitRspT;
} SmacResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SpanningTreeSetStpStateRspT;
} SpanningTreeResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } StormControlNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } StormControlSetStormControlMeterRspT;
} StormControlResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } StormControlStatsNopRspT;
} StormControlStatsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SwitchConfigParamsSetConfigParametersRspT;
} SwitchConfigParamsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclRedirectToCpuRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclCopyToCpuWithReasonRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclCopyToCpuRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclDropPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclDropPacketWithReasonRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SystemAclNegativeMirrorRspT;
} SystemAclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTunnelLookupMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTerminateTunnelInnerNonIpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTerminateTunnelInnerEthernetIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTerminateTunnelInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTerminateTunnelInnerEthernetIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelTerminateTunnelInnerIpv6RspT;
} TunnelResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelLookupMissNonIpTunnelLookupMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelLookupMissIpv4TunnelLookupMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelLookupMissIpv6TunnelLookupMissRspT;
} TunnelLookupMissResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelMissNonIpTunnelLookupMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelMissIpv4TunnelLookupMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelMissIpv6TunnelLookupMissRspT;
} TunnelMissResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } UrpfBdNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } UrpfBdUrpfBdMissRspT;
} UrpfBdResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateMplsPacketSetValidMplsLabel1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateMplsPacketSetValidMplsLabel2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateMplsPacketSetValidMplsLabel3RspT;
} ValidateMplsPacketResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetMalformedOuterEthernetPacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterUnicastPacketUntaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterUnicastPacketSingleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterUnicastPacketDoubleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterUnicastPacketQinqTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterMulticastPacketUntaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterMulticastPacketSingleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterMulticastPacketDoubleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterMulticastPacketQinqTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterBroadcastPacketUntaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterBroadcastPacketSingleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterBroadcastPacketDoubleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterEthernetSetValidOuterBroadcastPacketQinqTaggedRspT;
} ValidateOuterEthernetResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterIpv4PacketSetValidOuterIpv4PacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterIpv4PacketSetMalformedOuterIpv4PacketRspT;
} ValidateOuterIpv4PacketResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterIpv6PacketSetValidOuterIpv6PacketRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidateOuterIpv6PacketSetMalformedOuterIpv6PacketRspT;
} ValidateOuterIpv6PacketResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetUnicastRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetUnicastAndIpv6SrcIsLinkLocalRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetMulticastRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetMulticastAndIpv6SrcIsLinkLocalRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetBroadcastRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ValidatePacketSetMalformedPacketRspT;
} ValidatePacketResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressAclNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressAclEgressMirrorRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressAclEgressMirrorDropRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressAclEgressRedirectToCpuRspT;
} EgressAclResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressBdMapNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressBdMapSetEgressBdPropertiesRspT;
} EgressBdMapResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressBdStatsNopRspT;
} EgressBdStatsResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressFilterEgressFilterCheckRspT;
} EgressFilterResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressFilterDropSetEgressFilterDropRspT;
} EgressFilterDropResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressPortMappingEgressPortTypeNormalRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressPortMappingEgressPortTypeFabricRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressPortMappingEgressPortTypeCpuRspT;
} EgressPortMappingResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressVlanXlateSetEgressPacketVlanUntaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressVlanXlateSetEgressPacketVlanTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressVlanXlateSetEgressPacketVlanDoubleTaggedRspT;
} EgressVlanXlateResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressVniNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } EgressVniSetEgressTunnelVniRspT;
} EgressVniResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader0BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader1BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader2BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader3BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader4BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader5BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader6BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosIntSetHeader7BosRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntBosNopRspT;
} IntBosResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInsertIntTransitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInsertIntSrcRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInsertIntResetRspT;
} IntInsertResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I0RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I5RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I7RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I8RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I9RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I10RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I11RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I12RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I13RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I14RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0003IntSetHeader0003I15RspT;
} IntInst0003Response deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I0RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I5RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I7RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I8RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I9RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I10RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I11RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I12RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I13RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I14RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407IntSetHeader0407I15RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0407NopRspT;
} IntInst0407Response deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst0811NopRspT;
} IntInst0811Response deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntInst1215NopRspT;
} IntInst1215Response deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntMetaHeaderUpdateIntSetEBitRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntMetaHeaderUpdateIntUpdateTotalHopCntRspT;
} IntMetaHeaderUpdateResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntOuterEncapIntUpdateVxlanGpeIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntOuterEncapIntAddUpdateVxlanGpeIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } IntOuterEncapNopRspT;
} IntOuterEncapResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteIpv4UnicastRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteIpv4MulticastRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteIpv6UnicastRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteIpv6MulticastRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } L3RewriteMplsRewriteRspT;
} L3RewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MirrorNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MirrorSetMirrorNhopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MirrorSetMirrorBdRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MirrorSflowPktToCpuRspT;
} MirrorResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MtuMtuMissRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MtuIpv4MtuCheckRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } MtuIpv6MtuCheckRspT;
} MtuResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ReplicaTypeNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ReplicaTypeSetReplicaCopyBridgedRspT;
} ReplicaTypeResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetL2RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetL2RewriteWithTunnelRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetL3RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetL3RewriteWithTunnelRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetMplsSwapPushRewriteL2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetMplsPushRewriteL2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetMplsSwapPushRewriteL3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteSetMplsPushRewriteL3RspT;
} RewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteMulticastNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteMulticastRewriteIpv4MulticastRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RewriteMulticastRewriteIpv6MulticastRspT;
} RewriteMulticastResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RidNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RidOuterReplicaFromRidRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } RidInnerReplicaFromRidRspT;
} RidResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } SmacRewriteRewriteSmacRspT;
} SmacRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessInnerDecapInnerUdpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessInnerDecapInnerTcpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessInnerDecapInnerIcmpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessInnerDecapInnerUnknownRspT;
} TunnelDecapProcessInnerResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapVxlanInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapVxlanInnerIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapVxlanInnerNonIpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGenvInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGenvInnerIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGenvInnerNonIpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapNvgreInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapNvgreInnerIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapNvgreInnerNonIpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGreInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGreInnerIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapGreInnerNonIpRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapIpInnerIpv4RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapIpInnerIpv6RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv4Pop1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv6Pop1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv4Pop1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv6Pop1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetNonIpPop1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv4Pop2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv6Pop2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv4Pop2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv6Pop2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetNonIpPop2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv4Pop3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerIpv6Pop3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv4Pop3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetIpv6Pop3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDecapProcessOuterDecapMplsInnerEthernetNonIpPop3RspT;
} TunnelDecapProcessOuterResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDmacRewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDmacRewriteRewriteTunnelDmacRspT;
} TunnelDmacRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDstRewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDstRewriteRewriteTunnelIpv4DstRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelDstRewriteRewriteTunnelIpv6DstRspT;
} TunnelDstRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv4UdpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv4TcpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv4IcmpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv4UnknownRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv6UdpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv6TcpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv6IcmpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerIpv6UnknownRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessInnerInnerNonIpRewriteRspT;
} TunnelEncapProcessInnerResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4VxlanRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4GenvRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4NvgreRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4GreRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4IpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv4ErspanT3RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6GreRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6IpRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6NvgreRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6VxlanRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6GenvRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterIpv6ErspanT3RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsEthernetPush1RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsIpPush1RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsEthernetPush2RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsIpPush2RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsEthernetPush3RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterMplsIpPush3RewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelEncapProcessOuterFabricRewriteRspT;
} TunnelEncapProcessOuterResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelMtuTunnelMtuCheckRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelMtuTunnelMtuMissRspT;
} TunnelMtuResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteSetTunnelRewriteDetailsRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteSetMplsRewritePush1RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteSetMplsRewritePush2RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteSetMplsRewritePush3RspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteCpuRxRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteFabricUnicastRewriteRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelRewriteFabricMulticastRewriteRspT;
} TunnelRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelSmacRewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelSmacRewriteRewriteTunnelSmacRspT;
} TunnelSmacRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelSrcRewriteNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelSrcRewriteRewriteTunnelIpv4SrcRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } TunnelSrcRewriteRewriteTunnelIpv6SrcRspT;
} TunnelSrcRewriteResponse deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } VlanDecapNopRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } VlanDecapRemoveVlanSingleTaggedRspT;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } VlanDecapRemoveVlanDoubleTaggedRspT;
} VlanDecapResponse deriving (Bits, Eq, FShow);
typedef struct {
  Maybe#(Bit#(1)) acl_metadata$acl_deny;
  Maybe#(Bit#(14)) acl_metadata$acl_stats_index;
  Maybe#(Bit#(16)) meter_metadata$meter_index;
  Maybe#(Bit#(16)) fabric_metadata$reason_code;
  Maybe#(Bit#(1)) acl_metadata$acl_copy;
  Maybe#(Bit#(16)) runtime_acl_copy_reason_16;
  Maybe#(Bit#(1)) runtime_acl_copy_1;
  Maybe#(Bit#(16)) runtime_acl_meter_index_16;
  Maybe#(Bit#(14)) runtime_acl_stats_index_14;
  Maybe#(Bit#(48)) intrinsic_metadata$ingress_global_tstamp;
  Maybe#(Bit#(32)) i2e_metadata$ingress_tstamp;
  Maybe#(Bit#(16)) i2e_metadata$mirror_session_id;
  Maybe#(Bit#(32)) runtime_session_id_32;
  Maybe#(Bit#(1)) acl_metadata$acl_redirect;
  Maybe#(Bit#(16)) acl_metadata$acl_nexthop;
  Maybe#(Bit#(1)) acl_metadata$acl_nexthop_type;
  Maybe#(Bit#(16)) runtime_ecmp_index_16;
  Maybe#(Bit#(16)) runtime_nexthop_index_16;
  Maybe#(Bit#(3)) qos_metadata$marked_cos;
  Maybe#(Bit#(3)) runtime_cos_3;
  Maybe#(Bit#(8)) qos_metadata$marked_dscp;
  Maybe#(Bit#(8)) runtime_dscp_8;
  Maybe#(Bit#(3)) qos_metadata$marked_exp;
  Maybe#(Bit#(3)) runtime_tc_3;
  Maybe#(Bit#(16)) hash_metadata$hash2;
  Maybe#(Bit#(16)) hash_metadata$entropy_hash;
  Maybe#(Bit#(13)) intrinsic_metadata$mcast_hash;
  Maybe#(Bit#(16)) hash_metadata$hash1;
  Maybe#(Bit#(16)) runtime_reason_code_16;
  Maybe#(Bit#(16)) ingress_metadata$bd;
  Maybe#(Bit#(9)) ingress_metadata$ingress_port;
  Maybe#(Bit#(16)) ingress_metadata$ifindex;
  Maybe#(Bit#(16)) ethernet$etherType;
  Maybe#(Bit#(3)) fabric_header$packetType;
  Maybe#(Bit#(16)) fabric_header_cpu$reasonCode;
  Maybe#(Bit#(16)) fabric_header_cpu$ingressPort;
  Maybe#(Bit#(16)) fabric_header_cpu$ingressIfindex;
  Maybe#(Bit#(16)) fabric_payload_header$etherType;
  Maybe#(Bit#(16)) fabric_header_cpu$ingressBd;
  Maybe#(Bit#(2)) fabric_header$headerVersion;
  Maybe#(Bit#(2)) fabric_header$packetVersion;
  Maybe#(Bit#(1)) fabric_header$pad1;
  Maybe#(Bit#(16)) gre$proto;
  Maybe#(Bit#(16)) ingress_metadata$egress_ifindex;
  Maybe#(Bit#(16)) runtime_ifindex_16;
  Maybe#(Bit#(8)) fabric_metadata$dst_device;
  Maybe#(Bit#(16)) intrinsic_metadata$mcast_grp;
  Maybe#(Bit#(16)) runtime_mc_index_16;
  Maybe#(Bit#(1)) l2_metadata$l2_redirect;
  Maybe#(Bit#(16)) l2_metadata$l2_nexthop;
  Maybe#(Bit#(1)) l2_metadata$l2_nexthop_type;
  Maybe#(Bit#(32)) runtime_drop_reason_32;
  Maybe#(Bit#(16)) egress_metadata$ifindex;
  Maybe#(Bit#(2)) egress_metadata$port_type;
  Maybe#(Bit#(5)) tunnel_metadata$egress_tunnel_type;
  Maybe#(Bit#(16)) multicast_metadata$mcast_grp;
  Maybe#(Bit#(5)) tunnel_metadata$ingress_tunnel_type;
  Maybe#(Bit#(1)) l3_metadata$routed;
  Maybe#(Bit#(1)) tunnel_metadata$tunnel_terminate;
  Maybe#(Bit#(1)) l3_metadata$outer_routed;
  Maybe#(Bit#(1)) fabric_header_multicast$tunnelTerminate;
  Maybe#(Bit#(1)) fabric_header_multicast$routed;
  Maybe#(Bit#(5)) fabric_header_multicast$ingressTunnelType;
  Maybe#(Bit#(8)) fabric_header$dstDevice;
  Maybe#(Bit#(1)) fabric_header_multicast$outerRouted;
  Maybe#(Bit#(16)) fabric_header_multicast$ingressIfindex;
  Maybe#(Bit#(16)) fabric_header$dstPortOrGroup;
  Maybe#(Bit#(16)) fabric_header_multicast$ingressBd;
  Maybe#(Bit#(16)) fabric_header_multicast$mcastGrp;
  Maybe#(Bit#(16)) runtime_fabric_mgid_16;
  Maybe#(Bit#(14)) tunnel_metadata$tunnel_index;
  Maybe#(Bit#(14)) runtime_tunnel_index_14;
  Maybe#(Bit#(16)) l3_metadata$nexthop_index;
  Maybe#(Bit#(16)) fabric_metadata$dst_port;
  Maybe#(Bit#(1)) fabric_header_unicast$outerRouted;
  Maybe#(Bit#(1)) fabric_header_unicast$tunnelTerminate;
  Maybe#(Bit#(5)) fabric_header_unicast$ingressTunnelType;
  Maybe#(Bit#(16)) fabric_header_unicast$nexthopIndex;
  Maybe#(Bit#(1)) fabric_header_unicast$routed;
  Maybe#(Bit#(16)) l3_metadata$fib_nexthop;
  Maybe#(Bit#(1)) l3_metadata$fib_hit;
  Maybe#(Bit#(1)) l3_metadata$fib_nexthop_type;
  Maybe#(Bit#(48)) ethernet$srcAddr;
  Maybe#(Bit#(48)) ethernet$dstAddr;
  Maybe#(Bit#(48)) l2_metadata$lkp_mac_sa;
  Maybe#(Bit#(48)) l2_metadata$lkp_mac_da;
  Maybe#(Bit#(16)) ipv4$totalLen;
  Maybe#(Bit#(8)) tunnel_metadata$inner_ip_proto;
  Maybe#(Bit#(16)) egress_metadata$payload_length;
  Maybe#(Bit#(1)) multicast_metadata$replica;
  Maybe#(Bit#(1)) multicast_metadata$inner_replica;
  Maybe#(Bit#(4)) tunnel_metadata$egress_header_count;
  Maybe#(Bit#(16)) egress_metadata$bd;
  Maybe#(Bit#(1)) egress_metadata$routed;
  Maybe#(Bit#(5)) runtime_tunnel_type_5;
  Maybe#(Bit#(16)) runtime_bd_16;
  Maybe#(Bit#(4)) runtime_header_count_4;
  Maybe#(Bit#(8)) int_metadata$gpe_int_hdr_len8;
  Maybe#(Bit#(16)) int_metadata$insert_byte_cnt;
  Maybe#(Bit#(8)) vxlan_gpe$next_proto;
  Maybe#(Bit#(8)) vxlan_gpe_int_header$len;
  Maybe#(Bit#(8)) vxlan_gpe_int_header$next_proto;
  Maybe#(Bit#(8)) vxlan_gpe_int_header$int_type;
  Maybe#(Bit#(16)) udp$length_;
  Maybe#(Bit#(1)) int_metadata_i2e$sink;
  Maybe#(Bit#(32)) int_metadata$switch_id;
  Maybe#(Bit#(8)) int_metadata$insert_cnt;
  Maybe#(Bit#(16)) int_metadata$gpe_int_hdr_len;
  Maybe#(Bit#(16)) int_metadata$instruction_cnt;
  Maybe#(Bit#(1)) int_header$e;
  Maybe#(Bit#(19)) intrinsic_metadata$enq_qdepth;
  Maybe#(Bit#(24)) int_q_occupancy_header$q_occupancy0;
  Maybe#(Bit#(7)) int_q_occupancy_header$q_occupancy1;
  Maybe#(Bit#(32)) intrinsic_metadata$deq_timedelta;
  Maybe#(Bit#(31)) int_switch_id_header$switch_id;
  Maybe#(Bit#(31)) int_hop_latency_header$hop_latency;
  Maybe#(Bit#(15)) int_ingress_port_id_header$ingress_port_id_1;
  Maybe#(Bit#(16)) int_ingress_port_id_header$ingress_port_id_0;
  Maybe#(Bit#(31)) int_egress_port_tx_utilization_header$egress_port_tx_utilization;
  Maybe#(Bit#(31)) int_q_congestion_header$q_congestion;
  Maybe#(Bit#(31)) int_ingress_tstamp_header$ingress_tstamp;
  Maybe#(Bit#(9)) standard_metadata$egress_port;
  Maybe#(Bit#(31)) int_egress_port_id_header$egress_port_id;
  Maybe#(Bit#(1)) int_switch_id_header$bos;
  Maybe#(Bit#(1)) int_ingress_port_id_header$bos;
  Maybe#(Bit#(1)) int_hop_latency_header$bos;
  Maybe#(Bit#(1)) int_q_occupancy_header$bos;
  Maybe#(Bit#(1)) int_ingress_tstamp_header$bos;
  Maybe#(Bit#(1)) int_egress_port_id_header$bos;
  Maybe#(Bit#(1)) int_q_congestion_header$bos;
  Maybe#(Bit#(1)) int_egress_port_tx_utilization_header$bos;
  Maybe#(Bit#(1)) int_metadata_i2e$source;
  Maybe#(Bit#(32)) runtime_mirror_id_32;
  Maybe#(Bit#(16)) int_header$rsvd2;
  Maybe#(Bit#(5)) int_header$ins_cnt;
  Maybe#(Bit#(4)) int_header$instruction_mask_0407;
  Maybe#(Bit#(8)) int_header$total_hop_cnt;
  Maybe#(Bit#(4)) int_header$instruction_mask_1215;
  Maybe#(Bit#(5)) int_header$rsvd1;
  Maybe#(Bit#(4)) int_header$instruction_mask_0811;
  Maybe#(Bit#(2)) int_header$rep;
  Maybe#(Bit#(2)) int_header$ver;
  Maybe#(Bit#(8)) int_header$max_hop_cnt;
  Maybe#(Bit#(4)) int_header$instruction_mask_0003;
  Maybe#(Bit#(1)) int_header$c;
  Maybe#(Bit#(8)) runtime_total_words_8;
  Maybe#(Bit#(32)) runtime_switch_id_32;
  Maybe#(Bit#(4)) runtime_ins_mask0003_4;
  Maybe#(Bit#(16)) runtime_ins_byte_cnt_16;
  Maybe#(Bit#(5)) runtime_ins_cnt_5;
  Maybe#(Bit#(8)) runtime_hop_cnt_8;
  Maybe#(Bit#(4)) runtime_ins_mask0407_4;
  Maybe#(Bit#(1)) security_metadata$ipsg_check_fail;
  Maybe#(Bit#(1)) gre$S;
  Maybe#(Bit#(16)) ipv4$identification;
  Maybe#(Bit#(1)) gre$s;
  Maybe#(Bit#(4)) ipv4$version;
  Maybe#(Bit#(4)) ipv4$ihl;
  Maybe#(Bit#(8)) ipv4$ttl;
  Maybe#(Bit#(3)) gre$ver;
  Maybe#(Bit#(32)) erspan_t3_header$timestamp;
  Maybe#(Bit#(1)) gre$C;
  Maybe#(Bit#(3)) gre$recurse;
  Maybe#(Bit#(10)) erspan_t3_header$span_id;
  Maybe#(Bit#(1)) gre$K;
  Maybe#(Bit#(4)) erspan_t3_header$version;
  Maybe#(Bit#(5)) gre$flags;
  Maybe#(Bit#(32)) erspan_t3_header$sgt_other;
  Maybe#(Bit#(8)) ipv4$protocol;
  Maybe#(Bit#(1)) gre$R;
  Maybe#(Bit#(24)) tunnel_metadata$vnid;
  Maybe#(Bit#(24)) genv$vni;
  Maybe#(Bit#(16)) udp$checksum;
  Maybe#(Bit#(6)) genv$optLen;
  Maybe#(Bit#(1)) genv$oam;
  Maybe#(Bit#(8)) genv$reserved2;
  Maybe#(Bit#(1)) genv$critical;
  Maybe#(Bit#(16)) udp$srcPort;
  Maybe#(Bit#(16)) genv$protoType;
  Maybe#(Bit#(2)) genv$ver;
  Maybe#(Bit#(16)) udp$dstPort;
  Maybe#(Bit#(6)) genv$reserved;
  Maybe#(Bit#(16)) runtime_l3_mtu_16;
  Maybe#(Bit#(8)) nvgre$flow_id;
  Maybe#(Bit#(24)) nvgre$tni;
  Maybe#(Bit#(32)) ipv4$srcAddr;
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(16)) l3_metadata$lkp_outer_l4_dport;
  Maybe#(Bit#(16)) l3_metadata$lkp_outer_l4_sport;
  Maybe#(Bit#(32)) ipv4_metadata$lkp_ipv4_da;
  Maybe#(Bit#(32)) ipv4_metadata$lkp_ipv4_sa;
  Maybe#(Bit#(16)) l3_metadata$lkp_l4_dport;
  Maybe#(Bit#(16)) l3_metadata$lkp_l4_sport;
  Maybe#(Bit#(8)) l3_metadata$lkp_ip_proto;
  Maybe#(Bit#(8)) l3_metadata$lkp_ip_ttl;
  Maybe#(Bit#(48)) egress_metadata$mac_da;
  Maybe#(Bit#(2)) ipv4_metadata$ipv4_urpf_mode;
  Maybe#(Bit#(16)) l3_metadata$urpf_bd_group;
  Maybe#(Bit#(1)) l3_metadata$urpf_hit;
  Maybe#(Bit#(2)) l3_metadata$urpf_mode;
  Maybe#(Bit#(16)) runtime_urpf_bd_group_16;
  //Maybe#(Bit#(None)) vxlan$vni;
  //Maybe#(Bit#(None)) vxlan$flags;
  //Maybe#(Bit#(None)) vxlan$reserved2;
  //Maybe#(Bit#(None)) vxlan$reserved;
  Maybe#(Bit#(4)) ipv6$version;
  Maybe#(Bit#(8)) ipv6$trafficClass;
  Maybe#(Bit#(8)) ipv6$hopLimit;
  Maybe#(Bit#(20)) ipv6$flowLabel;
  Maybe#(Bit#(8)) ipv6$nextHdr;
  Maybe#(Bit#(16)) ipv6$payloadLen;
  Maybe#(Bit#(128)) ipv6$srcAddr;
  Maybe#(Bit#(128)) ipv6$dstAddr;
  Maybe#(Bit#(128)) ipv6_metadata$lkp_ipv6_sa;
  Maybe#(Bit#(128)) ipv6_metadata$lkp_ipv6_da;
  Maybe#(Bit#(2)) ipv6_metadata$ipv6_urpf_mode;
  Maybe#(Bit#(8)) ingress_metadata$drop_reason;
  Maybe#(Bit#(1)) ingress_metadata$drop_flag;
  Maybe#(Bit#(8)) runtime_drop_reason_8;
  Maybe#(Bit#(8)) mpls0$ttl;
  Maybe#(Bit#(16)) l3_metadata$l3_mtu_check;
  Maybe#(Bit#(1)) multicast_metadata$mcast_bridge_hit;
  Maybe#(Bit#(16)) multicast_metadata$multicast_bridge_mc_index;
  Maybe#(Bit#(1)) multicast_metadata$mcast_route_hit;
  Maybe#(Bit#(16)) multicast_metadata$multicast_route_mc_index;
  Maybe#(Bit#(2)) multicast_metadata$mcast_mode;
  Maybe#(Bit#(16)) runtime_mcast_rpf_group_16;
  Maybe#(Bit#(1)) l3_metadata$l3_copy;
  Maybe#(Bit#(16)) l2_metadata$lkp_mac_type;
  Maybe#(Bit#(1)) multicast_metadata$outer_mcast_route_hit;
  Maybe#(Bit#(2)) multicast_metadata$outer_mcast_mode;
  Maybe#(Bit#(1)) l3_metadata$rmac_hit;
  Maybe#(Bit#(1)) l2_metadata$port_vlan_mapping_miss;
  Maybe#(Bit#(1)) acl_metadata$racl_deny;
  Maybe#(Bit#(16)) acl_metadata$racl_nexthop;
  Maybe#(Bit#(1)) acl_metadata$racl_redirect;
  Maybe#(Bit#(1)) acl_metadata$racl_nexthop_type;
  Maybe#(Bit#(16)) vlan_tag_1$etherType;
  Maybe#(Bit#(16)) vlan_tag_0$etherType;
  Maybe#(Bit#(48)) runtime_smac_48;
  Maybe#(Bit#(48)) runtime_dmac_48;
  Maybe#(Bit#(32)) runtime_ip_32;
  Maybe#(Bit#(128)) runtime_ip_128;
  Maybe#(Bit#(1)) nexthop_metadata$nexthop_type;
  Maybe#(Bit#(16)) multicast_metadata$ipv4_mcast_key;
  Maybe#(Bit#(10)) l3_metadata$rmac_group;
  Maybe#(Bit#(1)) multicast_metadata$igmp_snooping_enabled;
  Maybe#(Bit#(16)) multicast_metadata$bd_mrpf_group;
  Maybe#(Bit#(1)) multicast_metadata$ipv4_multicast_enabled;
  Maybe#(Bit#(1)) multicast_metadata$mld_snooping_enabled;
  Maybe#(Bit#(16)) acl_metadata$bd_label;
  Maybe#(Bit#(10)) l2_metadata$stp_group;
  Maybe#(Bit#(16)) l3_metadata$vrf;
  Maybe#(Bit#(1)) ipv6_metadata$ipv6_unicast_enabled;
  Maybe#(Bit#(1)) l2_metadata$learning_enabled;
  Maybe#(Bit#(16)) ingress_metadata$outer_bd;
  Maybe#(Bit#(16)) multicast_metadata$ipv6_mcast_key;
  Maybe#(Bit#(1)) multicast_metadata$ipv4_mcast_key_type;
  Maybe#(Bit#(1)) multicast_metadata$ipv6_mcast_key_type;
  Maybe#(Bit#(1)) multicast_metadata$ipv6_multicast_enabled;
  Maybe#(Bit#(16)) l2_metadata$bd_stats_idx;
  Maybe#(Bit#(1)) ipv4_metadata$ipv4_unicast_enabled;
  Maybe#(Bit#(1)) runtime_ipv4_multicast_enabled_1;
  Maybe#(Bit#(1)) runtime_igmp_snooping_enabled_1;
  Maybe#(Bit#(16)) runtime_ipv6_mcast_key_16;
  Maybe#(Bit#(16)) runtime_mrpf_group_16;
  Maybe#(Bit#(1)) runtime_ipv4_mcast_key_type_1;
  Maybe#(Bit#(1)) runtime_mld_snooping_enabled_1;
  Maybe#(Bit#(1)) runtime_ipv6_multicast_enabled_1;
  Maybe#(Bit#(16)) runtime_stats_idx_16;
  Maybe#(Bit#(2)) runtime_ipv6_urpf_mode_2;
  Maybe#(Bit#(2)) runtime_ipv4_urpf_mode_2;
  Maybe#(Bit#(16)) runtime_ipv4_mcast_key_16;
  Maybe#(Bit#(16)) runtime_vrf_16;
  Maybe#(Bit#(1)) runtime_learning_enabled_1;
  Maybe#(Bit#(1)) runtime_ipv6_unicast_enabled_1;
  Maybe#(Bit#(16)) runtime_bd_label_16;
  Maybe#(Bit#(1)) runtime_ipv6_mcast_key_type_1;
  Maybe#(Bit#(10)) runtime_rmac_group_10;
  Maybe#(Bit#(1)) runtime_ipv4_unicast_enabled_1;
  Maybe#(Bit#(10)) runtime_stp_group_10;
  Maybe#(Bit#(3)) l2_metadata$lkp_pkt_type;
  Maybe#(Bit#(9)) standard_metadata$ingress_port;
  Maybe#(Bit#(1)) intrinsic_metadata$deflect_on_drop;
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(16)) l2_metadata$same_if_check;
  Maybe#(Bit#(1)) runtime_enable_dod_1;
  Maybe#(Bit#(16)) runtime_nhop_index_16;
  Maybe#(Bit#(1)) runtime_tunnel_1;
  Maybe#(Bit#(16)) runtime_uuc_mc_index_16;
  Maybe#(Bit#(9)) egress_metadata$smac_idx;
  Maybe#(Bit#(9)) runtime_smac_idx_9;
  Maybe#(Bit#(12)) vlan_tag_1$vid;
  Maybe#(Bit#(12)) vlan_tag_0$vid;
  Maybe#(Bit#(12)) runtime_c_tag_12;
  Maybe#(Bit#(12)) runtime_s_tag_12;
  Maybe#(Bit#(12)) runtime_vlan_id_12;
  Maybe#(Bit#(24)) runtime_vnid_24;
  Maybe#(Bit#(9)) runtime_port_9;
  Maybe#(Bit#(2)) ingress_metadata$port_type;
  Maybe#(Bit#(2)) runtime_port_type_2;
  Maybe#(Bit#(16)) acl_metadata$if_label;
  Maybe#(Bit#(16)) runtime_if_label_16;
  Maybe#(Bit#(16)) egress_metadata$outer_bd;
  Maybe#(Bit#(8)) l3_metadata$mtu_index;
  Maybe#(Bit#(8)) runtime_mtu_index_8;
  Maybe#(Bit#(8)) runtime_device_8;
  Maybe#(Bit#(16)) runtime_port_16;
  Maybe#(Bit#(16)) runtime_nhop_idx_16;
  Maybe#(Bit#(9)) tunnel_metadata$tunnel_smac_index;
  Maybe#(Bit#(3)) mpls0$exp;
  Maybe#(Bit#(1)) mpls0$bos;
  Maybe#(Bit#(14)) tunnel_metadata$tunnel_dmac_index;
  Maybe#(Bit#(20)) mpls0$label;
  Maybe#(Bit#(8)) runtime_ttl1_8;
  Maybe#(Bit#(3)) runtime_exp1_3;
  Maybe#(Bit#(20)) runtime_label1_20;
  Maybe#(Bit#(14)) runtime_dmac_idx_14;
  Maybe#(Bit#(8)) mpls1$ttl;
  Maybe#(Bit#(3)) mpls1$exp;
  Maybe#(Bit#(20)) mpls1$label;
  Maybe#(Bit#(1)) mpls1$bos;
  Maybe#(Bit#(8)) runtime_ttl2_8;
  Maybe#(Bit#(20)) runtime_label2_20;
  Maybe#(Bit#(3)) runtime_exp2_3;
  Maybe#(Bit#(1)) mpls2$bos;
  Maybe#(Bit#(3)) mpls2$exp;
  Maybe#(Bit#(8)) mpls2$ttl;
  Maybe#(Bit#(20)) mpls2$label;
  Maybe#(Bit#(3)) runtime_exp3_3;
  Maybe#(Bit#(20)) runtime_label3_20;
  Maybe#(Bit#(8)) runtime_ttl3_8;
  Maybe#(Bit#(20)) runtime_label_20;
  Maybe#(Bit#(1)) ipv6_metadata$ipv6_src_is_link_local;
  Maybe#(Bit#(16)) l3_metadata$same_bd_check;
  Maybe#(Bit#(32)) runtime_meter_idx_32;
  Maybe#(Bit#(3)) l2_metadata$stp_state;
  Maybe#(Bit#(3)) runtime_stp_state_3;
  Maybe#(Bit#(9)) tunnel_metadata$tunnel_src_index;
  Maybe#(Bit#(14)) tunnel_metadata$tunnel_dst_index;
  Maybe#(Bit#(16)) runtime_outer_bd_16;
  Maybe#(Bit#(9)) runtime_sip_index_9;
  Maybe#(Bit#(14)) runtime_dip_index_14;
  Maybe#(Bit#(24)) tunnel_metadata$tunnel_vni;
  Maybe#(Bit#(24)) runtime_tunnel_vni_24;
  Maybe#(Bit#(20)) tunnel_metadata$mpls_label;
  Maybe#(Bit#(3)) tunnel_metadata$mpls_exp;
  Maybe#(Bit#(8)) ipv4$diffserv;
  Maybe#(Bit#(8)) l3_metadata$lkp_ip_tc;
  Maybe#(Bit#(2)) l3_metadata$lkp_ip_type;
  Maybe#(Bit#(4)) l3_metadata$lkp_ip_version;
  Maybe#(Bit#(32)) runtime_sflow_i2e_mirror_id_32;
  Maybe#(Bit#(16)) sflow_metadata$sflow_session_id;
  Maybe#(Bit#(32)) runtime_rate_thr_32;
  Maybe#(Bit#(16)) runtime_session_id_16;
  Maybe#(Bit#(16)) fabric_header_sflow$sflow_session_id;
  Maybe#(Bit#(1)) l2_metadata$l2_src_miss;
  Maybe#(Bit#(1)) fabric_metadata$fabric_header_present;
  Maybe#(Bit#(1)) fabric_header_cpu$txBypass;
  Maybe#(Bit#(1)) egress_metadata$bypass;
  Maybe#(Bit#(16)) inner_ethernet$etherType;
  Maybe#(Bit#(8)) inner_ipv4$diffserv;
  Maybe#(Bit#(4)) inner_ipv4$version;
  Maybe#(Bit#(4)) inner_ipv6$version;
  Maybe#(Bit#(8)) inner_ipv6$trafficClass;
  Maybe#(Bit#(8)) qos_metadata$outer_dscp;
  Maybe#(Bit#(128)) inner_ipv6$dstAddr;
  Maybe#(Bit#(128)) inner_ipv6$srcAddr;
  Maybe#(Bit#(1)) l3_metadata$urpf_check_fail;
  Maybe#(Bit#(16)) multicast_metadata$mcast_rpf_group;
  //Maybe#(Bit#(None)) vxlan_gpe_int_header;
  //Maybe#(Bit#(None)) ipv4;
  //Maybe#(Bit#(None)) int_header;
  //Maybe#(Bit#(None)) inner_ipv4;
  Maybe#(Bit#(32)) inner_ipv4$dstAddr;
  Maybe#(Bit#(32)) inner_ipv4$srcAddr;
  Maybe#(Bit#(8)) tcp$flags;
  Maybe#(Bit#(16)) l2_metadata$l2_src_move;
  Maybe#(Bit#(2)) meter_metadata$meter_color;
  //Maybe#(Bit#(None)) inner_ipv6;
  //Maybe#(Bit#(None)) ipv6;
  //Maybe#(Bit#(None)) vlan_tag_0;
  //Maybe#(Bit#(None)) vlan_tag_1;
  Maybe#(Bit#(32)) ingress_metadata$sflow_take_sample;
  //Maybe#(Bit#(None)) sflow;
  Maybe#(Bit#(1)) security_metadata$storm_control_color;
  Maybe#(Bit#(1)) tunnel_metadata$tunnel_if_check;
  Maybe#(Bit#(1)) ingress_metadata$control_frame;
  //Maybe#(Bit#(None)) mpls0;
  //Maybe#(Bit#(None)) mpls1;
  //Maybe#(Bit#(None)) mpls2;
  Maybe#(Bit#(1)) intrinsic_metadata$deflection_flag;
  //Maybe#(Bit#(None)) vxlan_gpe;
  Maybe#(Bit#(16)) egress_metadata$same_bd_check;
  Maybe#(Bit#(16)) intrinsic_metadata$egress_rid;
  //Maybe#(Bit#(None)) inner_tcp;
  //Maybe#(Bit#(None)) inner_udp;
  //Maybe#(Bit#(None)) inner_icmp;
  //Maybe#(Bit#(None)) tcp;
  //Maybe#(Bit#(None)) udp;
  //Maybe#(Bit#(None)) icmp;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
  defaultValue = unpack(0);
endinstance
