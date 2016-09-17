import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
        Bit#(48) dmac;
    } SetDmacReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop2ReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction3ReqT;
} ForwardActionReq deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } SetDmacRspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop2RspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction3RspT;
} ForwardActionRsp deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
        Bit#(32) nhop_ipv4;
        Bit#(9) port;
    } SetNhopReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop1ReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction4ReqT;
} Ipv4LpmActionReq deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } SetNhopRspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop1RspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction4RspT;
} Ipv4LpmActionRsp deriving (Bits, Eq, FShow);
import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
        Bit#(48) smac;
    } RewriteMacReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop3ReqT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction2ReqT;
} SendFrameActionReq deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } RewriteMacRspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } Drop3RspT;
    struct {
        PacketInstance pkt;
        MetadataT meta;
    } NoAction2RspT;
} SendFrameActionRsp deriving (Bits, Eq, FShow);
