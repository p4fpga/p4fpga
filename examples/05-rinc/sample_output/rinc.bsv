
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
import Drop::*;
import GetSenderIp::*;
import IncreaseMincwnd::*;
import LookupFlowMap::*;
import LookupFlowMapReverse::*;
import RecordIp::*;
import RewriteMac::*;
import SampleNewRtt::*;
import SaveSourceIp::*;
import SetDmac::*;
import SetNhop::*;
import UpdateFlowDupack::*;
import UpdateFlowRcvd::*;
import UpdateFlowRetx3Dupack::*;
import UpdateFlowRetxTimeout::*;
import UpdateFlowSent::*;
import UseSampleRtt::*;
import UseSampleRttFirst::*;
import Debug::*;
import Direction::*;
import FirstRttSample::*;
import FlowDupack::*;
import FlowRcvd::*;
import FlowRetx3Dupack::*;
import FlowRetxTimeout::*;
import FlowSent::*;
import Forward::*;
import IncreaseCwnd::*;
import Init::*;
import Ipv4Lpm::*;
import Lookup::*;
import LookupReverse::*;
import SampleRttRcvd::*;
import SampleRttSent::*;
import SendFrame::*;
import UnionGenerated::*;

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) debug_req_ff <- mkFIFOF;
  FIFOF#(DebugResponse) debug_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) direction_req_ff <- mkFIFOF;
  FIFOF#(DirectionResponse) direction_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) first_rtt_sample_req_ff <- mkFIFOF;
  FIFOF#(FirstRttSampleResponse) first_rtt_sample_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_dupack_req_ff <- mkFIFOF;
  FIFOF#(FlowDupackResponse) flow_dupack_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_rcvd_req_ff <- mkFIFOF;
  FIFOF#(FlowRcvdResponse) flow_rcvd_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_retx_3dupack_req_ff <- mkFIFOF;
  FIFOF#(FlowRetx3DupackResponse) flow_retx_3dupack_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_retx_timeout_req_ff <- mkFIFOF;
  FIFOF#(FlowRetxTimeoutResponse) flow_retx_timeout_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) flow_sent_req_ff <- mkFIFOF;
  FIFOF#(FlowSentResponse) flow_sent_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_req_ff <- mkFIFOF;
  FIFOF#(ForwardResponse) forward_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) increase_cwnd_req_ff <- mkFIFOF;
  FIFOF#(IncreaseCwndResponse) increase_cwnd_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) init_req_ff <- mkFIFOF;
  FIFOF#(InitResponse) init_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- mkFIFOF;
  FIFOF#(Ipv4LpmResponse) ipv4_lpm_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) lookup_req_ff <- mkFIFOF;
  FIFOF#(LookupResponse) lookup_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) lookup_reverse_req_ff <- mkFIFOF;
  FIFOF#(LookupReverseResponse) lookup_reverse_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) sample_rtt_rcvd_req_ff <- mkFIFOF;
  FIFOF#(SampleRttRcvdResponse) sample_rtt_rcvd_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) sample_rtt_sent_req_ff <- mkFIFOF;
  FIFOF#(SampleRttSentResponse) sample_rtt_sent_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  Debug debug <- mkDebug();
  Direction direction <- mkDirection();
  FirstRttSample first_rtt_sample <- mkFirstRttSample();
  FlowDupack flow_dupack <- mkFlowDupack();
  FlowRcvd flow_rcvd <- mkFlowRcvd();
  FlowRetx3Dupack flow_retx_3dupack <- mkFlowRetx3Dupack();
  FlowRetxTimeout flow_retx_timeout <- mkFlowRetxTimeout();
  FlowSent flow_sent <- mkFlowSent();
  Forward forward <- mkForward();
  IncreaseCwnd increase_cwnd <- mkIncreaseCwnd();
  Init init <- mkInit();
  Ipv4Lpm ipv4_lpm <- mkIpv4Lpm();
  Lookup lookup <- mkLookup();
  LookupReverse lookup_reverse <- mkLookupReverse();
  SampleRttRcvd sample_rtt_rcvd <- mkSampleRttRcvd();
  SampleRttSent sample_rtt_sent <- mkSampleRttSent();
  mkConnection(toClient(debug_req_ff, debug_rsp_ff), debug.prev_control_state_0);
  mkConnection(toClient(direction_req_ff, direction_rsp_ff), direction.prev_control_state_0);
  mkConnection(toClient(first_rtt_sample_req_ff, first_rtt_sample_rsp_ff), first_rtt_sample.prev_control_state_0);
  mkConnection(toClient(flow_dupack_req_ff, flow_dupack_rsp_ff), flow_dupack.prev_control_state_0);
  mkConnection(toClient(flow_rcvd_req_ff, flow_rcvd_rsp_ff), flow_rcvd.prev_control_state_0);
  mkConnection(toClient(flow_retx_3dupack_req_ff, flow_retx_3dupack_rsp_ff), flow_retx_3dupack.prev_control_state_0);
  mkConnection(toClient(flow_retx_timeout_req_ff, flow_retx_timeout_rsp_ff), flow_retx_timeout.prev_control_state_0);
  mkConnection(toClient(flow_sent_req_ff, flow_sent_rsp_ff), flow_sent.prev_control_state_0);
  mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state_0);
  mkConnection(toClient(increase_cwnd_req_ff, increase_cwnd_rsp_ff), increase_cwnd.prev_control_state_0);
  mkConnection(toClient(init_req_ff, init_rsp_ff), init.prev_control_state_0);
  mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state_0);
  mkConnection(toClient(lookup_req_ff, lookup_rsp_ff), lookup.prev_control_state_0);
  mkConnection(toClient(lookup_reverse_req_ff, lookup_reverse_rsp_ff), lookup_reverse.prev_control_state_0);
  mkConnection(toClient(sample_rtt_rcvd_req_ff, sample_rtt_rcvd_rsp_ff), sample_rtt_rcvd.prev_control_state_0);
  mkConnection(toClient(sample_rtt_sent_req_ff, sample_rtt_sent_rsp_ff), sample_rtt_sent.prev_control_state_0);
  // Basic Blocks
  SaveSourceIp save_source_IP_0 <- mkSaveSourceIp();
  GetSenderIp get_sender_IP_0 <- mkGetSenderIp();
  UseSampleRttFirst use_sample_rtt_first_0 <- mkUseSampleRttFirst();
  UpdateFlowDupack update_flow_dupack_0 <- mkUpdateFlowDupack();
  UpdateFlowRcvd update_flow_rcvd_0 <- mkUpdateFlowRcvd();
  UpdateFlowRetx3Dupack update_flow_retx_3dupack_0 <- mkUpdateFlowRetx3Dupack();
  UpdateFlowRetxTimeout update_flow_retx_timeout_0 <- mkUpdateFlowRetxTimeout();
  UpdateFlowSent update_flow_sent_0 <- mkUpdateFlowSent();
  SetDmac set_dmac_0 <- mkSetDmac();
  Drop _drop_0 <- mkDrop();
  IncreaseMincwnd increase_mincwnd_0 <- mkIncreaseMincwnd();
  RecordIp record_IP_0 <- mkRecordIp();
  SetNhop set_nhop_0 <- mkSetNhop();
  Drop _drop_1 <- mkDrop();
  LookupFlowMap lookup_flow_map_0 <- mkLookupFlowMap();
  LookupFlowMapReverse lookup_flow_map_reverse_0 <- mkLookupFlowMapReverse();
  UseSampleRtt use_sample_rtt_0 <- mkUseSampleRtt();
  SampleNewRtt sample_new_rtt_0 <- mkSampleNewRtt();
  RegisterIfc#(1, 2) check_map <- mkP4Register();
  RegisterIfc#(2, 16) mss <- mkP4Register();
  RegisterIfc#(2, 8) wscale <- mkP4Register();
  RegisterIfc#(2, 32) sendIP <- mkP4Register();
  RegisterIfc#(2, 32) mincwnd <- mkP4Register();
  RegisterIfc#(2, 32) flight_size <- mkP4Register();
  RegisterIfc#(2, 16) flow_rwnd <- mkP4Register();
  RegisterIfc#(2, 32) flow_last_ack_rcvd <- mkP4Register();
  RegisterIfc#(2, 32) flow_last_seq_sent <- mkP4Register();
  RegisterIfc#(2, 32) flow_pkts_sent <- mkP4Register();
  RegisterIfc#(2, 32) flow_pkts_rcvd <- mkP4Register();
  RegisterIfc#(2, 32) flow_pkts_retx <- mkP4Register();
  RegisterIfc#(2, 32) flow_pkts_dup <- mkP4Register();
  RegisterIfc#(2, 32) ack_time <- mkP4Register();
  RegisterIfc#(2, 32) app_reaction_time <- mkP4Register();
  RegisterIfc#(2, 32) flow_srtt <- mkP4Register();
  RegisterIfc#(2, 32) rtt_samples <- mkP4Register();
  RegisterIfc#(2, 32) flow_rtt_sample_seq <- mkP4Register();
  RegisterIfc#(2, 32) flow_rtt_sample_time <- mkP4Register();
  RegisterIfc#(2, 32) srcIP <- mkP4Register();
  RegisterIfc#(2, 32) dstIP <- mkP4Register();
  RegisterIfc#(2, 32) metaIP <- mkP4Register();
  mkChan(mkFIFOF, mkFIFOF, debug.next_control_state_0, save_source_IP_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, direction.next_control_state_0, get_sender_IP_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, first_rtt_sample.next_control_state_0, use_sample_rtt_first_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_dupack.next_control_state_0, update_flow_dupack_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_rcvd.next_control_state_0, update_flow_rcvd_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_retx_3dupack.next_control_state_0, update_flow_retx_3dupack_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_retx_timeout.next_control_state_0, update_flow_retx_timeout_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, flow_sent.next_control_state_0, update_flow_sent_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_0, set_dmac_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_1, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, increase_cwnd.next_control_state_0, increase_mincwnd_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, init.next_control_state_0, record_IP_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_0, set_nhop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_1, _drop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, lookup.next_control_state_0, lookup_flow_map_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, lookup_reverse.next_control_state_0, lookup_flow_map_reverse_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, sample_rtt_rcvd.next_control_state_0, use_sample_rtt_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, sample_rtt_sent.next_control_state_0, sample_new_rtt_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    let ipv4$protocol = fromMaybe(?, meta.ipv4$protocol);
    let ipv4$srcAddr = fromMaybe(?, meta.ipv4$srcAddr);
    let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
    if (( ipv4$protocol == 'h6 )) begin
      if (( ipv4$srcAddr > ipv4$dstAddr )) begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        lookup_req_ff.enq(req);
      end
      else begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        lookup_reverse_req_ff.enq(req);
      end
    end
    else begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ipv4_lpm_req_ff.enq(req);
    end
  endrule

  rule debug_next_state if (debug_rsp_ff.notEmpty);
    debug_rsp_ff.deq;
    let _rsp = debug_rsp_ff.first;
    case (_rsp) matches
      tagged DebugSaveSourceIpRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule direction_next_state if (direction_rsp_ff.notEmpty);
    direction_rsp_ff.deq;
    let _rsp = direction_rsp_ff.first;
    case (_rsp) matches
      tagged DirectionGetSenderIpRspT {meta: .meta, pkt: .pkt}: begin
        let stats_metadata$seqNo = fromMaybe(?, meta.stats_metadata$seqNo);
        let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
        let stats_metadata$ackNo = fromMaybe(?, meta.stats_metadata$ackNo);
        let tcp$ackNo = fromMaybe(?, meta.tcp$ackNo);
        let stats_metadata$senderIP = fromMaybe(?, meta.stats_metadata$senderIP);
        let stats_metadata$dupack = fromMaybe(?, meta.stats_metadata$dupack);
        let ipv4$srcAddr = fromMaybe(?, meta.ipv4$srcAddr);
        let tcp$seqNo = fromMaybe(?, meta.tcp$seqNo);
        if (( ipv4$srcAddr == stats_metadata$senderIP )) begin
          if (( tcp$seqNo > stats_metadata$seqNo )) begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            flow_sent_req_ff.enq(req);
          end
          else begin
            if (( stats_metadata$dupack == 'h3 )) begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_retx_3dupack_req_ff.enq(req);
            end
            else begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_retx_timeout_req_ff.enq(req);
            end
          end
        end
        else begin
          if (( ipv4$dstAddr == stats_metadata$senderIP )) begin
            if (( tcp$ackNo > stats_metadata$ackNo )) begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_rcvd_req_ff.enq(req);
            end
            else begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_dupack_req_ff.enq(req);
            end
          end
          else begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            debug_req_ff.enq(req);
          end
        end
      end
    endcase
  endrule

  rule first_rtt_sample_next_state if (first_rtt_sample_rsp_ff.notEmpty);
    first_rtt_sample_rsp_ff.deq;
    let _rsp = first_rtt_sample_rsp_ff.first;
    case (_rsp) matches
      tagged FirstRttSampleUseSampleRttFirstRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule flow_dupack_next_state if (flow_dupack_rsp_ff.notEmpty);
    flow_dupack_rsp_ff.deq;
    let _rsp = flow_dupack_rsp_ff.first;
    case (_rsp) matches
      tagged FlowDupackUpdateFlowDupackRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule flow_rcvd_next_state if (flow_rcvd_rsp_ff.notEmpty);
    flow_rcvd_rsp_ff.deq;
    let _rsp = flow_rcvd_rsp_ff.first;
    case (_rsp) matches
      tagged FlowRcvdUpdateFlowRcvdRspT {meta: .meta, pkt: .pkt}: begin
        let stats_metadata$rtt_samples = fromMaybe(?, meta.stats_metadata$rtt_samples);
        let tcp$ackNo = fromMaybe(?, meta.tcp$ackNo);
        let stats_metadata$sample_rtt_seq = fromMaybe(?, meta.stats_metadata$sample_rtt_seq);
        if (( ( tcp$ackNo >= stats_metadata$sample_rtt_seq ) && ( stats_metadata$sample_rtt_seq > 'h0 ) )) begin
          if (( stats_metadata$rtt_samples == 'h0 )) begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            first_rtt_sample_req_ff.enq(req);
          end
          else begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            sample_rtt_rcvd_req_ff.enq(req);
          end
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          ipv4_lpm_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule flow_retx_3dupack_next_state if (flow_retx_3dupack_rsp_ff.notEmpty);
    flow_retx_3dupack_rsp_ff.deq;
    let _rsp = flow_retx_3dupack_rsp_ff.first;
    case (_rsp) matches
      tagged FlowRetx3DupackUpdateFlowRetx3DupackRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule flow_retx_timeout_next_state if (flow_retx_timeout_rsp_ff.notEmpty);
    flow_retx_timeout_rsp_ff.deq;
    let _rsp = flow_retx_timeout_rsp_ff.first;
    case (_rsp) matches
      tagged FlowRetxTimeoutUpdateFlowRetxTimeoutRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule flow_sent_next_state if (flow_sent_rsp_ff.notEmpty);
    flow_sent_rsp_ff.deq;
    let _rsp = flow_sent_rsp_ff.first;
    case (_rsp) matches
      tagged FlowSentUpdateFlowSentRspT {meta: .meta, pkt: .pkt}: begin
        let stats_metadata$dummy = fromMaybe(?, meta.stats_metadata$dummy);
        let stats_metadata$mincwnd = fromMaybe(?, meta.stats_metadata$mincwnd);
        let stats_metadata$sample_rtt_seq = fromMaybe(?, meta.stats_metadata$sample_rtt_seq);
        if (( stats_metadata$sample_rtt_seq == 'h0 )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          sample_rtt_sent_req_ff.enq(req);
        end
        else begin
          if (( stats_metadata$dummy > stats_metadata$mincwnd )) begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            increase_cwnd_req_ff.enq(req);
          end
          else begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            ipv4_lpm_req_ff.enq(req);
          end
        end
      end
    endcase
  endrule

  rule forward_next_state if (forward_rsp_ff.notEmpty);
    forward_rsp_ff.deq;
    let _rsp = forward_rsp_ff.first;
    case (_rsp) matches
      tagged ForwardSetDmacRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged ForwardDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule increase_cwnd_next_state if (increase_cwnd_rsp_ff.notEmpty);
    increase_cwnd_rsp_ff.deq;
    let _rsp = increase_cwnd_rsp_ff.first;
    case (_rsp) matches
      tagged IncreaseCwndIncreaseMincwndRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule init_next_state if (init_rsp_ff.notEmpty);
    init_rsp_ff.deq;
    let _rsp = init_rsp_ff.first;
    case (_rsp) matches
      tagged InitRecordIpRspT {meta: .meta, pkt: .pkt}: begin
        let stats_metadata$seqNo = fromMaybe(?, meta.stats_metadata$seqNo);
        let ipv4$dstAddr = fromMaybe(?, meta.ipv4$dstAddr);
        let stats_metadata$ackNo = fromMaybe(?, meta.stats_metadata$ackNo);
        let tcp$ackNo = fromMaybe(?, meta.tcp$ackNo);
        let stats_metadata$senderIP = fromMaybe(?, meta.stats_metadata$senderIP);
        let stats_metadata$dupack = fromMaybe(?, meta.stats_metadata$dupack);
        let ipv4$srcAddr = fromMaybe(?, meta.ipv4$srcAddr);
        let tcp$seqNo = fromMaybe(?, meta.tcp$seqNo);
        if (( ipv4$srcAddr == stats_metadata$senderIP )) begin
          if (( tcp$seqNo > stats_metadata$seqNo )) begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            flow_sent_req_ff.enq(req);
          end
          else begin
            if (( stats_metadata$dupack == 'h3 )) begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_retx_3dupack_req_ff.enq(req);
            end
            else begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_retx_timeout_req_ff.enq(req);
            end
          end
        end
        else begin
          if (( ipv4$dstAddr == stats_metadata$senderIP )) begin
            if (( tcp$ackNo > stats_metadata$ackNo )) begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_rcvd_req_ff.enq(req);
            end
            else begin
              MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
              flow_dupack_req_ff.enq(req);
            end
          end
          else begin
            MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
            debug_req_ff.enq(req);
          end
        end
      end
    endcase
  endrule

  rule ipv4_lpm_next_state if (ipv4_lpm_rsp_ff.notEmpty);
    ipv4_lpm_rsp_ff.deq;
    let _rsp = ipv4_lpm_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv4LpmSetNhopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        forward_req_ff.enq(req);
      end
      tagged Ipv4LpmDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        forward_req_ff.enq(req);
      end
    endcase
  endrule

  rule lookup_next_state if (lookup_rsp_ff.notEmpty);
    lookup_rsp_ff.deq;
    let _rsp = lookup_rsp_ff.first;
    case (_rsp) matches
      tagged LookupLookupFlowMapRspT {meta: .meta, pkt: .pkt}: begin
        let tcp$ack = fromMaybe(?, meta.tcp$ack);
        let tcp$syn = fromMaybe(?, meta.tcp$syn);
        if (( ( tcp$syn == 'h1 ) && ( tcp$ack == 'h0 ) )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          init_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          direction_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule lookup_reverse_next_state if (lookup_reverse_rsp_ff.notEmpty);
    lookup_reverse_rsp_ff.deq;
    let _rsp = lookup_reverse_rsp_ff.first;
    case (_rsp) matches
      tagged LookupReverseLookupFlowMapReverseRspT {meta: .meta, pkt: .pkt}: begin
        let tcp$ack = fromMaybe(?, meta.tcp$ack);
        let tcp$syn = fromMaybe(?, meta.tcp$syn);
        if (( ( tcp$syn == 'h1 ) && ( tcp$ack == 'h0 ) )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          init_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          direction_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule sample_rtt_rcvd_next_state if (sample_rtt_rcvd_rsp_ff.notEmpty);
    sample_rtt_rcvd_rsp_ff.deq;
    let _rsp = sample_rtt_rcvd_rsp_ff.first;
    case (_rsp) matches
      tagged SampleRttRcvdUseSampleRttRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_lpm_req_ff.enq(req);
      end
    endcase
  endrule

  rule sample_rtt_sent_next_state if (sample_rtt_sent_rsp_ff.notEmpty);
    sample_rtt_sent_rsp_ff.deq;
    let _rsp = sample_rtt_sent_rsp_ff.first;
    case (_rsp) matches
      tagged SampleRttSentSampleNewRttRspT {meta: .meta, pkt: .pkt}: begin
        let stats_metadata$dummy = fromMaybe(?, meta.stats_metadata$dummy);
        let stats_metadata$mincwnd = fromMaybe(?, meta.stats_metadata$mincwnd);
        if (( stats_metadata$dummy > stats_metadata$mincwnd )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          increase_cwnd_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          ipv4_lpm_req_ff.enq(req);
        end
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
  FIFOF#(MetadataRequest) send_frame_req_ff <- mkFIFOF;
  FIFOF#(SendFrameResponse) send_frame_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  SendFrame send_frame <- mkSendFrame();
  mkConnection(toClient(send_frame_req_ff, send_frame_rsp_ff), send_frame.prev_control_state_0);
  // Basic Blocks
  RewriteMac rewrite_mac_0 <- mkRewriteMac();
  Drop _drop_0 <- mkDrop();
  RegisterIfc#(1, 2) check_map <- mkP4Register(nil);
  RegisterIfc#(2, 16) mss <- mkP4Register(nil);
  RegisterIfc#(2, 8) wscale <- mkP4Register(nil);
  RegisterIfc#(2, 32) sendIP <- mkP4Register(nil);
  RegisterIfc#(2, 32) mincwnd <- mkP4Register(nil);
  RegisterIfc#(2, 32) flight_size <- mkP4Register(nil);
  RegisterIfc#(2, 16) flow_rwnd <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_last_ack_rcvd <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_last_seq_sent <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_pkts_sent <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_pkts_rcvd <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_pkts_retx <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_pkts_dup <- mkP4Register(nil);
  RegisterIfc#(2, 32) ack_time <- mkP4Register(nil);
  RegisterIfc#(2, 32) app_reaction_time <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_srtt <- mkP4Register(nil);
  RegisterIfc#(2, 32) rtt_samples <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_rtt_sample_seq <- mkP4Register(nil);
  RegisterIfc#(2, 32) flow_rtt_sample_time <- mkP4Register(nil);
  RegisterIfc#(2, 32) srcIP <- mkP4Register(nil);
  RegisterIfc#(2, 32) dstIP <- mkP4Register(nil);
  RegisterIfc#(2, 32) metaIP <- mkP4Register(nil);
  mkChan(mkFIFOF, mkFIFOF, send_frame.next_control_state_0, rewrite_mac_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, send_frame.next_control_state_1, _drop_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    send_frame_req_ff.enq(req);
  endrule

  rule send_frame_next_state if (send_frame_rsp_ff.notEmpty);
    send_frame_rsp_ff.deq;
    let _rsp = send_frame_rsp_ff.first;
    case (_rsp) matches
      tagged SendFrameRewriteMacRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged SendFrameDropRspT {meta: .meta, pkt: .pkt}: begin
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
