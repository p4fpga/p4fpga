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
} Header19T deriving (Bits, Eq, FShow);
function Header19T extract_header_19_t(Bit#(16) data);
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
} Header20T deriving (Bits, Eq, FShow);
function Header20T extract_header_20_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header21T deriving (Bits, Eq, FShow);
function Header21T extract_header_21_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header22T deriving (Bits, Eq, FShow);
function Header22T extract_header_22_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header23T deriving (Bits, Eq, FShow);
function Header23T extract_header_23_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header24T deriving (Bits, Eq, FShow);
function Header24T extract_header_24_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header25T deriving (Bits, Eq, FShow);
function Header25T extract_header_25_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header26T deriving (Bits, Eq, FShow);
function Header26T extract_header_26_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header27T deriving (Bits, Eq, FShow);
function Header27T extract_header_27_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header28T deriving (Bits, Eq, FShow);
function Header28T extract_header_28_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header29T deriving (Bits, Eq, FShow);
function Header29T extract_header_29_t(Bit#(16) data);
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
} Header30T deriving (Bits, Eq, FShow);
function Header30T extract_header_30_t(Bit#(16) data);
    return unpack(byteSwap(data));
endfunction
typedef struct {
    Bit#(16) field_0;
} Header31T deriving (Bits, Eq, FShow);
function Header31T extract_header_31_t(Bit#(16) data);
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
    Bit#(4) transportSpecific;
    Bit#(4) messageType;
    Bit#(4) reserved;
    Bit#(4) versionPTP;
    Bit#(16) messageLength;
    Bit#(8) domainNumber;
    Bit#(8) reserved2;
    Bit#(16) flags;
    Bit#(64) correction;
    Bit#(32) reserved3;
    Vector#(1, Bit#(64)) sourcePortIdentity;
    Bit#(16) sourcePortIdentity_;
    Bit#(16) sequenceId;
    Bit#(8) ptpControl;
    Bit#(8) logMessagePeriod;
    Vector#(1, Bit#(64)) originTimestamp;
    Bit#(16) originTimestamp_;
} PtpT deriving (Bits, Eq, FShow);
function PtpT extract_ptp_t(Bit#(352) data);
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
    Maybe#(Header#(Header19T)) header_19;
    Maybe#(Header#(Header2T)) header_2;
    Maybe#(Header#(Header20T)) header_20;
    Maybe#(Header#(Header21T)) header_21;
    Maybe#(Header#(Header22T)) header_22;
    Maybe#(Header#(Header23T)) header_23;
    Maybe#(Header#(Header24T)) header_24;
    Maybe#(Header#(Header25T)) header_25;
    Maybe#(Header#(Header26T)) header_26;
    Maybe#(Header#(Header27T)) header_27;
    Maybe#(Header#(Header28T)) header_28;
    Maybe#(Header#(Header29T)) header_29;
    Maybe#(Header#(Header3T)) header_3;
    Maybe#(Header#(Header30T)) header_30;
    Maybe#(Header#(Header31T)) header_31;
    Maybe#(Header#(Header4T)) header_4;
    Maybe#(Header#(Header5T)) header_5;
    Maybe#(Header#(Header6T)) header_6;
    Maybe#(Header#(Header7T)) header_7;
    Maybe#(Header#(Header8T)) header_8;
    Maybe#(Header#(Header9T)) header_9;
    Maybe#(Header#(PtpT)) ptp;
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
