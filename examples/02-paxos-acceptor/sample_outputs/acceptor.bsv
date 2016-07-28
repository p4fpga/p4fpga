
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
  } DropReqT;
  struct {
    PacketInstance pkt;
  } NopReqT;
  struct {
    PacketInstance pkt;
    Bit#(9) runtime_port;
  } ForwardReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$rnd;
    Bit#(32) paxos$inst;
    Bit#(16) runtime_learner_port;
  } Handle1AReqT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$rnd;
    Bit#(32) paxos$inst;
    Bit#(256) paxos$paxosval;
    Bit#(16) runtime_learner_port;
  } Handle2AReqT;
  struct {
    PacketInstance pkt;
    Bit#(32) paxos$inst;
  } ReadRoundReqT;
} BBRequest deriving (Bits, Eq, FShow);
typedef union tagged {
  struct {
    PacketInstance pkt;
  } DropRspT;
  struct {
    PacketInstance pkt;
  } NopRspT;
  struct {
    PacketInstance pkt;
    Bit#(9) standard_metadata$egress_spec;
  } ForwardRspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$msgtype;
    Bit#(16) udp$checksum;
    Bit#(16) paxos$acptid;
    Bit#(16) paxos$vrnd;
    Bit#(16) udp$dstPort;
    Bit#(256) paxos$paxosval;
  } Handle1ARspT;
  struct {
    PacketInstance pkt;
    Bit#(16) paxos$acptid;
    Bit#(16) paxos$msgtype;
    Bit#(16) udp$dstPort;
    Bit#(16) udp$checksum;
  } Handle2ARspT;
  struct {
    PacketInstance pkt;
    Bit#(1) local_metadata$set_drop;
    Bit#(16) local_metadata$round;
  } ReadRoundRspT;
} BBResponse deriving (Bits, Eq, FShow);

// ====== _DROP ======

interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkDrop  (Drop);
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

// ====== _NOP ======

