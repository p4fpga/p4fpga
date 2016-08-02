import ClientServer::*;
import UnionGenerated::*;
import StructGenerated::*;
import TxRx::*;
import FIFOF::*;
import Ethernet::*;
import MatchTable::*;
import Vector::*;
import Pipe::*;
import GetPut::*;
import Utils::*;
import DefaultValue::*;

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
  interface Server #(MetadataRequest, L2MatchResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
(* synthesize *)
module mkL2Match  (L2Match);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(L2MatchResponse) tx_metadata <- mkTX;
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
          BBRequest req = tagged SetEgressPortReqT {pkt: pkt, runtime_egress_port_8: resp.runtime_egress_port};
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
        L2MatchResponse rsp = tagged L2MatchNopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged SetEgressPortRspT {pkt: .pkt, ing_metadata$egress_port: .ing_metadata$egress_port}: begin
        meta.ing_metadata$egress_port = tagged Valid ing_metadata$egress_port;
        L2MatchResponse rsp = tagged L2MatchSetEgressPortRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
