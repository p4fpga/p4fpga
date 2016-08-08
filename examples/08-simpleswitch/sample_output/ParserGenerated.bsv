
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseIpv4
} ParserState deriving (Bits, Eq, FShow);
`endif //PARSER_STRUCT

`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_ethernet_parse_ipv4.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ethernet_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv4();
  action
    dbprint(3, $format("transit to start"));
    w_parse_ipv4_start.send();
  endaction
endfunction
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_ipv4_start, rl_parse_ethernet_start, rl_parse_ethernet_parse_ipv4, rl_start_parse_ethernet" *)
rule rl_parse_done if ((w_parse_done));
  MetadataT meta = defaultValue;
  let ethernet <- toGet(ethernet_out_ff).get;
  let ipv4 <- toGet(ipv4_out_ff).get;
  if (isValid(ethernet)) begin
    meta.ethernet$dstAddr = tagged Valid fromMaybe(?, ethernet).dstAddr;
    meta.ethernet$srcAddr = tagged Valid fromMaybe(?, ethernet).srcAddr;
  end
  if (isValid(ipv4)) begin
    meta.ipv4$ttl = tagged Valid fromMaybe(?, ipv4).ttl;
    meta.ipv4$dstAddr = tagged Valid fromMaybe(?, ipv4).dstAddr;
    meta.valid_ipv4 = tagged Valid;
  end
  dbprint(3, $format("parse_done"));
  meta_in_ff.enq(meta);
endrule
rule rl_start_parse_ethernet if ((w_start_parse_ethernet));
  parse_state_ff.enq(StateParseEthernet);
  dbprint(3, $format("%s -> %s", "start", "parse_ethernet"));
  fetch_next_header1(112);
endrule
(* fire_when_enabled *)
rule rl_parse_ethernet_load if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] < 112));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ethernet_extract if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] >= 112));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ethernet = extract_ethernet_t(truncate(data));
  compute_next_state_parse_ethernet(ethernet.etherType);
  rg_tmp[0] <= zeroExtend(data >> 112);
  succeed_and_next(112);
  dbprint(3, $format("extract %s", "parse_ethernet"));
  parse_state_ff.deq;
  ethernet_out_ff.enq(tagged Valid ethernet);
endrule
rule rl_parse_ethernet_parse_ipv4 if ((w_parse_ethernet_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_ethernet_start if ((w_parse_ethernet_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ethernet", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_load if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_extract if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] >= 160));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ipv4 = extract_ipv4_t(truncate(data));
  compute_next_state_parse_ipv4();
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("!!extract %s", "parse_ipv4"));
  parse_state_ff.deq;
  ipv4_out_ff.enq(tagged Valid ipv4);
endrule
rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv4", "start"));
  fetch_next_header0(0);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
FIFOF#(Maybe#(EthernetT)) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
//FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- printTimedTraceM("ipv4", mkDFIFOF(tagged Invalid));
FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- printTimedTraceM("ipv4", mkBypassFIFOF);
`endif
