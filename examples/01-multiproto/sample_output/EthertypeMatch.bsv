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

// ====== ETHERTYPE_MATCH ======

typedef struct {
  Bit#(2) padding;
  Bit#(16) ethernet$etherType;
} EthertypeMatchReqT deriving (Bits, Eq, FShow);
typedef enum {
  DEFAULT_ETHERTYPE_MATCH,
  L2_PACKET,
  IPV4_PACKET,
  IPV6_PACKET,
  MPLS_PACKET,
  MIM_PACKET
} EthertypeMatchActionT deriving (Bits, Eq, FShow);
typedef struct {
  EthertypeMatchActionT _action;
} EthertypeMatchRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(3)) matchtable_read_ethertype_match(Bit#(18) msgtype);
import "BDPI" function Action matchtable_write_ethertype_match(Bit#(18) msgtype, Bit#(3) data);
`endif
instance MatchTableSim#(0, 18, 3);
  function ActionValue#(Bit#(3)) matchtable_read(Bit#(0) id, Bit#(18) key);
    actionvalue
      let v <- matchtable_read_ethertype_match(key);
      return v;
    endactionvalue
  endfunction

  function Action matchtable_write(Bit#(0) id, Bit#(18) key, Bit#(3) data);
    action
      matchtable_write_ethertype_match(key, data);
    endaction
  endfunction

endinstance
interface EthertypeMatch;
  interface Server #(MetadataRequest, EthertypeMatchResponse) prev_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_0;
  interface Client #(BBRequest, BBResponse) next_control_state_1;
  interface Client #(BBRequest, BBResponse) next_control_state_2;
  interface Client #(BBRequest, BBResponse) next_control_state_3;
  interface Client #(BBRequest, BBResponse) next_control_state_4;
endinterface
(* synthesize *)
module mkEthertypeMatch  (EthertypeMatch);
  RX #(MetadataRequest) rx_metadata <- mkRX;
  let rx_info_metadata = rx_metadata.u;
  TX #(EthertypeMatchResponse) tx_metadata <- mkTX;
  let tx_info_metadata = tx_metadata.u;
  Vector#(5, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(5, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);
  FIFOF#(PacketInstance) packet_ff <- mkFIFOF;
  MatchTable#(0, 256, SizeOf#(EthertypeMatchReqT), SizeOf#(EthertypeMatchRspT)) matchTable <- mkMatchTable("ethertype_match.dat");
  Vector#(5, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
  Bool interruptStatus = False;
  Bit#(5) readyChannel = -1;
  for (Integer i=4; i>=0; i=i-1) begin
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
    let ethernet$etherType = fromMaybe(?, meta.ethernet$etherType);
    EthertypeMatchReqT req = EthertypeMatchReqT {padding: 0, ethernet$etherType: ethernet$etherType};
    matchTable.lookupPort.request.put(pack(req));
    packet_ff.enq(pkt);
    metadata_ff[0].enq(meta);
  endrule

  rule rl_handle_execute;
    let rsp <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packet_ff).get;
    let meta <- toGet(metadata_ff[0]).get;
    if (rsp matches tagged Valid .data) begin
      EthertypeMatchRspT resp = unpack(data);
      case (resp._action) matches
        L2_PACKET: begin
          BBRequest req = tagged L2PacketReqT {pkt: pkt};
          bbReqFifo[0].enq(req); //FIXME: replace with RXTX.
        end
        IPV4_PACKET: begin
          BBRequest req = tagged Ipv4PacketReqT {pkt: pkt};
          bbReqFifo[1].enq(req); //FIXME: replace with RXTX.
        end
        IPV6_PACKET: begin
          BBRequest req = tagged Ipv6PacketReqT {pkt: pkt};
          bbReqFifo[2].enq(req); //FIXME: replace with RXTX.
        end
        MPLS_PACKET: begin
          BBRequest req = tagged MplsPacketReqT {pkt: pkt};
          bbReqFifo[3].enq(req); //FIXME: replace with RXTX.
        end
        MIM_PACKET: begin
          BBRequest req = tagged MimPacketReqT {pkt: pkt};
          bbReqFifo[4].enq(req); //FIXME: replace with RXTX.
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
      tagged L2PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        EthertypeMatchResponse rsp = tagged EthertypeMatchL2PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv4PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        EthertypeMatchResponse rsp = tagged EthertypeMatchIpv4PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged Ipv6PacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        EthertypeMatchResponse rsp = tagged EthertypeMatchIpv6PacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MplsPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        EthertypeMatchResponse rsp = tagged EthertypeMatchMplsPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
      tagged MimPacketRspT {pkt: .pkt, ing_metadata$packet_type: .ing_metadata$packet_type}: begin
        meta.ing_metadata$packet_type = tagged Valid ing_metadata$packet_type;
        EthertypeMatchResponse rsp = tagged EthertypeMatchMimPacketRspT {pkt: pkt, meta: meta};
        tx_info_metadata.enq(rsp);
      end
    endcase
  endrule

  interface prev_control_state_0 = toServer(rx_metadata.e, tx_metadata.e);
  interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
  interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
  interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
  interface next_control_state_3 = toClient(bbReqFifo[3], bbRspFifo[3]);
  interface next_control_state_4 = toClient(bbReqFifo[4], bbRspFifo[4]);
endmodule
