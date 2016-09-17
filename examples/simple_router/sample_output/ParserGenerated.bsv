`ifdef PARSER_STRUCT
typedef enum {
    StateEthernet,
    StateIpv4
} ParserState deriving (Bits, Eq);
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_ethernet(Bit#(16) etherType);
    action
    let v = {etherType};
    case(v) matches
        2048: begin
            w_ethernet_parse_ipv4.send();
        end
        default: begin
            w_ethernet_accept.send();
        end
    endcase
    endaction
endfunction
function Action compute_next_state_ipv4();
    action
    let v = 0;
    case(v) matches
        default: begin
            w_ipv4_accept.send();
        end
    endcase
    endaction
endfunction
let initState = StateEthernet;
`endif
`ifdef PARSER_RULES
(* mutually_exclusive="rl_ethernet_parse_ipv4,rl_ethernet_accept,rl_ipv4_accept" *)
rule rl_ethernet_load if ((parse_state_ff.first == StateEthernet) && rg_buffered[0] < 112);
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
        data_ff.deq;
        let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
        rg_tmp[0] <= zeroExtend(data);
        move_shift_amt(128);
    end
endrule

rule rl_ethernet_extract if ((parse_state_ff.first == StateEthernet) && (rg_buffered[0] > 112));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
        data_ff.deq;
        data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let ethernet = extract_ethernet_t(truncate(data));
    compute_next_state_ethernet(ethernet.etherType);
    rg_tmp[0] <= zeroExtend(data >> 112);
    succeed_and_next(0);
    parse_state_ff.deq;
    ethernet_out_ff.enq(tagged Valid ethernet);
endrule

rule rl_ethernet_parse_ipv4 if (w_ethernet_parse_ipv4);
    parse_state_ff.enq(StateIpv4);
    fetch_next_header0(160);
endrule
rule rl_ethernet_accept if (w_ethernet_accept);
    parse_done[0] <= True;
    w_parse_done.send();
    fetch_next_header0(0);
endrule
rule rl_ipv4_load if ((parse_state_ff.first == StateIpv4) && rg_buffered[0] < 160);
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
    if (isValid(data_ff.first)) begin
        data_ff.deq;
        let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
        rg_tmp[0] <= zeroExtend(data);
        move_shift_amt(128);
    end
endrule

rule rl_ipv4_extract if ((parse_state_ff.first == StateIpv4) && (rg_buffered[0] > 160));
    let data = rg_tmp[0];
    if (isValid(data_ff.first)) begin
        data_ff.deq;
        data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    end
    report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
    let ipv4 = extract_ipv4_t(truncate(data));
    compute_next_state_ipv4();
    rg_tmp[0] <= zeroExtend(data >> 160);
    succeed_and_next(0);
    parse_state_ff.deq;
    ipv4_out_ff.enq(tagged Valid ipv4);
endrule

rule rl_ipv4_accept if (w_ipv4_accept);
    parse_done[0] <= True;
    w_parse_done.send();
    fetch_next_header0(0);
endrule
rule rl_accept if (delay_ff.notEmpty);
    delay_ff.deq;
    MetadataT meta = defaultValue;
    meta.nhop_ipv4 = tagged Invalid;
    let ethernet <- toGet(ethernet_out_ff).get;
    if (isValid(ethernet)) begin
        meta.ethernet = tagged Forward;
    end
    let ipv4 <- toGet(ipv4_out_ff).get;
    if (isValid(ipv4)) begin
        meta.ipv4 = tagged Forward;
    end
    if (ipv4 matches tagged Valid .d) begin
        meta.dstAddr = tagged Valid d.dstAddr;
    end
    rg_tmp[0] <= 0;
    rg_shift_amt[0] <= 0;
    rg_buffered[0] <= 0;
    meta_in_ff.enq(meta);
endrule
`endif
`ifdef PARSER_STATE
PulseWire w_ethernet_parse_ipv4 <- mkPulseWire;
PulseWire w_ethernet_accept <- mkPulseWire;
PulseWire w_ipv4_accept <- mkPulseWire;
FIFOF#(Maybe#(EthernetT)) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
`endif
