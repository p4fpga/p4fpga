
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
  method Action set_verbosity (int verbosity);
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
  Reg#(int) cf_verbosity <- mkConfigRegU;
  function Action dbprint(Integer level, Fmt msg);
    action
    if (cf_verbosity > fromInteger(level)) begin
      $display("(%d) ", $time, msg);
    end
    endaction
  endfunction

  FIFOF#(MetadataRequest) default_req_ff <- printTimedTraceM("default_req", mkFIFOF);
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) forward_req_ff <- printTimedTraceM("forward_req", mkFIFOF);
  FIFOF#(ForwardResponse) forward_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- printTimedTraceM("ipv4_req", mkFIFOF);
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
    let ipv4$ttl = fromMaybe(?, meta.ipv4$ttl);
    if (( ( isValid ( meta.valid_ipv4 ) ) && ( ipv4$ttl > 'h0 ) )) begin
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      ipv4_lpm_req_ff.enq(req);
    end
    else begin
      dbprint(3, $format("dropped", fshow(meta.ipv4$ttl)));
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
    dbprint(3, $format("lpm rsp", fshow(_rsp)));
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
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    set_dmac_0.set_verbosity(verbosity);
    _drop_0.set_verbosity(verbosity);
    set_nhop_0.set_verbosity(verbosity);
    _drop_1.set_verbosity(verbosity);
    forward.set_verbosity(verbosity);
    ipv4_lpm.set_verbosity(verbosity);
  endmethod
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
