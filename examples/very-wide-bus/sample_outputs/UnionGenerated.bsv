import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        Bit#(48) dmac;
    } SetDmacReqT;
    struct {
        Bit#(0) unused;
    } Drop2ReqT;
    struct {
        Bit#(0) unused;
    } NoAction3ReqT;
} ForwardParam deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(32) nhop_ipv4;
        Bit#(9) _port;
    } SetNhopReqT;
    struct {
        Bit#(0) unused;
    } Drop1ReqT;
    struct {
        Bit#(0) unused;
    } NoAction4ReqT;
} Ipv4LpmParam deriving (Bits, Eq, FShow);
import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        Bit#(48) smac;
    } RewriteMacReqT;
    struct {
        Bit#(0) unused;
    } Drop3ReqT;
    struct {
        Bit#(0) unused;
    } NoAction2ReqT;
} SendFrameParam deriving (Bits, Eq, FShow);
