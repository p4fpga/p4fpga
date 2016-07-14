
import BUtils::*;
import BuildVector::*;
import CBus::*;
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
import MIMO::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import Register::*;
import SpecialFIFOs::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;
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
  Bit#(16) ethertype;
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
  Bit#(1) drop;
  Bit#(8) egress_port;
  Bit#(7) _padding;
} IngressMetadataT deriving (Bits, Eq);
instance DefaultValue#(IngressMetadataT);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(IngressMetadataT);
  defaultMask = unpack(maxBound);
endinstance
function IngressMetadataT extract_ingress_metadata_t(Bit#(16) data);
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
  Maybe#(Bit#(1)) ing_metadata$drop;
  Maybe#(Bit#(8)) ing_metadata$egress_port;
  Maybe#(Bit#(8)) runtime_egress_port;
  Maybe#(Bit#(48)) ethernet$dstAddr;
  Maybe#(Bit#(48)) ethernet$srcAddr;
  Maybe#(Bit#(0)) valid_ethernet;
} MetadataT deriving (Bits, Eq);
typedef enum {
  StateParseStart,
  StateStart
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(ParserState) rg_parse_state <- mkReg(StateParseStart);
  Wire#(ParserState) parse_state_w <- mkDWire(StateParseStart);
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  PulseWire parse_done <- mkPulseWire();
  Reg#(Bit#(128)) rg_tmp_start <- mkReg(0);
  function Action succeed_and_next(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= offset;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= 0;
    endaction
  endfunction
  function Action push_phv(ParserState ty);
    action
    endaction
  endfunction
  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%d) Parser State %h offset %h, %h", $time, state, offset, data);
      end
    endaction
  endfunction
  rule rl_start_state if (rg_parse_state == StateParseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state <= StateStart;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  let data_this_cycle = data_in_ff.first.data;
  rule rl_parse_start_0 if ((rg_parse_state == StateStart) && (rg_offset == 0));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(0, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_start));
    Bit#(0) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(128) data = {data_this_cycle, data_last_cycle};
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let start = extract_ethernet_t(pack(takeAt(0, dataVec)));
    let next_state = StateParseStart;
    rg_parse_state <= next_state;
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    parse_state_w <= StateStart;
    succeed_and_next(rg_offset + 128);
  endrule

endmodule
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet
} DeparserState deriving (Bits, Eq);
interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  interface Put#(int) verbosity;
  method DeparserPerfRec read_perf_info ();
