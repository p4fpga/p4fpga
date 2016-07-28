
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseIpv4,
  StateParseTcp,
  StateParseTcpOptions,
  StateParseEnd,
  StateParseNop,
  StateParseMss,
  StateParseWscale,
  StateParseSack,
  StateParseTs
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
function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
  action
    let v = {protocol};
    if (v == 'h06) begin
      dbprint(3, $format("transit to parse_tcp"));
      w_parse_ipv4_parse_tcp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_tcp(Bit#(1) syn);
  action
    let v = {syn};
    if (v == 'h01) begin
      dbprint(3, $format("transit to parse_tcp_options"));
      w_parse_tcp_parse_tcp_options.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_tcp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_tcp_options(Bit#(8) parse_tcp_options_counter, Bit#(8) current);
  action
    let v = {parse_tcp_options_counter, current};
    if ((v & 'hff00) == 'h0000) begin
      dbprint(3, $format("transit to start"));
      w_parse_tcp_options_start.send();
    end
    else if ((v & 'h00ff) == 'h0000) begin
      dbprint(3, $format("transit to parse_end"));
      w_parse_tcp_options_parse_end.send();
    end
    else if ((v & 'h00ff) == 'h0001) begin
      dbprint(3, $format("transit to parse_nop"));
      w_parse_tcp_options_parse_nop.send();
    end
    else if ((v & 'h00ff) == 'h0002) begin
      dbprint(3, $format("transit to parse_mss"));
      w_parse_tcp_options_parse_mss.send();
    end
    else if ((v & 'h00ff) == 'h0003) begin
      dbprint(3, $format("transit to parse_wscale"));
      w_parse_tcp_options_parse_wscale.send();
    end
    else if ((v & 'h00ff) == 'h0004) begin
      dbprint(3, $format("transit to parse_sack"));
      w_parse_tcp_options_parse_sack.send();
    end
    else if ((v & 'h00ff) == 'h0008) begin
      dbprint(3, $format("transit to parse_ts"));
      w_parse_tcp_options_parse_ts.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_end();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_end_parse_tcp_options.send();
  endaction
endfunction
function Action compute_next_state_parse_nop();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_nop_parse_tcp_options.send();
  endaction
endfunction
function Action compute_next_state_parse_mss();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_mss_parse_tcp_options.send();
  endaction
endfunction
function Action compute_next_state_parse_wscale();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_wscale_parse_tcp_options.send();
  endaction
endfunction
function Action compute_next_state_parse_sack();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_sack_parse_tcp_options.send();
  endaction
endfunction
function Action compute_next_state_parse_ts();
  action
    dbprint(3, $format("transit to parse_tcp_options"));
    w_parse_ts_parse_tcp_options.send();
  endaction
endfunction
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_tcp_options_parse_nop, rl_parse_tcp_options_start, rl_parse_wscale_parse_tcp_options, rl_start_parse_ethernet, rl_parse_end_parse_tcp_options, rl_parse_ipv4_start, rl_parse_tcp_options_parse_wscale, rl_parse_ethernet_start, rl_parse_sack_parse_tcp_options, rl_parse_ts_parse_tcp_options, rl_parse_mss_parse_tcp_options, rl_parse_tcp_parse_tcp_options, rl_parse_tcp_start, rl_parse_ethernet_parse_ipv4, rl_parse_tcp_options_parse_mss, rl_parse_tcp_options_parse_sack, rl_parse_tcp_options_parse_end, rl_parse_tcp_options_parse_ts, rl_parse_ipv4_parse_tcp, rl_parse_nop_parse_tcp_options" *)
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
  let ipv4_t = extract_ipv4_t(truncate(data));
  compute_next_state_parse_ipv4(ipv4_t.protocol);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_ipv4"));
  parse_state_ff.deq;
endrule
rule rl_parse_ipv4_parse_tcp if ((w_parse_ipv4_parse_tcp));
  parse_state_ff.enq(StateParseTcp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_tcp"));
  fetch_next_header0(160);
endrule
rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv4", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_tcp_load if ((parse_state_ff.first == StateParseTcp) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_tcp_extract if ((parse_state_ff.first == StateParseTcp) && (rg_buffered[0] >= 160));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let tcp_t = extract_tcp_t(truncate(data));
  compute_next_state_parse_tcp(tcp_t.syn);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_tcp"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= ((tcp$dataOffset*'h4)-'h14);
endrule
rule rl_parse_tcp_parse_tcp_options if ((w_parse_tcp_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_tcp", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
rule rl_parse_tcp_start if ((w_parse_tcp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_tcp", "start"));
  fetch_next_header0(0);
endrule
rule rl_parse_tcp_options_start if ((w_parse_tcp_options_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "start"));
  fetch_next_header1(0);
endrule
rule rl_parse_tcp_options_parse_end if ((w_parse_tcp_options_parse_end));
  parse_state_ff.enq(StateParseEnd);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_end"));
  fetch_next_header1(8);
endrule
rule rl_parse_tcp_options_parse_nop if ((w_parse_tcp_options_parse_nop));
  parse_state_ff.enq(StateParseNop);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_nop"));
  fetch_next_header1(8);
endrule
rule rl_parse_tcp_options_parse_mss if ((w_parse_tcp_options_parse_mss));
  parse_state_ff.enq(StateParseMss);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_mss"));
  fetch_next_header1(32);
endrule
rule rl_parse_tcp_options_parse_wscale if ((w_parse_tcp_options_parse_wscale));
  parse_state_ff.enq(StateParseWscale);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_wscale"));
  fetch_next_header1(24);
endrule
rule rl_parse_tcp_options_parse_sack if ((w_parse_tcp_options_parse_sack));
  parse_state_ff.enq(StateParseSack);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_sack"));
  fetch_next_header1(16);
endrule
rule rl_parse_tcp_options_parse_ts if ((w_parse_tcp_options_parse_ts));
  parse_state_ff.enq(StateParseTs);
  dbprint(3, $format("%s -> %s", "parse_tcp_options", "parse_ts"));
  fetch_next_header1(80);
endrule
(* fire_when_enabled *)
rule rl_parse_end_load if ((parse_state_ff.first == StateParseEnd) && (rg_buffered[0] < 8));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_end_extract if ((parse_state_ff.first == StateParseEnd) && (rg_buffered[0] >= 8));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_end();
  rg_tmp[0] <= zeroExtend(data >> 8);
  succeed_and_next(8);
  dbprint(3, $format("extract %s", "parse_end"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'h1);
endrule
rule rl_parse_end_parse_tcp_options if ((w_parse_end_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_end", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_nop_load if ((parse_state_ff.first == StateParseNop) && (rg_buffered[0] < 8));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_nop_extract if ((parse_state_ff.first == StateParseNop) && (rg_buffered[0] >= 8));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_nop();
  rg_tmp[0] <= zeroExtend(data >> 8);
  succeed_and_next(8);
  dbprint(3, $format("extract %s", "parse_nop"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'h1);
endrule
rule rl_parse_nop_parse_tcp_options if ((w_parse_nop_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_nop", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_mss_load if ((parse_state_ff.first == StateParseMss) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mss_extract if ((parse_state_ff.first == StateParseMss) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mss();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_mss"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'h4);
endrule
rule rl_parse_mss_parse_tcp_options if ((w_parse_mss_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_mss", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_wscale_load if ((parse_state_ff.first == StateParseWscale) && (rg_buffered[0] < 24));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_wscale_extract if ((parse_state_ff.first == StateParseWscale) && (rg_buffered[0] >= 24));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_wscale();
  rg_tmp[0] <= zeroExtend(data >> 24);
  succeed_and_next(24);
  dbprint(3, $format("extract %s", "parse_wscale"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'h3);
endrule
rule rl_parse_wscale_parse_tcp_options if ((w_parse_wscale_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_wscale", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_sack_load if ((parse_state_ff.first == StateParseSack) && (rg_buffered[0] < 16));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_sack_extract if ((parse_state_ff.first == StateParseSack) && (rg_buffered[0] >= 16));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_sack();
  rg_tmp[0] <= zeroExtend(data >> 16);
  succeed_and_next(16);
  dbprint(3, $format("extract %s", "parse_sack"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'h2);
endrule
rule rl_parse_sack_parse_tcp_options if ((w_parse_sack_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_sack", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_ts_load if ((parse_state_ff.first == StateParseTs) && (rg_buffered[0] < 80));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ts_extract if ((parse_state_ff.first == StateParseTs) && (rg_buffered[0] >= 80));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_ts();
  rg_tmp[0] <= zeroExtend(data >> 80);
  succeed_and_next(80);
  dbprint(3, $format("extract %s", "parse_ts"));
  parse_state_ff.deq;
  my_metadata$parse_tcp_options_counter[0] <= (my_metadata$parse_tcp_options_counter[0]-'ha);
endrule
rule rl_parse_ts_parse_tcp_options if ((w_parse_ts_parse_tcp_options));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], lookahead);
  dbprint(3, $format("counter", my_metadata$parse_tcp_options_counter[1], lookahead ));
  dbprint(3, $format("%s -> %s", "parse_ts", "parse_tcp_options"));
  fetch_next_header0(0);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_tcp_options_parse_nop <- mkPulseWireOR();
PulseWire w_parse_tcp_options_start <- mkPulseWireOR();
PulseWire w_parse_wscale_parse_tcp_options <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
PulseWire w_parse_end_parse_tcp_options <- mkPulseWireOR();
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_tcp_options_parse_wscale <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_sack_parse_tcp_options <- mkPulseWireOR();
PulseWire w_parse_ts_parse_tcp_options <- mkPulseWireOR();
PulseWire w_parse_mss_parse_tcp_options <- mkPulseWireOR();
PulseWire w_parse_tcp_parse_tcp_options <- mkPulseWireOR();
PulseWire w_parse_tcp_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_tcp_options_parse_mss <- mkPulseWireOR();
PulseWire w_parse_tcp_options_parse_sack <- mkPulseWireOR();
PulseWire w_parse_tcp_options_parse_end <- mkPulseWireOR();
PulseWire w_parse_tcp_options_parse_ts <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
PulseWire w_parse_nop_parse_tcp_options <- mkPulseWireOR();

Array#(Reg#(Bit#(8))) my_metadata$parse_tcp_options_counter <- mkCReg(2, 0);
Reg#(Bit#(8)) tcp$dataOffset <- mkReg(0);
`endif
