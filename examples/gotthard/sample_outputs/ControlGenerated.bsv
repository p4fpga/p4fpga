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
    DROP
} ForwardActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(30, 36, 50, forward)
typedef Table#(3, MetadataRequest, ForwardParam, ConnectalTypes::ForwardReqT, ConnectalTypes::ForwardRspT) ForwardTable;
typedef MatchTable#(30, 256, SizeOf#(ConnectalTypes::ForwardReqT), SizeOf#(ConnectalTypes::ForwardRspT)) ForwardMatchTable;
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
            DROP: begin
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
    DROP
} Ipv4LpmActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(3, 36, 43, ipv4_lpm)
typedef Table#(3, MetadataRequest, Ipv4LpmParam, ConnectalTypes::Ipv4LpmReqT, ConnectalTypes::Ipv4LpmRspT) Ipv4LpmTable;
typedef MatchTable#(3, 256, SizeOf#(ConnectalTypes::Ipv4LpmReqT), SizeOf#(ConnectalTypes::Ipv4LpmRspT)) Ipv4LpmMatchTable;
`SynthBuildModule1(mkMatchTable, String, Ipv4LpmMatchTable, mkMatchTable_Ipv4Lpm)
instance Table_request #(ConnectalTypes::Ipv4LpmReqT);
    function ConnectalTypes::Ipv4LpmReqT table_request(MetadataRequest data);
        let dstAddr = fromMaybe(?, data.meta.meta.dstAddr);
        let v = ConnectalTypes::Ipv4LpmReqT {dstAddr: dstAddr, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::Ipv4LpmRspT, Ipv4LpmParam, 3);
    function Action table_execute(ConnectalTypes::Ipv4LpmRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, Ipv4LpmParam))) fifos);
        action
        case (unpack(resp._action)) matches
            SETNHOP: begin
                Ipv4LpmParam req = tagged SetNhopReqT {nhop_ipv4: resp.nhop_ipv4, port: resp.port};
                fifos[0].enq(tuple2(metadata, req));
            end
            DROP: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION4: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION5,
    NOP,
    DOOPTIUPDATE0,
    DOOPTIUPDATE1,
    DOOPTIUPDATE2,
    DOOPTIUPDATE3,
    DOOPTIUPDATE4,
    DOOPTIUPDATE5,
    DOOPTIUPDATE6,
    DOOPTIUPDATE7,
    DOOPTIUPDATE8,
    DOOPTIUPDATE9
} TOptiUpdateActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(8, 18, 4, t_opti_update)
typedef Table#(12, MetadataRequest, TOptiUpdateParam, ConnectalTypes::TOptiUpdateReqT, ConnectalTypes::TOptiUpdateRspT) TOptiUpdateTable;
typedef MatchTable#(8, 256, SizeOf#(ConnectalTypes::TOptiUpdateReqT), SizeOf#(ConnectalTypes::TOptiUpdateRspT)) TOptiUpdateMatchTable;
`SynthBuildModule1(mkMatchTable, String, TOptiUpdateMatchTable, mkMatchTable_TOptiUpdate)
instance Table_request #(ConnectalTypes::TOptiUpdateReqT);
    function ConnectalTypes::TOptiUpdateReqT table_request(MetadataRequest data);
        let op_cnt = fromMaybe(?, data.meta.meta.op_cnt);
        let v = ConnectalTypes::TOptiUpdateReqT {op_cnt: op_cnt, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TOptiUpdateRspT, TOptiUpdateParam, 12);
    function Action table_execute(ConnectalTypes::TOptiUpdateRspT resp, MetadataRequest metadata, Vector#(12, FIFOF#(Tuple2#(MetadataRequest, TOptiUpdateParam))) fifos);
        action
        case (unpack(resp._action)) matches
            NOP: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE0: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE1: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE2: begin
                fifos[3].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE3: begin
                fifos[4].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE4: begin
                fifos[5].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE5: begin
                fifos[6].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE6: begin
                fifos[7].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE7: begin
                fifos[8].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE8: begin
                fifos[9].enq(tuple2(metadata, ?));
            end
            DOOPTIUPDATE9: begin
                fifos[10].enq(tuple2(metadata, ?));
            end
            NOACTION5: begin
                fifos[11].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION6,
    DOREPLYABORT,
    DOREPLYOK
} TReplyClientActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(13, 9, 2, t_reply_client)
typedef Table#(3, MetadataRequest, TReplyClientParam, ConnectalTypes::TReplyClientReqT, ConnectalTypes::TReplyClientRspT) TReplyClientTable;
typedef MatchTable#(13, 256, SizeOf#(ConnectalTypes::TReplyClientReqT), SizeOf#(ConnectalTypes::TReplyClientRspT)) TReplyClientMatchTable;
`SynthBuildModule1(mkMatchTable, String, TReplyClientMatchTable, mkMatchTable_TReplyClient)
instance Table_request #(ConnectalTypes::TReplyClientReqT);
    function ConnectalTypes::TReplyClientReqT table_request(MetadataRequest data);
        let has_invalid_read = fromMaybe(?, data.meta.meta.has_invalid_read);
        let v = ConnectalTypes::TReplyClientReqT {has_invalid_read: has_invalid_read, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TReplyClientRspT, TReplyClientParam, 3);
    function Action table_execute(ConnectalTypes::TReplyClientRspT resp, MetadataRequest metadata, Vector#(3, FIFOF#(Tuple2#(MetadataRequest, TReplyClientParam))) fifos);
        action
        case (unpack(resp._action)) matches
            DOREPLYABORT: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            DOREPLYOK: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            NOACTION6: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION7,
    NOP,
    DOREQFIX0,
    DOREQFIX1,
    DOREQFIX2,
    DOREQFIX3,
    DOREQFIX4,
    DOREQFIX5,
    DOREQFIX6,
    DOREQFIX7,
    DOREQFIX8,
    DOREQFIX9
} TReqFixActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(18, 18, 4, t_req_fix)
typedef Table#(12, MetadataRequest, TReqFixParam, ConnectalTypes::TReqFixReqT, ConnectalTypes::TReqFixRspT) TReqFixTable;
typedef MatchTable#(18, 256, SizeOf#(ConnectalTypes::TReqFixReqT), SizeOf#(ConnectalTypes::TReqFixRspT)) TReqFixMatchTable;
`SynthBuildModule1(mkMatchTable, String, TReqFixMatchTable, mkMatchTable_TReqFix)
instance Table_request #(ConnectalTypes::TReqFixReqT);
    function ConnectalTypes::TReqFixReqT table_request(MetadataRequest data);
        let op_cnt = fromMaybe(?, data.meta.meta.op_cnt);
        let v = ConnectalTypes::TReqFixReqT {op_cnt: op_cnt, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TReqFixRspT, TReqFixParam, 12);
    function Action table_execute(ConnectalTypes::TReqFixRspT resp, MetadataRequest metadata, Vector#(12, FIFOF#(Tuple2#(MetadataRequest, TReqFixParam))) fifos);
        action
        case (unpack(resp._action)) matches
            NOP: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            DOREQFIX0: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            DOREQFIX1: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
            DOREQFIX2: begin
                fifos[3].enq(tuple2(metadata, ?));
            end
            DOREQFIX3: begin
                fifos[4].enq(tuple2(metadata, ?));
            end
            DOREQFIX4: begin
                fifos[5].enq(tuple2(metadata, ?));
            end
            DOREQFIX5: begin
                fifos[6].enq(tuple2(metadata, ?));
            end
            DOREQFIX6: begin
                fifos[7].enq(tuple2(metadata, ?));
            end
            DOREQFIX7: begin
                fifos[8].enq(tuple2(metadata, ?));
            end
            DOREQFIX8: begin
                fifos[9].enq(tuple2(metadata, ?));
            end
            DOREQFIX9: begin
                fifos[10].enq(tuple2(metadata, ?));
            end
            NOACTION7: begin
                fifos[11].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION8,
    NOP,
    DOCHECKOP0,
    DOCHECKOP1,
    DOCHECKOP2,
    DOCHECKOP3,
    DOCHECKOP4,
    DOCHECKOP5,
    DOCHECKOP6,
    DOCHECKOP7,
    DOCHECKOP8,
    DOCHECKOP9
} TReqPass1ActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(23, 18, 5, t_req_pass1)
typedef Table#(12, MetadataRequest, TReqPass1Param, ConnectalTypes::TReqPass1ReqT, ConnectalTypes::TReqPass1RspT) TReqPass1Table;
typedef MatchTable#(23, 256, SizeOf#(ConnectalTypes::TReqPass1ReqT), SizeOf#(ConnectalTypes::TReqPass1RspT)) TReqPass1MatchTable;
`SynthBuildModule1(mkMatchTable, String, TReqPass1MatchTable, mkMatchTable_TReqPass1)
instance Table_request #(ConnectalTypes::TReqPass1ReqT);
    function ConnectalTypes::TReqPass1ReqT table_request(MetadataRequest data);
        let op_cnt = fromMaybe(?, data.meta.meta.op_cnt);
        let v = ConnectalTypes::TReqPass1ReqT {op_cnt: op_cnt, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TReqPass1RspT, TReqPass1Param, 12);
    function Action table_execute(ConnectalTypes::TReqPass1RspT resp, MetadataRequest metadata, Vector#(12, FIFOF#(Tuple2#(MetadataRequest, TReqPass1Param))) fifos);
        action
        case (unpack(resp._action)) matches
            NOP: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            DOCHECKOP0: begin
                TReqPass1Param req = tagged DoCheckOp0ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[1].enq(tuple2(metadata, req));
            end
            DOCHECKOP1: begin
                TReqPass1Param req = tagged DoCheckOp1ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[2].enq(tuple2(metadata, req));
            end
            DOCHECKOP2: begin
                TReqPass1Param req = tagged DoCheckOp2ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[3].enq(tuple2(metadata, req));
            end
            DOCHECKOP3: begin
                TReqPass1Param req = tagged DoCheckOp3ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[4].enq(tuple2(metadata, req));
            end
            DOCHECKOP4: begin
                TReqPass1Param req = tagged DoCheckOp4ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[5].enq(tuple2(metadata, req));
            end
            DOCHECKOP5: begin
                TReqPass1Param req = tagged DoCheckOp5ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[6].enq(tuple2(metadata, req));
            end
            DOCHECKOP6: begin
                TReqPass1Param req = tagged DoCheckOp6ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[7].enq(tuple2(metadata, req));
            end
            DOCHECKOP7: begin
                TReqPass1Param req = tagged DoCheckOp7ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[8].enq(tuple2(metadata, req));
            end
            DOCHECKOP8: begin
                TReqPass1Param req = tagged DoCheckOp8ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[9].enq(tuple2(metadata, req));
            end
            DOCHECKOP9: begin
                TReqPass1Param req = tagged DoCheckOp9ReqT {read_cache_mode: resp.read_cache_mode};
                fifos[10].enq(tuple2(metadata, req));
            end
            NOACTION8: begin
                fifos[11].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef enum {
    NOACTION9,
    NOP,
    DOSTOREUPDATE0,
    DOSTOREUPDATE1,
    DOSTOREUPDATE2,
    DOSTOREUPDATE3,
    DOSTOREUPDATE4,
    DOSTOREUPDATE5,
    DOSTOREUPDATE6,
    DOSTOREUPDATE7,
    DOSTOREUPDATE8,
    DOSTOREUPDATE9
} TStoreUpdateActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(28, 18, 4, t_store_update)
typedef Table#(12, MetadataRequest, TStoreUpdateParam, ConnectalTypes::TStoreUpdateReqT, ConnectalTypes::TStoreUpdateRspT) TStoreUpdateTable;
typedef MatchTable#(28, 256, SizeOf#(ConnectalTypes::TStoreUpdateReqT), SizeOf#(ConnectalTypes::TStoreUpdateRspT)) TStoreUpdateMatchTable;
`SynthBuildModule1(mkMatchTable, String, TStoreUpdateMatchTable, mkMatchTable_TStoreUpdate)
instance Table_request #(ConnectalTypes::TStoreUpdateReqT);
    function ConnectalTypes::TStoreUpdateReqT table_request(MetadataRequest data);
        let op_cnt = fromMaybe(?, data.meta.meta.op_cnt);
        let v = ConnectalTypes::TStoreUpdateReqT {op_cnt: op_cnt, padding: 0};
        return v;
    endfunction
