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
    StateParseHeader19,
    StateParseHeader2,
    StateParseHeader20,
    StateParseHeader21,
    StateParseHeader22,
    StateParseHeader23,
    StateParseHeader24,
    StateParseHeader25,
    StateParseHeader26,
    StateParseHeader27,
    StateParseHeader28,
    StateParseHeader29,
    StateParseHeader3,
    StateParseHeader30,
    StateParseHeader31,
    StateParseHeader4,
    StateParseHeader5,
    StateParseHeader6,
    StateParseHeader7,
    StateParseHeader8,
    StateParseHeader9,
    StateParsePtp,
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
        35063: begin
            w_parse_ethernet_parse_ptp.send();
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
        0: begin
            w_parse_header_18_accept.send();
        end
        default: begin
            w_parse_header_18_parse_header_19.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_19(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_19_accept.send();
        end
        default: begin
            w_parse_header_19_parse_header_20.send();
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
function Action compute_next_state_parse_header_20(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_20_accept.send();
        end
        default: begin
            w_parse_header_20_parse_header_21.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_21(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_21_accept.send();
        end
        default: begin
            w_parse_header_21_parse_header_22.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_22(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_22_accept.send();
        end
        default: begin
            w_parse_header_22_parse_header_23.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_23(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_23_accept.send();
        end
        default: begin
            w_parse_header_23_parse_header_24.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_24(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_24_accept.send();
        end
        default: begin
            w_parse_header_24_parse_header_25.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_25(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_25_accept.send();
        end
        default: begin
            w_parse_header_25_parse_header_26.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_26(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_26_accept.send();
        end
        default: begin
            w_parse_header_26_parse_header_27.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_27(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_27_accept.send();
        end
        default: begin
            w_parse_header_27_parse_header_28.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_28(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_28_accept.send();
        end
        default: begin
            w_parse_header_28_parse_header_29.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_29(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_29_accept.send();
        end
        default: begin
            w_parse_header_29_parse_header_30.send();
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
function Action compute_next_state_parse_header_30(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        0: begin
            w_parse_header_30_accept.send();
        end
        default: begin
            w_parse_header_30_parse_header_31.send();
        end
    endcase
    endaction
endfunction
`endif
`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_header_31(Bit#(16) field_0);
    action
    let v = {field_0};
    case(v) matches
        default: begin
            w_parse_header_31_accept.send();
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
function Action compute_next_state_parse_ptp(Bit#(8) reserved2);
    action
    let v = {reserved2};
    case(v) matches
        1: begin
            w_parse_ptp_parse_header_0.send();
        end
        default: begin
            w_parse_ptp_accept.send();
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
typedef 16 ParseHeader19Sz;
typedef 16 ParseHeader2Sz;
typedef 16 ParseHeader20Sz;
typedef 16 ParseHeader21Sz;
typedef 16 ParseHeader22Sz;
typedef 16 ParseHeader23Sz;
typedef 16 ParseHeader24Sz;
typedef 16 ParseHeader25Sz;
typedef 16 ParseHeader26Sz;
typedef 16 ParseHeader27Sz;
typedef 16 ParseHeader28Sz;
typedef 16 ParseHeader29Sz;
typedef 16 ParseHeader3Sz;
typedef 16 ParseHeader30Sz;
typedef 16 ParseHeader31Sz;
typedef 16 ParseHeader4Sz;
typedef 16 ParseHeader5Sz;
typedef 16 ParseHeader6Sz;
typedef 16 ParseHeader7Sz;
typedef 16 ParseHeader8Sz;
typedef 16 ParseHeader9Sz;
typedef 352 ParsePtpSz;
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
        StateParseHeader19 : begin
            let header_19 = extract_header_19_t(truncate(data));
            Header#(Header19T) header0 = defaultValue;
            header0.hdr = header_19;
            header0.state = tagged Forward;
            header_19_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_19(header_19.field_0);
        end
        StateParseHeader2 : begin
            let header_2 = extract_header_2_t(truncate(data));
            Header#(Header2T) header0 = defaultValue;
            header0.hdr = header_2;
            header0.state = tagged Forward;
            header_2_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_2(header_2.field_0);
        end
        StateParseHeader20 : begin
            let header_20 = extract_header_20_t(truncate(data));
            Header#(Header20T) header0 = defaultValue;
            header0.hdr = header_20;
            header0.state = tagged Forward;
            header_20_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_20(header_20.field_0);
        end
        StateParseHeader21 : begin
            let header_21 = extract_header_21_t(truncate(data));
            Header#(Header21T) header0 = defaultValue;
            header0.hdr = header_21;
            header0.state = tagged Forward;
            header_21_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_21(header_21.field_0);
        end
        StateParseHeader22 : begin
            let header_22 = extract_header_22_t(truncate(data));
            Header#(Header22T) header0 = defaultValue;
            header0.hdr = header_22;
            header0.state = tagged Forward;
            header_22_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_22(header_22.field_0);
        end
        StateParseHeader23 : begin
            let header_23 = extract_header_23_t(truncate(data));
            Header#(Header23T) header0 = defaultValue;
            header0.hdr = header_23;
            header0.state = tagged Forward;
            header_23_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_23(header_23.field_0);
        end
        StateParseHeader24 : begin
            let header_24 = extract_header_24_t(truncate(data));
            Header#(Header24T) header0 = defaultValue;
            header0.hdr = header_24;
            header0.state = tagged Forward;
            header_24_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_24(header_24.field_0);
        end
        StateParseHeader25 : begin
            let header_25 = extract_header_25_t(truncate(data));
            Header#(Header25T) header0 = defaultValue;
            header0.hdr = header_25;
            header0.state = tagged Forward;
            header_25_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_25(header_25.field_0);
        end
        StateParseHeader26 : begin
            let header_26 = extract_header_26_t(truncate(data));
            Header#(Header26T) header0 = defaultValue;
            header0.hdr = header_26;
            header0.state = tagged Forward;
            header_26_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_26(header_26.field_0);
        end
        StateParseHeader27 : begin
            let header_27 = extract_header_27_t(truncate(data));
            Header#(Header27T) header0 = defaultValue;
            header0.hdr = header_27;
            header0.state = tagged Forward;
            header_27_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_27(header_27.field_0);
        end
        StateParseHeader28 : begin
            let header_28 = extract_header_28_t(truncate(data));
            Header#(Header28T) header0 = defaultValue;
            header0.hdr = header_28;
            header0.state = tagged Forward;
            header_28_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_28(header_28.field_0);
        end
        StateParseHeader29 : begin
            let header_29 = extract_header_29_t(truncate(data));
            Header#(Header29T) header0 = defaultValue;
            header0.hdr = header_29;
            header0.state = tagged Forward;
            header_29_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_29(header_29.field_0);
        end
        StateParseHeader3 : begin
            let header_3 = extract_header_3_t(truncate(data));
            Header#(Header3T) header0 = defaultValue;
            header0.hdr = header_3;
            header0.state = tagged Forward;
            header_3_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_3(header_3.field_0);
        end
        StateParseHeader30 : begin
            let header_30 = extract_header_30_t(truncate(data));
            Header#(Header30T) header0 = defaultValue;
            header0.hdr = header_30;
            header0.state = tagged Forward;
            header_30_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_30(header_30.field_0);
        end
        StateParseHeader31 : begin
            let header_31 = extract_header_31_t(truncate(data));
            Header#(Header31T) header0 = defaultValue;
            header0.hdr = header_31;
            header0.state = tagged Forward;
            header_31_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_header_31(header_31.field_0);
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
        StateParsePtp : begin
            let ptp = extract_ptp_t(truncate(data));
            Header#(PtpT) header0 = defaultValue;
            header0.hdr = ptp;
            header0.state = tagged Forward;
            ptp_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_ptp(ptp.reserved2);
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
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_ethernet_parse_ptp, StateParsePtp, valueOf(ParsePtpSz)))));
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
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_18_parse_header_19, StateParseHeader19, valueOf(ParseHeader19Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader19, valueOf(ParseHeader19Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader19, valueOf(ParseHeader19Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_19_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_19_parse_header_20, StateParseHeader20, valueOf(ParseHeader20Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader2, valueOf(ParseHeader2Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader2, valueOf(ParseHeader2Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_2_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_2_parse_header_3, StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader20, valueOf(ParseHeader20Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader20, valueOf(ParseHeader20Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_20_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_20_parse_header_21, StateParseHeader21, valueOf(ParseHeader21Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader21, valueOf(ParseHeader21Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader21, valueOf(ParseHeader21Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_21_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_21_parse_header_22, StateParseHeader22, valueOf(ParseHeader22Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader22, valueOf(ParseHeader22Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader22, valueOf(ParseHeader22Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_22_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_22_parse_header_23, StateParseHeader23, valueOf(ParseHeader23Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader23, valueOf(ParseHeader23Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader23, valueOf(ParseHeader23Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_23_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_23_parse_header_24, StateParseHeader24, valueOf(ParseHeader24Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader24, valueOf(ParseHeader24Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader24, valueOf(ParseHeader24Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_24_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_24_parse_header_25, StateParseHeader25, valueOf(ParseHeader25Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader25, valueOf(ParseHeader25Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader25, valueOf(ParseHeader25Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_25_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_25_parse_header_26, StateParseHeader26, valueOf(ParseHeader26Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader26, valueOf(ParseHeader26Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader26, valueOf(ParseHeader26Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_26_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_26_parse_header_27, StateParseHeader27, valueOf(ParseHeader27Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader27, valueOf(ParseHeader27Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader27, valueOf(ParseHeader27Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_27_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_27_parse_header_28, StateParseHeader28, valueOf(ParseHeader28Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader28, valueOf(ParseHeader28Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader28, valueOf(ParseHeader28Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_28_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_28_parse_header_29, StateParseHeader29, valueOf(ParseHeader29Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader29, valueOf(ParseHeader29Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader29, valueOf(ParseHeader29Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_29_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_29_parse_header_30, StateParseHeader30, valueOf(ParseHeader30Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader3, valueOf(ParseHeader3Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_3_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_3_parse_header_4, StateParseHeader4, valueOf(ParseHeader4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader30, valueOf(ParseHeader30Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader30, valueOf(ParseHeader30Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_30_accept))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_header_30_parse_header_31, StateParseHeader31, valueOf(ParseHeader31Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseHeader31, valueOf(ParseHeader31Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseHeader31, valueOf(ParseHeader31Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_header_31_accept))));
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
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParsePtp, valueOf(ParsePtpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParsePtp, valueOf(ParsePtpSz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_parse_ptp_parse_header_0, StateParseHeader0, valueOf(ParseHeader0Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_ptp_accept))));
Vector#(135, Rules) fsmRules = toVector(parse_fsm);
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
    let header_19 <- toGet(header_19_out_ff).get;
    meta.hdr.header_19 = header_19;
    let header_2 <- toGet(header_2_out_ff).get;
    meta.hdr.header_2 = header_2;
    let header_20 <- toGet(header_20_out_ff).get;
    meta.hdr.header_20 = header_20;
    let header_21 <- toGet(header_21_out_ff).get;
    meta.hdr.header_21 = header_21;
    let header_22 <- toGet(header_22_out_ff).get;
    meta.hdr.header_22 = header_22;
    let header_23 <- toGet(header_23_out_ff).get;
    meta.hdr.header_23 = header_23;
    let header_24 <- toGet(header_24_out_ff).get;
    meta.hdr.header_24 = header_24;
    let header_25 <- toGet(header_25_out_ff).get;
    meta.hdr.header_25 = header_25;
    let header_26 <- toGet(header_26_out_ff).get;
    meta.hdr.header_26 = header_26;
    let header_27 <- toGet(header_27_out_ff).get;
    meta.hdr.header_27 = header_27;
    let header_28 <- toGet(header_28_out_ff).get;
    meta.hdr.header_28 = header_28;
    let header_29 <- toGet(header_29_out_ff).get;
    meta.hdr.header_29 = header_29;
    let header_3 <- toGet(header_3_out_ff).get;
    meta.hdr.header_3 = header_3;
    let header_30 <- toGet(header_30_out_ff).get;
    meta.hdr.header_30 = header_30;
    let header_31 <- toGet(header_31_out_ff).get;
    meta.hdr.header_31 = header_31;
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
    let ptp <- toGet(ptp_out_ff).get;
    meta.hdr.ptp = ptp;
    rg_tmp[0] <= 0;
    rg_buffered[0] <= 0;
    meta_in_ff.enq(meta);
endrule
`endif
`ifdef PARSER_STATE
PulseWire w_parse_ethernet_parse_ptp <- mkPulseWire();
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
PulseWire w_parse_header_18_parse_header_19 <- mkPulseWire();
PulseWire w_parse_header_19_accept <- mkPulseWire();
PulseWire w_parse_header_19_parse_header_20 <- mkPulseWire();
PulseWire w_parse_header_2_accept <- mkPulseWire();
PulseWire w_parse_header_2_parse_header_3 <- mkPulseWire();
PulseWire w_parse_header_20_accept <- mkPulseWire();
PulseWire w_parse_header_20_parse_header_21 <- mkPulseWire();
PulseWire w_parse_header_21_accept <- mkPulseWire();
PulseWire w_parse_header_21_parse_header_22 <- mkPulseWire();
PulseWire w_parse_header_22_accept <- mkPulseWire();
PulseWire w_parse_header_22_parse_header_23 <- mkPulseWire();
PulseWire w_parse_header_23_accept <- mkPulseWire();
PulseWire w_parse_header_23_parse_header_24 <- mkPulseWire();
PulseWire w_parse_header_24_accept <- mkPulseWire();
PulseWire w_parse_header_24_parse_header_25 <- mkPulseWire();
PulseWire w_parse_header_25_accept <- mkPulseWire();
PulseWire w_parse_header_25_parse_header_26 <- mkPulseWire();
PulseWire w_parse_header_26_accept <- mkPulseWire();
PulseWire w_parse_header_26_parse_header_27 <- mkPulseWire();
PulseWire w_parse_header_27_accept <- mkPulseWire();
PulseWire w_parse_header_27_parse_header_28 <- mkPulseWire();
PulseWire w_parse_header_28_accept <- mkPulseWire();
PulseWire w_parse_header_28_parse_header_29 <- mkPulseWire();
PulseWire w_parse_header_29_accept <- mkPulseWire();
PulseWire w_parse_header_29_parse_header_30 <- mkPulseWire();
PulseWire w_parse_header_3_accept <- mkPulseWire();
PulseWire w_parse_header_3_parse_header_4 <- mkPulseWire();
PulseWire w_parse_header_30_accept <- mkPulseWire();
PulseWire w_parse_header_30_parse_header_31 <- mkPulseWire();
PulseWire w_parse_header_31_accept <- mkPulseWire();
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
PulseWire w_parse_ptp_parse_header_0 <- mkPulseWire();
PulseWire w_parse_ptp_accept <- mkPulseWire();
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
FIFOF#(Maybe#(Header#(Header19T))) header_19_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header2T))) header_2_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header20T))) header_20_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header21T))) header_21_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header22T))) header_22_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header23T))) header_23_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header24T))) header_24_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header25T))) header_25_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header26T))) header_26_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header27T))) header_27_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header28T))) header_28_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header29T))) header_29_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header3T))) header_3_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header30T))) header_30_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header31T))) header_31_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header4T))) header_4_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header5T))) header_5_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header6T))) header_6_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header7T))) header_7_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header8T))) header_8_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Header9T))) header_9_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(PtpT))) ptp_out_ff <- mkDFIFOF(tagged Invalid);
`endif
