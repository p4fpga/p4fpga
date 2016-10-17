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
    NOACTION3,
    SETDMAC,
    DROP2
} ForwardActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(31, 36, 50, forward)
typedef Table#(3, MetadataRequest, ForwardParam, ConnectalTypes::ForwardReqT, ConnectalTypes::ForwardRspT) ForwardTable;
typedef MatchTable#(31, 256, SizeOf#(ConnectalTypes::ForwardReqT), SizeOf#(ConnectalTypes::ForwardRspT)) ForwardMatchTable;
`SynthBuildModule1(mkMatchTable, String, ForwardMatchTable, mkMatchTable_Forward)
instance Table_request #(ConnectalTypes::ForwardReqT);
    function ConnectalTypes::ForwardReqT table_request(MetadataRequest data);
        let nhop_ipv4 = fromMaybe(?, data.meta.meta.nhop_ipv4);
        let v = ConnectalTypes::ForwardReqT {nhop_ipv4: nhop_ipv4, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::ForwardRspT, ForwardParam, 3);
    function Action table_execute(ConnectalTypes::ForwardRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, ForwardParam))) fifos);
        action
        case (unpack(resp._action)) matches
            SETDMAC: begin
                ForwardParam req = tagged SetDmacReqT {dmac: resp.dmac};
                fifos[0].enq(tuple2(metadata, req));
            end
            DROP2: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION3: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION4,
    SETNHOP,
    DROP1
} Ipv4LpmActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(4, 36, 43, ipv4_lpm)
typedef Table#(3, MetadataRequest, Ipv4LpmParam, ConnectalTypes::Ipv4LpmReqT, ConnectalTypes::Ipv4LpmRspT) Ipv4LpmTable;
typedef MatchTable#(4, 256, SizeOf#(ConnectalTypes::Ipv4LpmReqT), SizeOf#(ConnectalTypes::Ipv4LpmRspT)) Ipv4LpmMatchTable;
`SynthBuildModule1(mkMatchTable, String, Ipv4LpmMatchTable, mkMatchTable_Ipv4Lpm)
instance Table_request #(ConnectalTypes::Ipv4LpmReqT);
    function ConnectalTypes::Ipv4LpmReqT table_request(MetadataRequest data);
        ConnectalTypes::Ipv4LpmReqT v = defaultValue;
        if (data.meta.hdr.ipv4 matches tagged Valid .ipv4) begin
           let dstAddr = ipv4.hdr.dstAddr;
           v = ConnectalTypes::Ipv4LpmReqT {dstAddr: dstAddr, padding: 0};
        end
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Ipv4LpmRspT, Ipv4LpmParam, 3);
    function Action table_execute(ConnectalTypes::Ipv4LpmRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, Ipv4LpmParam))) fifos);
        action
        case (unpack(resp._action)) matches
            SETNHOP: begin
                Ipv4LpmParam req = tagged SetNhopReqT {nhop_ipv4: resp.nhop_ipv4, _port: resp._port};
                fifos[0].enq(tuple2(metadata, req));
            end
            DROP1: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION4: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardParam) NoAction3Action;
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) NoAction4Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) Drop1Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, ForwardParam) Drop2Action;
// INST (48) <Path>(10587):hdr.ethernet.dstAddr; = <Path>(10590):dmac;
typedef Engine#(1, MetadataRequest, ForwardParam) SetDmacAction;
instance Action_execute #(ForwardParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, ForwardParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (32) <Path>(10621):meta.routing_metadata.nhop_ipv4; = <Path>(10624):nhop_ipv4;
// INST (9) <Path>(10629):standard_metadata.egress_port; = <Path>(10632):_port;
// INST (8) <Path>(10638):hdr.ipv4.ttl; = <Path>(10638):hdr.ipv4.ttl + 255;
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) SetNhopAction;
instance Action_execute #(Ipv4LpmParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest req, Ipv4LpmParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(param));
            case (param) matches
               tagged SetNhopReqT {nhop_ipv4: .nhop_ipv4, _port: ._port}: begin
                  req.meta.meta.nhop_ipv4 = tagged Valid nhop_ipv4;
                  req.meta.standard_metadata.egress_port = tagged Valid _port;
                  $display("(%0d) execute action");
               end
            endcase
            $display("(%0d) step 1 updated req: ", $time, fshow(req));
            return req;
        endactionvalue
    endfunction