endinterface
module mkDeparser  (Deparser);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(EtherData) data_out_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  Reg#(Bit#(128)) rg_buff <- mkReg(0);
  Reg#(DeparserState) rg_deparse_state <- mkReg(StateDeparseStart);
  let din = data_in_ff.first;
  let meta = meta_in_ff.first;
  function Action report_deparse_action(DeparserState state, Bit#(32) offset);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%d) Deparse State %h offset %h", $time, state, offset);
      end
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= offset;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= 0;
    endaction
  endfunction
  function DeparserState compute_next_state(DeparserState state);
    DeparserState nextState = StateDeparseStart;
    return nextState;
  endfunction
  function Bit#(l) read_data(UInt#(8) lhs, UInt#(8) rhs)
   provisos (Add#(a__, l, 128));
    Bit#(l) ldata = truncate(din.data) << (fromInteger(valueOf(l))-lhs);
    Bit#(l) rdata = truncate(rg_buff) >> (fromInteger(valueOf(l))-rhs);
    Bit#(l) cdata = ldata | rdata;
    return cdata;
  endfunction
  function Bit#(max) create_mask(UInt#(max) count);
    Bit#(max) v = 1 << count - 1;
    return v;
  endfunction
  rule rl_start_state if (rg_deparse_state == StateDeparseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_deparse_state <= StateDeparseEthernet;
    end
    else begin
      data_in_ff.deq;
      data_out_ff.enq(v);
    end
  endrule

  function Rules build_deparse_rule_no_opt(DeparserState state, int offset, Tuple2#(Bit#(n), Bit#(n)) m, UInt#(8) clen, UInt#(8) plen)
   provisos (Mul#(TDiv#(n, 8), 8, n), Add#(a__, n, 128));
    Rules d = 
    rules
      rule rl_deparse if ((rg_deparse_state == state) && (rg_offset == unpack(pack(offset))));
        report_deparse_action(rg_deparse_state, rg_offset);
        match {.meta, .mask} = m;
        Vector#(n, Bit#(1)) curr_meta = takeAt(0, unpack(byteSwap(meta)));
        Vector#(n, Bit#(1)) curr_mask = takeAt(0, unpack(byteSwap(mask)));
        Bit#(n) curr_data = read_data (clen, plen);
        $display ("read_data %h", curr_data);
        let data = apply_changes (curr_data, pack(curr_meta), pack(curr_mask));
        let data_this_cycle = EtherData { sop: din.sop, eop: din.eop, data: zeroExtend(data), mask: create_mask(cExtend(fromInteger(valueOf(n)))) };
        data_out_ff.enq (data_this_cycle);
        DeparserState next_state = compute_next_state(state);
        $display ("next_state %h", next_state);
        rg_deparse_state <= next_state;
        rg_buff <= din.data;
        // apply header removal by marking mask zero
        // apply added header by setting field at offset.
        succeed_and_next (rg_offset + cExtend(clen) + cExtend(plen));
      endrule

    endrules;
    return d;
  endfunction
endmodule
typedef union tagged {
  struct {
    PacketInstance pkt;
  } IngDropReqT;
  struct {
    PacketInstance pkt;
  } NopReqT;
  struct {
    PacketInstance pkt;
    Bit#(8) runtime_egress_port;
  } SetEgressPortReqT;
} BBRequest deriving (Bits, Eq);
typedef union tagged {
  struct {
    PacketInstance pkt;
    Bit#(1) ing_metadata$drop;
  } IngDropRspT;
  struct {
    PacketInstance pkt;
  } NopRspT;
  struct {
    PacketInstance pkt;
    Bit#(8) ing_metadata$egress_port;
  } SetEgressPortRspT;
} BBResponse deriving (Bits, Eq);
interface IngDrop;
  interface Server#(BBRequest, BBResponse) prev_control_state;
endinterface
module mkIngDrop  (IngDrop);
  RX #(BBRequest) rx_prev_control_state <- mkRX;
  TX #(BBResponse) tx_prev_control_state <- mkTX;
  let rx_info_prev_control_state = rx_prev_control_state.u;
  let tx_info_prev_control_state = tx_prev_control_state.u;
  FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
  Reg#(Bit#(1)) ing_metadata$drop <- mkReg(0);
  rule ing_drop_request;
    let v = rx_info_prev_control_state.first;
    rx_info_prev_control_state.deq;
    case (v) matches
      tagged IngDropReqT {pkt: .pkt}: begin
        ing_metadata$drop <= 'h1;
        curr_packet_ff.enq(pkt);
      end
    endcase
  endrule

  rule ing_drop_response;
    let pkt <- toGet(curr_packet_ff).get;
    BBResponse rsp = tagged IngDropRspT {pkt: pkt, ing_metadata$drop: ing_metadata$drop};
    tx_info_prev_control_state.enq(rsp);
  endrule

  interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
endmodule
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
typedef struct {
  Bit#(48) ethernet$dstAddr;
  Bit#(6) padding;
} DmacReqT deriving (Bits, Eq);
typedef enum {
  NOOP_DMAC,
  NOP,
  SET_EGRESS_PORT
} DmacActionT deriving (Bits, Eq);
typedef struct {
  DmacActionT _action;
  Bit#(8) runtime_egress_port;
} DmacRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(10)) matchtable_read_54_10(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_54_10(Bit#(54) msgtype, Bit#(10) data);
instance MatchTableSim#(54, 10);
  function ActionValue#(Bit#(10)) matchtable_read(Bit#(54) key);
    actionvalue
      let v <- matchtable_read_54_10(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(54) key, Bit#(10) data);
    action
      matchtable_write_54_10(key, data);
    endaction
  endfunction
endinstance
interface Dmac;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkDmac  (Dmac);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(DmacReqT), SizeOf#(DmacRspT)) matchTable <- mkMatchTable();
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
    let ethernet$dstAddr = fromMaybe(?, meta.ethernet$dstAddr);
    DmacReqT req = DmacReqT {ethernet$dstAddr: ethernet$dstAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      DmacRspT resp = unpack(data);
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
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
typedef struct {
  Bit#(48) ethernet$srcAddr;
  Bit#(6) padding;
} SmacFilterReqT deriving (Bits, Eq);
typedef enum {
  NOOP_SMAC_FILTER,
  NOP,
  ING_DROP
} SmacFilterActionT deriving (Bits, Eq);
typedef struct {
  SmacFilterActionT _action;
} SmacFilterRspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(2)) matchtable_read_54_2(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_54_2(Bit#(54) msgtype, Bit#(2) data);
instance MatchTableSim#(54, 2);
  function ActionValue#(Bit#(2)) matchtable_read(Bit#(54) key);
    actionvalue
      let v <- matchtable_read_54_2(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(54) key, Bit#(2) data);
    action
      matchtable_write_54_2(key, data);
    endaction
  endfunction
endinstance
interface SmacFilter;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
module mkSmacFilter  (SmacFilter);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(SmacFilterReqT), SizeOf#(SmacFilterRspT)) matchTable <- mkMatchTable();
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
    SmacFilterReqT req = SmacFilterReqT {ethernet$srcAddr: ethernet$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      SmacFilterRspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        ING_DROP: begin
          BBRequest req = tagged IngDropReqT {pkt: pkt};
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
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged IngDropRspT {pkt: .pkt, ing_metadata$drop: .ing_metadata$drop}: begin
        meta.ing_metadata$drop = tagged Valid ing_metadata$drop;
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
interface Ingress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) dmac_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) dmac_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) smac_filter_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) smac_filter_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  Dmac dmac <- mkDmac();
  SmacFilter smac_filter <- mkSmacFilter();
  mkConnection(toClient(dmac_req_ff, dmac_rsp_ff), dmac.prev_control_state_0);
  mkConnection(toClient(smac_filter_req_ff, smac_filter_rsp_ff), smac_filter.prev_control_state_0);
  // Basic Blocks
  Nop nop_0 <- mkNop();
  SetEgressPort set_egress_port_0 <- mkSetEgressPort();
  Nop nop_1 <- mkNop();
  IngDrop ing_drop_0 <- mkIngDrop();
  mkChan(mkFIFOF, mkFIFOF, dmac.next_control_state_0, nop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, dmac.next_control_state_1, set_egress_port_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, smac_filter.next_control_state_0, nop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, smac_filter.next_control_state_1, ing_drop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule dmac_next_state if (dmac_rsp_ff.notEmpty);
    dmac_rsp_ff.deq;
    let _req = dmac_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule smac_filter_next_state if (smac_filter_rsp_ff.notEmpty);
    smac_filter_rsp_ff.deq;
    let _req = smac_filter_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

endmodule
typedef struct {
  Bit#(48) ethernet$srcAddr;
  Bit#(6) padding;
} ET1ReqT deriving (Bits, Eq);
typedef enum {
  NOOP_E_T1,
  NOP
} ET1ActionT deriving (Bits, Eq);
typedef struct {
  ET1ActionT _action;
} ET1RspT deriving (Bits, Eq);
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_54_1(Bit#(54) msgtype);
import "BDPI" function Action matchtable_write_54_1(Bit#(54) msgtype, Bit#(1) data);
instance MatchTableSim#(54, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(54) key);
    actionvalue
      let v <- matchtable_read_54_1(key);
      return v;
    endactionvalue
  endfunction
  function Action matchtable_write(Bit#(54) key, Bit#(1) data);
    action
      matchtable_write_54_1(key, data);
    endaction
  endfunction
endinstance
interface ET1;
  interface Server #(MetadataRequest, MetadataResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
module mkET1  (ET1);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(MetadataResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(1, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(1, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(256, SizeOf#(ET1ReqT), SizeOf#(ET1RspT)) matchTable <- mkMatchTable();
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
    let ethernet$srcAddr = fromMaybe(?, meta.ethernet$srcAddr);
    ET1ReqT req = ET1ReqT {ethernet$srcAddr: ethernet$srcAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ET1RspT resp = unpack(data);
      case (resp._action) matches
        NOP: begin
          BBRequest req = tagged NopReqT {pkt: pkt};
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
      tagged NopRspT {pkt: .pkt}: begin
        MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
interface Egress;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) e_t1_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) e_t1_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  ET1 e_t1 <- mkET1();
  mkConnection(toClient(e_t1_req_ff, e_t1_rsp_ff), e_t1.prev_control_state_0);
  // Basic Blocks
  Nop nop_0 <- mkNop();
  mkChan(mkFIFOF, mkFIFOF, e_t1.next_control_state_0, nop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

  rule e_t1_next_state if (e_t1_rsp_ff.notEmpty);
    e_t1_rsp_ff.deq;
    let _req = e_t1_rsp_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
  endrule

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
