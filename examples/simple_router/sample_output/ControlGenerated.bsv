import StructDefines::*;
import UnionDefines::*;
import CPU::*;
import IMem::*;
import Lists::*;
import TxRx::*;
typedef struct {
    Bit#(4) padding;
    Bit#(32) nhop_ipv4;
} ForwardReqT deriving (Bits, Eq, FShow);
typedef enum {
    NOACTION3,
    SETDMAC,
    DROP2
} ForwardActionT deriving (Bits, Eq, FShow);
typedef struct {
    ForwardActionT _action;
    Bit#(48) dmac;
} ForwardRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(50)) matchtable_read_forward(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_forward(Bit#(36) msgtype, Bit#(50) data);
`endif
instance MatchTableSim#(29, 36, 50);
    function ActionValue#(Bit#(50)) matchtable_read(Bit#(29) id, Bit#(36) key);
    actionvalue
        let v <- matchtable_read_forward(key);
        return v;
    endactionvalue
    endfunction
    function Action matchtable_write(Bit#(29) id, Bit#(36) key, Bit#(50) data);
    action
        matchtable_write_forward(key, data);
    endaction
    endfunction
endinstance
(* synthesize *)
module mkMatchTable_256_Forward(MatchTable#(29, 256, SizeOf#(ForwardReqT), SizeOf#(ForwardRspT)));
    (* hide *)
    MatchTable#(29, 256, SizeOf#(ForwardReqT), SizeOf#(ForwardRspT)) ifc <- mkMatchTable("forward");
    return ifc;
endmodule
// =============== table forward ==============
interface Forward;
    interface Server#(MetadataRequest, MetadataResponse) prev_control_state;
    interface Client#(ForwardActionReq, ForwardActionRsp) next_control_state_0;
    interface Client#(ForwardActionReq, ForwardActionRsp) next_control_state_1;
    interface Client#(ForwardActionReq, ForwardActionRsp) next_control_state_2;
    method Action add_entry(Bit#(SizeOf#(ForwardReqT)) key, Bit#(SizeOf#(ForwardRspT)) value);
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkForward (Control::Forward);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(MetadataRequest) rx_metadata <- mkRX;
    TX #(MetadataResponse) tx_metadata <- mkTX;
    let rx_info_metadata = rx_metadata.u;
    let tx_info_metadata = tx_metadata.u;
    Vector#(3, FIFOF#(ForwardActionReq)) bbReqFifo <- replicateM(mkFIFOF);
    Vector#(3, FIFOF#(ForwardActionRsp)) bbRspFifo <- replicateM(mkFIFOF);
    Vector#(2, FIFOF#(PacketInstance)) packet_ff <- replicateM(mkFIFOF);
    MatchTable#(29, 256, SizeOf#(ForwardReqT), SizeOf#(ForwardRspT)) matchTable <- mkMatchTable_256_Forward;
    Vector#(3, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
    Bool interruptStatus = False;
    Bit#(3) readyChannel = -1;
    for (Integer i=2; i>=0; i=i-1) begin
        if (readyBits[i]) begin
            interruptStatus = True;
            readyChannel = fromInteger(i);
        end
    end
    Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
    rule rl_handle_request;
        let data = rx_info_metadata.first;
        rx_info_metadata.deq;
        let meta = data.meta;
        let pkt = data.pkt;
        let nhop_ipv4 = fromMaybe(?, meta.nhop_ipv4);
        ForwardReqT req = ForwardReqT{nhop_ipv4: nhop_ipv4, padding: 0};
        matchTable.lookupPort.request.put(pack(req));
        packet_ff[0].enq(pkt);
        metadata_ff[0].enq(meta);
    endrule
    rule rl_execute;
        let rsp <- matchTable.lookupPort.response.get;
        let pkt <- toGet(packet_ff[0]).get;
        let meta <- toGet(metadata_ff[0]).get;
        if (rsp matches tagged Valid .data) begin
            ForwardRspT resp = unpack(data);
            case (resp._action) matches
                SETDMAC: begin
                    ForwardActionReq req = tagged SetDmacReqT {pkt: pkt, meta: meta , dmac: resp.dmac};
                    bbReqFifo[0].enq(req);
                end
                DROP2: begin
                    ForwardActionReq req = tagged Drop2ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[1].enq(req);
                end
                NOACTION3: begin
                    ForwardActionReq req = tagged NoAction3ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[2].enq(req);
                end
            endcase
        end
    endrule
    rule rl_handle_response;
        let v <- toGet(bbRspFifo[readyChannel]).get;
        case (v) matches
            tagged SetDmacRspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged Drop2RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged NoAction3RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
        endcase
    endrule
    interface prev_control_state = toServer(rx_metadata.e, tx_metadata.e);
    interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
    interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
    interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
    method Action add_entry(Bit#(SizeOf#(ForwardReqT)) key, Bit#(SizeOf#(ForwardRspT)) value);
        matchTable.add_entry.put(tuple2(key, value));
    endmethod
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
typedef struct {
    Bit#(4) padding;
    Bit#(32) dstAddr;
} Ipv4LpmReqT deriving (Bits, Eq, FShow);
typedef enum {
    NOACTION4,
    SETNHOP,
    DROP1
} Ipv4LpmActionT deriving (Bits, Eq, FShow);
typedef struct {
    Ipv4LpmActionT _action;
    Bit#(32) nhop_ipv4;
    Bit#(9) port;
} Ipv4LpmRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(43)) matchtable_read_ipv4lpm(Bit#(36) msgtype);
import "BDPI" function Action matchtable_write_ipv4lpm(Bit#(36) msgtype, Bit#(43) data);
`endif
instance MatchTableSim#(2, 36, 43);
    function ActionValue#(Bit#(43)) matchtable_read(Bit#(2) id, Bit#(36) key);
    actionvalue
        let v <- matchtable_read_ipv4lpm(key);
        return v;
    endactionvalue
    endfunction
    function Action matchtable_write(Bit#(2) id, Bit#(36) key, Bit#(43) data);
    action
        matchtable_write_ipv4lpm(key, data);
    endaction
    endfunction
endinstance
(* synthesize *)
module mkMatchTable_256_Ipv4Lpm(MatchTable#(2, 256, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRspT)));
    (* hide *)
    MatchTable#(2, 256, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRspT)) ifc <- mkMatchTable("ipv4_lpm");
    return ifc;
endmodule
// =============== table ipv4_lpm ==============
interface Ipv4Lpm;
    interface Server#(MetadataRequest, MetadataResponse) prev_control_state;
    interface Client#(Ipv4LpmActionReq, Ipv4LpmActionRsp) next_control_state_0;
    interface Client#(Ipv4LpmActionReq, Ipv4LpmActionRsp) next_control_state_1;
    interface Client#(Ipv4LpmActionReq, Ipv4LpmActionRsp) next_control_state_2;
    method Action add_entry(Bit#(SizeOf#(Ipv4LpmReqT)) key, Bit#(SizeOf#(Ipv4LpmRspT)) value);
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkIpv4Lpm (Control::Ipv4Lpm);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(MetadataRequest) rx_metadata <- mkRX;
    TX #(MetadataResponse) tx_metadata <- mkTX;
    let rx_info_metadata = rx_metadata.u;
    let tx_info_metadata = tx_metadata.u;
    Vector#(3, FIFOF#(Ipv4LpmActionReq)) bbReqFifo <- replicateM(mkFIFOF);
    Vector#(3, FIFOF#(Ipv4LpmActionRsp)) bbRspFifo <- replicateM(mkFIFOF);
    Vector#(2, FIFOF#(PacketInstance)) packet_ff <- replicateM(mkFIFOF);
    MatchTable#(2, 256, SizeOf#(Ipv4LpmReqT), SizeOf#(Ipv4LpmRspT)) matchTable <- mkMatchTable_256_Ipv4Lpm;
    Vector#(3, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
    Bool interruptStatus = False;
    Bit#(3) readyChannel = -1;
    for (Integer i=2; i>=0; i=i-1) begin
        if (readyBits[i]) begin
            interruptStatus = True;
            readyChannel = fromInteger(i);
        end
    end
    Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
    rule rl_handle_request;
        let data = rx_info_metadata.first;
        rx_info_metadata.deq;
        let meta = data.meta;
        let pkt = data.pkt;
        let dstAddr = fromMaybe(?, meta.dstAddr);
        Ipv4LpmReqT req = Ipv4LpmReqT{dstAddr: dstAddr, padding: 0};
        matchTable.lookupPort.request.put(pack(req));
        packet_ff[0].enq(pkt);
        metadata_ff[0].enq(meta);
    endrule
    rule rl_execute;
        let rsp <- matchTable.lookupPort.response.get;
        let pkt <- toGet(packet_ff[0]).get;
        let meta <- toGet(metadata_ff[0]).get;
        if (rsp matches tagged Valid .data) begin
            Ipv4LpmRspT resp = unpack(data);
            case (resp._action) matches
                SETNHOP: begin
                    Ipv4LpmActionReq req = tagged SetNhopReqT {pkt: pkt, meta: meta , nhop_ipv4: resp.nhop_ipv4, port: resp.port};
                    bbReqFifo[0].enq(req);
                end
                DROP1: begin
                    Ipv4LpmActionReq req = tagged Drop1ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[1].enq(req);
                end
                NOACTION4: begin
                    Ipv4LpmActionReq req = tagged NoAction4ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[2].enq(req);
                end
            endcase
        end
    endrule
    rule rl_handle_response;
        let v <- toGet(bbRspFifo[readyChannel]).get;
        case (v) matches
            tagged SetNhopRspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged Drop1RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged NoAction4RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
        endcase
    endrule
    interface prev_control_state = toServer(rx_metadata.e, tx_metadata.e);
    interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
    interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
    interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
    method Action add_entry(Bit#(SizeOf#(Ipv4LpmReqT)) key, Bit#(SizeOf#(Ipv4LpmRspT)) value);
        matchTable.add_entry.put(tuple2(key, value));
    endmethod
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// =============== action NoAction_3 ==============
interface NoAction3;
    interface Server#(ForwardActionReq, ForwardActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkNoAction3 (Control::NoAction3);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(ForwardActionReq) rx_prev_control_state <- mkRX;
    TX #(ForwardActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// =============== action NoAction_4 ==============
interface NoAction4;
    interface Server#(Ipv4LpmActionReq, Ipv4LpmActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkNoAction4 (Control::NoAction4);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(Ipv4LpmActionReq) rx_prev_control_state <- mkRX;
    TX #(Ipv4LpmActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// mark_to_drop 
// =============== action _drop1 ==============
interface Drop1;
    interface Server#(Ipv4LpmActionReq, Ipv4LpmActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkDrop1 (Control::Drop1);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(Ipv4LpmActionReq) rx_prev_control_state <- mkRX;
    TX #(Ipv4LpmActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    rule drop;
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
    endrule
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// mark_to_drop 
// =============== action _drop2 ==============
interface Drop2;
    interface Server#(ForwardActionReq, ForwardActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkDrop2 (Control::Drop2);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(ForwardActionReq) rx_prev_control_state <- mkRX;
    TX #(ForwardActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    rule drop;
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
    endrule
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// INST (48) <Path>(55317):hdr.ethernet.dstAddr; = <Path>(55321):dmac;
// =============== action set_dmac ==============
interface SetDmac;
    interface Server#(ForwardActionReq, ForwardActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkSetDmac (Control::SetDmac);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(ForwardActionReq) rx_prev_control_state <- mkRX;
    TX #(ForwardActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    Reg#(MetadataT) metadata <- mkReg(defaultValue);
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    Vector#(1, Reg#(Bit#(64))) temp <- replicateM(mkReg(0));
    CPU cpu <- mkCPU("set_dmac", toList(temp));
    IMem imem <- mkIMem("set_dmac.hex");
    mkConnection(cpu.imem_client, imem.cpu_server);
    rule rl_cpu_request if (cpu.not_running());
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
        case (v) matches
            tagged SetDmacReqT {pkt: .pkt, meta: .meta} : begin
                metadata <= meta;
                curr_packet_ff.enq(pkt);
            end
        endcase
        // copy from metadata to stack
        // run cpu
    endrule
    rule rl_cpu_resp if (cpu.not_running());
        let pkt <- toGet(curr_packet_ff).get;
        ForwardActionRsp rsp = tagged SetDmacRspT { pkt: pkt, meta: metadata};
        tx_info_prev_control_state.enq(rsp);
    endrule
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// INST (32) <Path>(55365):meta.routing_metadata.nhop_ipv4; = <Path>(55369):nhop_ipv4;
// INST (9) <Path>(55375):standard_metadata.egress_port; = <Path>(55379):port;
// INST (8) <Path>(55386):hdr.ipv4.ttl; = <Path>(55386):hdr.ipv4.ttl + 255;
// =============== action set_nhop ==============
interface SetNhop;
    interface Server#(Ipv4LpmActionReq, Ipv4LpmActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkSetNhop (Control::SetNhop);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(Ipv4LpmActionReq) rx_prev_control_state <- mkRX;
    TX #(Ipv4LpmActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    Reg#(MetadataT) metadata <- mkReg(defaultValue);
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    Vector#(1, Reg#(Bit#(64))) temp <- replicateM(mkReg(0));
    CPU cpu <- mkCPU("set_nhop", toList(temp));
    IMem imem <- mkIMem("set_nhop.hex");
    mkConnection(cpu.imem_client, imem.cpu_server);
    rule rl_cpu_request if (cpu.not_running());
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
        case (v) matches
            tagged SetNhopReqT {pkt: .pkt, meta: .meta} : begin
                metadata <= meta;
                curr_packet_ff.enq(pkt);
            end
        endcase
        // copy from metadata to stack
        // run cpu
    endrule
    rule rl_cpu_resp if (cpu.not_running());
        let pkt <- toGet(curr_packet_ff).get;
        Ipv4LpmActionRsp rsp = tagged SetNhopRspT { pkt: pkt, meta: metadata};
        tx_info_prev_control_state.enq(rsp);
    endrule
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// =============== control ingress ==============
interface Ingress;
    interface Client#(MetadataRequest, MetadataResponse) next;
    method Action forward_add_entry(Bit#(SizeOf#(ForwardReqT)) key, Bit#(SizeOf#(ForwardRspT)) value);
    method Action ipv4_lpm_add_entry(Bit#(SizeOf#(Ipv4LpmReqT)) key, Bit#(SizeOf#(Ipv4LpmRspT)) value);
    method Action set_verbosity(int verbosity);
endinterface
module mkIngress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Ingress);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    Control::NoAction3 noAction3 <- mkNoAction3();
    Control::NoAction4 noAction4 <- mkNoAction4();
    Control::Drop1 drop1 <- mkDrop1();
    Control::Drop2 drop2 <- mkDrop2();
    Control::SetDmac setdmac <- mkSetDmac();
    Control::SetNhop setnhop <- mkSetNhop();
    Control::Forward forward <- mkForward();
    Control::Ipv4Lpm ipv4_lpm <- mkIpv4Lpm();
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) forward_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) forward_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) ipv4_lpm_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) ipv4_lpm_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) node_2_req_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) exit_rsp_ff <- mkFIFOF;
    Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(entry_req_ff, entry_rsp_ff));
    mkConnection(mds, mdc);
    mkConnection(toClient(forward_req_ff, forward_rsp_ff), forward.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_0, setdmac.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_1, drop2.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, forward.next_control_state_2, noAction3.prev_control_state);
    mkConnection(toClient(ipv4_lpm_req_ff, ipv4_lpm_rsp_ff), ipv4_lpm.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_0, setnhop.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_1, drop1.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, ipv4_lpm.next_control_state_2, noAction4.prev_control_state);
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
        let ttl_isValid = meta.ttl matches tagged Valid .d ? True : False;
        let ttl = fromMaybe(?, meta.ttl);
        if ((isValid(meta.hdr.ipv4) && (ttl_isValid && ttl > 0))) begin
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
interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(exit_req_ff);
    interface response = toPut(exit_rsp_ff);
