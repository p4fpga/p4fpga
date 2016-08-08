import Ethernet::*;
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
    Bit#(48) runtime_smac_48;
  } RewriteMacReqT;
  struct {
    PacketInstance pkt;
    Bit#(48) runtime_dmac_48;
  } SetDmacReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port_9;
    Bit#(32) runtime_nhop_ipv4_32;
  } SetNhopReqT;
} BBRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
    Bit#(48) ethernet$srcAddr;
  } RewriteMacRspT;
  struct {
    PacketInstance pkt;
    Bit#(48) ethernet$dstAddr;
  } SetDmacRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ipv4$ttl;
    Bit#(9) standard_metadata$egress_port;
    Bit#(32) routing_metadata$nhop_ipv4;
  } SetNhopRspT;
} BBResponse deriving (Bits, Eq, FShow);
