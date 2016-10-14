typedef struct {
    Bit#(48) dstAddr;
    Bit#(48) srcAddr;
    Bit#(16) etherType;
} EthernetT deriving (Bits, Eq, FShow);
function EthernetT extract_ethernet_t(Bit#(112) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(1) msg_type;
    Bit#(1) from_switch;
    Bit#(6) unused_flags;
    Bit#(32) cl_id;
    Bit#(32) req_id;
    Bit#(8) frag_seq;
    Bit#(8) frag_cnt;
    Bit#(8) status;
    Bit#(16) op_cnt;
} GotthardHdrT deriving (Bits, Eq, FShow);
function GotthardHdrT extract_gotthard_hdr_t(Bit#(112) data);
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
function Ipv4T extract_ipv4_t(Bit#(160) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(8) remaining_cnt;
} OpParseMetaT deriving (Bits, Eq, FShow);
function OpParseMetaT extract_op_parse_meta_t(Bit#(8) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) srcPort;
    Bit#(16) dstPort;
    Bit#(16) length_;
    Bit#(16) checksum;
} UdpT deriving (Bits, Eq, FShow);
function UdpT extract_udp_t(Bit#(64) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(8) op_type;
    Bit#(32) key;
    Vector#(16, Bit#(64)) value;
} GotthardOpT deriving (Bits, Eq, FShow);
function GotthardOpT extract_gotthard_op_t(Bit#(1064) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(4) mcast_grp;
    Bit#(4) egress_rid;
    Bit#(16) mcast_hash;
    Bit#(32) lf_field_list;
    Bit#(16) resubmit_flag;
} IntrinsicMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(IntrinsicMetadataT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(8) r_cnt;
    Bit#(8) w_cnt;
    Bit#(8) rb_cnt;
    Bit#(1) has_cache_miss;
    Bit#(1) has_invalid_read;
    Bit#(1) has_opti_invalid_read;
    Bit#(1) read_cache_mode;
    Bit#(32) tmp_ipv4_dstAddr;
    Bit#(16) tmp_udp_dstPort;
} ReqMetaT deriving (Bits, Eq, FShow);
instance DefaultValue#(ReqMetaT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(32) nhop_ipv4;
} RoutingMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(RoutingMetadataT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Maybe#(Header#(EthernetT)) ethernet;
    Maybe#(Header#(GotthardHdrT)) gotthard_hdr;
    Maybe#(Header#(Ipv4T)) ipv4;
    Maybe#(Header#(OpParseMetaT)) parse_meta;
    Maybe#(Header#(UdpT)) udp;
    Vector#(10, Maybe#(Header#(GotthardOpT))) gotthard_op;
} Headers deriving (Bits, Eq, FShow);
typedef struct {
    Maybe#(Bit#(1)) has_invalid_read;
    Maybe#(Bit#(32)) nhop_ipv4;
    Maybe#(Bit#(16)) op_cnt;
    Maybe#(Bit#(32)) dstAddr;
    Maybe#(Bit#(9)) egress_port;
    Maybe#(IntrinsicMetadataT) intrinsic_metadata;
    Maybe#(ReqMetaT) req_meta;
    Maybe#(RoutingMetadataT) routing_metadata;
} Metadata deriving (Bits, Eq, FShow);
instance DefaultValue#(Metadata);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Maybe#(Bit#(9)) ingress_port;
    Maybe#(Bit#(9)) egress_spec;
    Maybe#(Bit#(9)) egress_port;
    Maybe#(Bit#(32)) clone_spec;
    Maybe#(Bit#(32)) instance_type;
    Maybe#(Bit#(1)) drop;
    Maybe#(Bit#(16)) recirculate_port;
    Maybe#(Bit#(32)) packet_length;
} StandardMetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(StandardMetadataT);
    defaultValue = unpack(0);
endinstance