endinterface);
method forward_add_entry = forward.add_entry;
method ipv4_lpm_add_entry = ipv4_lpm.add_entry;
method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    forward.set_verbosity(verbosity);
    ipv4_lpm.set_verbosity(verbosity);
endmethod
endmodule
import StructDefines::*;
import UnionDefines::*;
import CPU::*;
import IMem::*;
import Lists::*;
import TxRx::*;
typedef struct {
    Bit#(9) egress_port;
} SendFrameReqT deriving (Bits, Eq, FShow);
typedef enum {
    NOACTION2,
    REWRITEMAC,
    DROP3
} SendFrameActionT deriving (Bits, Eq, FShow);
typedef struct {
    SendFrameActionT _action;
    Bit#(48) smac;
} SendFrameRspT deriving (Bits, Eq, FShow);
`ifndef SVDPI
import "BDPI" function ActionValue#(Bit#(50)) matchtable_read_sendframe(Bit#(9) msgtype);
import "BDPI" function Action matchtable_write_sendframe(Bit#(9) msgtype, Bit#(50) data);
`endif
instance MatchTableSim#(14, 9, 50);
    function ActionValue#(Bit#(50)) matchtable_read(Bit#(14) id, Bit#(9) key);
    actionvalue
        let v <- matchtable_read_sendframe(key);
        return v;
    endactionvalue
    endfunction
    function Action matchtable_write(Bit#(14) id, Bit#(9) key, Bit#(50) data);
    action
        matchtable_write_sendframe(key, data);
    endaction
    endfunction
endinstance
(* synthesize *)
module mkMatchTable_256_SendFrame(MatchTable#(14, 256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRspT)));
    (* hide *)
    MatchTable#(14, 256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRspT)) ifc <- mkMatchTable("send_frame");
    return ifc;
endmodule
// =============== table send_frame ==============
interface SendFrame;
    interface Server#(MetadataRequest, MetadataResponse) prev_control_state;
    interface Client#(SendFrameActionReq, SendFrameActionRsp) next_control_state_0;
    interface Client#(SendFrameActionReq, SendFrameActionRsp) next_control_state_1;
    interface Client#(SendFrameActionReq, SendFrameActionRsp) next_control_state_2;
    method Action add_entry(Bit#(SizeOf#(SendFrameReqT)) key, Bit#(SizeOf#(SendFrameRspT)) value);
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkSendFrame (Control::SendFrame);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(MetadataRequest) rx_metadata <- mkRX;
    TX #(MetadataResponse) tx_metadata <- mkTX;
    let rx_info_metadata = rx_metadata.u;
    let tx_info_metadata = tx_metadata.u;
    Vector#(3, FIFOF#(SendFrameActionReq)) bbReqFifo <- replicateM(mkFIFOF);
    Vector#(3, FIFOF#(SendFrameActionRsp)) bbRspFifo <- replicateM(mkFIFOF);
    Vector#(2, FIFOF#(PacketInstance)) packet_ff <- replicateM(mkFIFOF);
    MatchTable#(14, 256, SizeOf#(SendFrameReqT), SizeOf#(SendFrameRspT)) matchTable <- mkMatchTable_256_SendFrame;
    Vector#(3, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
    Bool interruptStatus = False;
    Bit#(3) readyChannel = -1;
    for (Integer i=2; i>=0; i=i-1) begin
        if (readyBits[i]) begin
            interruptStatus = True;
            readyChannel = fromInteger(i);
        end
    end
    Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);
    rule rl_handle_request;
        let data = rx_info_metadata.first;
        rx_info_metadata.deq;
        let meta = data.meta;
        let pkt = data.pkt;
        let egress_port = fromMaybe(?, meta.egress_port);
        SendFrameReqT req = SendFrameReqT{egress_port: egress_port};
        matchTable.lookupPort.request.put(pack(req));
        packet_ff[0].enq(pkt);
        metadata_ff[0].enq(meta);
    endrule
    rule rl_execute;
        let rsp <- matchTable.lookupPort.response.get;
        let pkt <- toGet(packet_ff[0]).get;
        let meta <- toGet(metadata_ff[0]).get;
        if (rsp matches tagged Valid .data) begin
            SendFrameRspT resp = unpack(data);
            case (resp._action) matches
                REWRITEMAC: begin
                    SendFrameActionReq req = tagged RewriteMacReqT {pkt: pkt, meta: meta , smac: resp.smac};
                    bbReqFifo[0].enq(req);
                end
                DROP3: begin
                    SendFrameActionReq req = tagged Drop3ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[1].enq(req);
                end
                NOACTION2: begin
                    SendFrameActionReq req = tagged NoAction2ReqT {pkt: pkt, meta: meta };
                    bbReqFifo[2].enq(req);
                end
            endcase
        end
    endrule
    rule rl_handle_response;
        let v <- toGet(bbRspFifo[readyChannel]).get;
        case (v) matches
            tagged RewriteMacRspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged Drop3RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
            tagged NoAction2RspT {pkt: .pkt, meta: .meta} : begin
                MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};
                tx_info_metadata.enq(rsp);
            end
        endcase
    endrule
    interface prev_control_state = toServer(rx_metadata.e, tx_metadata.e);
    interface next_control_state_0 = toClient(bbReqFifo[0], bbRspFifo[0]);
    interface next_control_state_1 = toClient(bbReqFifo[1], bbRspFifo[1]);
    interface next_control_state_2 = toClient(bbReqFifo[2], bbRspFifo[2]);
    method Action add_entry(Bit#(SizeOf#(SendFrameReqT)) key, Bit#(SizeOf#(SendFrameRspT)) value);
        matchTable.add_entry.put(tuple2(key, value));
    endmethod
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// =============== action NoAction_2 ==============
interface NoAction2;
    interface Server#(SendFrameActionReq, SendFrameActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkNoAction2 (Control::NoAction2);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(SendFrameActionReq) rx_prev_control_state <- mkRX;
    TX #(SendFrameActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// mark_to_drop 
// =============== action _drop3 ==============
interface Drop3;
    interface Server#(SendFrameActionReq, SendFrameActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkDrop3 (Control::Drop3);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(SendFrameActionReq) rx_prev_control_state <- mkRX;
    TX #(SendFrameActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    rule drop;
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
    endrule
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// INST (48) <Path>(55269):hdr.ethernet.srcAddr; = <Path>(55273):smac;
// =============== action rewrite_mac ==============
interface RewriteMac;
    interface Server#(SendFrameActionReq, SendFrameActionRsp) prev_control_state;
    method Action set_verbosity(int verbosity);
endinterface
(* synthesize *)
module mkRewriteMac (Control::RewriteMac);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    RX #(SendFrameActionReq) rx_prev_control_state <- mkRX;
    TX #(SendFrameActionRsp) tx_prev_control_state <- mkTX;
    let rx_info_prev_control_state = rx_prev_control_state.u;
    let tx_info_prev_control_state = tx_prev_control_state.u;
    Reg#(MetadataT) metadata <- mkReg(defaultValue);
    FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;
    Vector#(1, Reg#(Bit#(64))) temp <- replicateM(mkReg(0));
    CPU cpu <- mkCPU("rewrite_mac", toList(temp));
    IMem imem <- mkIMem("rewrite_mac.hex");
    mkConnection(cpu.imem_client, imem.cpu_server);
    rule rl_cpu_request if (cpu.not_running());
        let v = rx_info_prev_control_state.first;
        rx_info_prev_control_state.deq;
        case (v) matches
            tagged RewriteMacReqT {pkt: .pkt, meta: .meta} : begin
                metadata <= meta;
                curr_packet_ff.enq(pkt);
            end
        endcase
        // copy from metadata to stack
        // run cpu
    endrule
    rule rl_cpu_resp if (cpu.not_running());
        let pkt <- toGet(curr_packet_ff).get;
        SendFrameActionRsp rsp = tagged RewriteMacRspT { pkt: pkt, meta: metadata};
        tx_info_prev_control_state.enq(rsp);
    endrule
    interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);
    method Action set_verbosity(int verbosity);
        cf_verbosity <= verbosity;
    endmethod
endmodule
// =============== control egress ==============
interface Egress;
    interface Client#(MetadataRequest, MetadataResponse) next;
    method Action send_frame_add_entry(Bit#(SizeOf#(SendFrameReqT)) key, Bit#(SizeOf#(SendFrameRspT)) value);
    method Action set_verbosity(int verbosity);
endinterface
module mkEgress #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (Egress);
    Reg#(int) cf_verbosity <- mkConfigRegU;
    function Action dbprint(Integer level, Fmt msg);
        action
        if (cf_verbosity > fromInteger(level)) begin
            $display("(%0d) " , $time, msg);
        end
        endaction
    endfunction
    Control::NoAction2 noAction2 <- mkNoAction2();
    Control::Drop3 drop3 <- mkDrop3();
    Control::RewriteMac rewritemac <- mkRewriteMac();
    Control::SendFrame send_frame <- mkSendFrame();
    FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) entry_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) send_frame_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) send_frame_rsp_ff <- mkFIFOF;
    FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;
    FIFOF#(MetadataResponse) exit_rsp_ff <- mkFIFOF;
    Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(entry_req_ff, entry_rsp_ff));
    mkConnection(mds, mdc);
    mkConnection(toClient(send_frame_req_ff, send_frame_rsp_ff), send_frame.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, send_frame.next_control_state_0, rewritemac.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, send_frame.next_control_state_1, drop3.prev_control_state);
    mkChan(mkFIFOF, mkFIFOF, send_frame.next_control_state_2, noAction2.prev_control_state);
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
interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(exit_req_ff);
    interface response = toPut(exit_rsp_ff);
endinterface);
method send_frame_add_entry = send_frame.add_entry;
method Action set_verbosity (int verbosity);
    cf_verbosity <= verbosity;
    send_frame.set_verbosity(verbosity);
endmethod
endmodule
