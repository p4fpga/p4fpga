
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
import Ipv4Packet::*;
import Ipv6Packet::*;
import L2Packet::*;
import MimPacket::*;
import MplsPacket::*;
import Nop::*;
import SetEgressPort::*;
import EthertypeMatch::*;
import Ipv4Match::*;
import Ipv6Match::*;
import L2Match::*;
import UnionGenerated::*;

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ethertype_match_req_ff <- mkFIFOF;
  FIFOF#(EthertypeMatchResponse) ethertype_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_match_req_ff <- mkFIFOF;
  FIFOF#(Ipv4MatchResponse) ipv4_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv6_match_req_ff <- mkFIFOF;
  FIFOF#(Ipv6MatchResponse) ipv6_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) l2_match_req_ff <- mkFIFOF;
  FIFOF#(L2MatchResponse) l2_match_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  EthertypeMatch ethertype_match <- mkEthertypeMatch();
  Ipv4Match ipv4_match <- mkIpv4Match();
  Ipv6Match ipv6_match <- mkIpv6Match();
  L2Match l2_match <- mkL2Match();
  mkConnection(toClient(ethertype_match_req_ff, ethertype_match_rsp_ff), ethertype_match.prev_control_state_0);
  mkConnection(toClient(ipv4_match_req_ff, ipv4_match_rsp_ff), ipv4_match.prev_control_state_0);
  mkConnection(toClient(ipv6_match_req_ff, ipv6_match_rsp_ff), ipv6_match.prev_control_state_0);
  mkConnection(toClient(l2_match_req_ff, l2_match_rsp_ff), l2_match.prev_control_state_0);
  // Basic Blocks
  L2Packet l2_packet_0 <- mkL2Packet();
  Ipv4Packet ipv4_packet_0 <- mkIpv4Packet();
  Ipv6Packet ipv6_packet_0 <- mkIpv6Packet();
  MplsPacket mpls_packet_0 <- mkMplsPacket();
  MimPacket mim_packet_0 <- mkMimPacket();
  Nop nop_0 <- mkNop();
  SetEgressPort set_egress_port_0 <- mkSetEgressPort();
  Nop nop_1 <- mkNop();
  SetEgressPort set_egress_port_1 <- mkSetEgressPort();
  Nop nop_2 <- mkNop();
  SetEgressPort set_egress_port_2 <- mkSetEgressPort();
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_0, l2_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_1, ipv4_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_2, ipv6_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_3, mpls_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ethertype_match.next_control_state_4, mim_packet_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_0, nop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_match.next_control_state_1, set_egress_port_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_0, nop_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv6_match.next_control_state_1, set_egress_port_1.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_0, nop_2.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, l2_match.next_control_state_1, set_egress_port_2.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    ethertype_match_req_ff.enq(req);
  endrule

  rule ethertype_match_next_state if (ethertype_match_rsp_ff.notEmpty);
    ethertype_match_rsp_ff.deq;
    let _rsp = ethertype_match_rsp_ff.first;
    case (_rsp) matches
      tagged EthertypeMatchL2PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv4PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv4_match_req_ff.enq(req);
      end
      tagged EthertypeMatchIpv6PacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMplsPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        ipv6_match_req_ff.enq(req);
      end
      tagged EthertypeMatchMimPacketRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        l2_match_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv4_match_next_state if (ipv4_match_rsp_ff.notEmpty);
    ipv4_match_rsp_ff.deq;
    let _rsp = ipv4_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv4MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv4MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule ipv6_match_next_state if (ipv6_match_rsp_ff.notEmpty);
    ipv6_match_rsp_ff.deq;
    let _rsp = ipv6_match_rsp_ff.first;
    case (_rsp) matches
      tagged Ipv6MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged Ipv6MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule l2_match_next_state if (l2_match_rsp_ff.notEmpty);
    l2_match_rsp_ff.deq;
    let _rsp = l2_match_rsp_ff.first;
    case (_rsp) matches
      tagged L2MatchNopRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
      tagged L2MatchSetEgressPortRspT {meta: .meta, pkt: .pkt}: begin
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

// ====== EGRESS ======

interface Egress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  // Basic Blocks
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    next_req_ff.enq(req);
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