endinstance
instance Table_execute #(ConnectalTypes::TStoreUpdateRspT, TStoreUpdateParam, 12);
    function Action table_execute(ConnectalTypes::TStoreUpdateRspT resp, MetadataRequest metadata, Vector#(12, FIFOF#(Tuple2#(MetadataRequest, TStoreUpdateParam))) fifos);
        action
        case (unpack(resp._action)) matches
            NOP: begin
                fifos[0].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE0: begin
                fifos[1].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE1: begin
                fifos[2].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE2: begin
                fifos[3].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE3: begin
                fifos[4].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE4: begin
                fifos[5].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE5: begin
                fifos[6].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE6: begin
                fifos[7].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE7: begin
                fifos[8].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE8: begin
                fifos[9].enq(tuple2(metadata, ?));
            end
            DOSTOREUPDATE9: begin
                fifos[10].enq(tuple2(metadata, ?));
            end
            NOACTION9: begin
                fifos[11].enq(tuple2(metadata, ?));
            end
        endcase
        endaction
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, ForwardParam) NoAction3Action;
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) NoAction4Action;
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) NoAction5Action;
typedef Engine#(1, MetadataRequest, TReplyClientParam) NoAction6Action;
typedef Engine#(1, MetadataRequest, TReqFixParam) NoAction7Action;
typedef Engine#(1, MetadataRequest, TReqPass1Param) NoAction8Action;
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) NoAction9Action;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, ForwardParam) DropAction;
// mark_to_drop 
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) DropAction;
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) NopAction;
typedef Engine#(1, MetadataRequest, TReqFixParam) NopAction;
typedef Engine#(1, MetadataRequest, TReqPass1Param) NopAction;
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) NopAction;
// INST (1) <Path>(196439):meta.req_meta.read_cache_mode; = <Path>(196443):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp0Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196471):meta.req_meta.read_cache_mode; = <Path>(196475):read_cache_mode;
// INST (1) <Path>(196483):meta.req_meta.read_cache_mode; = <Path>(196487):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp1Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196521):meta.req_meta.read_cache_mode; = <Path>(196525):read_cache_mode;
// INST (1) <Path>(196533):meta.req_meta.read_cache_mode; = <Path>(196525):read_cache_mode;
// INST (1) <Path>(196541):meta.req_meta.read_cache_mode; = <Path>(196545):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp2Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196585):meta.req_meta.read_cache_mode; = <Path>(196589):read_cache_mode;
// INST (1) <Path>(196597):meta.req_meta.read_cache_mode; = <Path>(196589):read_cache_mode;
// INST (1) <Path>(196605):meta.req_meta.read_cache_mode; = <Path>(196589):read_cache_mode;
// INST (1) <Path>(196613):meta.req_meta.read_cache_mode; = <Path>(196617):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp3Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196663):meta.req_meta.read_cache_mode; = <Path>(196667):read_cache_mode;
// INST (1) <Path>(196675):meta.req_meta.read_cache_mode; = <Path>(196667):read_cache_mode;
// INST (1) <Path>(196683):meta.req_meta.read_cache_mode; = <Path>(196667):read_cache_mode;
// INST (1) <Path>(196691):meta.req_meta.read_cache_mode; = <Path>(196667):read_cache_mode;
// INST (1) <Path>(196699):meta.req_meta.read_cache_mode; = <Path>(196703):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp4Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196755):meta.req_meta.read_cache_mode; = <Path>(196759):read_cache_mode;
// INST (1) <Path>(196767):meta.req_meta.read_cache_mode; = <Path>(196759):read_cache_mode;
// INST (1) <Path>(196775):meta.req_meta.read_cache_mode; = <Path>(196759):read_cache_mode;
// INST (1) <Path>(196783):meta.req_meta.read_cache_mode; = <Path>(196759):read_cache_mode;
// INST (1) <Path>(196791):meta.req_meta.read_cache_mode; = <Path>(196759):read_cache_mode;
// INST (1) <Path>(196799):meta.req_meta.read_cache_mode; = <Path>(196803):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp5Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196861):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196873):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196881):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196889):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196897):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196905):meta.req_meta.read_cache_mode; = <Path>(196865):read_cache_mode;
// INST (1) <Path>(196913):meta.req_meta.read_cache_mode; = <Path>(196917):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp6Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(196981):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(196993):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197001):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197009):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197017):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197025):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197033):meta.req_meta.read_cache_mode; = <Path>(196985):read_cache_mode;
// INST (1) <Path>(197041):meta.req_meta.read_cache_mode; = <Path>(197045):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp7Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(197115):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197127):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197135):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197143):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197151):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197159):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197167):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197175):meta.req_meta.read_cache_mode; = <Path>(197119):read_cache_mode;
// INST (1) <Path>(197183):meta.req_meta.read_cache_mode; = <Path>(197187):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp8Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (1) <Path>(197263):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197275):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197283):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197291):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197299):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197307):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197315):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197323):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197331):meta.req_meta.read_cache_mode; = <Path>(197267):read_cache_mode;
// INST (1) <Path>(197339):meta.req_meta.read_cache_mode; = <Path>(197343):read_cache_mode;
typedef Engine#(1, MetadataRequest, TReqPass1Param) DoCheckOp9Action;
instance Action_execute #(TReqPass1Param);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqPass1Param param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate0Action;
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate1Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate2Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate3Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate4Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate5Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate6Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate7Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate8Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TOptiUpdateParam) DoOptiUpdate9Action;
instance Action_execute #(TOptiUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TOptiUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (32) <Path>(195848):meta.req_meta.tmp_ipv4_dstAddr; = <Path>(195854):hdr.ipv4.dstAddr;
// INST (16) <Path>(195848):meta.req_meta.tmp_udp_dstPort; = <Path>(195854):hdr.udp.dstPort;
// INST (32) <Path>(195854):hdr.ipv4.dstAddr; = <Path>(195854):hdr.ipv4.srcAddr;
// INST (32) <Path>(195854):hdr.ipv4.srcAddr; = <Path>(195848):meta.req_meta.tmp_ipv4_dstAddr;
// INST (16) <Path>(195854):hdr.ipv4.totalLen; = 20 + (13 + <Path>(195885):hdr.gotthard_hdr.op_cnt * 5);
// INST (16) <Path>(195854):hdr.udp.dstPort; = <Path>(195854):hdr.udp.srcPort;
// INST (16) <Path>(195854):hdr.udp.srcPort; = <Path>(195848):meta.req_meta.tmp_udp_dstPort;
// INST (16) <Path>(195854):hdr.udp.length_; = 8 + (13 + <Path>(195885):hdr.gotthard_hdr.op_cnt * 5);
// INST (16) <Path>(195854):hdr.udp.checksum; = 0
// INST (1) <Path>(195854):hdr.gotthard_hdr.from_switch; = 1
// INST (1) <Path>(195854):hdr.gotthard_hdr.msg_type; = 1
// INST (8) <Path>(195854):hdr.gotthard_hdr.frag_cnt; = 1
// INST (8) <Path>(195854):hdr.gotthard_hdr.frag_seq; = 1
typedef Engine#(1, MetadataRequest, TReplyClientParam) DoReplyAbortAction;
instance Action_execute #(TReplyClientParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReplyClientParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (8) <Path>(195944):hdr.gotthard_hdr.status; = 0
// INST (32) <Path>(195959):meta.req_meta.tmp_ipv4_dstAddr; = <Path>(195965):hdr.ipv4.dstAddr;
// INST (16) <Path>(195959):meta.req_meta.tmp_udp_dstPort; = <Path>(195965):hdr.udp.dstPort;
// INST (32) <Path>(195965):hdr.ipv4.dstAddr; = <Path>(195965):hdr.ipv4.srcAddr;
// INST (32) <Path>(195965):hdr.ipv4.srcAddr; = <Path>(195959):meta.req_meta.tmp_ipv4_dstAddr;
// INST (16) <Path>(195965):hdr.ipv4.totalLen; = 20 + (13 + <Path>(195944):hdr.gotthard_hdr.op_cnt * 5);
// INST (16) <Path>(195965):hdr.udp.dstPort; = <Path>(195965):hdr.udp.srcPort;
// INST (16) <Path>(195965):hdr.udp.srcPort; = <Path>(195959):meta.req_meta.tmp_udp_dstPort;
// INST (16) <Path>(195965):hdr.udp.length_; = 8 + (13 + <Path>(195944):hdr.gotthard_hdr.op_cnt * 5);
// INST (16) <Path>(195965):hdr.udp.checksum; = 0
// INST (1) <Path>(195965):hdr.gotthard_hdr.from_switch; = 1
// INST (1) <Path>(195965):hdr.gotthard_hdr.msg_type; = 1
// INST (8) <Path>(195965):hdr.gotthard_hdr.frag_cnt; = 1
// INST (8) <Path>(195965):hdr.gotthard_hdr.frag_seq; = 1
typedef Engine#(1, MetadataRequest, TReplyClientParam) DoReplyOkAction;
instance Action_execute #(TReplyClientParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReplyClientParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix0Action;
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix1Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix2Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix3Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix4Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix5Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix6Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix7Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix8Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TReqFixParam) DoReqFix9Action;
instance Action_execute #(TReqFixParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TReqFixParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate0Action;
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate1Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate2Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate3Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate4Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate5Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate6Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate7Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate8Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
typedef Engine#(1, MetadataRequest, TStoreUpdateParam) DoStoreUpdate9Action;
instance Action_execute #(TStoreUpdateParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, TStoreUpdateParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (48) <Path>(195340):hdr.ethernet.dstAddr; = <Path>(195344):dmac;
typedef Engine#(1, MetadataRequest, ForwardParam) SetDmacAction;
instance Action_execute #(ForwardParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, ForwardParam param);
        actionvalue
            $display("(%0d) step 1: ", $time, fshow(meta));
            return meta;
        endactionvalue
    endfunction
