`ifdef DEPARSER_STRUCT
typedef enum {
    StateDeparseStart,
    StateDeparseEthernet,
    StateDeparseIpv4,
    StateDeparseUdp,
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
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseNextRule(w_tcp, StateDeparseTcp, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseLoadRule(StateDeparseTcp, 160))));
`COLLECT_RULE(deparse_fsm, joinRules(vec(genDeparseSendRule(StateDeparseTcp, 160))));
Vector#(12, Rules) fsmRules = toVector(deparse_fsm);
`endif  // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_ethernet <- mkPulseWire();
PulseWire w_ipv4 <- mkPulseWire();
PulseWire w_udp <- mkPulseWire();
PulseWire w_tcp <- mkPulseWire();

function Bit#(5) nextDeparseState(MetadataT metadata);
    Vector#(5, Bool) headerValid;
    headerValid[0] = False;
    headerValid[1] = checkForward(metadata.hdr.ethernet);
    headerValid[2] = checkForward(metadata.hdr.ipv4);
    headerValid[3] = checkForward(metadata.hdr.udp);
    headerValid[4] = checkForward(metadata.hdr.tcp);
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
        Bit#(3) nextHeader = truncate(pack(countZerosLSB(vec)% 5));
        DeparserState nextState = unpack(nextHeader);
        case (nextState) matches
            StateDeparseEthernet: w_ethernet.send();
            StateDeparseIpv4: w_ipv4.send();
            StateDeparseUdp: w_udp.send();
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
        StateDeparseTcp :
            metadata.hdr.tcp = updateState(metadata.hdr.tcp, tagged StructDefines::NotPresent);
    endcase
    return metadata;
endfunction
let initState = StateDeparseEthernet;
`endif  // DEPARSER_STATE