endinstance
// =============== control ingress ==============
interface Ingress;
    interface PipeIn#(MetadataRequest) prev;
    interface PipeOut#(MetadataRequest) next;
    method Action forward_add_entry(ConnectalTypes::ForwardReqT key, ConnectalTypes::ForwardRspT value);
    method Action ipv4_lpm_add_entry(ConnectalTypes::Ipv4LpmReqT key, ConnectalTypes::Ipv4LpmRspT value);
    method Action set_verbosity(int verbosity);
endinterface
module mkIngress (Ingress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) ipv4_lpm_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_2_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction3Action noAction3_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction4Action noAction4_action <- mkEngine(toList(vec(step_1)));
    Control::Drop1Action drop1_action <- mkEngine(toList(vec(step_1)));
    Control::Drop2Action drop2_action <- mkEngine(toList(vec(step_1)));
    Control::SetDmacAction setdmac_action <- mkEngine(toList(vec(step_1)));
    Control::SetNhopAction setnhop_action <- mkEngine(toList(vec(step_1)));
    ForwardMatchTable forward_table <- mkMatchTable_Forward("forward");
    Control::ForwardTable forward <- mkTable(table_request, table_execute, forward_table);
    messageM(printType(typeOf(forward_table)));
    messageM(printType(typeOf(forward)));
    Ipv4LpmMatchTable ipv4_lpm_table <- mkMatchTable_Ipv4Lpm("ipv4_lpm");
    Control::Ipv4LpmTable ipv4_lpm <- mkTable(table_request, table_execute, ipv4_lpm_table);
    messageM(printType(typeOf(ipv4_lpm_table)));
    messageM(printType(typeOf(ipv4_lpm)));
    mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state);
    mkConnection(forward.next_control_state[0], setdmac_action.prev_control_state);
    mkConnection(forward.next_control_state[1], drop2_action.prev_control_state);
    mkConnection(forward.next_control_state[2], noAction3_action.prev_control_state);
    mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[0], setnhop_action.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[1], drop1_action.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[2], noAction4_action.prev_control_state);
    rule rl_entry if (entry_req_ff.notEmpty);
        entry_req_ff.deq;
        let _req = entry_req_ff.first;
        let meta = _req.meta;
        let pkt = _req.pkt;
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        node_2_req_ff.enq(req);
        dbprint(3, $format("node_2", fshow(meta)));
    endrule
    rule rl_node_2 if (node_2_req_ff.notEmpty);
        node_2_req_ff.deq;
        let _req = node_2_req_ff.first;
        let meta = _req.meta;
        if (meta.hdr.ipv4 matches tagged Valid .h &&& h.hdr.ttl > 0) begin
            ipv4_lpm_req_ff.enq(_req);
            dbprint(3, $format("node_2 true", fshow(meta)));
        end
        else begin
            exit_req_ff.enq(_req);
            dbprint(3, $format("node_2 false", fshow(meta)));
        end
    endrule
    rule rl_ipv4_lpm if (ipv4_lpm_rsp_ff.notEmpty);
        ipv4_lpm_rsp_ff.deq;
        let _rsp = ipv4_lpm_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                forward_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_forward if (forward_rsp_ff.notEmpty);
        forward_rsp_ff.deq;
        let _rsp = forward_rsp_ff.first;
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
    method forward_add_entry = forward.add_entry;
    method ipv4_lpm_add_entry = ipv4_lpm.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        forward.set_verbosity(verbosity);
        ipv4_lpm.set_verbosity(verbosity);
    endmethod
