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
import Ethernet::*;
import StructDefines::*;
