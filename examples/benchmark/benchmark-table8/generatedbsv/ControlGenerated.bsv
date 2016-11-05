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
`MATCHTABLE_SIM(14, 54, 11, forward_table)
typedef Table#(3, MetadataRequest, ForwardTableParam, ConnectalTypes::ForwardTableReqT, ConnectalTypes::ForwardTableRspT) ForwardTableTable;
typedef MatchTable#(1, 14, 256, SizeOf#(ConnectalTypes::ForwardTableReqT), SizeOf#(ConnectalTypes::ForwardTableRspT)) ForwardTableMatchTable;
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
    FORWARD1,
    NOACTION2
} Table1ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(19, 54, 10, table_1)
typedef Table#(2, MetadataRequest, Table1Param, ConnectalTypes::Table1ReqT, ConnectalTypes::Table1RspT) Table1Table;
typedef MatchTable#(1, 19, 256, SizeOf#(ConnectalTypes::Table1ReqT), SizeOf#(ConnectalTypes::Table1RspT)) Table1MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table1MatchTable, mkMatchTable_Table1)
instance Table_request #(ConnectalTypes::Table1ReqT);
    function ConnectalTypes::Table1ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table1ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table1ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table1RspT, Table1Param, 2);
    function Action table_execute(ConnectalTypes::Table1RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table1Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD1: begin
                Table1Param req = tagged Forward1ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION2: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD2,
    NOACTION3
} Table2ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(24, 54, 10, table_2)
typedef Table#(2, MetadataRequest, Table2Param, ConnectalTypes::Table2ReqT, ConnectalTypes::Table2RspT) Table2Table;
typedef MatchTable#(1, 24, 256, SizeOf#(ConnectalTypes::Table2ReqT), SizeOf#(ConnectalTypes::Table2RspT)) Table2MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table2MatchTable, mkMatchTable_Table2)
instance Table_request #(ConnectalTypes::Table2ReqT);
    function ConnectalTypes::Table2ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table2ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table2ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table2RspT, Table2Param, 2);
    function Action table_execute(ConnectalTypes::Table2RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table2Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD2: begin
                Table2Param req = tagged Forward2ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION3: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD3,
    NOACTION4
} Table3ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(29, 54, 10, table_3)
typedef Table#(2, MetadataRequest, Table3Param, ConnectalTypes::Table3ReqT, ConnectalTypes::Table3RspT) Table3Table;
typedef MatchTable#(1, 29, 256, SizeOf#(ConnectalTypes::Table3ReqT), SizeOf#(ConnectalTypes::Table3RspT)) Table3MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table3MatchTable, mkMatchTable_Table3)
instance Table_request #(ConnectalTypes::Table3ReqT);
    function ConnectalTypes::Table3ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table3ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table3ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table3RspT, Table3Param, 2);
    function Action table_execute(ConnectalTypes::Table3RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table3Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD3: begin
                Table3Param req = tagged Forward3ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION4: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD4,
    NOACTION5
} Table4ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(2, 54, 10, table_4)
typedef Table#(2, MetadataRequest, Table4Param, ConnectalTypes::Table4ReqT, ConnectalTypes::Table4RspT) Table4Table;
typedef MatchTable#(1, 2, 256, SizeOf#(ConnectalTypes::Table4ReqT), SizeOf#(ConnectalTypes::Table4RspT)) Table4MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table4MatchTable, mkMatchTable_Table4)
instance Table_request #(ConnectalTypes::Table4ReqT);
    function ConnectalTypes::Table4ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table4ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table4ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table4RspT, Table4Param, 2);
    function Action table_execute(ConnectalTypes::Table4RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table4Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD4: begin
                Table4Param req = tagged Forward4ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION5: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD5,
    NOACTION6
} Table5ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(7, 54, 10, table_5)
typedef Table#(2, MetadataRequest, Table5Param, ConnectalTypes::Table5ReqT, ConnectalTypes::Table5RspT) Table5Table;
typedef MatchTable#(1, 7, 256, SizeOf#(ConnectalTypes::Table5ReqT), SizeOf#(ConnectalTypes::Table5RspT)) Table5MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table5MatchTable, mkMatchTable_Table5)
instance Table_request #(ConnectalTypes::Table5ReqT);
    function ConnectalTypes::Table5ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table5ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table5ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table5RspT, Table5Param, 2);
    function Action table_execute(ConnectalTypes::Table5RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table5Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD5: begin
                Table5Param req = tagged Forward5ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION6: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD6,
    NOACTION7
} Table6ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(12, 54, 10, table_6)
typedef Table#(2, MetadataRequest, Table6Param, ConnectalTypes::Table6ReqT, ConnectalTypes::Table6RspT) Table6Table;
typedef MatchTable#(1, 12, 256, SizeOf#(ConnectalTypes::Table6ReqT), SizeOf#(ConnectalTypes::Table6RspT)) Table6MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table6MatchTable, mkMatchTable_Table6)
instance Table_request #(ConnectalTypes::Table6ReqT);
    function ConnectalTypes::Table6ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table6ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table6ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table6RspT, Table6Param, 2);
    function Action table_execute(ConnectalTypes::Table6RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table6Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD6: begin
                Table6Param req = tagged Forward6ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION7: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    FORWARD7,
    NOACTION8
} Table7ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(17, 54, 10, table_7)
typedef Table#(2, MetadataRequest, Table7Param, ConnectalTypes::Table7ReqT, ConnectalTypes::Table7RspT) Table7Table;
typedef MatchTable#(1, 17, 256, SizeOf#(ConnectalTypes::Table7ReqT), SizeOf#(ConnectalTypes::Table7RspT)) Table7MatchTable;
`SynthBuildModule1(mkMatchTable, String, Table7MatchTable, mkMatchTable_Table7)
instance Table_request #(ConnectalTypes::Table7ReqT);
    function ConnectalTypes::Table7ReqT table_request(MetadataRequest data);
        ConnectalTypes::Table7ReqT v = defaultValue;
        if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin
            let dstAddr = ethernet.hdr.dstAddr;
            v = ConnectalTypes::Table7ReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Table7RspT, Table7Param, 2);
    function Action table_execute(ConnectalTypes::Table7RspT resp, MetadataRequest metadata, Vector#(2, FIFOF#(Tuple2#(MetadataRequest, Table7Param))) fifos);
        action
        case (unpack(resp._action)) matches
            FORWARD7: begin
                Table7Param req = tagged Forward7ReqT {_port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            NOACTION8: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardTableParam) NoAction1Action;
typedef Engine#(1, MetadataRequest, Table1Param) NoAction2Action;
typedef Engine#(1, MetadataRequest, Table2Param) NoAction3Action;
typedef Engine#(1, MetadataRequest, Table3Param) NoAction4Action;
typedef Engine#(1, MetadataRequest, Table4Param) NoAction5Action;
typedef Engine#(1, MetadataRequest, Table5Param) NoAction6Action;
typedef Engine#(1, MetadataRequest, Table6Param) NoAction7Action;
typedef Engine#(1, MetadataRequest, Table7Param) NoAction8Action;
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
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table1Param) Forward1Action;
instance Action_execute #(Table1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table2Param) Forward2Action;
instance Action_execute #(Table2Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table2Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table3Param) Forward3Action;
instance Action_execute #(Table3Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table3Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table4Param) Forward4Action;
instance Action_execute #(Table4Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table4Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table5Param) Forward5Action;
instance Action_execute #(Table5Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table5Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table6Param) Forward6Action;
instance Action_execute #(Table6Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table6Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (9) standard_metadata.egress_spec; = _port;
typedef Engine#(1, MetadataRequest, Table7Param) Forward7Action;
instance Action_execute #(Table7Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Table7Param param);
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
    method Action table_1_add_entry(ConnectalTypes::Table1ReqT key, ConnectalTypes::Table1RspT value);
    method Action table_2_add_entry(ConnectalTypes::Table2ReqT key, ConnectalTypes::Table2RspT value);
    method Action table_3_add_entry(ConnectalTypes::Table3ReqT key, ConnectalTypes::Table3RspT value);
    method Action table_4_add_entry(ConnectalTypes::Table4ReqT key, ConnectalTypes::Table4RspT value);
    method Action table_5_add_entry(ConnectalTypes::Table5ReqT key, ConnectalTypes::Table5RspT value);
    method Action table_6_add_entry(ConnectalTypes::Table6ReqT key, ConnectalTypes::Table6RspT value);
    method Action table_7_add_entry(ConnectalTypes::Table7ReqT key, ConnectalTypes::Table7RspT value);
    method Action set_verbosity(int verbosity);
