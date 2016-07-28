
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
    Bit#(32) paxos$inst;
  } IncreaseInstanceReqT;
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
    Bit#(32) paxos$inst;
    Bit#(16) udp$dstPort;
    Bit#(16) udp$checksum;
  } IncreaseInstanceRspT;
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

// ====== INCREASE_INSTANCE ======

interface IncreaseInstance;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) instance_register;
  interface Client#(RegRequest#(1, 32), RegResponse#(32)) instance_register;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIncreaseInstance  (IncreaseInstance);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  TX #(RegRequest#(1, 32)) tx_instance_register <- mkTX;
  RX #(RegResponse#(32)) rx_instance_register <- mkRX;
  let tx_info_instance_register = tx_instance_register.u;
  let rx_info_instance_register = rx_instance_register.u;
  TX #(RegRequest#(1, 32)) tx_instance_register <- mkTX;
  RX #(RegResponse#(32)) rx_instance_register <- mkRX;
  let tx_info_instance_register = tx_instance_register.u;
  let rx_info_instance_register = rx_instance_register.u;
  Reg#(Bit#(32)) rg_paxos$inst <- mkReg(0);
  Reg#(Bit#(16)) udp$dstPort <- mkReg(0);
  Reg#(Bit#(16)) udp$checksum <- mkReg(0);
  rule increase_instance_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged IncreaseInstanceReqT {pkt: .pkt, paxos$inst: .paxos$inst}: begin
        let instance_register_req = RegRequest { addr: 0, data: ?, write: False };
        tx_info_instance_register.enq(instance_register_req);
        let instance_register_req = RegRequest { addr: truncate(0), data: paxos$inst, write: True };
        tx_info_instance_register.enq(instance_register_req);
        rg_paxos$inst <= paxos$inst;
        udp$dstPort <= 'h8889;
        udp$checksum <= 'h0;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule increase_instance_response;
    let v_paxos$inst = rx_info_instance_register.first;
    rx_info_instance_register.deq;
    let paxos$inst = v_paxos$inst.data;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged IncreaseInstanceRspT {pkt: pkt, paxos$inst: paxos$inst, udp$dstPort: udp$dstPort, udp$checksum: udp$checksum};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface instance_register = toClient(tx_instance_register.e, rx_instance_register.e);
  interface instance_register = toClient(tx_instance_register.e, rx_instance_register.e);
  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule

// ====== SEQUENCE_TBL ======

typedef struct {
  Bit#(2) padding;
  Bit#(16) paxos$msgtype;
} SequenceTblReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_SEQUENCE_TBL,
  INCREASE_INSTANCE,
  NOP
} SequenceTblActionT deriving (Bits, Eq, FShow);
typedef struct {
  SequenceTblActionT _action;
} SequenceTblRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(2)) matchtable_read_sequence_tbl(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_sequence_tbl(Bit#(18) msgtype, Bit#(2) data);
`endif
instance MatchTableSim#(1, 18, 2);
  function ActionValue#(Bit#(2)) matchtable_read(Bit#(1) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_sequence_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(1) id, Bit#(18) key, Bit#(2) data);
    action
      matchtable_write_sequence_tbl(key, data);
    endaction
  endfunction

endinstance
interface SequenceTbl;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkSequenceTbl  (SequenceTbl);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(1, 256, SizeOf#(SequenceTblReqT), SizeOf#(SequenceTblRspT)) matchTable <- mkMatchTable("sequence_tbl.dat");
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
    let paxos$msgtype = fromMaybe(?, meta.paxos$msgtype);
    SequenceTblReqT req = SequenceTblReqT {paxos$msgtype: paxos$msgtype};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      SequenceTblRspT resp = unpack(data);
      case (resp._action) matches
        INCREASE_INSTANCE: begin
          BBRequest req = tagged IncreaseInstanceReqT {pkt: pkt, paxos$inst: paxos$inst};
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
      tagged IncreaseInstanceRspT {pkt: .pkt, paxos$inst: .paxos$inst, udp$dstPort: .udp$dstPort, udp$checksum: .udp$checksum}: begin
        meta.paxos$inst = tagged Valid paxos$inst;
        meta.udp$dstPort = tagged Valid udp$dstPort;
        meta.udp$checksum = tagged Valid udp$checksum;
        MetadataResponse rsp = tagged SequenceTblIncreaseInstanceRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = tagged SequenceTblNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
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
instance MatchTableSim#(0, 9, 11);
  function ActionValue#(Bit#(11)) matchtable_read(Bit#(0) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_forward_tbl(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(0) id, Bit#(9) key, Bit#(11) data);
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
  MatchTable#(0, 256, SizeOf#(ForwardTblReqT), SizeOf#(ForwardTblRspT)) matchTable <- mkMatchTable("forward_tbl.dat");
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

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) forward_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) sequence_tbl_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) sequence_tbl_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  ForwardTbl forward_tbl <- mkForwardTbl();
  SequenceTbl sequence_tbl <- mkSequenceTbl();
  mkConnection(toClient(forward_tbl_req_ff, forward_tbl_rsp_ff), forward_tbl.prev_control_state_0);
  mkConnection(toClient(sequence_tbl_req_ff, sequence_tbl_rsp_ff), sequence_tbl.prev_control_state_0);
  // Basic Blocks
  Forward forward_0 <- mkForward();
  Drop _drop_0 <- mkDrop();
  IncreaseInstance increase_instance_0 <- mkIncreaseInstance();
  Nop _nop_0 <- mkNop();
  RegisterIfc#(1, 32) instance_register <- mkP4Register(nil);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_0, forward_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward_tbl.next_control_state_1, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, sequence_tbl.next_control_state_0, increase_instance_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, sequence_tbl.next_control_state_1, _nop_0.prev_control_state);
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

  rule forward_tbl_next_state if (forward_tbl_rsp_ff.notEmpty);
    forward_tbl_rsp_ff.deq;
    let _rsp = forward_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged ForwardTblForwardRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          sequence_tbl_req_ff.enq(req);
        end
      end
      tagged ForwardTblDropRspT {meta: .meta, pkt: .pkt}: begin
        if (isValid(meta.valid_paxos)) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          sequence_tbl_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule sequence_tbl_next_state if (sequence_tbl_rsp_ff.notEmpty);
    sequence_tbl_rsp_ff.deq;
    let _rsp = sequence_tbl_rsp_ff.first;
    case (_rsp) matches
      tagged SequenceTblIncreaseInstanceRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged SequenceTblNopRspT {meta: .meta, pkt: .pkt}: begin
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
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  RegisterIfc#(1, 32) instance_register <- mkP4Register(nil);
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