interface Nop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkNop  (Nop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule _nop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged NopReqT {pkt: .pkt}: begin
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule _nop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged NopRspT {pkt: pkt};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== FORWARD ======

interface Forward;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkForward  (Forward);
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
        standard_metadata$egress_spec <= runtime_port;
        curr_packet_ff.enq(pkt);
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

// ====== HANDLE_1A ======

interface Handle1A;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) vrounds_register;
  interface Client#(RegRequest#(16, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) datapath_id;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandle1A  (Handle1A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_vrounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_vrounds_register <- mkRX;
  let tx_info_vrounds_register = tx_vrounds_register.u;
  let rx_info_vrounds_register = rx_vrounds_register.u;
  TX #(RegRequest#(16, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_datapath_id <- mkTX;
  RX #(RegResponse#(16)) rx_datapath_id <- mkRX;
  let tx_info_datapath_id = tx_datapath_id.u;
  let rx_info_datapath_id = rx_datapath_id.u;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  Reg#(Bit#(16)) rg_paxos$rnd <- mkReg(0);
  Reg#(Bit#(16)) paxos$msgtype <- mkReg(0);
  Reg#(Bit#(16)) udp$dstPort <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_1a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Handle1AReqT {pkt: .pkt, paxos$rnd: .paxos$rnd, paxos$inst: .paxos$inst, runtime_learner_port: .runtime_learner_port}: begin
        paxos$msgtype <= 'h1;
        let vrounds_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_vrounds_register.enq(vrounds_register_req);
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_values_register.enq(values_register_req);
        let datapath_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_datapath_id.enq(datapath_id_req);
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_rounds_register.enq(rounds_register_req);
        rg_paxos$rnd <= paxos$rnd;
        udp$dstPort <= runtime_learner_port;
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_1a_response;
    let v_paxos$vrnd = rx_info_vrounds_register.first;
    rx_info_vrounds_register.deq;
    let paxos$vrnd = v_paxos$vrnd.data;
    let v_paxos$paxosval = rx_info_values_register.first;
    rx_info_values_register.deq;
    let paxos$paxosval = v_paxos$paxosval.data;
    let v_paxos$acptid = rx_info_datapath_id.first;
    rx_info_datapath_id.deq;
    let paxos$acptid = v_paxos$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Handle1ARspT {pkt: pkt, paxos$msgtype: paxos$msgtype, udp$checksum: udp$checksum, paxos$acptid: paxos$acptid, paxos$vrnd: paxos$vrnd, udp$dstPort: udp$dstPort, paxos$paxosval: paxos$paxosval};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface vrounds_register = toClient(tx_vrounds_register.e, rx_vrounds_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface datapath_id = toClient(tx_datapath_id.e, rx_datapath_id.e);
  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== HANDLE_2A ======

interface Handle2A;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) vrounds_register;
  interface Client#(RegRequest#(16, 256), RegResponse#(256)) values_register;
  interface Client#(RegRequest#(1, 16), RegResponse#(16)) datapath_id;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkHandle2A  (Handle2A);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  TX #(RegRequest#(16, 16)) tx_vrounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_vrounds_register <- mkRX;
  let tx_info_vrounds_register = tx_vrounds_register.u;
  let rx_info_vrounds_register = rx_vrounds_register.u;
  TX #(RegRequest#(16, 256)) tx_values_register <- mkTX;
  RX #(RegResponse#(256)) rx_values_register <- mkRX;
  let tx_info_values_register = tx_values_register.u;
  let rx_info_values_register = rx_values_register.u;
  TX #(RegRequest#(1, 16)) tx_datapath_id <- mkTX;
  RX #(RegResponse#(16)) rx_datapath_id <- mkRX;
  let tx_info_datapath_id = tx_datapath_id.u;
  let rx_info_datapath_id = rx_datapath_id.u;
  Reg#(Bit#(256)) rg_paxos$paxosval <- mkReg(0);
  Reg#(Bit#(16)) rg_paxos$rnd <- mkReg(0);
  Reg#(Bit#(16)) paxos$msgtype <- mkReg(0);
  Reg#(Bit#(16)) udp$dstPort <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule handle_2a_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged Handle2AReqT {pkt: .pkt, paxos$rnd: .paxos$rnd, paxos$inst: .paxos$inst, paxos$paxosval: .paxos$paxosval, runtime_learner_port: .runtime_learner_port}: begin
        paxos$msgtype <= 'h3;
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_rounds_register.enq(rounds_register_req);
        rg_paxos$rnd <= paxos$rnd;
        let vrounds_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$rnd, write: True };
        tx_info_vrounds_register.enq(vrounds_register_req);
        rg_paxos$rnd <= paxos$rnd;
        let values_register_req = RegRequest { addr: truncate(paxos$inst), data: paxos$paxosval, write: True };
        tx_info_values_register.enq(values_register_req);
        rg_paxos$paxosval <= paxos$paxosval;
        let datapath_id_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_datapath_id.enq(datapath_id_req);
        udp$dstPort <= runtime_learner_port;
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule handle_2a_response;
    let v_paxos$acptid = rx_info_datapath_id.first;
    rx_info_datapath_id.deq;
    let paxos$acptid = v_paxos$acptid.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged Handle2ARspT {pkt: pkt, paxos$acptid: paxos$acptid, paxos$msgtype: paxos$msgtype, udp$dstPort: udp$dstPort, udp$checksum: udp$checksum};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface vrounds_register = toClient(tx_vrounds_register.e, rx_vrounds_register.e);
  interface values_register = toClient(tx_values_register.e, rx_values_register.e);
  interface datapath_id = toClient(tx_datapath_id.e, rx_datapath_id.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== READ_ROUND ======

interface ReadRound;
  interface Client#(RegRequest#(16, 16), RegResponse#(16)) rounds_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkReadRound  (ReadRound);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(16, 16)) tx_rounds_register <- mkTX;
  RX #(RegResponse#(16)) rx_rounds_register <- mkRX;
  let tx_info_rounds_register = tx_rounds_register.u;
  let rx_info_rounds_register = rx_rounds_register.u;
  Reg#(Bit#(1)) local_metadata$set_drop <- mkReg(0);
  rule read_round_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ReadRoundReqT {pkt: .pkt, paxos$inst: .paxos$inst}: begin
        let rounds_register_req = RegRequest { addr: truncate(paxos$inst), data: ?, write: False };
        tx_info_rounds_register.enq(rounds_register_req);
        local_metadata$set_drop <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule read_round_response;
    let v_local_metadata$round = rx_info_rounds_register.first;
    rx_info_rounds_register.deq;
    let local_metadata$round = v_local_metadata$round.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged ReadRoundRspT {pkt: pkt, local_metadata$set_drop: local_metadata$set_drop, local_metadata$round: local_metadata$round};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface rounds_register = toClient(tx_rounds_register.e, rx_rounds_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== FORWARD_TBL ======

typedef struct {
  Bit#(9) standard_metadata$ingress_port;
} ForwardTblReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_FORWARD_TBL,
  FORWARD,
  DROP
} ForwardTblActionT deriving (Bits, Eq, FShow);
typedef struct {
  ForwardTblActionT _action;
  Bit#(9) runtime_port;
} ForwardTblRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(11)) matchtable_read_forward_tbl(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_forward_tbl(Bit#(9) msgtype, Bit#(11) data);
`endif
instance MatchTableSim#(2, 9, 11);
  function ActionValue#(Bit#(11)) matchtable_read(Bit#(2) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_forward_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(2) id, Bit#(9) key, Bit#(11) data);
    action
      matchtable_write_forward_tbl(key, data);
    endaction
  endfunction

endinstance
interface ForwardTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkForwardTbl  (ForwardTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(2, 256, SizeOf#(ForwardTblReqT), SizeOf#(ForwardTblRspT)) matchTable <- mkMatchTable("forward_tbl.dat");
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
    let standard_metadata$ingress_port = fromMaybe(?, meta.standard_metadata$ingress_port);
    ForwardTblReqT req = ForwardTblReqT {standard_metadata$ingress_port: standard_metadata$ingress_port};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ForwardTblRspT resp = unpack(data);
      case (resp._action) matches
        FORWARD: begin
          BBRequest req = tagged ForwardReqT {pkt: pkt, runtime_port: resp.runtime_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
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
      tagged ForwardRspT {pkt: .pkt, standard_metadata$egress_spec: .standard_metadata$egress_spec}: begin
        meta.standard_metadata$egress_spec = tagged Valid standard_metadata$egress_spec;
        MetadataResponse rsp = tagged ForwardTblForwardRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged ForwardTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== ACCEPTOR_TBL ======

typedef struct {
  Bit#(2) padding;
  Bit#(16) paxos$msgtype;
} AcceptorTblReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_ACCEPTOR_TBL,
  HANDLE_1A,
  HANDLE_2A,
  DROP
} AcceptorTblActionT deriving (Bits, Eq, FShow);
typedef struct {
  AcceptorTblActionT _action;
  Bit#(16) runtime_learner_port;
  Bit#(16) runtime_learner_port;
} AcceptorTblRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(34)) matchtable_read_acceptor_tbl(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_acceptor_tbl(Bit#(18) msgtype, Bit#(34) data);
`endif
instance MatchTableSim#(1, 18, 34);
  function ActionValue#(Bit#(34)) matchtable_read(Bit#(1) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_acceptor_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(1) id, Bit#(18) key, Bit#(34) data);
    action
      matchtable_write_acceptor_tbl(key, data);
    endaction
  endfunction

endinstance
interface AcceptorTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
endinterface
module mkAcceptorTbl  (AcceptorTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(3, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(3, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1, 256, SizeOf#(AcceptorTblReqT), SizeOf#(AcceptorTblRspT)) matchTable <- mkMatchTable("acceptor_tbl.dat");
  Vector#(3, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(3) readyChannel = -1;
  for (Integer i=2; i>=0; i=i-1) begin
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
    let paxos$msgtype = fromMaybe(?, meta.paxos$msgtype);
    AcceptorTblReqT req = AcceptorTblReqT {paxos$msgtype: paxos$msgtype};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      AcceptorTblRspT resp = unpack(data);
      case (resp._action) matches
        HANDLE_1A: begin
          BBRequest req = tagged Handle1AReqT {pkt: pkt, paxos$rnd: paxos$rnd, paxos$inst: paxos$inst, runtime_learner_port: resp.runtime_learner_port};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        HANDLE_2A: begin
          BBRequest req = tagged Handle2AReqT {pkt: pkt, paxos$rnd: paxos$rnd, paxos$inst: paxos$inst, paxos$paxosval: paxos$paxosval, runtime_learner_port: resp.runtime_learner_port};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
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
      tagged Handle1ARspT {pkt: .pkt, paxos$msgtype: .paxos$msgtype, udp$checksum: .udp$checksum, paxos$acptid: .paxos$acptid, paxos$vrnd: .paxos$vrnd, udp$dstPort: .udp$dstPort, paxos$paxosval: .paxos$paxosval}: begin
        meta.paxos$msgtype = tagged Valid paxos$msgtype;
        meta.udp$checksum = tagged Valid udp$checksum;
        meta.paxos$acptid = tagged Valid paxos$acptid;
        meta.paxos$vrnd = tagged Valid paxos$vrnd;
        meta.udp$dstPort = tagged Valid udp$dstPort;
        meta.paxos$paxosval = tagged Valid paxos$paxosval;
        MetadataResponse rsp = tagged AcceptorTblHandle1ARspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Handle2ARspT {pkt: .pkt, paxos$acptid: .paxos$acptid, paxos$msgtype: .paxos$msgtype, udp$dstPort: .udp$dstPort, udp$checksum: .udp$checksum}: begin
        meta.paxos$acptid = tagged Valid paxos$acptid;
        meta.paxos$msgtype = tagged Valid paxos$msgtype;
        meta.udp$dstPort = tagged Valid udp$dstPort;
        meta.udp$checksum = tagged Valid udp$checksum;
        MetadataResponse rsp = tagged AcceptorTblHandle2ARspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged AcceptorTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
endmodule

// ====== ROUND_TBL ======

typedef struct {
} RoundTblReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_ROUND_TBL,
  READ_ROUND
} RoundTblActionT deriving (Bits, Eq, FShow);
typedef struct {
  RoundTblActionT _action;
} RoundTblRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_round_tbl(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_round_tbl(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(0, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_round_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(0) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_round_tbl(key, data);
    endaction
  endfunction

endinstance
interface RoundTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkRoundTbl  (RoundTbl);
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
    BBRequest req = tagged ReadRoundReqT {pkt: pkt, paxos$inst: paxos$inst};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ReadRoundRspT {pkt: .pkt, local_metadata$set_drop: .local_metadata$set_drop, local_metadata$round: .local_metadata$round}: begin
        meta.local_metadata$set_drop = tagged Valid local_metadata$set_drop;
        meta.local_metadata$round = tagged Valid local_metadata$round;
        MetadataResponse rsp = tagged RoundTblReadRoundRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) acceptor_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) acceptor_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) forward_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) round_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) round_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  AcceptorTbl acceptor_tbl <- mkAcceptorTbl();
  ForwardTbl forward_tbl <- mkForwardTbl();
  RoundTbl round_tbl <- mkRoundTbl();
  mkConnection(toClient(acceptor_tbl_req_ff, acceptor_tbl_rsp_ff), acceptor_tbl.prev_control_state_0);
  mkConnection(toClient(forward_tbl_req_ff, forward_tbl_rsp_ff), forward_tbl.prev_control_state_0);
  mkConnection(toClient(round_tbl_req_ff, round_tbl_rsp_ff), round_tbl.prev_control_state_0);
  // Basic Blocks
  Handle1A handle_1a_0 <- mkHandle1A();
  Handle2A handle_2a_0 <- mkHandle2A();
  Drop _drop_0 <- mkDrop();
  Forward forward_0 <- mkForward();
  Drop _drop_1 <- mkDrop();
  ReadRound read_round_0 <- mkReadRound();
  RegisterIfc#(1, 16) datapath_id <- mkP4Register(nil);
  RegisterIfc#(16, 16) rounds_register <- mkP4Register(nil);
  RegisterIfc#(16, 16) vrounds_register <- mkP4Register(nil);
  RegisterIfc#(16, 256) values_register <- mkP4Register(nil);
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_0, handle_1a_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_1, handle_2a_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, acceptor_tbl.next_control_state_2, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_0, forward_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_1, _drop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, round_tbl.next_control_state_0, read_round_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (isValid(meta.valid_ipv4)) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      forward_tbl_req_ff.enq(req);
    end
  endrule

  rule acceptor_tbl_next_state if (acceptor_tbl_rsp_ff.notEmpty);
    acceptor_tbl_rsp_ff.deq;
    let _rsp = acceptor_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged AcceptorTblHandle1ARspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged AcceptorTblHandle2ARspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged AcceptorTblDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule forward_tbl_next_state if (forward_tbl_rsp_ff.notEmpty);
    forward_tbl_rsp_ff.deq;
    let _rsp = forward_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged ForwardTblForwardRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          round_tbl_req_ff.enq(req);
        end
      end
      tagged ForwardTblDropRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          round_tbl_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule round_tbl_next_state if (round_tbl_rsp_ff.notEmpty);
    round_tbl_rsp_ff.deq;
    let _rsp = round_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged RoundTblReadRoundRspT {meta: .meta, pkt: .pkt}: begin
        let paxos$rnd = fromMaybe(?, meta.paxos$rnd);
        let local_metadata$round = fromMaybe(?, meta.local_metadata$round);
        if (( local_metadata$round <= paxos$rnd )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          acceptor_tbl_req_ff.enq(req);
        end
      end
    endcase
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
endmodule

// ====== DROP_TBL ======

typedef struct {
  Bit#(8) padding;
  Bit#(1) local_metadata$set_drop;
} DropTblReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_DROP_TBL,
  DROP,
  NOP
} DropTblActionT deriving (Bits, Eq, FShow);
typedef struct {
  DropTblActionT _action;
} DropTblRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(2)) matchtable_read_drop_tbl(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_drop_tbl(Bit#(9) msgtype, Bit#(2) data);
`endif
instance MatchTableSim#(3, 9, 2);
  function ActionValue#(Bit#(2)) matchtable_read(Bit#(3) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_drop_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(3) id, Bit#(9) key, Bit#(2) data);
    action
      matchtable_write_drop_tbl(key, data);
    endaction
  endfunction

endinstance
interface DropTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkDropTbl  (DropTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(3, 256, SizeOf#(DropTblReqT), SizeOf#(DropTblRspT)) matchTable <- mkMatchTable("drop_tbl.dat");
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
    let local_metadata$set_drop = fromMaybe(?, meta.local_metadata$set_drop);
    DropTblReqT req = DropTblReqT {local_metadata$set_drop: local_metadata$set_drop};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      DropTblRspT resp = unpack(data);
      case (resp._action) matches
        DROP: begin
          BBRequest req = tagged DropReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
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
      tagged DropRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged DropTblDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged DropTblNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule

// ====== EGRESS ======

interface Egress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) drop_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) drop_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  DropTbl drop_tbl <- mkDropTbl();
  mkConnection(toClient(drop_tbl_req_ff, drop_tbl_rsp_ff), drop_tbl.prev_control_state_0);
  // Basic Blocks
  Drop _drop_0 <- mkDrop();
  Nop _nop_0 <- mkNop();
  RegisterIfc#(1, 16) datapath_id <- mkP4Register(nil);
  RegisterIfc#(16, 16) rounds_register <- mkP4Register(nil);
  RegisterIfc#(16, 16) vrounds_register <- mkP4Register(nil);
  RegisterIfc#(16, 256) values_register <- mkP4Register(nil);
  mkChan(mkFIFOF, mkFIFOF, drop_tbl.next_control_state_0, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, drop_tbl.next_control_state_1, _nop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    drop_tbl_req_ff.enq(req);
  endrule

  rule drop_tbl_next_state if (drop_tbl_rsp_ff.notEmpty);
    drop_tbl_rsp_ff.deq;
    let _rsp = drop_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged DropTblDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged DropTblNopRspT {meta: .meta, pkt: .pkt}: begin
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
