import DefaultValue::*;
typedef struct{
    Bit#(4) padding;
    Bit#(32) nhop_ipv4;
} ForwardReqT deriving (Bits, FShow);
typedef struct {
    Bit#(2) _action;
    Bit#(48) dmac;
} ForwardRspT deriving (Bits, FShow);
typedef struct{
    Bit#(4) padding;
    Bit#(32) dstAddr;
} Ipv4LpmReqT deriving (Bits, FShow);
instance DefaultValue#(Ipv4LpmReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(2) _action;
    Bit#(9) _port;
    Bit#(32) nhop_ipv4;
} Ipv4LpmRspT deriving (Bits, FShow);
typedef struct{
    Bit#(9) egress_port;
} SendFrameReqT deriving (Bits, FShow);
typedef struct {
    Bit#(2) _action;
    Bit#(48) smac;
} SendFrameRspT deriving (Bits, FShow);
