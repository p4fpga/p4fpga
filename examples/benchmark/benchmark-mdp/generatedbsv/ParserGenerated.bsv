
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseIpv4,
  StateParseUdp,
  StateParseMdp,
  StateParseMdpMsg,
  StateParseMdpSbe,
  StateParseMdpRefreshbook,
  StateParseMdpGroup
} ParserState deriving (Bits, Eq, FShow);
`endif //PARSER_STRUCT

`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h0800) begin
      dbprint(4, $format("transit to parse_ipv4"));
      w_parse_ethernet_parse_ipv4.send();
    end
    else begin
      dbprint(4, $format("transit to start"));
      w_parse_ethernet_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
  action
    let v = {protocol};
    if (v == 'h11) begin
      dbprint(4, $format("transit to parse_udp"));
      w_parse_ipv4_parse_udp.send();
    end
    else begin
      dbprint(4, $format("transit to start"));
      w_parse_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_udp(Bit#(16) dstPort);
  action
    let v = {dstPort};
    if (v == 'h3bcf) begin
      dbprint(4, $format("transit to parse_mdp"));
      w_parse_udp_parse_mdp.send();
    end
    else if (v == 'h37e7) begin
      dbprint(4, $format("transit to parse_mdp"));
      w_parse_udp_parse_mdp.send();
    end
    else begin
      dbprint(4, $format("transit to start"));
      w_parse_udp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_mdp();
  action
    dbprint(4, $format("transit to parse_mdp_msg"));
    w_parse_mdp_parse_mdp_msg.send();
  endaction
endfunction
function Action compute_next_state_parse_mdp_msg();
  action
    dbprint(4, $format("transit to parse_mdp_sbe"));
    w_parse_mdp_msg_parse_mdp_sbe.send();
  endaction
endfunction
function Action compute_next_state_parse_mdp_sbe();
  action
    dbprint(4, $format("transit to parse_mdp_refreshbook"));
    w_parse_mdp_sbe_parse_mdp_refreshbook.send();
  endaction
endfunction
function Action compute_next_state_parse_mdp_refreshbook(Bit#(16) group_size);
  action
    let v = {group_size};
    if (v == 'h0000) begin
      dbprint(4, $format("transit to start"));
      w_parse_mdp_refreshbook_start.send();
    end
    else begin
      dbprint(4, $format("transit to parse_mdp_group"));
      w_parse_mdp_refreshbook_parse_mdp_group.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_mdp_group(Bit#(16) group_size);
  action
    let v = {group_size};
    if (v == 'h0000) begin
      dbprint(4, $format("transit to start"));
      w_parse_mdp_group_start.send();
    end
    else begin
      dbprint(4, $format("transit to parse_mdp_group"));
      w_parse_mdp_group_parse_mdp_group.send();
    end
  endaction
endfunction
let initState = StateParseEthernet;
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_mdp_sbe_parse_mdp_refreshbook, rl_parse_ipv4_parse_udp, rl_start_parse_ethernet, rl_parse_udp_start, rl_parse_ipv4_start, rl_parse_mdp_group_parse_mdp_group, rl_parse_ethernet_start, rl_parse_mdp_msg_parse_mdp_sbe, rl_parse_udp_parse_mdp, rl_parse_mdp_refreshbook_parse_mdp_group, rl_parse_mdp_group_start, rl_parse_ethernet_parse_ipv4, rl_parse_mdp_refreshbook_start, rl_parse_mdp_parse_mdp_msg" *)
rule rl_parse_done if (delay_ff.notEmpty());
  delay_ff.deq;
  MetadataT meta = defaultValue;
  let ethernet <- toGet(ethernet_out_ff).get;
  let udp <- toGet(udp_out_ff).get;
  let ipv4 <- toGet(ipv4_out_ff).get;
  let mdp <- toGet(mdp_out_ff).get;
  let mdp_msg <- toGet(mdp_msg_out_ff).get;
  let mdp_sbe <- toGet(mdp_sbe_out_ff).get;
  let mdp_refreshbook <- toGet(mdp_refreshbook_out_ff).get;
  if (isValid(ethernet)) begin
    meta.ethernet = tagged Forward;
  end
  if (isValid(ipv4)) begin
    meta.ipv4 = tagged Forward;
  end
  if (isValid(udp)) begin
    meta.udp = tagged Forward;
  end
  if (mdp matches tagged Valid .v) begin
    meta.mdp = tagged Forward;
    meta.mdp$msgSeqNum = tagged Valid v.msgSeqNum;
  end
  if (isValid(mdp_msg)) begin
    meta.mdp_msg = tagged Forward;
  end
  if (isValid(mdp_sbe)) begin
    meta.mdp_sbe = tagged Forward;
  end
  if (isValid(mdp_refreshbook)) begin
    meta.mdp_refreshbook = tagged Forward;
  end
  for (Integer i = 0; i < 10; i=i+1) begin
    let group <- toGet(mdp_refreshbook_group_out_ff[i]).get;
    if (isValid(group)) begin
      meta.group[i] = tagged Forward;
    end
  end
  dbprint(4, $format("parse_done"));
  meta_in_ff.enq(meta);
endrule
rule rl_start_parse_ethernet if ((w_start_parse_ethernet));
  parse_state_ff.enq(StateParseEthernet);
  dbprint(4, $format("%s -> %s", "start", "parse_ethernet"));
  fetch_next_header1(112);
endrule
(* fire_when_enabled *)
rule rl_parse_ethernet_load if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] < 112));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ethernet_extract if ((parse_state_ff.first == StateParseEthernet) && (rg_buffered[0] >= 112));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ethernet = extract_ethernet_t(truncate(data));
  compute_next_state_parse_ethernet(ethernet.etherType);
  rg_tmp <= zeroExtend(data >> 112);
  succeed_and_next(112);
  dbprint(4, $format("extract %s", "parse_ethernet"));
  dbprint(4, $format(fshow(ethernet)));
  parse_state_ff.deq;
  ethernet_out_ff.enq(tagged Valid ethernet);
endrule
rule rl_parse_ethernet_parse_ipv4 if ((w_parse_ethernet_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(4, $format("%s -> %s", "parse_ethernet", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_ethernet_start if ((w_parse_ethernet_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(4, $format("%s -> %s", "parse_ethernet", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_load if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_extract if ((parse_state_ff.first == StateParseIpv4) && (rg_buffered[0] >= 160));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ipv4 = extract_ipv4_t(truncate(data));
  compute_next_state_parse_ipv4(ipv4.protocol);
  rg_tmp <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(4, $format("extract %s", "parse_ipv4"));
  dbprint(4, $format(fshow(ipv4)));
  parse_state_ff.deq;
  ipv4_out_ff.enq(tagged Valid ipv4);
endrule
rule rl_parse_ipv4_parse_udp if ((w_parse_ipv4_parse_udp));
  parse_state_ff.enq(StateParseUdp);
  dbprint(4, $format("%s -> %s", "parse_ipv4", "parse_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(4, $format("%s -> %s", "parse_ipv4", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_udp_load if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_udp_extract if ((parse_state_ff.first == StateParseUdp) && (rg_buffered[0] >= 64));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let udp = extract_udp_t(truncate(data));
  compute_next_state_parse_udp(udp.dstPort);
  rg_tmp <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(4, $format("extract %s", "parse_udp"));
  dbprint(4, $format(fshow(udp)));
  parse_state_ff.deq;
  udp_out_ff.enq(tagged Valid udp);
endrule
rule rl_parse_udp_parse_mdp if ((w_parse_udp_parse_mdp));
  parse_state_ff.enq(StateParseMdp);
  dbprint(4, $format("%s -> %s", "parse_udp", "parse_mdp"));
  fetch_next_header0(96);
endrule
rule rl_parse_udp_start if ((w_parse_udp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(4, $format("%s -> %s", "parse_udp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_load if ((parse_state_ff.first == StateParseMdp) && (rg_buffered[0] < 96));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_extract if ((parse_state_ff.first == StateParseMdp) && (rg_buffered[0] >= 96));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mdp();
  let mdp = extract_mdp_packet_t(truncate(data));
  rg_tmp <= zeroExtend(data >> 96);
  succeed_and_next(96);
  dbprint(4, $format("extract %s", "parse_mdp"));
  dbprint(4, $format(fshow(mdp)));
  parse_state_ff.deq;
  mdp_out_ff.enq(tagged Valid mdp);
endrule
rule rl_parse_mdp_parse_mdp_msg if ((w_parse_mdp_parse_mdp_msg));
  parse_state_ff.enq(StateParseMdpMsg);
  dbprint(4, $format("%s -> %s", "parse_mdp", "parse_mdp_msg"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_msg_load if ((parse_state_ff.first == StateParseMdpMsg) && (rg_buffered[0] < 16));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_msg_extract if ((parse_state_ff.first == StateParseMdpMsg) && (rg_buffered[0] >= 16));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mdp_msg();
  let mdp_msg = extract_mdp_message_t(truncate(data));
  rg_tmp <= zeroExtend(data >> 16);
  succeed_and_next(16);
  dbprint(4, $format("extract %s", "parse_mdp_msg"));
  dbprint(4, $format(fshow(mdp_msg)));
  parse_state_ff.deq;
  mdp_msg_out_ff.enq(tagged Valid mdp_msg);
endrule
rule rl_parse_mdp_msg_parse_mdp_sbe if ((w_parse_mdp_msg_parse_mdp_sbe));
  parse_state_ff.enq(StateParseMdpSbe);
  dbprint(4, $format("%s -> %s", "parse_mdp_msg", "parse_mdp_sbe"));
  fetch_next_header0(64);
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_sbe_load if ((parse_state_ff.first == StateParseMdpSbe) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_sbe_extract if ((parse_state_ff.first == StateParseMdpSbe) && (rg_buffered[0] >= 64));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mdp_sbe();
  let mdp_sbe = extract_mdp_sbe_t(truncate(data));
  rg_tmp <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(4, $format("extract %s", "parse_mdp_sbe"));
  dbprint(4, $format(fshow(mdp_sbe)));
  parse_state_ff.deq;
  mdp_sbe_out_ff.enq(tagged Valid mdp_sbe);
endrule
rule rl_parse_mdp_sbe_parse_mdp_refreshbook if ((w_parse_mdp_sbe_parse_mdp_refreshbook));
  parse_state_ff.enq(StateParseMdpRefreshbook);
  dbprint(4, $format("%s -> %s", "parse_mdp_sbe", "parse_mdp_refreshbook"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_refreshbook_load if ((parse_state_ff.first == StateParseMdpRefreshbook) && (rg_buffered[0] < 112));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_refreshbook_extract if ((parse_state_ff.first == StateParseMdpRefreshbook) && (rg_buffered[0] >= 112));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let extracted_data = extract_mdIncrementalRefreshBook32(truncate(data));
  compute_next_state_parse_mdp_refreshbook(extracted_data.noMDEntries);
  rg_tmp <= zeroExtend(data >> 112);
  succeed_and_next(112);
  dbprint(4, $format("extract %s", "parse_mdp_refreshbook"));
  dbprint(4, $format(fshow(extracted_data)));
  parse_state_ff.deq;
  event_metadata$group_size[0] <= extracted_data.noMDEntries;
  mdp_refreshbook_out_ff.enq(tagged Valid extracted_data);
endrule
rule rl_parse_mdp_refreshbook_start if ((w_parse_mdp_refreshbook_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(4, $format("%s -> %s", "parse_mdp_refreshbook", "start"));
  fetch_next_header0(0);
endrule
rule rl_parse_mdp_refreshbook_parse_mdp_group if ((w_parse_mdp_refreshbook_parse_mdp_group));
  parse_state_ff.enq(StateParseMdpGroup);
  dbprint(4, $format("%s -> %s", "parse_mdp_refreshbook", "parse_mdp_group"));
  fetch_next_header0(256);
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_group_load if ((parse_state_ff.first == StateParseMdpGroup) && (rg_buffered[0] < 256));
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
    rg_tmp <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mdp_group_extract if ((parse_state_ff.first == StateParseMdpGroup) && (rg_buffered[0] >= 256));
  let data = rg_tmp;
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_buffered[0] | rg_tmp;
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let v = ( event_metadata$group_size[0] - 'h1 );
  let extracted_data = extract_mdIncrementalRefreshBook32Group(truncate(data));
  event_metadata$group_size[0] <= v;
  compute_next_state_parse_mdp_group(v);
  rg_tmp <= zeroExtend(data >> 256);
  succeed_and_next(256);
  mdp_refreshbook_group_out_ff[v].enq(tagged Valid extracted_data);
  dbprint(4, $format("extract %s %h", "parse_mdp_group", v));
  dbprint(4, $format(fshow(extracted_data)));
  parse_state_ff.deq;
endrule
rule rl_parse_mdp_group_start if ((w_parse_mdp_group_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(4, $format("%s -> %s", "parse_mdp_group", "start"));
  fetch_next_header0(0);
endrule
rule rl_parse_mdp_group_parse_mdp_group if ((w_parse_mdp_group_parse_mdp_group));
  parse_state_ff.enq(StateParseMdpGroup);
  dbprint(4, $format("%s -> %s", "parse_mdp_group", "parse_mdp_group"));
  fetch_next_header0(256);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_mdp_sbe_parse_mdp_refreshbook <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
PulseWire w_parse_udp_start <- mkPulseWireOR();
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_mdp_group_parse_mdp_group <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_mdp_msg_parse_mdp_sbe <- mkPulseWireOR();
PulseWire w_parse_udp_parse_mdp <- mkPulseWireOR();
PulseWire w_parse_mdp_refreshbook_parse_mdp_group <- mkPulseWireOR();
PulseWire w_parse_mdp_group_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_mdp_refreshbook_start <- mkPulseWireOR();
PulseWire w_parse_mdp_parse_mdp_msg <- mkPulseWireOR();
FIFOF#(Maybe#(EthernetT)) ethernet_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Ipv4T)) ipv4_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(UdpT)) udp_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(MdpPacketT)) mdp_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(MdpMessageT)) mdp_msg_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(MdpSbeT)) mdp_sbe_out_ff <- mkDFIFOF(tagged Invalid);
FIFOF#(Maybe#(Mdincrementalrefreshbook32)) mdp_refreshbook_out_ff <- mkDFIFOF(tagged Invalid);
Vector#(10, FIFOF#(Maybe#(Mdincrementalrefreshbook32Group))) mdp_refreshbook_group_out_ff <- replicateM(mkDFIFOF(tagged Invalid));
Reg#(Bit#(16)) event_metadata$group_size[2] <- mkCReg(2, 0);
`endif
