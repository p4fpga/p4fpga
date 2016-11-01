typedef struct {
    Bit#(48) dstAddr;
    Bit#(48) srcAddr;
    Bit#(16) etherType;
} EthernetT deriving (Bits, Eq, FShow);
function EthernetT extract_ethernet_t(Bit#(112) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
    Bit#(16) field_1;
    Bit#(16) field_2;
    Bit#(16) field_3;
    Bit#(16) field_4;
    Bit#(16) field_5;
    Bit#(16) field_6;
    Bit#(16) field_7;
    Bit#(16) field_8;
    Bit#(16) field_9;
    Bit#(16) field_10;
    Bit#(16) field_11;
    Bit#(16) field_12;
    Bit#(16) field_13;
    Bit#(16) field_14;
    Bit#(16) field_15;
} Header0T deriving (Bits, Eq, FShow);
function Header0T extract_header_0_t(Bit#(256) data);
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
    Bit#(16) srcPort;
    Bit#(16) dstPort;
    Bit#(32) seqNo;
    Bit#(32) ackNo;
    Bit#(4) dataOffset;
    Bit#(3) res;
    Bit#(3) ecn;
    Bit#(6) ctrl;
    Bit#(16) window;
    Bit#(16) checksum;
    Bit#(16) urgentPtr;
} TcpT deriving (Bits, Eq, FShow);
function TcpT extract_tcp_t(Bit#(160) data);
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
    Maybe#(Header#(EthernetT)) ethernet;
    Maybe#(Header#(Header0T)) header_0;
    Maybe#(Header#(Ipv4T)) ipv4;
    Maybe#(Header#(TcpT)) tcp;
    Maybe#(Header#(UdpT)) udp;
} Headers deriving (Bits, Eq, FShow);
typedef struct {
    Maybe#(Bit#(48)) dstAddr;
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
