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
`MATCHTABLE_SIM(2, 54, 11, forward_table)
typedef Table#(3, MetadataRequest, ForwardTableParam, ConnectalTypes::ForwardTableReqT, ConnectalTypes::ForwardTableRspT) ForwardTableTable;
typedef MatchTable#(1, 2, 256, SizeOf#(ConnectalTypes::ForwardTableReqT), SizeOf#(ConnectalTypes::ForwardTableRspT)) ForwardTableMatchTable;
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
    NOP,
    MODHEADERS,
    NOACTION2
} TestTblActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(7, 18, 2, test_tbl)
typedef Table#(3, MetadataRequest, TestTblParam, ConnectalTypes::TestTblReqT, ConnectalTypes::TestTblRspT) TestTblTable;
typedef MatchTable#(1, 7, 256, SizeOf#(ConnectalTypes::TestTblReqT), SizeOf#(ConnectalTypes::TestTblRspT)) TestTblMatchTable;
`SynthBuildModule1(mkMatchTable, String, TestTblMatchTable, mkMatchTable_TestTbl)
instance Table_request #(ConnectalTypes::TestTblReqT);
    function ConnectalTypes::TestTblReqT table_request(MetadataRequest data);
        ConnectalTypes::TestTblReqT v = defaultValue;
        if (data.meta.hdr.udp matches tagged Valid .udp) begin
           let dstPort = udp.hdr.dstPort;
           v = ConnectalTypes::TestTblReqT {dstPort: dstPort, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TestTblRspT, TestTblParam, 3);
    function Action table_execute(ConnectalTypes::TestTblRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, TestTblParam))) fifos);
        action
        case (unpack(resp._action)) matches
            NOP: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            MODHEADERS: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION2: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardTableParam) NoAction1Action;
