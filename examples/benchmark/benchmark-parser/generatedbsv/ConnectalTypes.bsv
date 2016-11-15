import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} ForwardTableReqT deriving (Bits, FShow);
instance DefaultValue#(ForwardTableReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(2) _action;
    Bit#(9) _port;
} ForwardTableRspT deriving (Bits, FShow);
