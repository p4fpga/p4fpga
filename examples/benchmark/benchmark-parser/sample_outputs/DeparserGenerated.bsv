`ifdef DEPARSER_STRUCT
typedef enum {
    StateDeparseStart,
    StateDeparseEthernet,
    StateDeparseIpv4,
    StateDeparseUdp,
    StateDeparseHeader0,
    StateDeparseHeader1,
    StateDeparseHeader2,
    StateDeparseHeader3,
    StateDeparseHeader4,
    StateDeparseHeader5,
    StateDeparseHeader6,
    StateDeparseHeader7,
    StateDeparseHeader8,
    StateDeparseHeader9,
    StateDeparseHeader10,
    StateDeparseHeader11,
    StateDeparseHeader12,
    StateDeparseHeader13,
    StateDeparseHeader14,
    StateDeparseHeader15,
    StateDeparseHeader16,
    StateDeparseHeader17,
    StateDeparseHeader18,
    StateDeparseTcp
} DeparserState deriving (Bits, Eq, FShow);
`endif  // DEPARSER_STRUCT
`ifdef DEPARSER_RULES
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_ethernet, StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_ipv4, StateDeparseIpv4, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseIpv4, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseIpv4, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_udp, StateDeparseUdp, 64))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseUdp, 64))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseUdp, 64))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_0, StateDeparseHeader0, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader0, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader0, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_1, StateDeparseHeader1, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader1, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader1, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_2, StateDeparseHeader2, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader2, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader2, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_3, StateDeparseHeader3, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader3, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader3, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_4, StateDeparseHeader4, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader4, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader4, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_5, StateDeparseHeader5, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader5, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader5, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_6, StateDeparseHeader6, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader6, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader6, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_7, StateDeparseHeader7, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader7, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader7, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_8, StateDeparseHeader8, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader8, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader8, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_9, StateDeparseHeader9, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader9, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader9, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_10, StateDeparseHeader10, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader10, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader10, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_11, StateDeparseHeader11, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader11, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader11, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_12, StateDeparseHeader12, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader12, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader12, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_13, StateDeparseHeader13, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader13, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader13, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_14, StateDeparseHeader14, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader14, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader14, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_15, StateDeparseHeader15, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader15, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader15, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_16, StateDeparseHeader16, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader16, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader16, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_17, StateDeparseHeader17, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader17, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader17, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_18, StateDeparseHeader18, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader18, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader18, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_tcp, StateDeparseTcp, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseTcp, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseTcp, 160))));
Vector#(69, Rules) fsmRules = toVector(deparse_fsm);
`endif  // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_ethernet <- mkPulseWire();
PulseWire w_ipv4 <- mkPulseWire();
PulseWire w_udp <- mkPulseWire();
PulseWire w_header_0 <- mkPulseWire();
PulseWire w_header_1 <- mkPulseWire();
PulseWire w_header_2 <- mkPulseWire();
PulseWire w_header_3 <- mkPulseWire();
PulseWire w_header_4 <- mkPulseWire();
PulseWire w_header_5 <- mkPulseWire();
PulseWire w_header_6 <- mkPulseWire();
PulseWire w_header_7 <- mkPulseWire();
PulseWire w_header_8 <- mkPulseWire();
PulseWire w_header_9 <- mkPulseWire();
PulseWire w_header_10 <- mkPulseWire();
PulseWire w_header_11 <- mkPulseWire();
PulseWire w_header_12 <- mkPulseWire();
PulseWire w_header_13 <- mkPulseWire();
PulseWire w_header_14 <- mkPulseWire();
PulseWire w_header_15 <- mkPulseWire();
PulseWire w_header_16 <- mkPulseWire();
PulseWire w_header_17 <- mkPulseWire();
PulseWire w_header_18 <- mkPulseWire();
PulseWire w_tcp <- mkPulseWire();

function Bit#(24) nextDeparseState(MetadataT metadata);
    Vector#(24, Bool) headerValid;
    headerValid[0] = False;
    headerValid[1] = checkForward(metadata.hdr.ethernet);
    headerValid[2] = checkForward(metadata.hdr.ipv4);
    headerValid[3] = checkForward(metadata.hdr.udp);
    headerValid[4] = checkForward(metadata.hdr.header_0);
    headerValid[5] = checkForward(metadata.hdr.header_1);
    headerValid[6] = checkForward(metadata.hdr.header_2);
    headerValid[7] = checkForward(metadata.hdr.header_3);
    headerValid[8] = checkForward(metadata.hdr.header_4);
    headerValid[9] = checkForward(metadata.hdr.header_5);
    headerValid[10] = checkForward(metadata.hdr.header_6);
    headerValid[11] = checkForward(metadata.hdr.header_7);
    headerValid[12] = checkForward(metadata.hdr.header_8);
    headerValid[13] = checkForward(metadata.hdr.header_9);
    headerValid[14] = checkForward(metadata.hdr.header_10);
    headerValid[15] = checkForward(metadata.hdr.header_11);
    headerValid[16] = checkForward(metadata.hdr.header_12);
    headerValid[17] = checkForward(metadata.hdr.header_13);
    headerValid[18] = checkForward(metadata.hdr.header_14);
    headerValid[19] = checkForward(metadata.hdr.header_15);
    headerValid[20] = checkForward(metadata.hdr.header_16);
    headerValid[21] = checkForward(metadata.hdr.header_17);
    headerValid[22] = checkForward(metadata.hdr.header_18);
    headerValid[23] = checkForward(metadata.hdr.tcp);
    let vec = pack(headerValid);
    return vec;