endinstance
// INST (32) <Path>(195394):meta.routing_metadata.nhop_ipv4; = <Path>(195398):nhop_ipv4;
// INST (9) <Path>(195404):standard_metadata.egress_spec; = <Path>(195408):port;
// INST (8) <Path>(195415):hdr.ipv4.ttl; = <Path>(195415):hdr.ipv4.ttl + 255;
typedef Engine#(1, MetadataRequest, Ipv4LpmParam) SetNhopAction;
instance Action_execute #(Ipv4LpmParam);
    function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, Ipv4LpmParam param);
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
    method Action forward_add_entry(ConnectalTypes::ForwardReqT key, ConnectalTypes::ForwardRspT value);
    method Action ipv4_lpm_add_entry(ConnectalTypes::Ipv4LpmReqT key, ConnectalTypes::Ipv4LpmRspT value);
    method Action t_opti_update_add_entry(ConnectalTypes::TOptiUpdateReqT key, ConnectalTypes::TOptiUpdateRspT value);
    method Action t_reply_client_add_entry(ConnectalTypes::TReplyClientReqT key, ConnectalTypes::TReplyClientRspT value);
    method Action t_req_fix_add_entry(ConnectalTypes::TReqFixReqT key, ConnectalTypes::TReqFixRspT value);
    method Action t_req_pass1_add_entry(ConnectalTypes::TReqPass1ReqT key, ConnectalTypes::TReqPass1RspT value);
    method Action t_store_update_add_entry(ConnectalTypes::TStoreUpdateReqT key, ConnectalTypes::TStoreUpdateRspT value);
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
    FIFOF#(MetadataRequest) t_opti_update_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_opti_update_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_reply_client_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_reply_client_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_req_fix_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_req_fix_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_req_pass1_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_req_pass1_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_store_update_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) t_store_update_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_2_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_3_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_4_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_6_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_9_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_11_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;
    Control::NoAction3Action noAction3_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction4Action noAction4_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction5Action noAction5_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction6Action noAction6_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction7Action noAction7_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction8Action noAction8_action <- mkEngine(toList(vec(step_1)));
    Control::NoAction9Action noAction9_action <- mkEngine(toList(vec(step_1)));
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::NopAction nop_action <- mkEngine(toList(vec(step_1)));
    Control::NopAction nop_action <- mkEngine(toList(vec(step_1)));
    Control::NopAction nop_action <- mkEngine(toList(vec(step_1)));
    Control::NopAction nop_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp0Action docheckop0_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp1Action docheckop1_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp2Action docheckop2_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp3Action docheckop3_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp4Action docheckop4_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp5Action docheckop5_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp6Action docheckop6_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp7Action docheckop7_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp8Action docheckop8_action <- mkEngine(toList(vec(step_1)));
    Control::DoCheckOp9Action docheckop9_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate0Action dooptiupdate0_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate1Action dooptiupdate1_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate2Action dooptiupdate2_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate3Action dooptiupdate3_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate4Action dooptiupdate4_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate5Action dooptiupdate5_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate6Action dooptiupdate6_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate7Action dooptiupdate7_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate8Action dooptiupdate8_action <- mkEngine(toList(vec(step_1)));
    Control::DoOptiUpdate9Action dooptiupdate9_action <- mkEngine(toList(vec(step_1)));
    Control::DoReplyAbortAction doreplyabort_action <- mkEngine(toList(vec(step_1)));
    Control::DoReplyOkAction doreplyok_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix0Action doreqfix0_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix1Action doreqfix1_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix2Action doreqfix2_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix3Action doreqfix3_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix4Action doreqfix4_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix5Action doreqfix5_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix6Action doreqfix6_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix7Action doreqfix7_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix8Action doreqfix8_action <- mkEngine(toList(vec(step_1)));
    Control::DoReqFix9Action doreqfix9_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate0Action dostoreupdate0_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate1Action dostoreupdate1_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate2Action dostoreupdate2_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate3Action dostoreupdate3_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate4Action dostoreupdate4_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate5Action dostoreupdate5_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate6Action dostoreupdate6_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate7Action dostoreupdate7_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate8Action dostoreupdate8_action <- mkEngine(toList(vec(step_1)));
    Control::DoStoreUpdate9Action dostoreupdate9_action <- mkEngine(toList(vec(step_1)));
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
    TOptiUpdateMatchTable t_opti_update_table <- mkMatchTable_TOptiUpdate("t_opti_update");
    Control::TOptiUpdateTable t_opti_update <- mkTable(table_request, table_execute, t_opti_update_table);
    messageM(printType(typeOf(t_opti_update_table)));
    messageM(printType(typeOf(t_opti_update)));
    TReplyClientMatchTable t_reply_client_table <- mkMatchTable_TReplyClient("t_reply_client");
    Control::TReplyClientTable t_reply_client <- mkTable(table_request, table_execute, t_reply_client_table);
    messageM(printType(typeOf(t_reply_client_table)));
    messageM(printType(typeOf(t_reply_client)));
    TReqFixMatchTable t_req_fix_table <- mkMatchTable_TReqFix("t_req_fix");
    Control::TReqFixTable t_req_fix <- mkTable(table_request, table_execute, t_req_fix_table);
    messageM(printType(typeOf(t_req_fix_table)));
    messageM(printType(typeOf(t_req_fix)));
    TReqPass1MatchTable t_req_pass1_table <- mkMatchTable_TReqPass1("t_req_pass1");
    Control::TReqPass1Table t_req_pass1 <- mkTable(table_request, table_execute, t_req_pass1_table);
    messageM(printType(typeOf(t_req_pass1_table)));
    messageM(printType(typeOf(t_req_pass1)));
    TStoreUpdateMatchTable t_store_update_table <- mkMatchTable_TStoreUpdate("t_store_update");
    Control::TStoreUpdateTable t_store_update <- mkTable(table_request, table_execute, t_store_update_table);
    messageM(printType(typeOf(t_store_update_table)));
    messageM(printType(typeOf(t_store_update)));
    mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state);
    mkConnection(forward.next_control_state[0], setdmac_action.prev_control_state);
    mkConnection(forward.next_control_state[1], drop_action.prev_control_state);
    mkConnection(forward.next_control_state[2], noAction3_action.prev_control_state);
    mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[0], setnhop_action.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[1], drop_action.prev_control_state);
    mkConnection(ipv4_lpm.next_control_state[2], noAction4_action.prev_control_state);
    mkConnection(toClient(t_opti_update_req_ff, t_opti_update_rsp_ff), t_opti_update.prev_control_state);
    mkConnection(t_opti_update.next_control_state[0], nop_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[1], dooptiupdate0_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[2], dooptiupdate1_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[3], dooptiupdate2_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[4], dooptiupdate3_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[5], dooptiupdate4_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[6], dooptiupdate5_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[7], dooptiupdate6_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[8], dooptiupdate7_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[9], dooptiupdate8_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[10], dooptiupdate9_action.prev_control_state);
    mkConnection(t_opti_update.next_control_state[11], noAction5_action.prev_control_state);
    mkConnection(toClient(t_reply_client_req_ff, t_reply_client_rsp_ff), t_reply_client.prev_control_state);
    mkConnection(t_reply_client.next_control_state[0], doreplyabort_action.prev_control_state);
    mkConnection(t_reply_client.next_control_state[1], doreplyok_action.prev_control_state);
    mkConnection(t_reply_client.next_control_state[2], noAction6_action.prev_control_state);
    mkConnection(toClient(t_req_fix_req_ff, t_req_fix_rsp_ff), t_req_fix.prev_control_state);
    mkConnection(t_req_fix.next_control_state[0], nop_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[1], doreqfix0_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[2], doreqfix1_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[3], doreqfix2_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[4], doreqfix3_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[5], doreqfix4_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[6], doreqfix5_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[7], doreqfix6_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[8], doreqfix7_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[9], doreqfix8_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[10], doreqfix9_action.prev_control_state);
    mkConnection(t_req_fix.next_control_state[11], noAction7_action.prev_control_state);
    mkConnection(toClient(t_req_pass1_req_ff, t_req_pass1_rsp_ff), t_req_pass1.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[0], nop_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[1], docheckop0_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[2], docheckop1_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[3], docheckop2_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[4], docheckop3_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[5], docheckop4_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[6], docheckop5_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[7], docheckop6_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[8], docheckop7_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[9], docheckop8_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[10], docheckop9_action.prev_control_state);
    mkConnection(t_req_pass1.next_control_state[11], noAction8_action.prev_control_state);
    mkConnection(toClient(t_store_update_req_ff, t_store_update_rsp_ff), t_store_update.prev_control_state);
    mkConnection(t_store_update.next_control_state[0], nop_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[1], dostoreupdate0_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[2], dostoreupdate1_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[3], dostoreupdate2_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[4], dostoreupdate3_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[5], dostoreupdate4_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[6], dostoreupdate5_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[7], dostoreupdate6_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[8], dostoreupdate7_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[9], dostoreupdate8_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[10], dostoreupdate9_action.prev_control_state);
    mkConnection(t_store_update.next_control_state[11], noAction9_action.prev_control_state);
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
        if (meta.hdr.ipv4 matches tagged Valid .h) begin
            node_3_req_ff.enq(_req);
            dbprint(3, $format("node_2 true", fshow(meta)));
        end
        else begin
            exit_req_ff.enq(_req);
            dbprint(3, $format("node_2 false", fshow(meta)));
        end
    endrule
    rule rl_node_3 if (node_3_req_ff.notEmpty);
        node_3_req_ff.deq;
        let _req = node_3_req_ff.first;
        let meta = _req.meta;
        if (meta.hdr.gotthard_hdr matches tagged Valid .h) begin
            node_4_req_ff.enq(_req);
            dbprint(3, $format("node_3 true", fshow(meta)));
        end
        else begin
            ipv4_lpm_req_ff.enq(_req);
            dbprint(3, $format("node_3 false", fshow(meta)));
        end
    endrule
    rule rl_node_4 if (node_4_req_ff.notEmpty);
        node_4_req_ff.deq;
        let _req = node_4_req_ff.first;
        let meta = _req.meta;
        if (h.hdr.msg_type0 &&& h.hdr.frag_cnt1) begin
            t_req_pass1_req_ff.enq(_req);
            dbprint(3, $format("node_4 true", fshow(meta)));
        end
        else begin
            node_11_req_ff.enq(_req);
            dbprint(3, $format("node_4 false", fshow(meta)));
        end
    endrule
    rule rl_t_req_pass1 if (t_req_pass1_rsp_ff.notEmpty);
        t_req_pass1_rsp_ff.deq;
        let _rsp = t_req_pass1_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                node_6_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_node_6 if (node_6_req_ff.notEmpty);
        node_6_req_ff.deq;
        let _req = node_6_req_ff.first;
        let meta = _req.meta;
        if (h.hdr.has_cache_miss0 &&& h.hdr.has_invalid_read1 &&& h.hdr.read_cache_mode0h.hdr.read_cache_mode1 &&& h.hdr.r_cnt > 0 &&& h.hdr.w_cnt0 &&& h.hdr.rb_cnt0h.hdr.read_cache_mode0 &&& h.hdr.rb_cnt > 0 &&& h.hdr.r_cnt0 &&& h.hdr.w_cnt0) begi
            t_req_fix_req_ff.enq(_req);
            dbprint(3, $format("node_6 true", fshow(meta)));
        end
        else begin
            node_9_req_ff.enq(_req);
            dbprint(3, $format("node_6 false", fshow(meta)));
        end
    endrule
    rule rl_t_req_fix if (t_req_fix_rsp_ff.notEmpty);
        t_req_fix_rsp_ff.deq;
        let _rsp = t_req_fix_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                t_reply_client_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_t_reply_client if (t_reply_client_rsp_ff.notEmpty);
        t_reply_client_rsp_ff.deq;
        let _rsp = t_reply_client_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                node_9_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_node_9 if (node_9_req_ff.notEmpty);
        node_9_req_ff.deq;
        let _req = node_9_req_ff.first;
        let meta = _req.meta;
        if (h.hdr.w_cnt > 0 &&& h.hdr.has_cache_miss0 &&& h.hdr.has_invalid_read0) begin
            t_opti_update_req_ff.enq(_req);
            dbprint(3, $format("node_9 true", fshow(meta)));
        end
        else begin
            ipv4_lpm_req_ff.enq(_req);
            dbprint(3, $format("node_9 false", fshow(meta)));
        end
    endrule
    rule rl_t_opti_update if (t_opti_update_rsp_ff.notEmpty);
        t_opti_update_rsp_ff.deq;
        let _rsp = t_opti_update_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                ipv4_lpm_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
    endrule
    rule rl_node_11 if (node_11_req_ff.notEmpty);
        node_11_req_ff.deq;
        let _req = node_11_req_ff.first;
        let meta = _req.meta;
        if (h.hdr.msg_type1) begin
            t_store_update_req_ff.enq(_req);
            dbprint(3, $format("node_11 true", fshow(meta)));
        end
        else begin
            ipv4_lpm_req_ff.enq(_req);
            dbprint(3, $format("node_11 false", fshow(meta)));
        end
    endrule
    rule rl_t_store_update if (t_store_update_rsp_ff.notEmpty);
        t_store_update_rsp_ff.deq;
        let _rsp = t_store_update_rsp_ff.first;
        let meta = _rsp.meta;
        let pkt = _rsp.pkt;
        case (_rsp) matches
            default: begin
                MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};
                ipv4_lpm_req_ff.enq(req);
                dbprint(3, $format("default ", fshow(meta)));
            end
        endcase
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
    method t_opti_update_add_entry = t_opti_update.add_entry;
    method t_reply_client_add_entry = t_reply_client.add_entry;
    method t_req_fix_add_entry = t_req_fix.add_entry;
    method t_req_pass1_add_entry = t_req_pass1.add_entry;
    method t_store_update_add_entry = t_store_update.add_entry;
    method Action set_verbosity (int verbosity);
        cf_verbosity <= verbosity;
        forward.set_verbosity(verbosity);
        ipv4_lpm.set_verbosity(verbosity);
        t_opti_update.set_verbosity(verbosity);
        t_reply_client.set_verbosity(verbosity);
        t_req_fix.set_verbosity(verbosity);
        t_req_pass1.set_verbosity(verbosity);
        t_store_update.set_verbosity(verbosity);
    endmethod
