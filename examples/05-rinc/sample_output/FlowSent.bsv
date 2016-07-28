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

// ====== FLOW_SENT ======

typedef struct {
} FlowSentReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_FLOW_SENT,
  UPDATE_FLOW_SENT
} FlowSentActionT deriving (Bits, Eq, FShow);
typedef struct {
  FlowSentActionT _action;
} FlowSentRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_flow_sent(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_flow_sent(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(5, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(5) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_flow_sent(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(5) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_flow_sent(key, data);
    endaction
  endfunction

endinstance
interface FlowSent;
  interface Server #(MetadataRequest, FlowSentResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
(* synthesize *)
module mkFlowSent  (FlowSent);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(FlowSentResponse) tx_metadata <- mkTX;
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
    let stats_metadata$flow_map_index = fromMaybe(?, meta.stats_metadata$flow_map_index);
    let intrinsic_metadata$ingress_global_timestamp = fromMaybe(?, meta.intrinsic_metadata$ingress_global_timestamp);
    let stats_metadata$dummy = fromMaybe(?, meta.stats_metadata$dummy);
    let tcp$seqNo = fromMaybe(?, meta.tcp$seqNo);
    let stats_metadata$dummy2 = fromMaybe(?, meta.stats_metadata$dummy2);
    BBRequest req = tagged UpdateFlowSentReqT {pkt: pkt, stats_metadata$flow_map_index: stats_metadata$flow_map_index, intrinsic_metadata$ingress_global_timestamp: intrinsic_metadata$ingress_global_timestamp, stats_metadata$dummy: stats_metadata$dummy, tcp$seqNo: tcp$seqNo, stats_metadata$dummy2: stats_metadata$dummy2};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged UpdateFlowSentRspT {pkt: .pkt, stats_metadata$dummy: .stats_metadata$dummy, stats_metadata$dummy2: .stats_metadata$dummy2}: begin
        meta.stats_metadata$dummy = tagged Valid stats_metadata$dummy;
        meta.stats_metadata$dummy2 = tagged Valid stats_metadata$dummy2;
        FlowSentResponse rsp = tagged FlowSentUpdateFlowSentRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
