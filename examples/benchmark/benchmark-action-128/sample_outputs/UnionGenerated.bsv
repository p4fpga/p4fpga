import Ethernet::*;
import StructDefines::*;
typedef union tagged {
    struct {
        Bit#(9) _port;
    } ForwardReqT;
    struct {
        Bit#(0) unused;
    } DropReqT;
    struct {
        Bit#(0) unused;
    } NoAction1ReqT;
} ForwardTableParam deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(0) unused;
    } NopReqT;
    struct {
        Bit#(0) unused;
    } ModHeadersReqT;
    struct {
        Bit#(0) unused;
    } NoAction2ReqT;
} TestTblParam deriving (Bits, Eq, FShow);
import Ethernet::*;
import StructDefines::*;
