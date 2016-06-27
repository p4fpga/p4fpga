
import BuildVector::*;
import ClientServer::*;
import Connectable::*;
import DbgDefs::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import MatchTable::*;
import MatchTableSim::*;
import PacketBuffer::*;
import Pipe::*;
import Register::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;
import MainDefs::*;

typedef struct {
  Bit#(9) ingress_port;
  Bit#(32) packet_length;
  Bit#(9) egress_spec;
  Bit#(9) egress_port;
  Bit#(32) egress_instance;
  Bit#(32) instance_type;
  Bit#(32) clone_spec;
  Bit#(5) _padding;
} StandardMetadataT deriving (Bits, Eq);
instance DefaultValue#(StandardMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(StandardMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function StandardMetadataT extract_standard_metadata_t(Bit#(160) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(48) dstAddr;
  Bit#(48) srcAddr;
  Bit#(16) etherType;
} EthernetT deriving (Bits, Eq);
instance DefaultValue#(EthernetT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(EthernetT);
  defaultMask = unpack(maxBound);
endinstance
function EthernetT extract_ethernet_t(Bit#(112) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(4) version;
  Bit#(4) ihl;
  Bit#(8) diffserv;
  Bit#(16) totalLen;
  Bit#(16) identification;
  Bit#(3) flags;
  Bit#(13) fragOffset;
  Bit#(8) ttl;
  Bit#(8) protocol;
  Bit#(16) hdrChecksum;
  Bit#(32) srcAddr;
  Bit#(32) dstAddr;
} Ipv4T deriving (Bits, Eq);
instance DefaultValue#(Ipv4T);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Ipv4T);
  defaultMask = unpack(maxBound);
endinstance
function Ipv4T extract_ipv4_t(Bit#(160) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) hrd;
  Bit#(16) pro;
  Bit#(8) hln;
  Bit#(8) pln;
  Bit#(16) op;
  Bit#(48) sha;
  Bit#(32) spa;
  Bit#(48) tha;
  Bit#(32) tpa;
} ArpT deriving (Bits, Eq);
instance DefaultValue#(ArpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(ArpT);
  defaultMask = unpack(maxBound);
endinstance
function ArpT extract_arp_t(Bit#(224) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(8) icmptype;
  Bit#(8) code;
  Bit#(16) checksum;
  Bit#(32) quench;
} IcmpT deriving (Bits, Eq);
instance DefaultValue#(IcmpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IcmpT);
  defaultMask = unpack(maxBound);
endinstance
function IcmpT extract_icmp_t(Bit#(64) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) srcPort;
  Bit#(16) dstPort;
  Bit#(16) length_;
  Bit#(16) checksum;
} UdpT deriving (Bits, Eq);
instance DefaultValue#(UdpT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(UdpT);
  defaultMask = unpack(maxBound);
endinstance
function UdpT extract_udp_t(Bit#(64) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) msgtype;
  Bit#(32) inst;
} PaxosT deriving (Bits, Eq);
instance DefaultValue#(PaxosT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(PaxosT);
  defaultMask = unpack(maxBound);
endinstance
function PaxosT extract_paxos_t(Bit#(48) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) ballot;
} Phase1AT deriving (Bits, Eq);
instance DefaultValue#(Phase1AT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase1AT);
  defaultMask = unpack(maxBound);
endinstance
function Phase1AT extract_phase1a_t(Bit#(16) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) ballot;
  Bit#(16) vballot;
  Bit#(256) paxosval;
  Bit#(16) acptid;
} Phase1BT deriving (Bits, Eq);
instance DefaultValue#(Phase1BT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase1BT);
  defaultMask = unpack(maxBound);
endinstance
function Phase1BT extract_phase1b_t(Bit#(304) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) ballot;
  Bit#(256) paxosval;
} Phase2AT deriving (Bits, Eq);
instance DefaultValue#(Phase2AT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase2AT);
  defaultMask = unpack(maxBound);
endinstance
function Phase2AT extract_phase2a_t(Bit#(272) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) ballot;
  Bit#(256) paxosval;
  Bit#(16) acptid;
} Phase2BT deriving (Bits, Eq);
instance DefaultValue#(Phase2BT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(Phase2BT);
  defaultMask = unpack(maxBound);
