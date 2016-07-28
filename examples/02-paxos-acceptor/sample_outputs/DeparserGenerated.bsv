`ifdef DEPARSER_STRUCT
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseArp,
  StateDeparseIpv4,
  StateDeparseUdp,
  StateDeparsePaxos,
  StateDeparseIpv6
} DeparserState deriving (Bits, Eq, FShow);
`endif // DEPARSER_STRUCT
`ifdef DEPARSER_RULES
rule rl_deparse_ethernet_next if (w_deparse_ethernet);
  deparse_state_ff.enq(StateDeparseEthernet);
  fetch_next_header(112);
endrule
rule rl_deparse_ethernet_load if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] < 112));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_ethernet_send if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] >= 112));
  succeed_and_next(112);
  deparse_state_ff.deq;
endrule
rule rl_deparse_arp_next if (w_deparse_arp);
  deparse_state_ff.enq(StateDeparseArp);
  fetch_next_header(224);
endrule
rule rl_deparse_arp_load if ((deparse_state_ff.first == StateDeparseArp) && (rg_buffered[0] < 224));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_arp_send if ((deparse_state_ff.first == StateDeparseArp) && (rg_buffered[0] >= 224));
  succeed_and_next(224);
  deparse_state_ff.deq;
endrule
rule rl_deparse_ipv4_next if (w_deparse_ipv4);
  deparse_state_ff.enq(StateDeparseIpv4);
  fetch_next_header(160);
endrule
rule rl_deparse_ipv4_load if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] < 160));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_ipv4_send if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
endrule
rule rl_deparse_udp_next if (w_deparse_udp);
  deparse_state_ff.enq(StateDeparseUdp);
  fetch_next_header(64);
endrule
rule rl_deparse_udp_load if ((deparse_state_ff.first == StateDeparseUdp) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_udp_send if ((deparse_state_ff.first == StateDeparseUdp) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_paxos_next if (w_deparse_paxos);
  deparse_state_ff.enq(StateDeparsePaxos);
  fetch_next_header(352);
endrule
rule rl_deparse_paxos_load if ((deparse_state_ff.first == StateDeparsePaxos) && (rg_buffered[0] < 352));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_paxos_send if ((deparse_state_ff.first == StateDeparsePaxos) && (rg_buffered[0] >= 352));
  succeed_and_next(352);
  deparse_state_ff.deq;
endrule
rule rl_deparse_ipv6_next if (w_deparse_ipv6);
  deparse_state_ff.enq(StateDeparseIpv6);
  fetch_next_header(320);
endrule
rule rl_deparse_ipv6_load if ((deparse_state_ff.first == StateDeparseIpv6) && (rg_buffered[0] < 320));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_ipv6_send if ((deparse_state_ff.first == StateDeparseIpv6) && (rg_buffered[0] >= 320));
  succeed_and_next(320);
  deparse_state_ff.deq;
endrule
`endif // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_deparse_ethernet <- mkPulseWire();
PulseWire w_deparse_arp <- mkPulseWire();
PulseWire w_deparse_ipv4 <- mkPulseWire();
PulseWire w_deparse_udp <- mkPulseWire();
PulseWire w_deparse_paxos <- mkPulseWire();
PulseWire w_deparse_ipv6 <- mkPulseWire();
`endif // DEPARSER_STATE
