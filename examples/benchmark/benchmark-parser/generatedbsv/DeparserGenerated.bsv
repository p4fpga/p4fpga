`ifdef DEPARSER_STRUCT
typedef enum {
    StateDeparseStart,
    StateDeparseEthernet,
    StateDeparsePtp,
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
    StateDeparseHeader19,
    StateDeparseHeader20,
    StateDeparseHeader21,
    StateDeparseHeader22,
    StateDeparseHeader23,
    StateDeparseHeader24,
    StateDeparseHeader25,
    StateDeparseHeader26,
    StateDeparseHeader27,
    StateDeparseHeader28,
    StateDeparseHeader29,
    StateDeparseHeader30,
    StateDeparseHeader31
} DeparserState deriving (Bits, Eq, FShow);
`endif  // DEPARSER_STRUCT
`ifdef DEPARSER_RULES
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_ethernet, StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseEthernet, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_ptp, StateDeparsePtp, 352))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparsePtp, 352))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparsePtp, 352))));
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
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_19, StateDeparseHeader19, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader19, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader19, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_20, StateDeparseHeader20, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader20, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader20, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_21, StateDeparseHeader21, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader21, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader21, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_22, StateDeparseHeader22, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader22, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader22, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_23, StateDeparseHeader23, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader23, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader23, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_24, StateDeparseHeader24, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader24, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader24, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_25, StateDeparseHeader25, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader25, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader25, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_26, StateDeparseHeader26, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader26, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader26, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_27, StateDeparseHeader27, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader27, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader27, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_28, StateDeparseHeader28, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader28, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader28, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_29, StateDeparseHeader29, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader29, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader29, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_30, StateDeparseHeader30, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader30, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader30, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_header_31, StateDeparseHeader31, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseHeader31, 16))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseHeader31, 16))));
Vector#(102, Rules) fsmRules = toVector(deparse_fsm);
`endif  // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_ethernet <- mkPulseWire();
PulseWire w_ptp <- mkPulseWire();
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
PulseWire w_header_19 <- mkPulseWire();
PulseWire w_header_20 <- mkPulseWire();
PulseWire w_header_21 <- mkPulseWire();
PulseWire w_header_22 <- mkPulseWire();
PulseWire w_header_23 <- mkPulseWire();
PulseWire w_header_24 <- mkPulseWire();
PulseWire w_header_25 <- mkPulseWire();
PulseWire w_header_26 <- mkPulseWire();
PulseWire w_header_27 <- mkPulseWire();
PulseWire w_header_28 <- mkPulseWire();
PulseWire w_header_29 <- mkPulseWire();
PulseWire w_header_30 <- mkPulseWire();
PulseWire w_header_31 <- mkPulseWire();

function Bit#(35) nextDeparseState(MetadataT metadata);
    Vector#(35, Bool) headerValid;
    headerValid[0] = False;
    headerValid[1] = checkForward(metadata.hdr.ethernet);
    headerValid[2] = checkForward(metadata.hdr.ptp);
    headerValid[3] = checkForward(metadata.hdr.header_0);
    headerValid[4] = checkForward(metadata.hdr.header_1);
    headerValid[5] = checkForward(metadata.hdr.header_2);
    headerValid[6] = checkForward(metadata.hdr.header_3);
    headerValid[7] = checkForward(metadata.hdr.header_4);
    headerValid[8] = checkForward(metadata.hdr.header_5);
    headerValid[9] = checkForward(metadata.hdr.header_6);
    headerValid[10] = checkForward(metadata.hdr.header_7);
    headerValid[11] = checkForward(metadata.hdr.header_8);
    headerValid[12] = checkForward(metadata.hdr.header_9);
    headerValid[13] = checkForward(metadata.hdr.header_10);
    headerValid[14] = checkForward(metadata.hdr.header_11);
    headerValid[15] = checkForward(metadata.hdr.header_12);
    headerValid[16] = checkForward(metadata.hdr.header_13);
    headerValid[17] = checkForward(metadata.hdr.header_14);
    headerValid[18] = checkForward(metadata.hdr.header_15);
    headerValid[19] = checkForward(metadata.hdr.header_16);
    headerValid[20] = checkForward(metadata.hdr.header_17);
    headerValid[21] = checkForward(metadata.hdr.header_18);
    headerValid[22] = checkForward(metadata.hdr.header_19);
    headerValid[23] = checkForward(metadata.hdr.header_20);
    headerValid[24] = checkForward(metadata.hdr.header_21);
    headerValid[25] = checkForward(metadata.hdr.header_22);
    headerValid[26] = checkForward(metadata.hdr.header_23);
    headerValid[27] = checkForward(metadata.hdr.header_24);
    headerValid[28] = checkForward(metadata.hdr.header_25);
    headerValid[29] = checkForward(metadata.hdr.header_26);
    headerValid[30] = checkForward(metadata.hdr.header_27);
    headerValid[31] = checkForward(metadata.hdr.header_28);
    headerValid[32] = checkForward(metadata.hdr.header_29);
    headerValid[33] = checkForward(metadata.hdr.header_30);
    headerValid[34] = checkForward(metadata.hdr.header_31);
    let vec = pack(headerValid);
    return vec;
