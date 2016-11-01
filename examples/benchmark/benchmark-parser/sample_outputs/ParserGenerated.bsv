`ifdef PARSER_STRUCT
typedef enum {
    StateParseEthernet,
    StateParseHeader0,
    StateParseHeader1,
    StateParseHeader10,
    StateParseHeader11,
    StateParseHeader12,
    StateParseHeader13,
    StateParseHeader14,
    StateParseHeader15,
    StateParseHeader16,
    StateParseHeader17,
    StateParseHeader18,
    StateParseHeader2,
    StateParseHeader3,
    StateParseHeader4,
    StateParseHeader5,
    StateParseHeader6,
    StateParseHeader7,
    StateParseHeader8,
    StateParseHeader9,
    StateParseIpv4,
    StateParseTcp,
    StateParseUdp,
    StateStart,
    StateAccept,
    StateReject
} ParserState deriving (Bits, Eq);
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
    action
    let v = {etherType};
    case(v) matches
        2048: begin
            w_parse_ethernet_parse_ipv4.send();
        end
        default: begin
            w_parse_ethernet_accept.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_0(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_0_accept.send();
        end
        default: begin
            w_parse_header_0_parse_header_1.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_1(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_1_accept.send();
        end
        default: begin
            w_parse_header_1_parse_header_2.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_10(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_10_accept.send();
        end
        default: begin
            w_parse_header_10_parse_header_11.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_11(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_11_accept.send();
        end
        default: begin
            w_parse_header_11_parse_header_12.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_12(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_12_accept.send();
        end
        default: begin
            w_parse_header_12_parse_header_13.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_13(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_13_accept.send();
        end
        default: begin
            w_parse_header_13_parse_header_14.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_14(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_14_accept.send();
        end
        default: begin
            w_parse_header_14_parse_header_15.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_15(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_15_accept.send();
        end
        default: begin
            w_parse_header_15_parse_header_16.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_16(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_16_accept.send();
        end
        default: begin
            w_parse_header_16_parse_header_17.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_17(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_17_accept.send();
        end
        default: begin
            w_parse_header_17_parse_header_18.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_18(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        default: begin
            w_parse_header_18_accept.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_2(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_2_accept.send();
        end
        default: begin
            w_parse_header_2_parse_header_3.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_3(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_3_accept.send();
        end
        default: begin
            w_parse_header_3_parse_header_4.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_4(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_4_accept.send();
        end
        default: begin
            w_parse_header_4_parse_header_5.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_5(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_5_accept.send();
        end
        default: begin
            w_parse_header_5_parse_header_6.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_6(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_6_accept.send();
        end
        default: begin
            w_parse_header_6_parse_header_7.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_7(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_7_accept.send();
        end
        default: begin
            w_parse_header_7_parse_header_8.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_8(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_8_accept.send();
        end
        default: begin
            w_parse_header_8_parse_header_9.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_9(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_9_accept.send();
        end
        default: begin
            w_parse_header_9_parse_header_10.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
    action
    let v = {protocol};
    case(v) matches
        6: begin
            w_parse_ipv4_parse_tcp.send();
        end
        17: begin
            w_parse_ipv4_parse_udp.send();
        end
        default: begin
            w_parse_ipv4_accept.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_tcp();
    action
    w_parse_tcp_accept.send();
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_udp(Bit#(16) dstPort);
    action
    let v = {dstPort};
    case(v) matches
        37009: begin
            w_parse_udp_parse_header_0.send();
        end
        default: begin
            w_parse_udp_accept.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_start();
    action
    w_start_parse_ethernet.send();
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
let initState = StateParseEthernet;
`endif
`ifdef PARSER_STRUCT
typedef 112 ParseEthernetSz;
typedef 16 ParseHeader0Sz;
typedef 16 ParseHeader1Sz;
typedef 16 ParseHeader10Sz;
typedef 16 ParseHeader11Sz;
typedef 16 ParseHeader12Sz;
typedef 16 ParseHeader13Sz;
typedef 16 ParseHeader14Sz;
typedef 16 ParseHeader15Sz;
typedef 16 ParseHeader16Sz;
typedef 16 ParseHeader17Sz;
typedef 16 ParseHeader18Sz;
typedef 16 ParseHeader2Sz;
typedef 16 ParseHeader3Sz;
typedef 16 ParseHeader4Sz;
typedef 16 ParseHeader5Sz;
typedef 16 ParseHeader6Sz;
typedef 16 ParseHeader7Sz;
typedef 16 ParseHeader8Sz;
typedef 16 ParseHeader9Sz;
typedef 160 ParseIpv4Sz;
typedef 160 ParseTcpSz;
typedef 64 ParseUdpSz;
`endif
`ifdef PARSER_FUNCTION
function Action extract_header(ParserState state, Bit#(512) data);
    action
    case (state) matches
        StateParseEthernet : begin
            let ethernet = extract_ethernet_t(truncate(data));
            Header#(EthernetT) header0 = defaultValue;
            header0.hdr = ethernet;
            header0.state = tagged Forward;
            ethernet_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_ethernet(ethernet.etherType);
        end
        StateParseHeader0 : begin
            let header_0 = extract_header_0_t(truncate(data));
            Header#(Header0T) header0 = defaultValue;
            header0.hdr = header_0;
            header0.state = tagged Forward;
            header_0_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_0(header_0.field_0);
        end
        StateParseHeader1 : begin
            let header_1 = extract_header_1_t(truncate(data));
            Header#(Header1T) header0 = defaultValue;
            header0.hdr = header_1;
            header0.state = tagged Forward;
            header_1_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_1(header_1.field_0);
        end
        StateParseHeader10 : begin
            let header_10 = extract_header_10_t(truncate(data));
            Header#(Header10T) header0 = defaultValue;
            header0.hdr = header_10;
            header0.state = tagged Forward;
            header_10_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_10(header_10.field_0);
        end
        StateParseHeader11 : begin
            let header_11 = extract_header_11_t(truncate(data));
            Header#(Header11T) header0 = defaultValue;
            header0.hdr = header_11;
            header0.state = tagged Forward;
            header_11_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_11(header_11.field_0);
        end
        StateParseHeader12 : begin
            let header_12 = extract_header_12_t(truncate(data));
            Header#(Header12T) header0 = defaultValue;
            header0.hdr = header_12;
            header0.state = tagged Forward;
            header_12_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_12(header_12.field_0);
        end
        StateParseHeader13 : begin
            let header_13 = extract_header_13_t(truncate(data));
            Header#(Header13T) header0 = defaultValue;
            header0.hdr = header_13;
            header0.state = tagged Forward;
            header_13_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_13(header_13.field_0);
        end
        StateParseHeader14 : begin
            let header_14 = extract_header_14_t(truncate(data));
            Header#(Header14T) header0 = defaultValue;
            header0.hdr = header_14;
            header0.state = tagged Forward;
            header_14_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_14(header_14.field_0);
        end
        StateParseHeader15 : begin
            let header_15 = extract_header_15_t(truncate(data));
            Header#(Header15T) header0 = defaultValue;
            header0.hdr = header_15;
            header0.state = tagged Forward;
            header_15_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_15(header_15.field_0);
        end
        StateParseHeader16 : begin
            let header_16 = extract_header_16_t(truncate(data));
            Header#(Header16T) header0 = defaultValue;
            header0.hdr = header_16;
            header0.state = tagged Forward;
            header_16_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_16(header_16.field_0);
        end
        StateParseHeader17 : begin
            let header_17 = extract_header_17_t(truncate(data));
            Header#(Header17T) header0 = defaultValue;
            header0.hdr = header_17;
            header0.state = tagged Forward;
            header_17_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_17(header_17.field_0);
        end
        StateParseHeader18 : begin
            let header_18 = extract_header_18_t(truncate(data));
            Header#(Header18T) header0 = defaultValue;
            header0.hdr = header_18;
            header0.state = tagged Forward;
            header_18_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_18(header_18.field_0);
        end
        StateParseHeader2 : begin
            let header_2 = extract_header_2_t(truncate(data));
            Header#(Header2T) header0 = defaultValue;
            header0.hdr = header_2;
            header0.state = tagged Forward;
            header_2_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_2(header_2.field_0);
        end
        StateParseHeader3 : begin
            let header_3 = extract_header_3_t(truncate(data));
            Header#(Header3T) header0 = defaultValue;
            header0.hdr = header_3;
            header0.state = tagged Forward;
            header_3_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_3(header_3.field_0);
        end
        StateParseHeader4 : begin
            let header_4 = extract_header_4_t(truncate(data));
            Header#(Header4T) header0 = defaultValue;
            header0.hdr = header_4;
            header0.state = tagged Forward;
            header_4_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_4(header_4.field_0);
        end
        StateParseHeader5 : begin
            let header_5 = extract_header_5_t(truncate(data));
            Header#(Header5T) header0 = defaultValue;
            header0.hdr = header_5;
            header0.state = tagged Forward;
            header_5_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_5(header_5.field_0);
        end
        StateParseHeader6 : begin
            let header_6 = extract_header_6_t(truncate(data));
            Header#(Header6T) header0 = defaultValue;
            header0.hdr = header_6;
            header0.state = tagged Forward;
            header_6_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_6(header_6.field_0);
        end
        StateParseHeader7 : begin
            let header_7 = extract_header_7_t(truncate(data));
            Header#(Header7T) header0 = defaultValue;
            header0.hdr = header_7;
            header0.state = tagged Forward;
            header_7_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_7(header_7.field_0);
        end
        StateParseHeader8 : begin
            let header_8 = extract_header_8_t(truncate(data));
            Header#(Header8T) header0 = defaultValue;
            header0.hdr = header_8;
            header0.state = tagged Forward;
            header_8_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_8(header_8.field_0);
        end
        StateParseHeader9 : begin
            let header_9 = extract_header_9_t(truncate(data));
            Header#(Header9T) header0 = defaultValue;
            header0.hdr = header_9;
            header0.state = tagged Forward;
            header_9_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_9(header_9.field_0);
        end
        StateParseIpv4 : begin
            let ipv4 = extract_ipv4_t(truncate(data));
            Header#(Ipv4T) header0 = defaultValue;
            header0.hdr = ipv4;
            header0.state = tagged Forward;
            ipv4_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_ipv4(ipv4.protocol);
        end
        StateParseTcp : begin
            let tcp = extract_tcp_t(truncate(data));
            Header#(TcpT) header0 = defaultValue;
            header0.hdr = tcp;
            header0.state = tagged Forward;
            tcp_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_tcp();
        end
        StateParseUdp : begin
            let udp = extract_udp_t(truncate(data));
            Header#(UdpT) header0 = defaultValue;
            header0.hdr = udp;
            header0.state = tagged Forward;
            udp_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_udp(udp.dstPort);
        end
        StateStart : begin
        end
        StateAccept : begin
        end
        StateReject : begin
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_RULES
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseEthernet, valueOf(ParseEthernetSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseEthernet, valueOf(ParseEthernetSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_ethernet_parse_ipv4, StateParseIpv4, valueOf(ParseIpv4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_ethernet_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader0, valueOf(ParseHeader0Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader0, valueOf(ParseHeader0Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_0_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_0_parse_header_1, StateParseHeader1, valueOf(ParseHeader1Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader1, valueOf(ParseHeader1Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader1, valueOf(ParseHeader1Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_1_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_1_parse_header_2, StateParseHeader2, valueOf(ParseHeader2Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader10, valueOf(ParseHeader10Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader10, valueOf(ParseHeader10Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_10_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_10_parse_header_11, StateParseHeader11, valueOf(ParseHeader11Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader11, valueOf(ParseHeader11Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader11, valueOf(ParseHeader11Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_11_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_11_parse_header_12, StateParseHeader12, valueOf(ParseHeader12Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader12, valueOf(ParseHeader12Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader12, valueOf(ParseHeader12Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_12_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_12_parse_header_13, StateParseHeader13, valueOf(ParseHeader13Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader13, valueOf(ParseHeader13Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader13, valueOf(ParseHeader13Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_13_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_13_parse_header_14, StateParseHeader14, valueOf(ParseHeader14Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader14, valueOf(ParseHeader14Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader14, valueOf(ParseHeader14Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_14_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_14_parse_header_15, StateParseHeader15, valueOf(ParseHeader15Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader15, valueOf(ParseHeader15Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader15, valueOf(ParseHeader15Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_15_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_15_parse_header_16, StateParseHeader16, valueOf(ParseHeader16Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader16, valueOf(ParseHeader16Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader16, valueOf(ParseHeader16Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_16_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_16_parse_header_17, StateParseHeader17, valueOf(ParseHeader17Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader17, valueOf(ParseHeader17Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader17, valueOf(ParseHeader17Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_17_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_17_parse_header_18, StateParseHeader18, valueOf(ParseHeader18Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader18, valueOf(ParseHeader18Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader18, valueOf(ParseHeader18Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_18_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader2, valueOf(ParseHeader2Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader2, valueOf(ParseHeader2Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_2_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_2_parse_header_3, StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_3_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_3_parse_header_4, StateParseHeader4, valueOf(ParseHeader4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader4, valueOf(ParseHeader4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader4, valueOf(ParseHeader4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_4_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_4_parse_header_5, StateParseHeader5, valueOf(ParseHeader5Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader5, valueOf(ParseHeader5Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader5, valueOf(ParseHeader5Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_5_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_5_parse_header_6, StateParseHeader6, valueOf(ParseHeader6Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader6, valueOf(ParseHeader6Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader6, valueOf(ParseHeader6Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_6_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_6_parse_header_7, StateParseHeader7, valueOf(ParseHeader7Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader7, valueOf(ParseHeader7Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader7, valueOf(ParseHeader7Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_7_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_7_parse_header_8, StateParseHeader8, valueOf(ParseHeader8Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader8, valueOf(ParseHeader8Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader8, valueOf(ParseHeader8Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_8_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_8_parse_header_9, StateParseHeader9, valueOf(ParseHeader9Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader9, valueOf(ParseHeader9Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader9, valueOf(ParseHeader9Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_9_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_9_parse_header_10, StateParseHeader10, valueOf(ParseHeader10Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseIpv4, valueOf(ParseIpv4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseIpv4, valueOf(ParseIpv4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_ipv4_parse_tcp, StateParseTcp, valueOf(ParseTcpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_ipv4_parse_udp, StateParseUdp, valueOf(ParseUdpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_ipv4_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseTcp, valueOf(ParseTcpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseTcp, valueOf(ParseTcpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseUdp, valueOf(ParseUdpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseUdp, valueOf(ParseUdpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_udp_parse_header_0, StateParseHeader0, valueOf(ParseHeader0Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_udp_accept))));
Vector#(90, Rules) fsmRules = toVector(parse_fsm);
`endif
`ifdef PARSER_RULES
rule rl_accept if (delay_ff.notEmpty);
    delay_ff.deq;
    MetadataT meta = defaultValue;
    let ethernet <- toGet(ethernet_out_ff).get;
    meta.hdr.ethernet = ethernet;
    let header_0 <- toGet(header_0_out_ff).get;
    meta.hdr.header_0 = header_0;
    let header_1 <- toGet(header_1_out_ff).get;
    meta.hdr.header_1 = header_1;
    let header_10 <- toGet(header_10_out_ff).get;
    meta.hdr.header_10 = header_10;
    let header_11 <- toGet(header_11_out_ff).get;
    meta.hdr.header_11 = header_11;
    let header_12 <- toGet(header_12_out_ff).get;
    meta.hdr.header_12 = header_12;
    let header_13 <- toGet(header_13_out_ff).get;
    meta.hdr.header_13 = header_13;
    let header_14 <- toGet(header_14_out_ff).get;
    meta.hdr.header_14 = header_14;
    let header_15 <- toGet(header_15_out_ff).get;
    meta.hdr.header_15 = header_15;
    let header_16 <- toGet(header_16_out_ff).get;
    meta.hdr.header_16 = header_16;
    let header_17 <- toGet(header_17_out_ff).get;
    meta.hdr.header_17 = header_17;
    let header_18 <- toGet(header_18_out_ff).get;
    meta.hdr.header_18 = header_18;
    let header_2 <- toGet(header_2_out_ff).get;
    meta.hdr.header_2 = header_2;
    let header_3 <- toGet(header_3_out_ff).get;
    meta.hdr.header_3 = header_3;
    let header_4 <- toGet(header_4_out_ff).get;
    meta.hdr.header_4 = header_4;
    let header_5 <- toGet(header_5_out_ff).get;
    meta.hdr.header_5 = header_5;
    let header_6 <- toGet(header_6_out_ff).get;
    meta.hdr.header_6 = header_6;
    let header_7 <- toGet(header_7_out_ff).get;
    meta.hdr.header_7 = header_7;
    let header_8 <- toGet(header_8_out_ff).get;
    meta.hdr.header_8 = header_8;
    let header_9 <- toGet(header_9_out_ff).get;
    meta.hdr.header_9 = header_9;
    let ipv4 <- toGet(ipv4_out_ff).get;
    meta.hdr.ipv4 = ipv4;
    let tcp <- toGet(tcp_out_ff).get;
    meta.hdr.tcp = tcp;
    let udp <- toGet(udp_out_ff).get;
    meta.hdr.udp = udp;
    rg_tmp[0] <= 0;
    rg_buffered[0] <= 0;
    meta_in_ff.enq(meta);
endrule
`endif
`ifdef PARSER_STATE
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWire();
PulseWire w_parse_ethernet_accept <- mkPulseWire();
PulseWire w_parse_header_0_accept <- mkPulseWire();
PulseWire w_parse_header_0_parse_header_1 <- mkPulseWire();
PulseWire w_parse_header_1_accept <- mkPulseWire();
PulseWire w_parse_header_1_parse_header_2 <- mkPulseWire();
PulseWire w_parse_header_10_accept <- mkPulseWire();
PulseWire w_parse_header_10_parse_header_11 <- mkPulseWire();
PulseWire w_parse_header_11_accept <- mkPulseWire();
PulseWire w_parse_header_11_parse_header_12 <- mkPulseWire();
PulseWire w_parse_header_12_accept <- mkPulseWire();
PulseWire w_parse_header_12_parse_header_13 <- mkPulseWire();
PulseWire w_parse_header_13_accept <- mkPulseWire();
PulseWire w_parse_header_13_parse_header_14 <- mkPulseWire();
PulseWire w_parse_header_14_accept <- mkPulseWire();
PulseWire w_parse_header_14_parse_header_15 <- mkPulseWire();
PulseWire w_parse_header_15_accept <- mkPulseWire();
PulseWire w_parse_header_15_parse_header_16 <- mkPulseWire();
PulseWire w_parse_header_16_accept <- mkPulseWire();
PulseWire w_parse_header_16_parse_header_17 <- mkPulseWire();
PulseWire w_parse_header_17_accept <- mkPulseWire();
PulseWire w_parse_header_17_parse_header_18 <- mkPulseWire();
PulseWire w_parse_header_18_accept <- mkPulseWire();
PulseWire w_parse_header_2_accept <- mkPulseWire();
PulseWire w_parse_header_2_parse_header_3 <- mkPulseWire();
PulseWire w_parse_header_3_accept <- mkPulseWire();
PulseWire w_parse_header_3_parse_header_4 <- mkPulseWire();
PulseWire w_parse_header_4_accept <- mkPulseWire();
PulseWire w_parse_header_4_parse_header_5 <- mkPulseWire();
PulseWire w_parse_header_5_accept <- mkPulseWire();
PulseWire w_parse_header_5_parse_header_6 <- mkPulseWire();
PulseWire w_parse_header_6_accept <- mkPulseWire();
PulseWire w_parse_header_6_parse_header_7 <- mkPulseWire();
PulseWire w_parse_header_7_accept <- mkPulseWire();
PulseWire w_parse_header_7_parse_header_8 <- mkPulseWire();
PulseWire w_parse_header_8_accept <- mkPulseWire();
PulseWire w_parse_header_8_parse_header_9 <- mkPulseWire();
PulseWire w_parse_header_9_accept <- mkPulseWire();
PulseWire w_parse_header_9_parse_header_10 <- mkPulseWire();
PulseWire w_parse_ipv4_parse_tcp <- mkPulseWire();
PulseWire w_parse_ipv4_parse_udp <- mkPulseWire();
PulseWire w_parse_ipv4_accept <- mkPulseWire();
PulseWire w_parse_tcp_accept <- mkPulseWire();
PulseWire w_parse_udp_parse_header_0 <- mkPulseWire();
PulseWire w_parse_udp_accept <- mkPulseWire();
PulseWire w_start_parse_ethernet <- mkPulseWire();
FIFOF#(Maybe#(Header#(EthernetT))) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header0T))) header_0_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header1T))) header_1_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header10T))) header_10_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header11T))) header_11_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header12T))) header_12_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header13T))) header_13_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header14T))) header_14_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header15T))) header_15_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header16T))) header_16_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header17T))) header_17_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header18T))) header_18_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header2T))) header_2_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header3T))) header_3_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header4T))) header_4_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header5T))) header_5_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header6T))) header_6_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header7T))) header_7_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header8T))) header_8_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header9T))) header_9_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Ipv4T))) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(TcpT))) tcp_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(UdpT))) udp_out_ff <- mkDFIFOF(tagged Invalid);
`endif
