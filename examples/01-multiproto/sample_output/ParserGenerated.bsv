
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseVlanTag,
  StateParseIpv4,
  StateParseIpv6,
  StateParseIcmp,
  StateParseTcp,
  StateParseUdp
} ParserState deriving (Bits, Eq, FShow);
`endif //PARSER_STRUCT

`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h8100) begin
      dbprint(3, $format("transit to parse_vlan_tag"));
      w_parse_ethernet_parse_vlan_tag.send();
    end
    else if (v == 'h9100) begin
      dbprint(3, $format("transit to parse_vlan_tag"));
      w_parse_ethernet_parse_vlan_tag.send();
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
function Action compute_next_state_parse_vlan_tag(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_vlan_tag_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_vlan_tag_parse_ipv6.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_vlan_tag_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv4(Bit#(13) fragOffset, Bit#(4) ihl, Bit#(8) protocol);
  action
    let v = {fragOffset, ihl, protocol};
    if ((v & 'h00000fff) == 'h00000501) begin
      dbprint(3, $format("transit to parse_icmp"));
      w_parse_ipv4_parse_icmp.send();
    end
    else if ((v & 'h00000fff) == 'h00000506) begin
      dbprint(3, $format("transit to parse_tcp"));
      w_parse_ipv4_parse_tcp.send();
    end
    else if ((v & 'h00000fff) == 'h00000511) begin
      dbprint(3, $format("transit to parse_udp"));
      w_parse_ipv4_parse_udp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv6(Bit#(8) nextHdr);
  action
    let v = {nextHdr};
    if (v == 'h01) begin
      dbprint(3, $format("transit to parse_icmp"));
      w_parse_ipv6_parse_icmp.send();
    end
    else if (v == 'h06) begin
      dbprint(3, $format("transit to parse_tcp"));
      w_parse_ipv6_parse_tcp.send();
    end
    else if (v == 'h11) begin
      dbprint(3, $format("transit to parse_udp"));
      w_parse_ipv6_parse_udp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv6_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_icmp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_icmp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_tcp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_tcp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_udp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_udp_start.send();
  endaction
endfunction
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_ipv4_parse_udp, rl_parse_ipv6_parse_tcp, rl_parse_ipv4_parse_icmp, rl_start_parse_ethernet, rl_parse_udp_start, rl_parse_ipv4_start, rl_parse_ethernet_start, rl_parse_ipv6_parse_udp, rl_parse_ipv6_parse_icmp, rl_parse_icmp_start, rl_parse_ethernet_parse_vlan_tag, rl_parse_ethernet_parse_ipv4, rl_parse_ethernet_parse_ipv6, rl_parse_vlan_tag_start, rl_parse_vlan_tag_parse_ipv4, rl_parse_vlan_tag_parse_ipv6, rl_parse_tcp_start, rl_parse_ipv4_parse_tcp, rl_parse_ipv6_start" *)
rule rl_parse_done if ((w_parse_done));
  MetadataT meta = defaultValue;
  let ethernet <- toGet(ethernet_out_ff).get;
  let vlan_tag <- toGet(vlan_tag_out_ff).get;
  let ipv4 <- toGet(ipv4_out_ff).get;
  let ipv6 <- toGet(ipv6_out_ff).get;
  if (isValid(ethernet)) begin
    meta.ethernet$etherType = tagged Valid fromMaybe(?, ethernet).etherType;
    meta.ethernet$srcAddr = tagged Valid fromMaybe(?, ethernet).srcAddr;
  end
  if (isValid(ipv4)) begin
    meta.ipv4$srcAddr = tagged Valid fromMaybe(?, ipv4).srcAddr;
  end
  if (isValid(ipv6)) begin
    meta.ipv6$srcAddr = tagged Valid fromMaybe(?, ipv6).srcAddr;
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
rule rl_parse_ethernet_parse_vlan_tag if ((w_parse_ethernet_parse_vlan_tag));
  parse_state_ff.enq(StateParseVlanTag);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_vlan_tag"));
  fetch_next_header0(32);
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
rule rl_parse_vlan_tag_load if ((parse_state_ff.first == StateParseVlanTag) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_vlan_tag_extract if ((parse_state_ff.first == StateParseVlanTag) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let vlan_tag = extract_vlan_tag_t(truncate(data));
  compute_next_state_parse_vlan_tag(vlan_tag.etherType);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_vlan_tag"));
  parse_state_ff.deq;
  vlan_tag_out_ff.enq(tagged Valid vlan_tag);
endrule
rule rl_parse_vlan_tag_parse_ipv4 if ((w_parse_vlan_tag_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_vlan_tag", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_vlan_tag_parse_ipv6 if ((w_parse_vlan_tag_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_vlan_tag", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_vlan_tag_start if ((w_parse_vlan_tag_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_vlan_tag", "start"));
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
  compute_next_state_parse_ipv4(ipv4.fragOffset,ipv4.ihl,ipv4.protocol);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_ipv4"));
  parse_state_ff.deq;
  ipv4_out_ff.enq(tagged Valid ipv4);
endrule
rule rl_parse_ipv4_parse_icmp if ((w_parse_ipv4_parse_icmp));
  parse_state_ff.enq(StateParseIcmp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_icmp"));
  fetch_next_header0(32);
endrule
rule rl_parse_ipv4_parse_tcp if ((w_parse_ipv4_parse_tcp));
  parse_state_ff.enq(StateParseTcp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_tcp"));
  fetch_next_header0(160);
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
  let ipv6 = extract_ipv6_t(truncate(data));
  compute_next_state_parse_ipv6(ipv6.nextHdr);
  rg_tmp[0] <= zeroExtend(data >> 320);
  succeed_and_next(320);
  dbprint(3, $format("extract %s", "parse_ipv6"));
  parse_state_ff.deq;
  ipv6_out_ff.enq(tagged Valid ipv6);
endrule
rule rl_parse_ipv6_parse_icmp if ((w_parse_ipv6_parse_icmp));
  parse_state_ff.enq(StateParseIcmp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_icmp"));
  fetch_next_header0(32);
endrule
rule rl_parse_ipv6_parse_tcp if ((w_parse_ipv6_parse_tcp));
  parse_state_ff.enq(StateParseTcp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_tcp"));
  fetch_next_header0(160);
endrule
rule rl_parse_ipv6_parse_udp if ((w_parse_ipv6_parse_udp));
  parse_state_ff.enq(StateParseUdp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_ipv6_start if ((w_parse_ipv6_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv6", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_icmp_load if ((parse_state_ff.first == StateParseIcmp) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_icmp_extract if ((parse_state_ff.first == StateParseIcmp) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_icmp();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_icmp"));
  parse_state_ff.deq;
endrule
rule rl_parse_icmp_start if ((w_parse_icmp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_icmp", "start"));
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
  compute_next_state_parse_tcp();
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_tcp"));
  parse_state_ff.deq;
endrule
rule rl_parse_tcp_start if ((w_parse_tcp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_tcp", "start"));
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
  compute_next_state_parse_udp();
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_udp"));
  parse_state_ff.deq;
endrule
rule rl_parse_udp_start if ((w_parse_udp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_udp", "start"));
  fetch_next_header0(0);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_tcp <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_icmp <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
PulseWire w_parse_udp_start <- mkPulseWireOR();
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_udp <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_icmp <- mkPulseWireOR();
PulseWire w_parse_icmp_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_vlan_tag <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_vlan_tag_start <- mkPulseWireOR();
PulseWire w_parse_vlan_tag_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_vlan_tag_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_tcp_start <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
PulseWire w_parse_ipv6_start <- mkPulseWireOR();
FIFOF#(Maybe#(EthernetT)) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(VlanTagT)) vlan_tag_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Ipv6T)) ipv6_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(IcmpT)) icmp_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(TcpT)) tcp_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(UdpT)) udp_out_ff <- mkDFIFOF(tagged Invalid);
`endif