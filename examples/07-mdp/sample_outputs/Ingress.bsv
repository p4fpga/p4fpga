
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
import Dedup::*;
import Drop::*;
import Forward::*;
import TblBloomfilter::*;
import TblDrop::*;
import TblForward::*;
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

  FIFOF#(MetadataRequest) default_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) default_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) tbl_bloomfilter_req_ff <- mkFIFOF;
  FIFOF#(TblBloomfilterResponse) tbl_bloomfilter_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) tbl_drop_req_ff <- mkFIFOF;
  FIFOF#(TblDropResponse) tbl_drop_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) tbl_forward_req_ff <- mkFIFOF;
  FIFOF#(TblForwardResponse) tbl_forward_rsp_ff <- mkFIFOF;
  FIFOF#(MetadataRequest) next_req_ff <- mkFIFOF;
  FIFOF#(MetadataResponse) next_rsp_ff <- mkFIFOF;
  Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));
  mkConnection(mds, mdc);
  TblBloomfilter tbl_bloomfilter <- mkTblBloomfilter();
  TblDrop tbl_drop <- mkTblDrop();
  TblForward tbl_forward <- mkTblForward();
  mkConnection(toClient(tbl_bloomfilter_req_ff, tbl_bloomfilter_rsp_ff), tbl_bloomfilter.prev_control_state_0);
  mkConnection(toClient(tbl_drop_req_ff, tbl_drop_rsp_ff), tbl_drop.prev_control_state_0);
  mkConnection(toClient(tbl_forward_req_ff, tbl_forward_rsp_ff), tbl_forward.prev_control_state_0);
  // Basic Blocks
  Dedup dedup_0 <- mkDedup();
  Drop drop_0 <- mkDrop();
  Forward forward_0 <- mkForward();
  mkChan(mkFIFOF, mkFIFOF, tbl_bloomfilter.next_control_state_0, dedup_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, tbl_drop.next_control_state_0, drop_0.prev_control_state);
  mkChan(mkFIFOF, mkFIFOF, tbl_forward.next_control_state_0, forward_0.prev_control_state);
  rule default_next_state if (default_req_ff.notEmpty);
    default_req_ff.deq;
    let _req = default_req_ff.first;
    let meta = _req.meta;
    let pkt = _req.pkt;
    MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
    tbl_bloomfilter_req_ff.enq(req);
  endrule

  rule tbl_bloomfilter_next_state if (tbl_bloomfilter_rsp_ff.notEmpty);
    tbl_bloomfilter_rsp_ff.deq;
    let _rsp = tbl_bloomfilter_rsp_ff.first;
    case (_rsp) matches
      tagged TblBloomfilterDedupRspT {meta: .meta, pkt: .pkt}: begin
        let dedup$notPresent = fromMaybe(?, meta.dedup$notPresent);
        if (( dedup$notPresent == 'h1 )) begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          tbl_forward_req_ff.enq(req);
        end
        else begin
          MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
          tbl_drop_req_ff.enq(req);
        end
      end
    endcase
  endrule

  rule tbl_drop_next_state if (tbl_drop_rsp_ff.notEmpty);
    tbl_drop_rsp_ff.deq;
    let _rsp = tbl_drop_rsp_ff.first;
    case (_rsp) matches
      tagged TblDropDropRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  rule tbl_forward_next_state if (tbl_forward_rsp_ff.notEmpty);
    tbl_forward_rsp_ff.deq;
    let _rsp = tbl_forward_rsp_ff.first;
    case (_rsp) matches
      tagged TblForwardForwardRspT {meta: .meta, pkt: .pkt}: begin
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        next_req_ff.enq(req);
      end
    endcase
  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(next_req_ff);
    interface response = toPut(next_rsp_ff);
  endinterface);
  method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    dedup_0.set_verbosity(verbosity);
    drop_0.set_verbosity(verbosity);
    forward_0.set_verbosity(verbosity);
    tbl_bloomfilter.set_verbosity(verbosity);
    tbl_drop.set_verbosity(verbosity);
    tbl_forward.set_verbosity(verbosity);
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
