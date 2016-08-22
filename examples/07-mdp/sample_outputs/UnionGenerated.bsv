import Ethernet::*;
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(32) mdp$msgSeqNum;
  } DedupReqT;
  struct {
    PacketInstance pkt;
  } DropReqT;
  struct {
    PacketInstance pkt;
  } ForwardReqT;
} BBRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(32) mdp$msgSeqNum;
  } DedupRspT;
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
  } ForwardRspT;
} BBResponse deriving (Bits, Eq, FShow);
