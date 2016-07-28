
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseArp,
  StateParseIpv4,
  StateParseIpv6,
  StateParseUdp,
  StateParsePaxos
} ParserState deriving (Bits, Eq, FShow);
`endif //PARSER_STRUCT

`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp"));
      w_parse_ethernet_parse_arp.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_ethernet_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_ethernet_parse_ipv6.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ethernet_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_arp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_arp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
  action
    let v = {protocol};
    if (v == 'h11) begin
      dbprint(3, $format("transit to parse_udp"));
      w_parse_ipv4_parse_udp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv6();
  action
    dbprint(3, $format("transit to start"));
    w_parse_ipv6_start.send();
  endaction
endfunction
function Action compute_next_state_parse_udp(Bit#(16) dstPort);
  action
    let v = {dstPort};
    if (v == 'h8888) begin
      dbprint(3, $format("transit to parse_paxos"));
      w_parse_udp_parse_paxos.send();
    end
    else if (v == 'h8889) begin
      dbprint(3, $format("transit to parse_paxos"));
      w_parse_udp_parse_paxos.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_udp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_paxos();
  action
    dbprint(3, $format("transit to start"));
    w_parse_paxos_start.send();
  endaction
endfunction
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_ipv4_parse_udp, rl_parse_paxos_start, rl_start_parse_ethernet, rl_parse_udp_start, rl_parse_ipv4_start, rl_parse_ethernet_start, rl_parse_udp_parse_paxos, rl_parse_arp_start, rl_parse_ethernet_parse_ipv4, rl_parse_ethernet_parse_ipv6, rl_parse_ipv6_start, rl_parse_ethernet_parse_arp" *)
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
  let ethernet_t = extract_ethernet_t(truncate(data));
  compute_next_state_parse_ethernet(ethernet_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 112);
  succeed_and_next(112);
  dbprint(3, $format("extract %s", "parse_ethernet"));
  parse_state_ff.deq;
endrule
rule rl_parse_ethernet_parse_arp if ((w_parse_ethernet_parse_arp));
  parse_state_ff.enq(StateParseArp);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_arp"));
  fetch_next_header0(224);
endrule
rule rl_parse_ethernet_parse_ipv4 if ((w_parse_ethernet_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_ethernet_parse_ipv6 if ((w_parse_ethernet_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_ethernet_start if ((w_parse_ethernet_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ethernet", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_arp_load if ((parse_state_ff.first == StateParseArp) && (rg_buffered[0] < 224));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_arp_extract if ((parse_state_ff.first == StateParseArp) && (rg_buffered[0] >= 224));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_arp();
  rg_tmp[0] <= zeroExtend(data >> 224);
  succeed_and_next(224);
  dbprint(3, $format("extract %s", "parse_arp"));
  parse_state_ff.deq;
endrule
rule rl_parse_arp_start if ((w_parse_arp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_arp", "start"));
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
  let ipv4_t = extract_ipv4_t(truncate(data));
  compute_next_state_parse_ipv4(ipv4_t.protocol);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_ipv4"));
  parse_state_ff.deq;
endrule
rule rl_parse_ipv4_parse_udp if ((w_parse_ipv4_parse_udp));
  parse_state_ff.enq(StateParseUdp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv4", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_ipv6_load if ((parse_state_ff.first == StateParseIpv6) && (rg_buffered[0] < 320));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ipv6_extract if ((parse_state_ff.first == StateParseIpv6) && (rg_buffered[0] >= 320));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_ipv6();
  rg_tmp[0] <= zeroExtend(data >> 320);
  succeed_and_next(320);
  dbprint(3, $format("extract %s", "parse_ipv6"));
  parse_state_ff.deq;
endrule
rule rl_parse_ipv6_start if ((w_parse_ipv6_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv6", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_udp_load if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_udp_extract if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let udp_t = extract_udp_t(truncate(data));
  compute_next_state_parse_udp(udp_t.dstPort);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_udp"));
  parse_state_ff.deq;
endrule
rule rl_parse_udp_parse_paxos if ((w_parse_udp_parse_paxos));
  parse_state_ff.enq(StateParsePaxos);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_paxos"));
  fetch_next_header0(352);
endrule
rule rl_parse_udp_start if ((w_parse_udp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_udp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_paxos_load if ((parse_state_ff.first == StateParsePaxos) && (rg_buffered[0] < 352));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_paxos_extract if ((parse_state_ff.first == StateParsePaxos) && (rg_buffered[0] >= 352));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_paxos();
  rg_tmp[0] <= zeroExtend(data >> 352);
  succeed_and_next(352);
  dbprint(3, $format("extract %s", "parse_paxos"));
  parse_state_ff.deq;
endrule
rule rl_parse_paxos_start if ((w_parse_paxos_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_paxos", "start"));
  fetch_next_header0(0);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
PulseWire w_parse_paxos_start <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
PulseWire w_parse_udp_start <- mkPulseWireOR();
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_udp_parse_paxos <- mkPulseWireOR();
PulseWire w_parse_arp_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_ipv6_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_arp <- mkPulseWireOR();
`endif