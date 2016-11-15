import Library::*;
import StructDefines::*;
import UnionDefines::*;
import ConnectalTypes::*;
import Table::*;
import Engine::*;
import Pipe::*;
import Lists::*;
`include "TieOff.defines"
`include "Debug.defines"
`include "SynthBuilder.defines"
`include "MatchTable.defines"
typedef enum {
    FORWARD,
    DROP,
    NOACTION1
} ForwardTableActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(25, 54, 11, forward_table)
typedef Table#(3, MetadataRequest, ForwardTableParam, ConnectalTypes::ForwardTableReqT, ConnectalTypes::ForwardTableRspT) ForwardTableTable;
typedef MatchTable#(1, 25, 256, SizeOf#(ConnectalTypes::ForwardTableReqT), SizeOf#(ConnectalTypes::ForwardTableRspT)) ForwardTableMatchTable;
`SynthBuildModule1(mkMatchTable, String, ForwardTableMatchTable, mkMatchTable_ForwardTable)
instance Table_request #(ConnectalTypes::ForwardTableReqT);
    function ConnectalTypes::ForwardTableReqT table_request(MetadataRequest data);
        ConnectalTypes::ForwardTableReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
           let dstAddr = ethernet.hdr.dstAddr;
           v = ConnectalTypes::ForwardTableReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::ForwardTableRspT, ForwardTableParam, 3);
    function Action table_execute(ConnectalTypes::ForwardTableRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, ForwardTableParam))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD: begin
                ForwardTableParam req = tagged ForwardReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            DROP: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION1: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardTableParam) NoAction1Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, ForwardTableParam) DropAction;
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, ForwardTableParam) ForwardAction;
instance Action_execute #(ForwardTableParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, ForwardTableParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// =============== control ingress ==============
interface Ingress;
    interface PipeIn#(MetadataRequest) prev;
    interface PipeOut#(MetadataRequest) next;
    method Action forward_table_add_entry(ConnectalTypes::ForwardTableReqT key, ConnectalTypes::ForwardTableRspT value);
    method Action set_verbosity(int verbosity);
endinterface
module mkIngress (Ingress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction1Action noAction1_action <- mkEngine(toList(vec(step_1)));
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::ForwardAction forward_action <- mkEngine(toList(vec(step_1)));
    ForwardTableMatchTable forward_table_table <- mkMatchTable_ForwardTable("forward_table");
    Control::ForwardTableTable forward_table <- mkTable(table_request, table_execute, forward_table_table);
    messageM(printType(typeOf(forward_table_table)));
    messageM(printType(typeOf(forward_table)));
    mkConnection(toClient(forward_table_req_ff, forward_table_rsp_ff), forward_table.prev_control_state);
    mkConnection(forward_table.next_control_state[0], forward_action.prev_control_state);
    mkConnection(forward_table.next_control_state[1], drop_action.prev_control_state);
    mkConnection(forward_table.next_control_state[2], noAction1_action.prev_control_state);
    rule rl_entry if (entry_req_ff.notEmpty);
        entry_req_ff.deq;
        let _req = entry_req_ff.first;
        let meta = _req.meta;
        let pkt = _req.pkt;
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        forward_table_req_ff.enq(req);
        dbprint(3, $format("forward_table", fshow(meta)));
    endrule
    rule rl_forward_table if (forward_table_rsp_ff.notEmpty);
        forward_table_rsp_ff.deq;
        let _rsp = forward_table_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                exit_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    interface prev = toPipeIn(entry_req_ff);
    interface next = toPipeOut(exit_req_ff);
    method forward_table_add_entry = forward_table.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        forward_table.set_verbosity(verbosity);
    endmethod
endmodule
// =============== control egress ==============
interface Egress;
    interface PipeIn#(MetadataRequest) prev;
    interface PipeOut#(MetadataRequest) next;
    method Action set_verbosity(int verbosity);
endinterface
module mkEgress (Egress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    rule rl_entry if (entry_req_ff.notEmpty);
        entry_req_ff.deq;
        let _req = entry_req_ff.first;
        let meta = _req.meta;
        let pkt = _req.pkt;
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        exit_req_ff.enq(req);
        dbprint(3, $format("exit", fshow(meta)));
    endrule
    interface prev = toPipeIn(entry_req_ff);
    interface next = toPipeOut(exit_req_ff);
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
