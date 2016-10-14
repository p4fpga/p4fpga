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
typedef struct {
    Bit#(2) _action;
    Bit#(32) nhop_ipv4;
    Bit#(9) port;
} Ipv4LpmRspT deriving (Bits, FShow);
typedef struct{
    Bit#(2) padding;
    Bit#(16) op_cnt;
} TOptiUpdateReqT deriving (Bits, FShow);
typedef struct {
    Bit#(4) _action;
} TOptiUpdateRspT deriving (Bits, FShow);
typedef struct{
    Bit#(8) padding;
    Bit#(1) has_invalid_read;
} TReplyClientReqT deriving (Bits, FShow);
typedef struct {
    Bit#(2) _action;
} TReplyClientRspT deriving (Bits, FShow);
typedef struct{
    Bit#(2) padding;
    Bit#(16) op_cnt;
} TReqFixReqT deriving (Bits, FShow);
typedef struct {
    Bit#(4) _action;
} TReqFixRspT deriving (Bits, FShow);
typedef struct{
    Bit#(2) padding;
    Bit#(16) op_cnt;
} TReqPass1ReqT deriving (Bits, FShow);
typedef struct {
    Bit#(4) _action;
    Bit#(1) read_cache_mode;
} TReqPass1RspT deriving (Bits, FShow);
typedef struct{
    Bit#(2) padding;
    Bit#(16) op_cnt;
} TStoreUpdateReqT deriving (Bits, FShow);
typedef struct {
    Bit#(4) _action;
} TStoreUpdateRspT deriving (Bits, FShow);
typedef struct{
    Bit#(9) egress_port;
} SendFrameReqT deriving (Bits, FShow);
typedef struct {
    Bit#(2) _action;
    Bit#(48) smac;
} SendFrameRspT deriving (Bits, FShow);
