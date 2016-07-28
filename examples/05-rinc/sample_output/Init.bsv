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

// ====== INIT ======

typedef struct {
} InitReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_INIT,
  RECORD_IP
} InitActionT deriving (Bits, Eq, FShow);
typedef struct {
  InitActionT _action;
} InitRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(1)) matchtable_read_init(Bit#(0) msgtype);
import "BDPI" function Action matchtable_write_init(Bit#(0) msgtype, Bit#(1) data);
`endif
instance MatchTableSim#(2, 0, 1);
  function ActionValue#(Bit#(1)) matchtable_read(Bit#(2) id, Bit#(0) key);
    actionvalue
      let v <- matchtable_read_init(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(2) id, Bit#(0) key, Bit#(1) data);
    action
      matchtable_write_init(key, data);
    endaction
  endfunction

endinstance
interface Init;
  interface Server #(MetadataRequest, InitResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
endinterface
(* synthesize *)
module mkInit  (Init);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(InitResponse) tx_metadata <- mkTX;
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
    let options_wscale$wscale = fromMaybe(?, meta.options_wscale$wscale);
    let stats_metadata$flow_map_index = fromMaybe(?, meta.stats_metadata$flow_map_index);
    let options_mss$mss = fromMaybe(?, meta.options_mss$mss);
    let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
    BBRequest req = tagged RecordIpReqT {pkt: pkt, options_wscale$wscale: options_wscale$wscale, stats_metadata$flow_map_index: stats_metadata$flow_map_index, options_mss$mss: options_mss$mss, ipv4$dstAddr: ipv4$dstAddr};
    bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
  endrule

  rule rl_handle_action_response if (interruptStatus);
    let v <- toGet(bbRspFifo[readyChannel]).get;
    let meta <- toGet(metadata_ff).get;
    case (v) matches
      tagged RecordIpRspT {pkt: .pkt, stats_metadata$senderIP: .stats_metadata$senderIP}: begin
        meta.stats_metadata$senderIP = tagged Valid stats_metadata$senderIP;
        InitResponse rsp = tagged InitRecordIpRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
endmodule
