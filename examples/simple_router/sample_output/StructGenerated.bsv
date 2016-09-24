import DefaultValue::*;
typedef struct {
    Bit#(48) dstAddr;
    Bit#(48) srcAddr;
    Bit#(16) etherType;
} EthernetT deriving (Bits, Eq);
function EthernetT extract_ethernet_t(Bit#(112) data);
    return unpack(byteSwap(data));
endfunction
import DefaultValue::*;
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
   Maybe#(void) ipv4;
   Maybe#(void) ethernet;
} Headers deriving (Bits, Eq, FShow);
instance DefaultValue#(Headers);
   defaultValue = unpack(0);
endinstance
typedef struct {
    Maybe#(Bit#(32)) dstAddr;
    Maybe#(Bit#(9)) egress_port;
    Maybe#(Bit#(32)) nhop_ipv4;
    Maybe#(Bit#(8)) ttl;
    Headers hdr;
    HeaderState ethernet;
    HeaderState ipv4;
} MetadataT deriving (Bits, Eq, FShow);
instance DefaultValue#(MetadataT);
    defaultValue = unpack(0);
endinstance
