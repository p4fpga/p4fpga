
import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import MIMO::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import PrintTrace::*;
import Register::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import StructGenerated::*;
import TxRx::*;
import Utils::*;
import Vector::*;
typedef union tagged {
  struct {
    PacketInstance pkt;
  } Ipv4PacketReqT;
  struct {
    PacketInstance pkt;
  } Ipv6PacketReqT;
  struct {
    PacketInstance pkt;
  } L2PacketReqT;
  struct {
    PacketInstance pkt;
  } MimPacketReqT;
  struct {
    PacketInstance pkt;
  } MplsPacketReqT;
  struct {
    PacketInstance pkt;
  } NopReqT;
  struct {
    PacketInstance pkt;
    Bit#(8) runtime_egress_port;
  } SetEgressPortReqT;
} BBRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } Ipv4PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } Ipv6PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } L2PacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } MimPacketRspT;
  struct {
    PacketInstance pkt;
    Bit#(4) ing_metadata$packet_type;
  } MplsPacketRspT;
  struct {
    PacketInstance pkt;
  } NopRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ing_metadata$egress_port;
  } SetEgressPortRspT;
} BBResponse deriving (Bits, Eq, FShow);

// ====== IPV4_PACKET ======

interface Ipv4Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIpv4Packet  (Ipv4Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule ipv4_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Ipv4PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule ipv4_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Ipv4PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== IPV6_PACKET ======

interface Ipv6Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIpv6Packet  (Ipv6Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule ipv6_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Ipv6PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h2;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule ipv6_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Ipv6PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== L2_PACKET ======

interface L2Packet;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkL2Packet  (L2Packet);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule l2_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged L2PacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule l2_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged L2PacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== MIM_PACKET ======

interface MimPacket;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkMimPacket  (MimPacket);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule mim_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged MimPacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h4;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mim_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged MimPacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== MPLS_PACKET ======

interface MplsPacket;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkMplsPacket  (MplsPacket);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(4)) ing_metadata$packet_type <- mkReg(0);
  rule mpls_packet_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged MplsPacketReqT {pkt: .pkt}: begin
        ing_metadata$packet_type <= 'h3;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule mpls_packet_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged MplsPacketRspT {pkt: pkt, ing_metadata$packet_type: ing_metadata$packet_type};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== NOP ======

interface Nop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkNop  (Nop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule nop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged NopReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule nop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged NopRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== SET_EGRESS_PORT ======

interface SetEgressPort;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkSetEgressPort  (SetEgressPort);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(8)) ing_metadata$egress_port <- mkReg(0);
  rule set_egress_port_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged SetEgressPortReqT {pkt: .pkt, runtime_egress_port: .runtime_egress_port}: begin
        ing_metadata$egress_port <= runtime_egress_port;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule set_egress_port_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged SetEgressPortRspT {pkt: pkt, ing_metadata$egress_port: ing_metadata$egress_port};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== L2_MATCH ======

typedef struct {
  Bit#(6) padding;
  Bit#(48) ethernet$srcAddr;
} L2MatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_L2_MATCH,
  NOP,
  SET_EGRESS_PORT
} L2MatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  L2MatchActionT _action;
  Bit#(8) runtime_egress_port;
} L2MatchRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_l2_match(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_l2_match(Bit#(54) msgtype, Bit#(10) data);
`endif
instance MatchTableSim#(3, 54, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(3) id, Bit#(54) key);
    actionvalue
      let v <- matchtable_read_l2_match(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(3) id, Bit#(54) key, Bit#(10) data);
    action
      matchtable_write_l2_match(key, data);
    endaction
  endfunction

endinstance
interface L2Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkL2Match  (L2Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(3, 256, SizeOf#(L2MatchReqT), SizeOf#(L2MatchRspT)) matchTable <- mkMatchTable("l2_match.dat");
  Vector#(2, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(2) readyChannel = -1;
  for (Integer i=1; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
  rule rl_handle_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    let ethernet$srcAddr = fromMaybe(?, meta.ethernet$srcAddr);
    L2MatchReqT req = L2MatchReqT {padding: 0, ethernet$srcAddr: ethernet$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      L2MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
      endcase
      // forward metadata to next stage.
      metadata_ff[1].enq(meta);
    end
  endrule

  rule rl_handle_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff[1]).get;
    case (v) matches
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged L2MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged L2MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== IPV4_MATCH ======

typedef struct {
  Bit#(4) padding;
  Bit#(32) ipv4$srcAddr;
} Ipv4MatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_IPV4_MATCH,
  NOP,
  SET_EGRESS_PORT
} Ipv4MatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  Ipv4MatchActionT _action;
  Bit#(8) runtime_egress_port;
} Ipv4MatchRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_ipv4_match(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_ipv4_match(Bit#(36) msgtype, Bit#(10) data);
`endif
instance MatchTableSim#(1, 36, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(1) id, Bit#(36) key);
    actionvalue
      let v <- matchtable_read_ipv4_match(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(1) id, Bit#(36) key, Bit#(10) data);
    action
      matchtable_write_ipv4_match(key, data);
    endaction
  endfunction

endinstance
interface Ipv4Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkIpv4Match  (Ipv4Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1, 256, SizeOf#(Ipv4MatchReqT), SizeOf#(Ipv4MatchRspT)) matchTable <- mkMatchTable("ipv4_match.dat");
  Vector#(2, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(2) readyChannel = -1;
  for (Integer i=1; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
  rule rl_handle_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    let ipv4$srcAddr = fromMaybe(?, meta.ipv4$srcAddr);
    Ipv4MatchReqT req = Ipv4MatchReqT {padding: 0, ipv4$srcAddr: ipv4$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv4MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
      endcase
      // forward metadata to next stage.
      metadata_ff[1].enq(meta);
    end
  endrule

  rule rl_handle_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff[1]).get;
    case (v) matches
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged Ipv4MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged Ipv4MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== ETHERTYPE_MATCH ======

typedef struct {
  Bit#(2) padding;
  Bit#(16) ethernet$etherType;
} EthertypeMatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_ETHERTYPE_MATCH,
  L2_PACKET,
  IPV4_PACKET,
  IPV6_PACKET,
  MPLS_PACKET,
  MIM_PACKET
} EthertypeMatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  EthertypeMatchActionT _action;
} EthertypeMatchRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(3)) matchtable_read_ethertype_match(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_ethertype_match(Bit#(18) msgtype, Bit#(3) data);
`endif
instance MatchTableSim#(0, 18, 3);
  function ActionValue#(Bit#(3)) matchtable_read(Bit#(0) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_ethertype_match(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(0) id, Bit#(18) key, Bit#(3) data);
    action
      matchtable_write_ethertype_match(key, data);
    endaction
  endfunction

endinstance
interface EthertypeMatch;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
  interface Client #(BBRequest, BBResponse) next_control_state_3;
  interface Client #(BBRequest, BBResponse) next_control_state_4;
endinterface
module mkEthertypeMatch  (EthertypeMatch);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(5, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(5, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(0, 256, SizeOf#(EthertypeMatchReqT), SizeOf#(EthertypeMatchRspT)) matchTable <- mkMatchTable("ethertype_match.dat");
  Vector#(5, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(5) readyChannel = -1;
  for (Integer i=4; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
  rule rl_handle_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    let ethernet$etherType = fromMaybe(?, meta.ethernet$etherType);
    EthertypeMatchReqT req = EthertypeMatchReqT {padding: 0, ethernet$etherType: ethernet$etherType};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      EthertypeMatchRspT resp = unpack(data);
      case (resp._action) matches
        L2_PACKET: begin
          BBRequest req = tagged L2PacketReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        IPV4_PACKET: begin
          BBRequest req = tagged Ipv4PacketReqT {pkt: pkt};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        IPV6_PACKET: begin
          BBRequest req = tagged Ipv6PacketReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
        end
        MPLS_PACKET: begin
          BBRequest req = tagged MplsPacketReqT {pkt: pkt};
          bbReqFifo[3].enq(req); //FIXME: replace with RXTX.
        end
        MIM_PACKET: begin
          BBRequest req = tagged MimPacketReqT {pkt: pkt};
          bbReqFifo[4].enq(req); //FIXME: replace with RXTX.
        end
      endcase
      // forward metadata to next stage.
      metadata_ff[1].enq(meta);
    end
  endrule

  rule rl_handle_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff[1]).get;
    case (v) matches
      tagged L2PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchL2PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv4PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchIpv4PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv6PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchIpv6PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MplsPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchMplsPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MimPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        MetadataResponse rsp = tagged EthertypeMatchMimPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
  interface next_control_state_3 = toClient(bbReqFifo[3], bbRspFifo[3]);
  interface next_control_state_4 = toClient(bbReqFifo[4], bbRspFifo[4]);
endmodule

// ====== IPV6_MATCH ======

typedef struct {
  Bit#(7) padding;
  Bit#(128) ipv6$srcAddr;
} Ipv6MatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_IPV6_MATCH,
  NOP,
  SET_EGRESS_PORT
} Ipv6MatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  Ipv6MatchActionT _action;
  Bit#(8) runtime_egress_port;
} Ipv6MatchRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_ipv6_match(Bit#(135) msgtype);
import "BDPI" function Action matchtable_write_ipv6_match(Bit#(135) msgtype, Bit#(10) data);
`endif
instance MatchTableSim#(2, 135, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(2) id, Bit#(135) key);
    actionvalue
      let v <- matchtable_read_ipv6_match(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(2) id, Bit#(135) key, Bit#(10) data);
    action
      matchtable_write_ipv6_match(key, data);
    endaction
  endfunction

endinstance
interface Ipv6Match;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkIpv6Match  (Ipv6Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(2, 256, SizeOf#(Ipv6MatchReqT), SizeOf#(Ipv6MatchRspT)) matchTable <- mkMatchTable("ipv6_match.dat");
  Vector#(2, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(2) readyChannel = -1;
  for (Integer i=1; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
  rule rl_handle_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    let ipv6$srcAddr = fromMaybe(?, meta.ipv6$srcAddr);
    Ipv6MatchReqT req = Ipv6MatchReqT {padding: 0, ipv6$srcAddr: ipv6$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv6MatchRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        SET_EGRESS_PORT: begin
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port: resp.runtime_egress_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
      endcase
      // forward metadata to next stage.
      metadata_ff[1].enq(meta);
    end
  endrule

  rule rl_handle_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff[1]).get;
    case (v) matches
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged Ipv6MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = tagged Ipv6MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ethertype_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ethertype_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ipv4_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv6_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ipv6_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) l2_match_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) l2_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  EthertypeMatch ethertype_match <- mkEthertypeMatch();
  Ipv4Match ipv4_match <- mkIpv4Match();
  Ipv6Match ipv6_match <- mkIpv6Match();
  L2Match l2_match <- mkL2Match();
  mkConnection(toClient(ethertype_match_req_ff, ethertype_match_rsp_ff), ethertype_match.prev_control_state_0);
  mkConnection(toClient(ipv4_match_req_ff, ipv4_match_rsp_ff), ipv4_match.prev_control_state_0);
  mkConnection(toClient(ipv6_match_req_ff, ipv6_match_rsp_ff), ipv6_match.prev_control_state_0);
  mkConnection(toClient(l2_match_req_ff, l2_match_rsp_ff), l2_match.prev_control_state_0);
  // Basic Blocks
  L2Packet l2_packet_0 <- mkL2Packet();
  Ipv4Packet ipv4_packet_0 <- mkIpv4Packet();
  Ipv6Packet ipv6_packet_0 <- mkIpv6Packet();
  MplsPacket mpls_packet_0 <- mkMplsPacket();
  MimPacket mim_packet_0 <- mkMimPacket();
  Nop nop_0 <- mkNop();
  SetEgressPort set_egress_port_0 <- mkSetEgressPort();
  Nop nop_1 <- mkNop();
  SetEgressPort set_egress_port_1 <- mkSetEgressPort();
  Nop nop_2 <- mkNop();
  SetEgressPort set_egress_port_2 <- mkSetEgressPort();
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_0, l2_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_1, ipv4_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_2, ipv6_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_3, mpls_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_4, mim_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_0, nop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_1, set_egress_port_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_0, nop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_1, set_egress_port_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_0, nop_2.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_1, set_egress_port_2.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    ethertype_match_req_ff.enq(req);
  endrule

  rule ethertype_match_next_state if (ethertype_match_rsp_ff.notEmpty);
    ethertype_match_rsp_ff.deq;
    let _rsp = ethertype_match_rsp_ff.first;
    case (_rsp) matches
      tagged EthertypeMatchL2PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv4PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv6PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMplsPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMimPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv4_match_next_state if (ipv4_match_rsp_ff.notEmpty);
    ipv4_match_rsp_ff.deq;
    let _rsp = ipv4_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv4MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv4MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv6_match_next_state if (ipv6_match_rsp_ff.notEmpty);
    ipv6_match_rsp_ff.deq;
    let _rsp = ipv6_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv6MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv6MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule l2_match_next_state if (l2_match_rsp_ff.notEmpty);
    l2_match_rsp_ff.deq;
    let _rsp = l2_match_rsp_ff.first;
    case (_rsp) matches
      tagged L2MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged L2MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule

// ====== EGRESS ======

interface Egress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- printTimedTraceM("egress nextreq", mkFIFOF);
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    next_req_ff.enq(req);
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule
// Copyright (c) 2016 P4FPGA Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