endmodule
typedef enum {
    NOACTION2,
    REWRITEMAC,
    DROP
} SendFrameActionT deriving (Bits, Eq, FShow);
`MATCHTABLE_SIM(25, 9, 50, send_frame)
typedef Table#(3, MetadataRequest, SendFrameParam, ConnectalTypes::SendFrameReqT, ConnectalTypes::SendFrameRspT) SendFrameTable;
typedef MatchTable#(25, 256, SizeOf#(ConnectalTypes::SendFrameReqT), SizeOf#(ConnectalTypes::SendFrameRspT)) SendFrameMatchTable;
`SynthBuildModule1(mkMatchTable, String, SendFrameMatchTable, mkMatchTable_SendFrame)
instance Table_request #(ConnectalTypes::SendFrameReqT);
    function ConnectalTypes::SendFrameReqT table_request(MetadataRequest data);
        let egress_port = fromMaybe(?, data.meta.meta.egress_port);
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
            DROP: begin
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
typedef Engine#(1, MetadataRequest, SendFrameParam) DropAction;
// INST (48) <Path>(195286):hdr.ethernet.srcAddr; = <Path>(195290):smac;
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
    Control::DropAction drop_action <- mkEngine(toList(vec(step_1)));
    Control::RewriteMacAction rewritemac_action <- mkEngine(toList(vec(step_1)));
    SendFrameMatchTable send_frame_table <- mkMatchTable_SendFrame("send_frame");
    Control::SendFrameTable send_frame <- mkTable(table_request, table_execute, send_frame_table);
    messageM(printType(typeOf(send_frame_table)));
    messageM(printType(typeOf(send_frame)));
    mkConnection(toClient(send_frame_req_ff, send_frame_rsp_ff), send_frame.prev_control_state);
    mkConnection(send_frame.next_control_state[0], rewritemac_action.prev_control_state);
    mkConnection(send_frame.next_control_state[1], drop_action.prev_control_state);
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
                dbprint(3, $format("default ", fshow(meta)));
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
