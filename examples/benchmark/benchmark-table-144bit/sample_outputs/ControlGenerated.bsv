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

`define HASH 1
`define BCAM 2
`define TCAM 3

typedef enum {
    FORWARD,
    DROP,
    NOACTION1
} ForwardTableActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(19, 144, 11, forward_table)
typedef Table#(3, MetadataRequest, ForwardTableParam, ConnectalTypes::ForwardTableReqT, ConnectalTypes::ForwardTableRspT) ForwardTableTable;
typedef MatchTable#(`HASH, 19, 1024, SizeOf#(ConnectalTypes::ForwardTableReqT), SizeOf#(ConnectalTypes::ForwardTableRspT)) ForwardTableMatchTable;
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
typedef enum {
    MODHEADERS,
    NOACTION2
} TestTblActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(23, 0, 1, test_tbl)
typedef Table#(2, MetadataRequest, TestTblParam, ConnectalTypes::TestTblReqT, ConnectalTypes::TestTblRspT) TestTblTable;
typedef MatchTable#(`HASH, 23, 256, SizeOf#(ConnectalTypes::TestTblReqT), SizeOf#(ConnectalTypes::TestTblRspT)) TestTblMatchTable;
`SynthBuildModule1(mkMatchTable, String, TestTblMatchTable, mkMatchTable_TestTbl)
//TestTblMatchTable 
instance Table_request #(ConnectalTypes::TestTblReqT);
    function ConnectalTypes::TestTblReqT table_request(MetadataRequest data);
        let v = 0; //ConnectalTypes::TestTblReqT {};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TestTblRspT, TestTblParam, 2);
    function Action table_execute(ConnectalTypes::TestTblRspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, TestTblParam))) fifos);
        action
        case (unpack(resp._action)) matches
            MODHEADERS: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            NOACTION2: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardTableParam) NoAction1Action;
typedef Engine#(1, MetadataRequest, TestTblParam) NoAction2Action;
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
// INST (16) hdr.header_0.field_0; = 1
// INST (16) hdr.header_0.field_1; = 1
// INST (16) hdr.header_0.field_2; = 1
// INST (16) hdr.header_0.field_3; = 1
// INST (16) hdr.header_0.field_4; = 1
// INST (16) hdr.header_0.field_5; = 1
// INST (16) hdr.header_0.field_6; = 1
// INST (16) hdr.header_0.field_7; = 1
// INST (16) hdr.header_0.field_8; = 1
// INST (16) hdr.header_0.field_9; = 1
// INST (16) hdr.header_0.field_10; = 1
// INST (16) hdr.header_0.field_11; = 1
// INST (16) hdr.header_0.field_12; = 1
// INST (16) hdr.header_0.field_13; = 1
// INST (16) hdr.header_0.field_14; = 1
// INST (16) hdr.header_0.field_15; = 1
typedef Engine#(1, MetadataRequest, TestTblParam) ModHeadersAction;
instance Action_execute #(TestTblParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest req, TestTblParam param);
        actionvalue
            let new_header_0 = req.meta.hdr.header_0;
            $display("(%0d) step 1: ", $time, fshow(req));
            if (isValid(new_header_0)) begin
               let header_0 = fromMaybe(?, new_header_0);
               header_0.hdr.field_0 = 1;
               header_0.hdr.field_1 = 1;
               header_0.hdr.field_2 = 1;
               header_0.hdr.field_3 = 1;
               header_0.hdr.field_4 = 1;
               header_0.hdr.field_5 = 1;
               header_0.hdr.field_6 = 1;
               header_0.hdr.field_7 = 1;
               header_0.hdr.field_8 = 1;
               header_0.hdr.field_9 = 1;
               header_0.hdr.field_10 = 1;
               header_0.hdr.field_11 = 1;
               header_0.hdr.field_12 = 1;
               header_0.hdr.field_13 = 1;
               header_0.hdr.field_14 = 1;
               header_0.hdr.field_15 = 1;
               new_header_0 = tagged Valid header_0;
            end
            req.meta.hdr.header_0 = new_header_0;
            return req;
        endactionvalue
    endfunction
endinstance
// =============== control ingress ==============
interface Ingress;
    interface PipeIn#(MetadataRequest) prev;
    interface PipeOut#(MetadataRequest) next;
    method Action forward_table_add_entry(ConnectalTypes::ForwardTableReqT key, ConnectalTypes::ForwardTableRspT value);
    method Action test_tbl_add_entry(ConnectalTypes::TestTblReqT key, ConnectalTypes::TestTblRspT value);
    method Action set_verbosity(int verbosity);
endinterface
module mkIngress (Ingress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) test_tbl_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) test_tbl_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction1Action noAction1_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction2Action noAction2_action <- mkEngine(toList(vec(step_1)));
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::ForwardAction forward_action <- mkEngine(toList(vec(step_1)));
    Control::ModHeadersAction modheaders_action <- mkEngine(toList(vec(step_1)));
    ForwardTableMatchTable forward_table_table <- mkMatchTable_ForwardTable("forward_table");
    Control::ForwardTableTable forward_table <- mkTable(table_request, table_execute, forward_table_table);
    messageM(printType(typeOf(forward_table_table)));
    messageM(printType(typeOf(forward_table)));
    TestTblMatchTable test_tbl_table <- mkMatchTable_TestTbl("test_tbl");
    Control::TestTblTable test_tbl <- mkTable(table_request, table_execute, test_tbl_table);
    messageM(printType(typeOf(test_tbl_table)));
    messageM(printType(typeOf(test_tbl)));
    mkConnection(toClient(forward_table_req_ff, forward_table_rsp_ff), forward_table.prev_control_state);
    mkConnection(forward_table.next_control_state[0], forward_action.prev_control_state);
    mkConnection(forward_table.next_control_state[1], drop_action.prev_control_state);
    mkConnection(forward_table.next_control_state[2], noAction1_action.prev_control_state);
    mkConnection(toClient(test_tbl_req_ff, test_tbl_rsp_ff), test_tbl.prev_control_state);
    mkConnection(test_tbl.next_control_state[0], modheaders_action.prev_control_state);
    mkConnection(test_tbl.next_control_state[1], noAction2_action.prev_control_state);
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
                test_tbl_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_test_tbl if (test_tbl_rsp_ff.notEmpty);
        test_tbl_rsp_ff.deq;
        let _rsp = test_tbl_rsp_ff.first;
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
    method test_tbl_add_entry = test_tbl.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        forward_table.set_verbosity(verbosity);
        test_tbl.set_verbosity(verbosity);
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
