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
        Bit#(9) _port;
    } Forward1ReqT;
    struct {
        Bit#(0) unused;
    } NoAction2ReqT;
} Table1Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward2ReqT;
    struct {
        Bit#(0) unused;
    } NoAction3ReqT;
} Table2Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward3ReqT;
    struct {
        Bit#(0) unused;
    } NoAction4ReqT;
} Table3Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward4ReqT;
    struct {
        Bit#(0) unused;
    } NoAction5ReqT;
} Table4Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward5ReqT;
    struct {
        Bit#(0) unused;
    } NoAction6ReqT;
} Table5Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward6ReqT;
    struct {
        Bit#(0) unused;
    } NoAction7ReqT;
} Table6Param deriving (Bits, Eq, FShow);
typedef union tagged {
    struct {
        Bit#(9) _port;
    } Forward7ReqT;
    struct {
        Bit#(0) unused;
    } NoAction8ReqT;
} Table7Param deriving (Bits, Eq, FShow);
import Ethernet::*;
import StructDefines::*;
