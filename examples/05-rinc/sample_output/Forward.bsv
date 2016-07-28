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

// ====== FORWARD ======

typedef struct {
  Bit#(4) padding;
  Bit#(32) routing_metadata$nhop_ipv4;
} ForwardReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_FORWARD,
  SET_DMAC,
  DROP
} ForwardActionT deriving (Bits, Eq, FShow);
typedef struct {
  ForwardActionT _action;
  Bit#(48) runtime_dmac;
} ForwardRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(50)) matchtable_read_forward(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_forward(Bit#(36) msgtype, Bit#(50) data);
`endif
instance MatchTableSim#(14, 36, 50);
  function ActionValue#(Bit#(50)) matchtable_read(Bit#(14) id, Bit#(36) key);
    actionvalue
      let v <- matchtable_read_forward(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(14) id, Bit#(36) key, Bit#(50) data);
    action
      matchtable_write_forward(key, data);
    endaction
  endfunction

endinstance
interface Forward;
  interface Server #(MetadataRequest, ForwardResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
(* synthesize *)
module mkForward  (Forward);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(ForwardResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(14, 512, SizeOf#(ForwardReqT), SizeOf#(ForwardRspT)) matchTable <- mkMatchTable("forward.dat");
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
    let routing_metadata$nhop_ipv4 = fromMaybe(?, meta.routing_metadata$nhop_ipv4);
    ForwardReqT req = ForwardReqT {routing_metadata$nhop_ipv4: routing_metadata$nhop_ipv4};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      ForwardRspT resp = unpack(data);
      case (resp._action) matches
        SET_DMAC: begin
          BBRequest req = tagged SetDmacReqT {pkt: pkt, runtime_dmac_48: resp.runtime_dmac};
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
      tagged SetDmacRspT {pkt: .pkt, ethernet$dstAddr: .ethernet$dstAddr}: begin
        meta.ethernet$dstAddr = tagged Valid ethernet$dstAddr;
        ForwardResponse rsp = tagged ForwardSetDmacRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        ForwardResponse rsp = tagged ForwardDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
