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
} Header0T deriving (Bits, Eq, FShow);
function Header0T extract_header_0_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header1T deriving (Bits, Eq, FShow);
function Header1T extract_header_1_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header10T deriving (Bits, Eq, FShow);
function Header10T extract_header_10_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header11T deriving (Bits, Eq, FShow);
function Header11T extract_header_11_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header12T deriving (Bits, Eq, FShow);
function Header12T extract_header_12_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header13T deriving (Bits, Eq, FShow);
function Header13T extract_header_13_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header14T deriving (Bits, Eq, FShow);
function Header14T extract_header_14_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header15T deriving (Bits, Eq, FShow);
function Header15T extract_header_15_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header16T deriving (Bits, Eq, FShow);
function Header16T extract_header_16_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header17T deriving (Bits, Eq, FShow);
function Header17T extract_header_17_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header18T deriving (Bits, Eq, FShow);
function Header18T extract_header_18_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header2T deriving (Bits, Eq, FShow);
function Header2T extract_header_2_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header3T deriving (Bits, Eq, FShow);
function Header3T extract_header_3_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header4T deriving (Bits, Eq, FShow);
function Header4T extract_header_4_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header5T deriving (Bits, Eq, FShow);
function Header5T extract_header_5_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header6T deriving (Bits, Eq, FShow);
function Header6T extract_header_6_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header7T deriving (Bits, Eq, FShow);
function Header7T extract_header_7_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header8T deriving (Bits, Eq, FShow);
function Header8T extract_header_8_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header9T deriving (Bits, Eq, FShow);
function Header9T extract_header_9_t(Bit#(16) data);
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
    Maybe#(Header#(Header1T)) header_1;
    Maybe#(Header#(Header10T)) header_10;
    Maybe#(Header#(Header11T)) header_11;
    Maybe#(Header#(Header12T)) header_12;
    Maybe#(Header#(Header13T)) header_13;
    Maybe#(Header#(Header14T)) header_14;
    Maybe#(Header#(Header15T)) header_15;
    Maybe#(Header#(Header16T)) header_16;
    Maybe#(Header#(Header17T)) header_17;
    Maybe#(Header#(Header18T)) header_18;
    Maybe#(Header#(Header2T)) header_2;
    Maybe#(Header#(Header3T)) header_3;
    Maybe#(Header#(Header4T)) header_4;
    Maybe#(Header#(Header5T)) header_5;
    Maybe#(Header#(Header6T)) header_6;
    Maybe#(Header#(Header7T)) header_7;
    Maybe#(Header#(Header8T)) header_8;
    Maybe#(Header#(Header9T)) header_9;
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
