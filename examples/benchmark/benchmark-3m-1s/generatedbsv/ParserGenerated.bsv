`ifdef PARSER_STRUCT
typedef enum {
    StateParseEthernet,
    StateParseIpv4,
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
function Action compute_next_state_parse_ipv4();
    action
    w_parse_ipv4_accept.send();
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
typedef 160 ParseIpv4Sz;
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
        StateParseIpv4 : begin
            let ipv4 = extract_ipv4_t(truncate(data));
            Header#(Ipv4T) header0 = defaultValue;
            header0.hdr = ipv4;
            header0.state = tagged Forward;
            ipv4_out_ff.enq(tagged Valid header0);
            compute_next_state_parse_ipv4();
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
`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(StateParseIpv4, valueOf(ParseIpv4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(StateParseIpv4, valueOf(ParseIpv4Sz)))));
`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_parse_ipv4_accept))));
Vector#(7, Rules) fsmRules = toVector(parse_fsm);
`endif
`ifdef PARSER_RULES
rule rl_accept if (delay_ff.notEmpty);
    delay_ff.deq;
    MetadataT meta = defaultValue;
    meta.meta.routing_metadata = rg_routing_metadata;
    let ethernet <- toGet(ethernet_out_ff).get;
    meta.hdr.ethernet = ethernet;
    let ipv4 <- toGet(ipv4_out_ff).get;
    meta.hdr.ipv4 = ipv4;
    rg_tmp[0] <= 0;
    rg_buffered[0] <= 0;
    meta_in_ff.enq(meta);
endrule
`endif
`ifdef PARSER_STATE
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWire();
PulseWire w_parse_ethernet_accept <- mkPulseWire();
PulseWire w_parse_ipv4_accept <- mkPulseWire();
PulseWire w_start_parse_ethernet <- mkPulseWire();
FIFOF#(Maybe#(Header#(EthernetT))) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Header#(Ipv4T))) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
Reg#(Maybe#(RoutingMetadataT)) rg_routing_metadata <- mkReg(tagged Invalid);
`endif
