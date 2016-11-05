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
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table1ReqT deriving (Bits, FShow);
instance DefaultValue#(Table1ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table1RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table2ReqT deriving (Bits, FShow);
instance DefaultValue#(Table2ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table2RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table3ReqT deriving (Bits, FShow);
instance DefaultValue#(Table3ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table3RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table4ReqT deriving (Bits, FShow);
instance DefaultValue#(Table4ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table4RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table5ReqT deriving (Bits, FShow);
instance DefaultValue#(Table5ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table5RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table6ReqT deriving (Bits, FShow);
instance DefaultValue#(Table6ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table6RspT deriving (Bits, FShow);
import DefaultValue::*;
typedef struct{
    Bit#(6) padding;
    Bit#(48) dstAddr;
} Table7ReqT deriving (Bits, FShow);
instance DefaultValue#(Table7ReqT);
    defaultValue = unpack(0);
endinstance
typedef struct {
    Bit#(1) _action;
    Bit#(9) _port;
} Table7RspT deriving (Bits, FShow);
