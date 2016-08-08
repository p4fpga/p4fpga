
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
import RewriteMac::*;
import SetDmac::*;
import SetNhop::*;
import Forward::*;
import Ipv4Lpm::*;
import SendFrame::*;
import UnionGenerated::*;

// ====== INGRESS ======

interface Ingress;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_req_ff <- mkFIFOF;
  FIFOF#(ForwardResponse) forward_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- mkFIFOF;
  FIFOF#(Ipv4LpmResponse) ipv4_lpm_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  Forward forward <- mkForward();
  Ipv4Lpm ipv4_lpm <- mkIpv4Lpm();
  mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state_0);
  mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state_0);
  // Basic Blocks
  SetDmac set_dmac_0 <- mkSetDmac();
  Drop _drop_0 <- mkDrop();
  SetNhop set_nhop_0 <- mkSetNhop();
  Drop _drop_1 <- mkDrop();
  mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_0, set_dmac_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_1, _drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_0, set_nhop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_1, _drop_1.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    if (( ( isValid ( meta.valid_ipv4 ) ) && ( ipv4$ttl > 'h0 ) )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ipv4_lpm_req_ff.enq(req);
    end
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