endfunction

function Action transit_next_state(MetadataT metadata);
    action
    let vec = nextDeparseState(metadata);
    if (vec == 0) begin
        header_done <= True;
    end
    else begin
        Bit#(6) nextHeader = truncate(pack(countZerosLSB(vec)% 35));
        DeparserState nextState = unpack(nextHeader);
        case (nextState) matches
            StateDeparseEthernet: w_ethernet.send();
            StateDeparsePtp: w_ptp.send();
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
            StateDeparseHeader19: w_header_19.send();
            StateDeparseHeader20: w_header_20.send();
            StateDeparseHeader21: w_header_21.send();
            StateDeparseHeader22: w_header_22.send();
            StateDeparseHeader23: w_header_23.send();
            StateDeparseHeader24: w_header_24.send();
            StateDeparseHeader25: w_header_25.send();
            StateDeparseHeader26: w_header_26.send();
            StateDeparseHeader27: w_header_27.send();
            StateDeparseHeader28: w_header_28.send();
            StateDeparseHeader29: w_header_29.send();
            StateDeparseHeader30: w_header_30.send();
            StateDeparseHeader31: w_header_31.send();
            default: $display("ERROR: unknown states.");
        endcase
    end
    endaction
endfunction
function MetadataT update_metadata(DeparserState state);
    let metadata = rg_metadata;
    case (state) matches
        StateDeparseEthernet :
            metadata.hdr.ethernet = updateState(metadata.hdr.ethernet, tagged StructDefines::NotPresent);
        StateDeparsePtp :
            metadata.hdr.ptp = updateState(metadata.hdr.ptp, tagged StructDefines::NotPresent);
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
        StateDeparseHeader19 :
            metadata.hdr.header_19 = updateState(metadata.hdr.header_19, tagged StructDefines::NotPresent);
        StateDeparseHeader20 :
            metadata.hdr.header_20 = updateState(metadata.hdr.header_20, tagged StructDefines::NotPresent);
        StateDeparseHeader21 :
            metadata.hdr.header_21 = updateState(metadata.hdr.header_21, tagged StructDefines::NotPresent);
        StateDeparseHeader22 :
            metadata.hdr.header_22 = updateState(metadata.hdr.header_22, tagged StructDefines::NotPresent);
        StateDeparseHeader23 :
            metadata.hdr.header_23 = updateState(metadata.hdr.header_23, tagged StructDefines::NotPresent);
        StateDeparseHeader24 :
            metadata.hdr.header_24 = updateState(metadata.hdr.header_24, tagged StructDefines::NotPresent);
        StateDeparseHeader25 :
            metadata.hdr.header_25 = updateState(metadata.hdr.header_25, tagged StructDefines::NotPresent);
        StateDeparseHeader26 :
            metadata.hdr.header_26 = updateState(metadata.hdr.header_26, tagged StructDefines::NotPresent);
        StateDeparseHeader27 :
            metadata.hdr.header_27 = updateState(metadata.hdr.header_27, tagged StructDefines::NotPresent);
        StateDeparseHeader28 :
            metadata.hdr.header_28 = updateState(metadata.hdr.header_28, tagged StructDefines::NotPresent);
        StateDeparseHeader29 :
            metadata.hdr.header_29 = updateState(metadata.hdr.header_29, tagged StructDefines::NotPresent);
        StateDeparseHeader30 :
            metadata.hdr.header_30 = updateState(metadata.hdr.header_30, tagged StructDefines::NotPresent);
        StateDeparseHeader31 :
            metadata.hdr.header_31 = updateState(metadata.hdr.header_31, tagged StructDefines::NotPresent);
    endcase
    return metadata;
endfunction
let initState = StateDeparseEthernet;
`endif  // DEPARSER_STATE