endinterface
module mkIngress (Ingress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_table_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_1_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_1_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_2_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_2_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_3_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_3_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_4_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_4_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_5_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_5_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_6_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_6_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_7_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) table_7_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction1Action noAction1_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction2Action noAction2_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction3Action noAction3_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction4Action noAction4_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction5Action noAction5_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction6Action noAction6_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction7Action noAction7_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction8Action noAction8_action <- mkEngine(toList(vec(step_1)));
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::ForwardAction forward_action <- mkEngine(toList(vec(step_1)));
    Control::Forward1Action forward1_action <- mkEngine(toList(vec(step_1)));
    Control::Forward2Action forward2_action <- mkEngine(toList(vec(step_1)));
    Control::Forward3Action forward3_action <- mkEngine(toList(vec(step_1)));
    Control::Forward4Action forward4_action <- mkEngine(toList(vec(step_1)));
    Control::Forward5Action forward5_action <- mkEngine(toList(vec(step_1)));
    Control::Forward6Action forward6_action <- mkEngine(toList(vec(step_1)));
    Control::Forward7Action forward7_action <- mkEngine(toList(vec(step_1)));
    ForwardTableMatchTable forward_table_table <- mkMatchTable_ForwardTable("forward_table");
    Control::ForwardTableTable forward_table <- mkTable(table_request, table_execute, forward_table_table);
    messageM(printType(typeOf(forward_table_table)));
    messageM(printType(typeOf(forward_table)));
    Table1MatchTable table_1_table <- mkMatchTable_Table1("table_1");
    Control::Table1Table table_1 <- mkTable(table_request, table_execute, table_1_table);
    messageM(printType(typeOf(table_1_table)));
    messageM(printType(typeOf(table_1)));
    Table2MatchTable table_2_table <- mkMatchTable_Table2("table_2");
    Control::Table2Table table_2 <- mkTable(table_request, table_execute, table_2_table);
    messageM(printType(typeOf(table_2_table)));
    messageM(printType(typeOf(table_2)));
    Table3MatchTable table_3_table <- mkMatchTable_Table3("table_3");
    Control::Table3Table table_3 <- mkTable(table_request, table_execute, table_3_table);
    messageM(printType(typeOf(table_3_table)));
    messageM(printType(typeOf(table_3)));
    Table4MatchTable table_4_table <- mkMatchTable_Table4("table_4");
    Control::Table4Table table_4 <- mkTable(table_request, table_execute, table_4_table);
    messageM(printType(typeOf(table_4_table)));
    messageM(printType(typeOf(table_4)));
    Table5MatchTable table_5_table <- mkMatchTable_Table5("table_5");
    Control::Table5Table table_5 <- mkTable(table_request, table_execute, table_5_table);
    messageM(printType(typeOf(table_5_table)));
    messageM(printType(typeOf(table_5)));
    Table6MatchTable table_6_table <- mkMatchTable_Table6("table_6");
    Control::Table6Table table_6 <- mkTable(table_request, table_execute, table_6_table);
    messageM(printType(typeOf(table_6_table)));
    messageM(printType(typeOf(table_6)));
    Table7MatchTable table_7_table <- mkMatchTable_Table7("table_7");
    Control::Table7Table table_7 <- mkTable(table_request, table_execute, table_7_table);
    messageM(printType(typeOf(table_7_table)));
    messageM(printType(typeOf(table_7)));
    mkConnection(toClient(forward_table_req_ff, forward_table_rsp_ff), forward_table.prev_control_state);
    mkConnection(forward_table.next_control_state[0], forward_action.prev_control_state);
    mkConnection(forward_table.next_control_state[1], drop_action.prev_control_state);
    mkConnection(forward_table.next_control_state[2], noAction1_action.prev_control_state);
    mkConnection(toClient(table_1_req_ff, table_1_rsp_ff), table_1.prev_control_state);
    mkConnection(table_1.next_control_state[0], forward1_action.prev_control_state);
    mkConnection(table_1.next_control_state[1], noAction2_action.prev_control_state);
    mkConnection(toClient(table_2_req_ff, table_2_rsp_ff), table_2.prev_control_state);
    mkConnection(table_2.next_control_state[0], forward2_action.prev_control_state);
    mkConnection(table_2.next_control_state[1], noAction3_action.prev_control_state);
    mkConnection(toClient(table_3_req_ff, table_3_rsp_ff), table_3.prev_control_state);
    mkConnection(table_3.next_control_state[0], forward3_action.prev_control_state);
    mkConnection(table_3.next_control_state[1], noAction4_action.prev_control_state);
    mkConnection(toClient(table_4_req_ff, table_4_rsp_ff), table_4.prev_control_state);
    mkConnection(table_4.next_control_state[0], forward4_action.prev_control_state);
    mkConnection(table_4.next_control_state[1], noAction5_action.prev_control_state);
    mkConnection(toClient(table_5_req_ff, table_5_rsp_ff), table_5.prev_control_state);
    mkConnection(table_5.next_control_state[0], forward5_action.prev_control_state);
    mkConnection(table_5.next_control_state[1], noAction6_action.prev_control_state);
    mkConnection(toClient(table_6_req_ff, table_6_rsp_ff), table_6.prev_control_state);
    mkConnection(table_6.next_control_state[0], forward6_action.prev_control_state);
    mkConnection(table_6.next_control_state[1], noAction7_action.prev_control_state);
    mkConnection(toClient(table_7_req_ff, table_7_rsp_ff), table_7.prev_control_state);
    mkConnection(table_7.next_control_state[0], forward7_action.prev_control_state);
    mkConnection(table_7.next_control_state[1], noAction8_action.prev_control_state);
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
                table_1_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_1 if (table_1_rsp_ff.notEmpty);
        table_1_rsp_ff.deq;
        let _rsp = table_1_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_2_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_2 if (table_2_rsp_ff.notEmpty);
        table_2_rsp_ff.deq;
        let _rsp = table_2_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_3_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_3 if (table_3_rsp_ff.notEmpty);
        table_3_rsp_ff.deq;
        let _rsp = table_3_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_4_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_4 if (table_4_rsp_ff.notEmpty);
        table_4_rsp_ff.deq;
        let _rsp = table_4_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_5_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_5 if (table_5_rsp_ff.notEmpty);
        table_5_rsp_ff.deq;
        let _rsp = table_5_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_6_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_6 if (table_6_rsp_ff.notEmpty);
        table_6_rsp_ff.deq;
        let _rsp = table_6_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                table_7_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_table_7 if (table_7_rsp_ff.notEmpty);
        table_7_rsp_ff.deq;
        let _rsp = table_7_rsp_ff.first;
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
    method table_1_add_entry = table_1.add_entry;
    method table_2_add_entry = table_2.add_entry;
    method table_3_add_entry = table_3.add_entry;
    method table_4_add_entry = table_4.add_entry;
    method table_5_add_entry = table_5.add_entry;
    method table_6_add_entry = table_6.add_entry;
    method table_7_add_entry = table_7.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        forward_table.set_verbosity(verbosity);
        table_1.set_verbosity(verbosity);
        table_2.set_verbosity(verbosity);
        table_3.set_verbosity(verbosity);
        table_4.set_verbosity(verbosity);
        table_5.set_verbosity(verbosity);
        table_6.set_verbosity(verbosity);
        table_7.set_verbosity(verbosity);
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
