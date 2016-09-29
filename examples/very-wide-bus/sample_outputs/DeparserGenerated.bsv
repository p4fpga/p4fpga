`ifdef DEPARSER_STRUCT
typedef enum {
    StateDeparseStart,
    StateDeparseEthernet,
    StateDeparseIpv4
} DeparserState deriving (Bits, Eq, FShow);
`endif  // DEPARSER_STRUCT
`ifdef DEPARSER_RULES
(* mutually_exclusive="rl_deparse_ethernet_next,rl_deparse_ipv4_next" *)
rule rl_deparse_ethernet_next if (w_ethernet);
    deparse_state_ff.enq(StateDeparseEthernet);
    fetch_next_header(112);
endrule

rule rl_deparse_ethernet_load if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] < 112));
    dbprint(3, $format("deparse load ethernet"));
    rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);
    UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
    move_buffered_amt(cExtend(n_bits_used));
endrule

rule rl_deparse_ethernet_send if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] > 112));
    dbprint(3, $format("deparse send ethernet"));
    succeed_and_next(112);
    deparse_state_ff.deq;
    let metadata = meta[0];
    metadata.ethernet = tagged StructDefines::NotPresent;
    transit_next_state(metadata);
    meta[0] <= metadata;
endrule

rule rl_deparse_ipv4_next if (w_ipv4);
    deparse_state_ff.enq(StateDeparseIpv4);
    fetch_next_header(160);
endrule

rule rl_deparse_ipv4_load if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] < 160));
    dbprint(3, $format("deparse load ipv4"));
    rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);
    UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
    move_buffered_amt(cExtend(n_bits_used));
endrule

rule rl_deparse_ipv4_send if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] > 160));
    dbprint(3, $format("deparse send ipv4"));
    succeed_and_next(160);
    deparse_state_ff.deq;
    let metadata = meta[0];
    metadata.ipv4 = tagged StructDefines::NotPresent;
    transit_next_state(metadata);
    meta[0] <= metadata;
endrule

`endif  // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_ethernet <- mkPulseWire();
PulseWire w_ipv4 <- mkPulseWire();

function Bit#(3) nextDeparseState(MetadataT metadata);
    Vector#(3, Bool) headerValid;
    headerValid[0] = False;
    headerValid[1] = metadata.ethernet matches tagged Forward ? True : False;
    headerValid[2] = metadata.ipv4 matches tagged Forward ? True : False;
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
        Bit#(2) nextHeader = truncate(pack(countZerosLSB(vec)% 3));
        DeparserState nextState = unpack(nextHeader);
        case (nextState) matches
            StateDeparseEthernet: w_ethernet.send();
            StateDeparseIpv4: w_ipv4.send();
            default: $display("ERROR: unknown states.");
        endcase
    end
    endaction
endfunction
let initState = StateDeparseEthernet;
`endif  // DEPARSER_STATE
