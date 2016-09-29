import StructDefines::*;
import UnionDefines::*;
import ConnectalTypes::*;
import CPU::*;
import IMem::*;
import Lists::*;
import TxRx::*;
import TieOff::*;
import FIFOF::*;
import Pipe::*;
import ConfigReg::*;
import StructDefines::*;
import Table::*;
import Engine::*;
import PrintTrace::*;

`include "TieOff.defines"
`include "Debug.defines"
`include "SynthBuilder.defines"
`include "MatchTable.defines"
`MATCHTABLE_SIM(29, 36, 50)

typedef enum {
    NOACTION3,
    SETDMAC,
    DROP2
} ForwardActionT deriving (Bits, Eq, FShow);

typedef Table#(3, MetadataRequest,
                  ForwardActionReq,
                  ConnectalTypes::ForwardReqT,
                  ConnectalTypes::ForwardRspT) ForwardTable;

function ConnectalTypes::ForwardReqT forward_build_lookup_request();
   let v = ConnectalTypes::ForwardReqT {padding: 0, nhop_ipv4: 1};
   return v;
endfunction

function Action execute_action(ConnectalTypes::ForwardRspT resp,
                               MetadataRequest metadata,
                               Vector#(3, FIFOF#(Tuple2#(MetadataRequest, ForwardActionReq))) bbReqFifo);
   action
      $display("(%0d) execute action ", $time, fshow(resp._action));
      case (unpack(resp._action)) matches
         SETDMAC: begin
            ForwardActionReq req = tagged SetDmacReqT {dmac: resp.dmac};
            bbReqFifo[0].enq(tuple2(metadata, req));
         end
         DROP2: begin
            bbReqFifo[1].enq(tuple2(metadata, ?));
         end
         NOACTION3: begin
            bbReqFifo[2].enq(tuple2(metadata, ?));
         end
      endcase
   endaction
endfunction

function ActionValue#(MetadataRequest) step1(MetadataRequest meta, ForwardActionReq param);
   actionvalue
      $display("(%0d) step 1: ", $time, fshow(meta));
      return meta;
   endactionvalue
endfunction

function ActionValue#(MetadataRequest) step2(MetadataRequest meta, ForwardActionReq param);
   actionvalue
      $display("(%0d) step 2: ", $time, fshow(meta));
      return meta;
   endactionvalue
endfunction

typedef MatchTable#(29, 256, SizeOf#(ConnectalTypes::ForwardReqT), SizeOf#(ConnectalTypes::ForwardRspT)) ForwardMatchTable;
typedef Engine#(2, MetadataRequest, ForwardActionReq) ForwardAction;

`SynthBuildModule1(mkMatchTable, String, ForwardMatchTable, mkMatchTable_256_Forward)

interface Ingress;
   interface PipeIn#(MetadataRequest) prev;
   interface PipeOut#(MetadataRequest) next;
   method Action set_verbosity(int verbosity);
`include "APIDefGenerated.bsv"
endinterface
module mkIngress(Ingress);
   `PRINT_DEBUG_MSG

   FIFOF#(MetadataRequest) entry_req_ff <- mkSizedFIFOF(16);
   FIFOF#(MetadataRequest) forward_req_ff <- mkSizedFIFOF(16);
   FIFOF#(MetadataRequest) forward_rsp_ff <- mkSizedFIFOF(16);
   FIFOF#(MetadataRequest) exit_req_ff <- mkSizedFIFOF(16);

   ForwardMatchTable matchTable <- mkMatchTable_256_Forward("forward");
   let fvec = vec(step1, step2);
   let flist = toList(fvec);
   ForwardAction forward_action <- mkEngine(flist);
   ForwardTable forward <- mkTable(forward_build_lookup_request, execute_action, matchTable);

   mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state);
   //mkChan(mkFIFOF, mkFIFOF, forward.next_control_state[0], forward_action.prev_control_state);
   mkConnection(forward.next_control_state[0], forward_action.prev_control_state);

   rule rl_entry if (entry_req_ff.notEmpty);
      entry_req_ff.deq;
      let _req = entry_req_ff.first;
      let meta = _req.meta;
      let pkt = _req.pkt;
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      forward_req_ff.enq(req);
      dbprint(3, $format("forward", fshow(meta)));
   endrule

   rule rl_forward if (forward_rsp_ff.notEmpty);
      forward_rsp_ff.deq;
      let req = forward_rsp_ff.first;
      exit_req_ff.enq(req);
   endrule

   interface prev = toPipeIn(entry_req_ff);
   interface next = toPipeOut(exit_req_ff);
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
      forward.set_verbosity(verbosity);
      forward_action.set_verbosity(verbosity);
   endmethod
   method forward_add_entry=forward.add_entry;
endmodule

interface Egress;
   interface PipeIn#(MetadataRequest) prev;
   interface PipeOut#(MetadataRequest) next;
   method Action set_verbosity(int verbosity);
endinterface
module mkEgress(Egress);
   `PRINT_DEBUG_MSG
   FIFOF#(MetadataRequest) entry_req_ff <- mkSizedFIFOF(16);
   FIFOF#(MetadataRequest) exit_req_ff <- mkSizedFIFOF(16);

   rule rl_entry if (entry_req_ff.notEmpty);
      entry_req_ff.deq;
      let _req = entry_req_ff.first;
      let meta = _req.meta;
      let pkt = _req.pkt;
      MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
      exit_req_ff.enq(req);
      dbprint(3, $format("bypass", fshow(meta)));
   endrule
   interface prev = toPipeIn(entry_req_ff);
   interface next = toPipeOut(exit_req_ff);
   method Action set_verbosity(int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
