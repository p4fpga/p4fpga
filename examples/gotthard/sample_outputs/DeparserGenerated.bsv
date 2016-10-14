`ifdef DEPARSER_STRUCT
typedef enum {
    StateDeparseStart,
    StateDeparseEthernet,
    StateDeparseIpv4,
    StateDeparseUdp,
    StateDeparseGotthardHdr,
    StateDeparseGotthardOp0,
    StateDeparseGotthardOp1,
    StateDeparseGotthardOp2,
    StateDeparseGotthardOp3,
    StateDeparseGotthardOp4,
    StateDeparseGotthardOp5,
    StateDeparseGotthardOp6,
    StateDeparseGotthardOp7,
    StateDeparseGotthardOp8,
    StateDeparseGotthardOp9
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
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_hdr, StateDeparseGotthardHdr, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardHdr, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardHdr, 112))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op0, StateDeparseGotthardOp0, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp0, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp0, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op1, StateDeparseGotthardOp1, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp1, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp1, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op2, StateDeparseGotthardOp2, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp2, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp2, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op3, StateDeparseGotthardOp3, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp3, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp3, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op4, StateDeparseGotthardOp4, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp4, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp4, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op5, StateDeparseGotthardOp5, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp5, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp5, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op6, StateDeparseGotthardOp6, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp6, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp6, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op7, StateDeparseGotthardOp7, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp7, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp7, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op8, StateDeparseGotthardOp8, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp8, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp8, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_gotthard_op9, StateDeparseGotthardOp9, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseGotthardOp9, 1064))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseGotthardOp9, 1064))));
Vector#(42, Rules) fsmRules = toVector(deparse_fsm);
`endif  // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_ethernet <- mkPulseWire();
PulseWire w_ipv4 <- mkPulseWire();
PulseWire w_udp <- mkPulseWire();
PulseWire w_gotthard_hdr <- mkPulseWire();
PulseWire w_gotthard_op0 <- mkPulseWire();
PulseWire w_gotthard_op1 <- mkPulseWire();
PulseWire w_gotthard_op2 <- mkPulseWire();
PulseWire w_gotthard_op3 <- mkPulseWire();
PulseWire w_gotthard_op4 <- mkPulseWire();
PulseWire w_gotthard_op5 <- mkPulseWire();
PulseWire w_gotthard_op6 <- mkPulseWire();
PulseWire w_gotthard_op7 <- mkPulseWire();
PulseWire w_gotthard_op8 <- mkPulseWire();
PulseWire w_gotthard_op9 <- mkPulseWire();

function Bit#(15) nextDeparseState(MetadataT metadata);
    Vector#(15, Bool) headerValid;
    headerValid[0] = False;
    headerValid[1] = checkForward(metadata.hdr.ethernet);
    headerValid[2] = checkForward(metadata.hdr.ipv4);
    headerValid[3] = checkForward(metadata.hdr.udp);
    headerValid[4] = checkForward(metadata.hdr.gotthard_hdr);
    headerValid[5] = checkForward(metadata.hdr.gotthard_op[0]);
    headerValid[6] = checkForward(metadata.hdr.gotthard_op[1]);
    headerValid[7] = checkForward(metadata.hdr.gotthard_op[2]);
    headerValid[8] = checkForward(metadata.hdr.gotthard_op[3]);
    headerValid[9] = checkForward(metadata.hdr.gotthard_op[4]);
    headerValid[10] = checkForward(metadata.hdr.gotthard_op[5]);
    headerValid[11] = checkForward(metadata.hdr.gotthard_op[6]);
    headerValid[12] = checkForward(metadata.hdr.gotthard_op[7]);
    headerValid[13] = checkForward(metadata.hdr.gotthard_op[8]);
    headerValid[14] = checkForward(metadata.hdr.gotthard_op[9]);
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
        Bit#(4) nextHeader = truncate(pack(countZerosLSB(vec)              ));
        DeparserState nextState = unpack(nextHeader);
        case (nextState) matches
            StateDeparseEthernet: w_ethernet.send();
            StateDeparseIpv4: w_ipv4.send();
            StateDeparseUdp: w_udp.send();
            StateDeparseGotthardHdr: w_gotthard_hdr.send();
            StateDeparseGotthardOp0: w_gotthard_op0.send();
            StateDeparseGotthardOp1: w_gotthard_op1.send();
            StateDeparseGotthardOp2: w_gotthard_op2.send();
            StateDeparseGotthardOp3: w_gotthard_op3.send();
            StateDeparseGotthardOp4: w_gotthard_op4.send();
            StateDeparseGotthardOp5: w_gotthard_op5.send();
            StateDeparseGotthardOp6: w_gotthard_op6.send();
            StateDeparseGotthardOp7: w_gotthard_op7.send();
            StateDeparseGotthardOp8: w_gotthard_op8.send();
            StateDeparseGotthardOp9: w_gotthard_op9.send();
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
        StateDeparseGotthardHdr :
            metadata.hdr.gotthard_hdr = updateState(metadata.hdr.gotthard_hdr, tagged StructDefines::NotPresent);
        StateDeparseGotthardOp0 :
            metadata.hdr.gotthard_op[0] = updateState(metadata.hdr.gotthard_op[0], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp1 :
            metadata.hdr.gotthard_op[1] = updateState(metadata.hdr.gotthard_op[1], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp2 :
            metadata.hdr.gotthard_op[2] = updateState(metadata.hdr.gotthard_op[2], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp3 :
            metadata.hdr.gotthard_op[3] = updateState(metadata.hdr.gotthard_op[3], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp4 :
            metadata.hdr.gotthard_op[4] = updateState(metadata.hdr.gotthard_op[4], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp5 :
            metadata.hdr.gotthard_op[5] = updateState(metadata.hdr.gotthard_op[5], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp6 :
            metadata.hdr.gotthard_op[6] = updateState(metadata.hdr.gotthard_op[6], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp7 :
            metadata.hdr.gotthard_op[7] = updateState(metadata.hdr.gotthard_op[7], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp8 :
            metadata.hdr.gotthard_op[8] = updateState(metadata.hdr.gotthard_op[8], tagged StructDefines::NotPresent);
        StateDeparseGotthardOp9 :
            metadata.hdr.gotthard_op[9] = updateState(metadata.hdr.gotthard_op[9], tagged StructDefines::NotPresent);
    endcase
    return metadata;
endfunction
let initState = StateDeparseEthernet;
`endif  // DEPARSER_STATE
