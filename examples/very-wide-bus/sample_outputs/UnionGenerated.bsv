import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        Bit#(48) dmac;
    } SetDmacReqT;
    struct {
    } DropReqT;
} ForwardActionReq deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(32) nhop_ipv4;
        Bit#(9) _port;
    } SetNhopReqT;
} Ipv4LpmActionReq deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(48) smac;
    } RewriteMacReqT;
} SendFrameActionReq deriving (Bits, Eq, FShow);