endfunction

function Action transit_next_state(MetadataT metadata);
    action
    let vec = nextDeparseState(metadata);
    if (vec == 0) begin
        w_deparse_header_done.send();
    end
    else begin
        Bit#(5) nextHeader = truncate(pack(countZerosLSB(vec)% 24));
        DeparserState nextState = unpack(nextHeader);
        case (nextState) matches
            StateDeparseEthernet: w_ethernet.send();
            StateDeparseIpv4: w_ipv4.send();
            StateDeparseUdp: w_udp.send();
            StateDeparseHeader0: w_header_0.send();
            StateDeparseHeader1: w_header_1.send();
            StateDeparseHeader2: w_header_2.send();
            StateDeparseHeader3: w_header_3.send();
            StateDeparseHeader4: w_header_4.send();
            StateDeparseHeader5: w_header_5.send();
            StateDeparseHeader6: w_header_6.send();
            StateDeparseHeader7: w_header_7.send();
            StateDeparseHeader8: w_header_8.send();
            StateDeparseHeader9: w_header_9.send();
            StateDeparseHeader10: w_header_10.send();
            StateDeparseHeader11: w_header_11.send();
            StateDeparseHeader12: w_header_12.send();
            StateDeparseHeader13: w_header_13.send();
            StateDeparseHeader14: w_header_14.send();
            StateDeparseHeader15: w_header_15.send();
            StateDeparseHeader16: w_header_16.send();
            StateDeparseHeader17: w_header_17.send();
            StateDeparseHeader18: w_header_18.send();
            StateDeparseTcp: w_tcp.send();
            default: $display("ERROR: unknown states.");
        endcase
    end
    endaction
endfunction
function MetadataT update_metadata(DeparserState state);
    let metadata = meta[0];
    case (state) matches
        StateDeparseEthernet :
            metadata.hdr.ethernet = updateState(metadata.hdr.ethernet, tagged StructDefines::NotPresent);
        StateDeparseIpv4 :
            metadata.hdr.ipv4 = updateState(metadata.hdr.ipv4, tagged StructDefines::NotPresent);
        StateDeparseUdp :
            metadata.hdr.udp = updateState(metadata.hdr.udp, tagged StructDefines::NotPresent);
        StateDeparseHeader0 :
            metadata.hdr.header_0 = updateState(metadata.hdr.header_0, tagged StructDefines::NotPresent);
        StateDeparseHeader1 :
            metadata.hdr.header_1 = updateState(metadata.hdr.header_1, tagged StructDefines::NotPresent);
        StateDeparseHeader2 :
            metadata.hdr.header_2 = updateState(metadata.hdr.header_2, tagged StructDefines::NotPresent);
        StateDeparseHeader3 :
            metadata.hdr.header_3 = updateState(metadata.hdr.header_3, tagged StructDefines::NotPresent);
        StateDeparseHeader4 :
            metadata.hdr.header_4 = updateState(metadata.hdr.header_4, tagged StructDefines::NotPresent);
        StateDeparseHeader5 :
            metadata.hdr.header_5 = updateState(metadata.hdr.header_5, tagged StructDefines::NotPresent);
        StateDeparseHeader6 :
            metadata.hdr.header_6 = updateState(metadata.hdr.header_6, tagged StructDefines::NotPresent);
        StateDeparseHeader7 :
            metadata.hdr.header_7 = updateState(metadata.hdr.header_7, tagged StructDefines::NotPresent);
        StateDeparseHeader8 :
            metadata.hdr.header_8 = updateState(metadata.hdr.header_8, tagged StructDefines::NotPresent);
        StateDeparseHeader9 :
            metadata.hdr.header_9 = updateState(metadata.hdr.header_9, tagged StructDefines::NotPresent);
        StateDeparseHeader10 :
            metadata.hdr.header_10 = updateState(metadata.hdr.header_10, tagged StructDefines::NotPresent);
        StateDeparseHeader11 :
            metadata.hdr.header_11 = updateState(metadata.hdr.header_11, tagged StructDefines::NotPresent);
        StateDeparseHeader12 :
            metadata.hdr.header_12 = updateState(metadata.hdr.header_12, tagged StructDefines::NotPresent);
        StateDeparseHeader13 :
            metadata.hdr.header_13 = updateState(metadata.hdr.header_13, tagged StructDefines::NotPresent);
        StateDeparseHeader14 :
            metadata.hdr.header_14 = updateState(metadata.hdr.header_14, tagged StructDefines::NotPresent);
        StateDeparseHeader15 :
            metadata.hdr.header_15 = updateState(metadata.hdr.header_15, tagged StructDefines::NotPresent);
        StateDeparseHeader16 :
            metadata.hdr.header_16 = updateState(metadata.hdr.header_16, tagged StructDefines::NotPresent);
        StateDeparseHeader17 :
            metadata.hdr.header_17 = updateState(metadata.hdr.header_17, tagged StructDefines::NotPresent);
        StateDeparseHeader18 :
            metadata.hdr.header_18 = updateState(metadata.hdr.header_18, tagged StructDefines::NotPresent);
        StateDeparseTcp :
            metadata.hdr.tcp = updateState(metadata.hdr.tcp, tagged StructDefines::NotPresent);
    endcase
    return metadata;
endfunction
let initState = StateDeparseEthernet;
`endif  // DEPARSER_STATE