endinstance
function Phase2BT extract_phase2b_t(Bit#(288) data);
  return unpack(data);
endfunction


typedef struct {
  Bit#(16) ballot;
} LocalMetadataT deriving (Bits, Eq);
instance DefaultValue#(LocalMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(LocalMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function LocalMetadataT extract_local_metadata_t(Bit#(16) data);
  return unpack(data);
endfunction


typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataRequest deriving (Bits, Eq);
typedef struct {
  PacketInstance pkt;
  MetadataT meta;
} MetadataResponse deriving (Bits, Eq);
typedef struct {
  Maybe#(Bit#(9)) standard_metadata$egress_spec;
  Maybe#(Bit#(9)) runtime_port;
  Maybe#(Bit#(32)) paxos$inst;
  Maybe#(Bit#(16)) paxos1a$ballot;
  Maybe#(Bit#(16)) paxos1b$vballot;
  Maybe#(Bit#(16)) paxos1b$ballot;
  Maybe#(Bit#(16)) udp$checksum;
  Maybe#(Bit#(256)) paxos1b$paxosval;
  Maybe#(Bit#(16)) paxos1b$acptid;
  Maybe#(Bit#(256)) paxos2a$paxosval;
  Maybe#(Bit#(16)) paxos2a$ballot;
  Maybe#(Bit#(16)) paxos2b$ballot;
  Maybe#(Bit#(16)) paxos2b$acptid;
  Maybe#(Bit#(256)) paxos2b$paxosval;
  Maybe#(Bit#(16)) paxos_ballot$ballot;
  Maybe#(Bit#(9)) standard_metadata$ingress_port;
  Maybe#(Bit#(32)) ipv4$dstAddr;
  Maybe#(Bit#(16)) ethernet$etherType;
  Maybe#(Bool) valid_ipv4;
  Maybe#(Bool) valid_paxos;
  Maybe#(Bool) valid_paxos1a;
  Maybe#(Bool) valid_paxos2a;
} MetadataT deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
    Bit#(16) paxos1a$ballot;
  } HandlePhase1AReqT;
  struct {
    PacketInstance pkt;
    Bit#(256) paxos2a$paxosval;
    Bit#(16) paxos2a$ballot;
    Bit#(32) paxos$inst;
  } HandlePhase2AReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
  } ReadBallotReqT;
  struct {
    PacketInstance pkt;
  } DropReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos1b$vballot;
    Bit#(16) paxos1b$ballot;
    Bit#(16) udp$checksum;
    Bit#(256) paxos1b$paxosval;
    Bit#(16) paxos1b$acptid;
  } HandlePhase1ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos2b$ballot;
    Bit#(16) udp$checksum;
    Bit#(16) paxos2b$acptid;
    Bit#(256) paxos2b$paxosval;
  } HandlePhase2ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos_ballot$ballot;
  } ReadBallotRspT;
  struct {
    PacketInstance pkt;
  } DropRspT;
} BBResponse deriving (Bits, Eq);
interface Forward;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkForward(Forward);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(9)) standard_metadata$egress_spec <- mkReg(0);
  rule forward_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ForwardReqT {pkt: .pkt, runtime_port: .runtime_port}: begin
        curr_packet_ff.enq(pkt);
        standard_metadata$egress_spec <= runtime_port;
      end
    endcase
  endrule

  rule forward_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ForwardRspT {pkt: pkt, standard_metadata$egress_spec: standard_metadata$egress_spec};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface HandlePhase1A;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) vballots_register;
  interface Client#(RegRequest#(10, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) acceptor_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandlePhase1A(HandlePhase1A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  TX #(RegRequest#(10, 16)) tx_vballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_vballots_register <- mkRX;
  let tx_info_vballots_register = tx_vballots_register.u;
  let rx_info_vballots_register = rx_vballots_register.u;
  TX #(RegRequest#(10, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_acceptor_id <- mkTX;
  RX #(RegResponse#(16)) rx_acceptor_id <- mkRX;
  let tx_info_acceptor_id = tx_acceptor_id.u;
  let rx_info_acceptor_id = rx_acceptor_id.u;

  Reg#(Bit#(16)) rg_ballot <- mkReg(0);
  rule handle_phase1a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged HandlePhase1AReqT {pkt: .pkt, paxos$inst: .paxos$inst, paxos1a$ballot: .paxos1a$ballot}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos1a$ballot, write: True };
        tx_info_ballots_register.enq(ballots_register_req);
        let vballots_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_vballots_register.enq(vballots_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_values_register.enq(values_register_req);
        let acceptor_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_acceptor_id.enq(acceptor_id_req);
        rg_ballot <= paxos1a$ballot;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_phase1a_response;
    let v_vballot = rx_info_vballots_register.first;
    rx_info_vballots_register.deq;
    let vballot = v_vballot.data;
    let v_paxosval = rx_info_values_register.first;
    rx_info_values_register.deq;
    let paxosval = v_paxosval.data;
    let v_acptid = rx_info_acceptor_id.first;
    rx_info_acceptor_id.deq;
    let acptid = v_acptid.data;
    let pkt <- toGet(curr_packet_ff).get;

    BBResponse rsp = tagged HandlePhase1ARspT {pkt: pkt, paxos1b$vballot: vballot, paxos1b$ballot: rg_ballot, udp$checksum: 0, paxos1b$paxosval: paxosval, paxos1b$acptid: acptid};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface vballots_register = toClient(tx_vballots_register.e, rx_vballots_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface acceptor_id = toClient(tx_acceptor_id.e, rx_acceptor_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface HandlePhase2A;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) vballots_register;
  interface Client#(RegRequest#(10, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) acceptor_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandlePhase2A(HandlePhase2A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  TX #(RegRequest#(10, 16)) tx_vballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_vballots_register <- mkRX;
  let tx_info_vballots_register = tx_vballots_register.u;
  let rx_info_vballots_register = rx_vballots_register.u;
  TX #(RegRequest#(10, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_acceptor_id <- mkTX;
  RX #(RegResponse#(16)) rx_acceptor_id <- mkRX;
  let tx_info_acceptor_id = tx_acceptor_id.u;
  let rx_info_acceptor_id = rx_acceptor_id.u;
  Reg#(Bit#(16)) rg_ballot <- mkReg(0);
  Reg#(Bit#(256)) rg_paxosval <- mkReg(0);
  rule handle_phase2a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged HandlePhase2AReqT {pkt: .pkt, paxos2a$paxosval: .paxos2a$paxosval, paxos2a$ballot: .paxos2a$ballot, paxos$inst: .paxos$inst}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$ballot, write: True };
        tx_info_ballots_register.enq(ballots_register_req);
        let vballots_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$ballot, write: True };
        tx_info_vballots_register.enq(vballots_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos2a$paxosval, write: True };
        tx_info_values_register.enq(values_register_req);
        let acceptor_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_acceptor_id.enq(acceptor_id_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_phase2a_response;
    let v_acptid = rx_info_acceptor_id.first;
    rx_info_acceptor_id.deq;
    let acptid = v_acptid.data;
    let pkt <- toGet(curr_packet_ff).get;

    BBResponse rsp = tagged HandlePhase2ARspT {pkt: pkt, paxos2b$ballot: rg_ballot, udp$checksum: 0, paxos2b$acptid: acptid, paxos2b$paxosval: rg_paxosval};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface vballots_register = toClient(tx_vballots_register.e, rx_vballots_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface acceptor_id = toClient(tx_acceptor_id.e, rx_acceptor_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface ReadBallot;
  interface Client#(RegRequest#(10, 16), RegResponse#(16)) ballots_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadBallot(ReadBallot);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(10, 16)) tx_ballots_register <- mkTX;
  RX #(RegResponse#(16)) rx_ballots_register <- mkRX;
  let tx_info_ballots_register = tx_ballots_register.u;
  let rx_info_ballots_register = rx_ballots_register.u;
  rule read_ballot_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadBallotReqT {pkt: .pkt, paxos$inst: .paxos$inst}: begin
        let ballots_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_ballots_register.enq(ballots_register_req);
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_ballot_response;
    let v_ballot = rx_info_ballots_register.first;
    rx_info_ballots_register.deq;
    let ballot = v_ballot.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadBallotRspT {pkt: pkt, paxos_ballot$ballot: ballot};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface ballots_register = toClient(tx_ballots_register.e, rx_ballots_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkDrop(Drop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule _drop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DropReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule _drop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged DropRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
typedef struct {
  Bit#(9) standard_metadata$ingress_port;
} FwdTblReqT deriving (Bits, Eq);
typedef struct {
  FwdTblActionT _action;
  Bit#(9) runtime_port;
} FwdTblRspT deriving (Bits, Eq);
interface FwdTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkFwdTbl(FwdTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(FwdTblReqT), SizeOf#(FwdTblRspT)) matchTable <- mkMatchTable();
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
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
    let standard_metadata$ingress_port = fromMaybe(?, meta.standard_metadata$ingress_port);
    FwdTblReqT req = FwdTblReqT {standard_metadata$ingress_port: standard_metadata$ingress_port};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      FwdTblRspT resp = unpack(data);
      case (resp._action) matches
        FORWARD: begin
          BBRequest req = tagged ForwardReqT {pkt: pkt, runtime_port: resp.runtime_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
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
      tagged ForwardRspT {pkt: .pkt, standard_metadata$egress_spec: .standard_metadata$egress_spec}: begin
        meta.standard_metadata$egress_spec = tagged Valid standard_metadata$egress_spec;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(9) padding;
} BallotTblReqT deriving (Bits, Eq);
typedef enum {
  READBALLOT
} BallotTblActionT deriving (Bits, Eq);
typedef struct {
  BallotTblActionT _action;
} BallotTblRspT deriving (Bits, Eq);
interface BallotTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkBallotTbl(BallotTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkFIFOF;
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    BBRequest req = tagged ReadBallotReqT {pkt: pkt, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadBallotRspT {pkt: .pkt, paxos_ballot$ballot: .paxos_ballot$ballot}: begin
        meta.paxos_ballot$ballot = tagged Valid paxos_ballot$ballot;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(9) padding;
} DropTblReqT deriving (Bits, Eq);
typedef enum {
  DROP
} DropTblActionT deriving (Bits, Eq);
typedef struct {
  DropTblActionT _action;
} DropTblRspT deriving (Bits, Eq);
interface DropTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkDropTbl(DropTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkFIFOF;
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    BBRequest req = tagged DropReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(9) padding;
} Paxos1ATblReqT deriving (Bits, Eq);
typedef enum {
  HANDLEPHASE1A
} Paxos1ATblActionT deriving (Bits, Eq);
typedef struct {
  Paxos1ATblActionT _action;
} Paxos1ATblRspT deriving (Bits, Eq);
interface Paxos1ATbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkPaxos1ATbl(Paxos1ATbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkFIFOF;
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    let paxos1a$ballot = fromMaybe(?, meta.paxos1a$ballot);
    BBRequest req = tagged HandlePhase1AReqT {pkt: pkt, paxos$inst: paxos$inst, paxos1a$ballot: paxos1a$ballot};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged HandlePhase1ARspT {pkt: .pkt, paxos1b$vballot: .paxos1b$vballot, paxos1b$ballot: .paxos1b$ballot, udp$checksum: .udp$checksum, paxos1b$paxosval: .paxos1b$paxosval, paxos1b$acptid: .paxos1b$acptid}: begin
        meta.paxos1b$vballot = tagged Valid paxos1b$vballot;
        meta.paxos1b$ballot = tagged Valid paxos1b$ballot;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos1b$paxosval = tagged Valid paxos1b$paxosval;
        meta.paxos1b$acptid = tagged Valid paxos1b$acptid;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
typedef struct {
  Bit#(9) padding;
} Paxos2ATblReqT deriving (Bits, Eq);
typedef enum {
  HANDLEPHASE2A
} Paxos2ATblActionT deriving (Bits, Eq);
typedef struct {
  Paxos2ATblActionT _action;
} Paxos2ATblRspT deriving (Bits, Eq);
interface Paxos2ATbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkPaxos2ATbl(Paxos2ATbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkFIFOF;
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    let paxos2a$paxosval = fromMaybe(?, meta.paxos2a$paxosval);
    let paxos2a$ballot = fromMaybe(?, meta.paxos2a$ballot);
    let paxos$inst = fromMaybe(?, meta.paxos$inst);
    BBRequest req = tagged HandlePhase2AReqT {pkt: pkt, paxos2a$paxosval: paxos2a$paxosval, paxos2a$ballot: paxos2a$ballot, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged HandlePhase2ARspT {pkt: .pkt, paxos2b$ballot: .paxos2b$ballot, udp$checksum: .udp$checksum, paxos2b$acptid: .paxos2b$acptid, paxos2b$paxosval: .paxos2b$paxosval}: begin
        meta.paxos2b$ballot = tagged Valid paxos2b$ballot;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos2b$acptid = tagged Valid paxos2b$acptid;
        meta.paxos2b$paxosval = tagged Valid paxos2b$paxosval;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
interface Ingress;
  interface PipeOut#(MetadataRequest) eventPktSend;
  // FIXME
  method Action routingTable_add_entry(Bit#(32) dstAddr, FwdTblActionT act, Bit#(9) port_);
endinterface
module mkIngress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) fwd_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) fwd_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ballot_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) ballot_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) drop_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) paxos1a_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) paxos1a_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) paxos2a_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) paxos2a_tbl_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  FwdTbl fwd_tbl <- mkFwdTbl();
  BallotTbl ballot_tbl <- mkBallotTbl();
  DropTbl drop_tbl <- mkDropTbl();
  Paxos1ATbl paxos1a_tbl <- mkPaxos1ATbl();
  Paxos2ATbl paxos2a_tbl <- mkPaxos2ATbl();
  mkConnection(toClient(fwd_tbl_req_ff, fwd_tbl_rsp_ff), fwd_tbl.prev_control_state_0);
  mkConnection(toClient(ballot_tbl_req_ff, ballot_tbl_rsp_ff), ballot_tbl.prev_control_state_0);
  mkConnection(toClient(drop_tbl_req_ff, drop_tbl_rsp_ff), drop_tbl.prev_control_state_0);
  mkConnection(toClient(paxos1a_tbl_req_ff, paxos1a_tbl_rsp_ff), paxos1a_tbl.prev_control_state_0);
  mkConnection(toClient(paxos2a_tbl_req_ff, paxos2a_tbl_rsp_ff), paxos2a_tbl.prev_control_state_0);
  // Basic Blocks
  Forward forward <- mkForward();
  ReadBallot read_ballot <- mkReadBallot();
  Drop _drop <- mkDrop();
  HandlePhase1A handle_phase1a <- mkHandlePhase1A();
  HandlePhase2A handle_phase2a <- mkHandlePhase2A();
  RegisterIfc#(1, 16) acceptor_id <- mkP4Register(vec(handle_phase1a.acceptor_id));
  RegisterIfc#(10, 16) ballots_register <- mkP4Register(vec(handle_phase1a.ballots_register));
  RegisterIfc#(10, 16) vballots_register <- mkP4Register(vec(handle_phase1a.vballots_register));
  RegisterIfc#(10, 256) values_register <- mkP4Register(vec(handle_phase1a.values_register));
  mkConnection(fwd_tbl.next_control_state_0, forward.prev_control_state);
  mkConnection(ballot_tbl.next_control_state_0, read_ballot.prev_control_state);
  mkConnection(drop_tbl.next_control_state_0, _drop.prev_control_state);
  mkConnection(paxos1a_tbl.next_control_state_0, handle_phase1a.prev_control_state);
  mkConnection(paxos2a_tbl.next_control_state_0, handle_phase2a.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_ipv4)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      fwd_tbl_req_ff.enq(req);
    end
  endrule

  rule fwd_tbl_next_state if (fwd_tbl_rsp_ff.notEmpty);
    fwd_tbl_rsp_ff.deq;
    let _req = fwd_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_paxos)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ballot_tbl_req_ff.enq(req);
    end
  endrule

  rule ballot_tbl_next_state if (ballot_tbl_rsp_ff.notEmpty);
    ballot_tbl_rsp_ff.deq;
    let _req = ballot_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let paxos_ballot$ballot = fromMaybe(?, meta.paxos_ballot$ballot);
    let paxos1a$ballot = fromMaybe(?, meta.paxos1a$ballot);
    let paxos2a$ballot = fromMaybe(?, meta.paxos2a$ballot);
    if (isValid(meta.valid_paxos1a)) begin
      if (( paxos_ballot$ballot <= paxos1a$ballot )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        paxos1a_tbl_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        drop_tbl_req_ff.enq(req);
      end
    end
    else begin
      if (isValid(meta.valid_paxos2a)) begin
        if (( paxos_ballot$ballot <= paxos2a$ballot )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          paxos2a_tbl_req_ff.enq(req);
        end
      end
    end
  endrule

  rule drop_tbl_next_state if (drop_tbl_rsp_ff.notEmpty);
    drop_tbl_rsp_ff.deq;
    let _req = drop_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule paxos1a_tbl_next_state if (paxos1a_tbl_rsp_ff.notEmpty);
    paxos1a_tbl_rsp_ff.deq;
    let _req = paxos1a_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule paxos2a_tbl_next_state if (paxos2a_tbl_rsp_ff.notEmpty);
    paxos2a_tbl_rsp_ff.deq;
    let _req = paxos2a_tbl_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

endmodule
interface Egress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkEgress#(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc)(Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest request = MetadataRequest {pkt: pkt, meta: meta};
  endrule

endmodule
// Copyright (c) 2016 Cornell University

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
