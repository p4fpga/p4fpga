import StructDefines::*;
import UnionDefines::*;
import CPU::*;
import IMem::*;
import Lists::*;
import TxRx::*;
import SharedBuff::*;
import CountingFilter::*;
import Lists::*;
// ====== DEDUP ======

interface Dedup;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkDedup  (Dedup);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(64)) mdp$msgSeqNum <- mkReg('hfff);
  Reg#(Bool) rg_forward <- mkReg(False);
  CPU cpu <- mkCPU("dedup", list1(mdp$msgSeqNum));
  COUNTING_FILTER#(Bit#(32), 1) filter <- mkCountingFilter();

  IMem imem <- mkIMem("dedup.hex");
  mkConnection(cpu.imem_client, imem.cpu_server);

  // INST: modify_field [OrderedDict([('type', 'field'), ('value', ['mdp', 'msgSeqNum'])]), OrderedDict([('type', 'hexstr'), ('value', '0x0')])]
  rule dedup_request if (cpu.not_running());
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DedupReqT {pkt: .pkt, mdp$msgSeqNum: .msgSeqNum}: begin
        cpu.run();
        curr_packet_ff.enq(pkt);
        let notSet = filter.notSet(msgSeqNum);
        if (notSet) begin
           let present = filter.test(msgSeqNum);
           dbprint(3, $format("BLM: test ", fshow(present)));
           if (present matches tagged Valid .hash) begin
              dbprint(3, $format("BLM: set bloom filter ", fshow(present)));
              filter.set(hash);
              dbprint(3, $format("BLM: add ", fshow(present)));
              rg_forward <= True;
           end
        end
        else begin
           filter.remove(msgSeqNum);
           dbprint(3, $format("BLM: remove ", fshow(msgSeqNum)));
           rg_forward <= False;
        end
        mdp$msgSeqNum <= zeroExtend(msgSeqNum);
      end
    endcase
  endrule

  rule dedup_response if (cpu.not_running());
    let pkt <- toGet(curr_packet_ff).get;
    Bool fwd = rg_forward;
    BBResponse rsp = tagged DedupRspT {pkt: pkt, forward: fwd};
    dbprint(3, $format("BLM: forward? ", fshow(pkt), fshow(fwd)));
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    cpu.set_verbosity(verbosity);
    imem.set_verbosity(verbosity);
    filter.set_verbosity(verbosity);
  endmethod
endmodule
// ====== DROP ======

interface Drop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  interface MemFreeClient freeClient;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkDrop  (Drop);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  FIFO#(PktId) freeReqFifo <- printTraceM("freereq", mkSizedFIFO(6));
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  MemFreeClient free = (interface MemFreeClient;
    interface Get freeReq = toGet(freeReqFifo);
  endinterface);

  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule drop_loopback;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged DropReqT {pkt: .pkt}: begin
        //freeReqFifo.enq(pkt.id);
        BBResponse rsp = tagged DropRspT {pkt: pkt};
        tx_info_prev_control_state.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  interface freeClient = free;
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
// ====== FORWARD ======

interface Forward;
  interface Server#(BBRequest, BBResponse) prev_control_state;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkForward  (Control::Forward);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  rule forward_loopback;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged ForwardReqT {pkt: .pkt}: begin
        BBResponse rsp = tagged ForwardRspT {pkt: pkt};
        tx_info_prev_control_state.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
// ====== TBL_BLOOMFILTER ======

typedef struct {
} TblBloomfilterReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_TBL_BLOOMFILTER,
  DEDUP
} TblBloomfilterActionT deriving (Bits, Eq, FShow);
typedef struct {
  TblBloomfilterActionT _action;
} TblBloomfilterRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_tbl_bloomfilter(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_tbl_bloomfilter(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(0, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(0) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_tbl_bloomfilter(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(0) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_tbl_bloomfilter(key, data);
    endaction
  endfunction

endinstance
interface TblBloomfilter;
  interface Server #(MetadataRequest, TblBloomfilterResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkTblBloomfilter  (TblBloomfilter);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(TblBloomfilterResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkPipelineFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkPipelineFIFOF);
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
    //packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    BBRequest req = tagged DedupReqT {pkt: pkt, mdp$msgSeqNum: fromMaybe(?, meta.mdp$msgSeqNum)};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
    dbprint(3, $format("bloom request"));
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged DedupRspT {pkt: .pkt, forward: .forward}: begin
        meta.forward = tagged Valid forward;
        TblBloomfilterResponse rsp = tagged TblBloomfilterDedupRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
    dbprint(3, $format("bloom resp ", fshow(v)));
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
// ====== TBL_DROP ======

typedef struct {
} TblDropReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_TBL_DROP,
  DROP
} TblDropActionT deriving (Bits, Eq, FShow);
typedef struct {
  TblDropActionT _action;
} TblDropRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_tbl_drop(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_tbl_drop(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(2, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(2) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_tbl_drop(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(2) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_tbl_drop(key, data);
    endaction
  endfunction

endinstance
interface TblDrop;
  interface Server #(MetadataRequest, TblDropResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkTblDrop  (TblDrop);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(TblDropResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkPipelineFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkPipelineFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkSizedFIFOF(4);
  Vector#(1, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(1) readyChannel = -1;
  for (Integer i=0; i>=0; i=i-1) begin
      if (readyBits[i]) begin
          interruptStatus = True;
          readyChannel = fromInteger(i);
      end
  end

  FIFOF#(MetadataT) metadata_ff <- mkSizedFIFOF(4);
  rule rl_handle_action_request;
    let data = rx_info_metadata.first;
    rx_info_metadata.deq;
    let meta = data.meta;
    let pkt = data.pkt;
    //packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    BBRequest req = tagged DropReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    meta.standard_metadata.egress_port = tagged Valid 0;
    case (v) matches
      tagged DropRspT {pkt: .pkt}: begin
        TblDropResponse rsp = tagged TblDropDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
        $display("(%0d) dropped", $time);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
// ====== TBL_FORWARD ======

typedef struct {
} TblForwardReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_TBL_FORWARD,
  FORWARD
} TblForwardActionT deriving (Bits, Eq, FShow);
typedef struct {
  TblForwardActionT _action;
} TblForwardRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_tbl_forward(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_tbl_forward(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(1, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(1) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_tbl_forward(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(1) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_tbl_forward(key, data);
    endaction
  endfunction

endinstance
interface TblForward;
  interface Server #(MetadataRequest, TblForwardResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  method Action set_verbosity (int verbosity);
endinterface
(* synthesize *)
module mkTblForward  (TblForward);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%d) ", $time, msg);
    end
    endaction
  endfunction

  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(TblForwardResponse) tx_metadata <- mkTX;
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
    //packet_ff.enq(pkt);
    metadata_ff.enq(meta);
    BBRequest req = tagged ForwardReqT {pkt: pkt};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged ForwardRspT {pkt: .pkt}: begin
        TblForwardResponse rsp = tagged TblForwardForwardRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
// ====== INGRESS ======

interface Ingress;
  interface PipeIn#(MetadataRequest) prev;
  interface PipeOut#(MetadataRequest) next;
  interface MemFreeClient freeClient;
  method Action set_verbosity (int verbosity);
endinterface
module mkIngress (Ingress);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%0d) ", $time, msg);
    end
    endaction
  endfunction

  FIFOF#(MetadataRequest) entry_req_ff <- printTimedTraceM("entry_req_ff", mkBypassFIFOF);
  FIFOF#(MetadataResponse) entry_rsp_ff <- printTimedTraceM("entry_rsp_ff", mkBypassFIFOF);
  FIFOF#(MetadataRequest) tbl_bloomfilter_req_ff <- printTimedTraceM("blm_req_ff", mkBypassFIFOF);
  FIFOF#(TblBloomfilterResponse) tbl_bloomfilter_rsp_ff <- printTimedTraceM("blm_rsp_ff", mkBypassFIFOF);
  FIFOF#(MetadataRequest) tbl_drop_req_ff <- mkBypassFIFOF;
  FIFOF#(TblDropResponse) tbl_drop_rsp_ff <- mkBypassFIFOF;
  FIFOF#(MetadataRequest) tbl_forward_req_ff <- mkBypassFIFOF;
  FIFOF#(TblForwardResponse) tbl_forward_rsp_ff <- mkBypassFIFOF;
  FIFOF#(MetadataRequest) exit_req_ff <- mkBypassFIFOF;
  FIFOF#(MetadataResponse) exit_rsp_ff <- mkBypassFIFOF;
  TblBloomfilter tbl_bloomfilter <- mkTblBloomfilter();
  TblDrop tbl_drop <- mkTblDrop();
  TblForward tbl_forward <- mkTblForward();
  mkConnection(toClient(tbl_bloomfilter_req_ff, tbl_bloomfilter_rsp_ff), tbl_bloomfilter.prev_control_state_0);
  mkConnection(toClient(tbl_drop_req_ff, tbl_drop_rsp_ff), tbl_drop.prev_control_state_0);
  mkConnection(toClient(tbl_forward_req_ff, tbl_forward_rsp_ff), tbl_forward.prev_control_state_0);
  // Basic Blocks
  Dedup dedup_0 <- mkDedup();
  Drop drop_0 <- mkDrop();
  Forward forward_0 <- mkForward();
  mkChan(printTimedTraceM("tbl_blm_req", mkBypassFIFOF), printTimedTraceM("tbl_blm_rsp", mkBypassFIFOF), tbl_bloomfilter.next_control_state_0, dedup_0.prev_control_state);
  mkChan(printTimedTraceM("tbl_drop_req", mkBypassFIFOF), printTimedTraceM("tbl_drop_rsp", mkBypassFIFOF), tbl_drop.next_control_state_0, drop_0.prev_control_state);
  mkChan(printTimedTraceM("tbl_fwd_req", mkBypassFIFOF), printTimedTraceM("tbl_fwd_rsp", mkBypassFIFOF), tbl_forward.next_control_state_0, forward_0.prev_control_state);
  rule default_next_state if (entry_req_ff.notEmpty);
    entry_req_ff.deq;
    let _req = entry_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    req.meta.standard_metadata.egress_port = req.meta.standard_metadata.ingress_port;
    tbl_bloomfilter_req_ff.enq(req);
  endrule

  rule tbl_bloomfilter_next_state if (tbl_bloomfilter_rsp_ff.notEmpty);
    tbl_bloomfilter_rsp_ff.deq;
    let _rsp = tbl_bloomfilter_rsp_ff.first;
    dbprint(3, $format("bloom: ", fshow(_rsp)));
    case (_rsp) matches
      tagged TblBloomfilterDedupRspT {meta: .meta, pkt: .pkt}: begin
        let forward = fromMaybe(?, meta.forward);
        if (forward) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          tbl_forward_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          tbl_drop_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule tbl_drop_next_state if (tbl_drop_rsp_ff.notEmpty);
    tbl_drop_rsp_ff.deq;
    let _rsp = tbl_drop_rsp_ff.first;
    case (_rsp) matches
      tagged TblDropDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        exit_req_ff.enq(req);
      end
    endcase
    dbprint(3, $format("drop: ", fshow(_rsp)));
  endrule

  rule tbl_forward_next_state if (tbl_forward_rsp_ff.notEmpty);
    tbl_forward_rsp_ff.deq;
    let _rsp = tbl_forward_rsp_ff.first;
    case (_rsp) matches
      tagged TblForwardForwardRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        exit_req_ff.enq(req);
      end
    endcase
    dbprint(3, $format("forward: ", fshow(_rsp)));
  endrule

  interface prev = toPipeIn(entry_req_ff);
  interface next = toPipeOut(exit_req_ff);
  interface freeClient = drop_0.freeClient;
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    dedup_0.set_verbosity(verbosity);
    drop_0.set_verbosity(verbosity);
    forward_0.set_verbosity(verbosity);
    tbl_bloomfilter.set_verbosity(verbosity);
    tbl_drop.set_verbosity(verbosity);
    tbl_forward.set_verbosity(verbosity);
  endmethod
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
// ====== EGRESS ======

interface Egress;
  interface PipeIn#(MetadataRequest) prev;
  interface PipeOut#(MetadataRequest) next;
  method Action set_verbosity (int verbosity);
endinterface
module mkEgress (Egress);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%d) ", $time, msg);
    end
    endaction
  endfunction

  FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) entry_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) exit_req_ff <- mkSizedFIFOF(16);
  FIFOF#(MetadataResponse) exit_rsp_ff <- mkFIFOF;
  // Basic Blocks
  rule default_next_state if (entry_req_ff.notEmpty);
    entry_req_ff.deq;
    let _req = entry_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    exit_req_ff.enq(req);
    dbprint(3, $format("egress: ", fshow(req)));
  endrule

  interface prev = toPipeIn(entry_req_ff);
  interface next = toPipeOut(exit_req_ff);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
  endmethod
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
