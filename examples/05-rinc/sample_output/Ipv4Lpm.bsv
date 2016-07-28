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

// ====== IPV4_LPM ======

typedef struct {
  Bit#(4) padding;
  Bit#(32) ipv4$dstAddr;
} Ipv4LpmReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_IPV4_LPM,
  SET_NHOP,
  DROP
} Ipv4LpmActionT deriving (Bits, Eq, FShow);
typedef struct {
  Ipv4LpmActionT _action;
  Bit#(32) runtime_nhop_ipv4;
  Bit#(9) runtime_port;
} Ipv4LpmRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(43)) matchtable_read_ipv4_lpm(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_ipv4_lpm(Bit#(36) msgtype, Bit#(43) data);
`endif
instance MatchTableSim#(13, 36, 43);
  function ActionValue#(Bit#(43)) matchtable_read(Bit#(13) id, Bit#(36) key);
    actionvalue
      let v <- matchtable_read_ipv4_lpm(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(13) id, Bit#(36) key, Bit#(43) data);
    action
      matchtable_write_ipv4_lpm(key, data);
    endaction
  endfunction

endinstance
interface Ipv4Lpm;
  interface Server #(MetadataRequest, Ipv4LpmResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
endinterface
(* synthesize *)
module mkIpv4Lpm  (Ipv4Lpm);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(Ipv4LpmResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(2, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(2, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(13, 1024, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRspT)) matchTable <- mkMatchTable("ipv4_lpm.dat");
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
    let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
    Ipv4LpmReqT req = Ipv4LpmReqT {ipv4$dstAddr: ipv4$dstAddr};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      Ipv4LpmRspT resp = unpack(data);
      case (resp._action) matches
        SET_NHOP: begin
          BBRequest req = tagged SetNhopReqT {pkt: pkt, runtime_port_9: resp.runtime_port, runtime_nhop_ipv4_32: resp.runtime_nhop_ipv4};
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
      tagged SetNhopRspT {pkt: .pkt, ipv4$ttl: .ipv4$ttl, standard_metadata$egress_spec: .standard_metadata$egress_spec, routing_metadata$nhop_ipv4: .routing_metadata$nhop_ipv4}: begin
        meta.ipv4$ttl = tagged Valid ipv4$ttl;
        meta.standard_metadata$egress_spec = tagged Valid standard_metadata$egress_spec;
        meta.routing_metadata$nhop_ipv4 = tagged Valid routing_metadata$nhop_ipv4;
        Ipv4LpmResponse rsp = tagged Ipv4LpmSetNhopRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged DropRspT {pkt: .pkt}: begin
        Ipv4LpmResponse rsp = tagged Ipv4LpmDropRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
endmodule