typedef Engine#(1, MetadataRequest, TestTblParam) NoAction2Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, ForwardTableParam) DropAction;
typedef Engine#(1, MetadataRequest, TestTblParam) NopAction;
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
// INST (8) hdr.ipv4.diffserv; = 0
// INST (16) hdr.ipv4.identification; = 1
// INST (8) hdr.ipv4.ttl; = 2
// INST (16) hdr.ipv4.hdrChecksum; = 3
// INST (16) hdr.udp.srcPort; = 4
// INST (16) hdr.udp.checksum; = 5
// INST (8) hdr.ipv4.diffserv; = 6
// INST (16) hdr.ipv4.identification; = 7
// INST (8) hdr.ipv4.ttl; = 8
// INST (16) hdr.ipv4.hdrChecksum; = 9
// INST (16) hdr.udp.srcPort; = 10
// INST (16) hdr.udp.checksum; = 11
// INST (8) hdr.ipv4.diffserv; = 12
// INST (16) hdr.ipv4.identification; = 13
// INST (8) hdr.ipv4.ttl; = 14
// INST (16) hdr.ipv4.hdrChecksum; = 15
// INST (16) hdr.udp.srcPort; = 16
// INST (16) hdr.udp.checksum; = 17
// INST (8) hdr.ipv4.diffserv; = 18
// INST (16) hdr.ipv4.identification; = 19
// INST (8) hdr.ipv4.ttl; = 20
// INST (16) hdr.ipv4.hdrChecksum; = 21
// INST (16) hdr.udp.srcPort; = 22
// INST (16) hdr.udp.checksum; = 23
// INST (8) hdr.ipv4.diffserv; = 24
// INST (16) hdr.ipv4.identification; = 25
// INST (8) hdr.ipv4.ttl; = 26
// INST (16) hdr.ipv4.hdrChecksum; = 27
// INST (16) hdr.udp.srcPort; = 28
// INST (16) hdr.udp.checksum; = 29
// INST (8) hdr.ipv4.diffserv; = 30
// INST (16) hdr.ipv4.identification; = 31
// INST (8) hdr.ipv4.ttl; = 32
// INST (16) hdr.ipv4.hdrChecksum; = 33
// INST (16) hdr.udp.srcPort; = 34
// INST (16) hdr.udp.checksum; = 35
// INST (8) hdr.ipv4.diffserv; = 36
// INST (16) hdr.ipv4.identification; = 37
// INST (8) hdr.ipv4.ttl; = 38
// INST (16) hdr.ipv4.hdrChecksum; = 39
// INST (16) hdr.udp.srcPort; = 40
// INST (16) hdr.udp.checksum; = 41
// INST (8) hdr.ipv4.diffserv; = 42
// INST (16) hdr.ipv4.identification; = 43
// INST (8) hdr.ipv4.ttl; = 44
// INST (16) hdr.ipv4.hdrChecksum; = 45
// INST (16) hdr.udp.srcPort; = 46
// INST (16) hdr.udp.checksum; = 47
// INST (8) hdr.ipv4.diffserv; = 48
// INST (16) hdr.ipv4.identification; = 49
// INST (8) hdr.ipv4.ttl; = 50
// INST (16) hdr.ipv4.hdrChecksum; = 51
// INST (16) hdr.udp.srcPort; = 52
// INST (16) hdr.udp.checksum; = 53
// INST (8) hdr.ipv4.diffserv; = 54
// INST (16) hdr.ipv4.identification; = 55
// INST (8) hdr.ipv4.ttl; = 56
// INST (16) hdr.ipv4.hdrChecksum; = 57
// INST (16) hdr.udp.srcPort; = 58
// INST (16) hdr.udp.checksum; = 59
// INST (8) hdr.ipv4.diffserv; = 60
// INST (16) hdr.ipv4.identification; = 61
// INST (8) hdr.ipv4.ttl; = 62
// INST (16) hdr.ipv4.hdrChecksum; = 63
// INST (16) hdr.udp.srcPort; = 64
// INST (16) hdr.udp.checksum; = 65
// INST (8) hdr.ipv4.diffserv; = 66
// INST (16) hdr.ipv4.identification; = 67
// INST (8) hdr.ipv4.ttl; = 68
// INST (16) hdr.ipv4.hdrChecksum; = 69
// INST (16) hdr.udp.srcPort; = 70
// INST (16) hdr.udp.checksum; = 71
// INST (8) hdr.ipv4.diffserv; = 72
// INST (16) hdr.ipv4.identification; = 73
// INST (8) hdr.ipv4.ttl; = 74
// INST (16) hdr.ipv4.hdrChecksum; = 75
// INST (16) hdr.udp.srcPort; = 76
// INST (16) hdr.udp.checksum; = 77
// INST (8) hdr.ipv4.diffserv; = 78
// INST (16) hdr.ipv4.identification; = 79
// INST (8) hdr.ipv4.ttl; = 80
// INST (16) hdr.ipv4.hdrChecksum; = 81
// INST (16) hdr.udp.srcPort; = 82
// INST (16) hdr.udp.checksum; = 83
// INST (8) hdr.ipv4.diffserv; = 84
// INST (16) hdr.ipv4.identification; = 85
// INST (8) hdr.ipv4.ttl; = 86
// INST (16) hdr.ipv4.hdrChecksum; = 87
// INST (16) hdr.udp.srcPort; = 88
// INST (16) hdr.udp.checksum; = 89
// INST (8) hdr.ipv4.diffserv; = 90
// INST (16) hdr.ipv4.identification; = 91
// INST (8) hdr.ipv4.ttl; = 92
// INST (16) hdr.ipv4.hdrChecksum; = 93
// INST (16) hdr.udp.srcPort; = 94
// INST (16) hdr.udp.checksum; = 95
// INST (8) hdr.ipv4.diffserv; = 96
// INST (16) hdr.ipv4.identification; = 97
// INST (8) hdr.ipv4.ttl; = 98
// INST (16) hdr.ipv4.hdrChecksum; = 99
// INST (16) hdr.udp.srcPort; = 100
// INST (16) hdr.udp.checksum; = 101
// INST (8) hdr.ipv4.diffserv; = 102
// INST (16) hdr.ipv4.identification; = 103
// INST (8) hdr.ipv4.ttl; = 104
// INST (16) hdr.ipv4.hdrChecksum; = 105
// INST (16) hdr.udp.srcPort; = 106
// INST (16) hdr.udp.checksum; = 107
// INST (8) hdr.ipv4.diffserv; = 108
// INST (16) hdr.ipv4.identification; = 109
// INST (8) hdr.ipv4.ttl; = 110
// INST (16) hdr.ipv4.hdrChecksum; = 111
// INST (16) hdr.udp.srcPort; = 112
// INST (16) hdr.udp.checksum; = 113
// INST (8) hdr.ipv4.diffserv; = 114
// INST (16) hdr.ipv4.identification; = 115
// INST (8) hdr.ipv4.ttl; = 116
// INST (16) hdr.ipv4.hdrChecksum; = 117
// INST (16) hdr.udp.srcPort; = 118
// INST (16) hdr.udp.checksum; = 119
// INST (8) hdr.ipv4.diffserv; = 120
// INST (16) hdr.ipv4.identification; = 121
// INST (8) hdr.ipv4.ttl; = 122
// INST (16) hdr.ipv4.hdrChecksum; = 123
// INST (16) hdr.udp.srcPort; = 124
// INST (16) hdr.udp.checksum; = 125
// INST (8) hdr.ipv4.diffserv; = 126
// INST (16) hdr.ipv4.identification; = 127
typedef Engine#(1, MetadataRequest, TestTblParam) ModHeadersAction;
instance Action_execute #(TestTblParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TestTblParam param);
        actionvalue
            if (isValid(meta.meta.hdr.ipv4)) begin
               let ipv4 = fromMaybe(?, meta.meta.hdr.ipv4);
               ipv4.hdr.diffserv = 0;
               ipv4.hdr.identification= 1;
               ipv4.hdr.ttl = 2;
               ipv4.hdr.hdrChecksum = 3;
               meta.meta.hdr.ipv4 = tagged Valid ipv4;
            end
            if (isValid(meta.meta.hdr.udp)) begin
               let udp = fromMaybe(?, meta.meta.hdr.udp);
               udp.hdr.srcPort = 4;
               udp.hdr.checksum = 5;
               meta.meta.hdr.udp = tagged Valid udp;
            end
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
    Control::NopAction nop_action <- mkEngine(toList(vec(step_1)));
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
    mkConnection(test_tbl.next_control_state[0], nop_action.prev_control_state);
    mkConnection(test_tbl.next_control_state[1], modheaders_action.prev_control_state);
    mkConnection(test_tbl.next_control_state[2], noAction2_action.prev_control_state);
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
