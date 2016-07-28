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

// ====== SEND_FRAME ======

typedef struct {
  Bit#(9) standard_metadata$egress_port;
} SendFrameReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_SEND_FRAME,
  REWRITE_MAC,
  DROP
} SendFrameActionT deriving (Bits, Eq, FShow);
typedef struct {
  SendFrameActionT _action;
  Bit#(48) runtime_smac;
} SendFrameRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(50)) matchtable_read_send_frame(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_send_frame(Bit#(9) msgtype, Bit#(50) data);
`endif
instance MatchTableSim#(16, 9, 50);
  function ActionValue#(Bit#(50)) matchtable_read(Bit#(16) id, Bit#(9) key);
    actionvalue
      let v <- matchtable_read_send_frame(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(16) id, Bit#(9) key, Bit#(50) data);
    action
      matchtable_write_send_frame(key, data);
    endaction
  endfunction

endinstance
interface SendFrame;
  interface Server #(MetadataRequest, SendFrameResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
(* synthesize *)
module mkSendFrame  (SendFrame);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(SendFrameResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(16, 256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRspT)) matchTable <- mkMatchTable("send_frame.dat");
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
    let standard_metadata$egress_port = fromMaybe(?, meta.standard_metadata$egress_port);
    SendFrameReqT req = SendFrameReqT {standard_metadata$egress_port: standard_metadata$egress_port};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      SendFrameRspT resp = unpack(data);
      case (resp._action) matches
        REWRITE_MAC: begin
          BBRequest req = tagged RewriteMacReqT {pkt: pkt, runtime_smac_48: resp.runtime_smac};
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
      tagged RewriteMacRspT {pkt: .pkt, ethernet$srcAddr: .ethernet$srcAddr}: begin
        meta.ethernet$srcAddr = tagged Valid ethernet$srcAddr;
        SendFrameResponse rsp = tagged SendFrameRewriteMacRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        SendFrameResponse rsp = tagged SendFrameDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
