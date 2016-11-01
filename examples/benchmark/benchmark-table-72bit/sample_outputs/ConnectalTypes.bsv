import DefaultValue::*;
typedef struct{
    Bit#(24) padding;
    Bit#(48) dstAddr;
} ForwardTableReqT deriving (Bits, FShow);
instance DefaultValue#(ForwardTableReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(2) _action;
    Bit#(9) _port;
} ForwardTableRspT deriving (Bits, FShow);
typedef Bit#(0) TestTblReqT;
typedef struct {
    Bit#(1) _action;
} TestTblRspT deriving (Bits, FShow);