endmodule
typedef enum {
    NOACTION2,
    REWRITEMAC,
    DROP3
} SendFrameActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(16, 9, 50, send_frame)
typedef Table#(3, MetadataRequest, SendFrameParam, ConnectalTypes::SendFrameReqT, ConnectalTypes::SendFrameRspT) SendFrameTable;
typedef MatchTable#(16, 256, SizeOf#(ConnectalTypes::SendFrameReqT), SizeOf#(ConnectalTypes::SendFrameRspT)) SendFrameMatchTable;
`SynthBuildModule1(mkMatchTable, String, SendFrameMatchTable, mkMatchTable_SendFrame)
instance Table_request #(ConnectalTypes::SendFrameReqT);
    function ConnectalTypes::SendFrameReqT table_request(MetadataRequest req);
        let egress_port = fromMaybe(?, req.meta.standard_metadata.egress_port);
        let v = ConnectalTypes::SendFrameReqT {egress_port: egress_port};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::SendFrameRspT, SendFrameParam, 3);
    function Action table_execute(ConnectalTypes::SendFrameRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, SendFrameParam))) fifos);
        action
        case (unpack(resp._action)) matches
            REWRITEMAC: begin
                SendFrameParam req = tagged RewriteMacReqT {smac: resp.smac};
                fifos[0].enq(tuple2(metadata, req));
            end
            DROP3: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION2: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, SendFrameParam) NoAction2Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, SendFrameParam) Drop3Action;
// INST (48) <Path>(10553):hdr.ethernet.srcAddr; = <Path>(10556):smac;
typedef Engine#(1, MetadataRequest, SendFrameParam) RewriteMacAction;
instance Action_execute #(SendFrameParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, SendFrameParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// =============== control egress ==============
interface Egress;
    interface PipeIn#(MetadataRequest) prev;
    interface PipeOut#(MetadataRequest) next;
    method Action send_frame_add_entry(ConnectalTypes::SendFrameReqT key, ConnectalTypes::SendFrameRspT value);
    method Action set_verbosity(int verbosity);
endinterface
module mkEgress (Egress);
    `PRINT_DEBUG_MSG
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) send_frame_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) send_frame_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction2Action noAction2_action <- mkEngine(toList(vec(step_1)));
    Control::Drop3Action drop3_action <- mkEngine(toList(vec(step_1)));
    Control::RewriteMacAction rewritemac_action <- mkEngine(toList(vec(step_1)));
    SendFrameMatchTable send_frame_table <- mkMatchTable_SendFrame("send_frame");
    Control::SendFrameTable send_frame <- mkTable(table_request, table_execute, send_frame_table);
    messageM(printType(typeOf(send_frame_table)));
    messageM(printType(typeOf(send_frame)));
    mkConnection(toClient(send_frame_req_ff, send_frame_rsp_ff), send_frame.prev_control_state);
    mkConnection(send_frame.next_control_state[0], rewritemac_action.prev_control_state);
    mkConnection(send_frame.next_control_state[1], drop3_action.prev_control_state);
    mkConnection(send_frame.next_control_state[2], noAction2_action.prev_control_state);
    rule rl_entry if (entry_req_ff.notEmpty);
        entry_req_ff.deq;
        let _req = entry_req_ff.first;
        let meta = _req.meta;
        let pkt = _req.pkt;
        MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};
        send_frame_req_ff.enq(req);
        dbprint(3, $format("send_frame", fshow(meta)));
    endrule
    rule rl_send_frame if (send_frame_rsp_ff.notEmpty);
        send_frame_rsp_ff.deq;
        let _rsp = send_frame_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                exit_req_ff.enq(req);
                dbprint(3, $format("send frame ", fshow(meta)));
            end
        endcase
    endrule
    interface prev = toPipeIn(entry_req_ff);
    interface next = toPipeOut(exit_req_ff);
    method send_frame_add_entry = send_frame.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        send_frame.set_verbosity(verbosity);
    endmethod
endmodule
