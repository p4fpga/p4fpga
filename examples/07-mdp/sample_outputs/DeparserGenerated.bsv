`ifdef DEPARSER_STRUCT
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4,
  StateDeparseUdp,
  StateDeparseMdp,
  StateDeparseMdpMsg,
  StateDeparseMdpSbe,
  StateDeparseMdpRefreshbook,
  StateDeparseGroup0,
  StateDeparseGroup1,
  StateDeparseGroup2,
  StateDeparseGroup3,
  StateDeparseGroup4,
  StateDeparseGroup5,
  StateDeparseGroup6,
  StateDeparseGroup7,
  StateDeparseGroup8,
  StateDeparseGroup9
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
rule rl_deparse_mdp_next if (w_deparse_mdp);
  deparse_state_ff.enq(StateDeparseMdp);
  fetch_next_header(96);
endrule
rule rl_deparse_mdp_load if ((deparse_state_ff.first == StateDeparseMdp) && (rg_buffered[0] < 96));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mdp_send if ((deparse_state_ff.first == StateDeparseMdp) && (rg_buffered[0] >= 96));
  succeed_and_next(96);
  deparse_state_ff.deq;
endrule
rule rl_deparse_mdp_msg_next if (w_deparse_mdp_msg);
  deparse_state_ff.enq(StateDeparseMdpMsg);
  fetch_next_header(16);
endrule
rule rl_deparse_mdp_msg_load if ((deparse_state_ff.first == StateDeparseMdpMsg) && (rg_buffered[0] < 16));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mdp_msg_send if ((deparse_state_ff.first == StateDeparseMdpMsg) && (rg_buffered[0] >= 16));
  succeed_and_next(16);
  deparse_state_ff.deq;
endrule
rule rl_deparse_mdp_sbe_next if (w_deparse_mdp_sbe);
  deparse_state_ff.enq(StateDeparseMdpSbe);
  fetch_next_header(64);
endrule
rule rl_deparse_mdp_sbe_load if ((deparse_state_ff.first == StateDeparseMdpSbe) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mdp_sbe_send if ((deparse_state_ff.first == StateDeparseMdpSbe) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_mdp_refreshbook_next if (w_deparse_mdp_refreshbook);
  deparse_state_ff.enq(StateDeparseMdpRefreshbook);
  fetch_next_header(112);
endrule
rule rl_deparse_mdp_refreshbook_load if ((deparse_state_ff.first == StateDeparseMdpRefreshbook) && (rg_buffered[0] < 112));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mdp_refreshbook_send if ((deparse_state_ff.first == StateDeparseMdpRefreshbook) && (rg_buffered[0] >= 112));
  succeed_and_next(112);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group0_next if (w_deparse_group0);
  deparse_state_ff.enq(StateDeparseGroup0);
  fetch_next_header(256);
endrule
rule rl_deparse_group0_load if ((deparse_state_ff.first == StateDeparseGroup0) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group0_send if ((deparse_state_ff.first == StateDeparseGroup0) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group1_next if (w_deparse_group1);
  deparse_state_ff.enq(StateDeparseGroup1);
  fetch_next_header(256);
endrule
rule rl_deparse_group1_load if ((deparse_state_ff.first == StateDeparseGroup1) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group1_send if ((deparse_state_ff.first == StateDeparseGroup1) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group2_next if (w_deparse_group2);
  deparse_state_ff.enq(StateDeparseGroup2);
  fetch_next_header(256);
endrule
rule rl_deparse_group2_load if ((deparse_state_ff.first == StateDeparseGroup2) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group2_send if ((deparse_state_ff.first == StateDeparseGroup2) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group3_next if (w_deparse_group3);
  deparse_state_ff.enq(StateDeparseGroup3);
  fetch_next_header(256);
endrule
rule rl_deparse_group3_load if ((deparse_state_ff.first == StateDeparseGroup3) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group3_send if ((deparse_state_ff.first == StateDeparseGroup3) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group4_next if (w_deparse_group4);
  deparse_state_ff.enq(StateDeparseGroup4);
  fetch_next_header(256);
endrule
rule rl_deparse_group4_load if ((deparse_state_ff.first == StateDeparseGroup4) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group4_send if ((deparse_state_ff.first == StateDeparseGroup4) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group5_next if (w_deparse_group5);
  deparse_state_ff.enq(StateDeparseGroup5);
  fetch_next_header(256);
endrule
rule rl_deparse_group5_load if ((deparse_state_ff.first == StateDeparseGroup5) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group5_send if ((deparse_state_ff.first == StateDeparseGroup5) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group6_next if (w_deparse_group6);
  deparse_state_ff.enq(StateDeparseGroup6);
  fetch_next_header(256);
endrule
rule rl_deparse_group6_load if ((deparse_state_ff.first == StateDeparseGroup6) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group6_send if ((deparse_state_ff.first == StateDeparseGroup6) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group7_next if (w_deparse_group7);
  deparse_state_ff.enq(StateDeparseGroup7);
  fetch_next_header(256);
endrule
rule rl_deparse_group7_load if ((deparse_state_ff.first == StateDeparseGroup7) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group7_send if ((deparse_state_ff.first == StateDeparseGroup7) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group8_next if (w_deparse_group8);
  deparse_state_ff.enq(StateDeparseGroup8);
  fetch_next_header(256);
endrule
rule rl_deparse_group8_load if ((deparse_state_ff.first == StateDeparseGroup8) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group8_send if ((deparse_state_ff.first == StateDeparseGroup8) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
rule rl_deparse_group9_next if (w_deparse_group9);
  deparse_state_ff.enq(StateDeparseGroup9);
  fetch_next_header(256);
endrule
rule rl_deparse_group9_load if ((deparse_state_ff.first == StateDeparseGroup9) && (rg_buffered[0] < 256));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_group9_send if ((deparse_state_ff.first == StateDeparseGroup9) && (rg_buffered[0] >= 256));
  succeed_and_next(256);
  deparse_state_ff.deq;
endrule
`endif // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_deparse_ethernet <- mkPulseWire();
PulseWire w_deparse_ipv4 <- mkPulseWire();
PulseWire w_deparse_udp <- mkPulseWire();
PulseWire w_deparse_mdp <- mkPulseWire();
PulseWire w_deparse_mdp_msg <- mkPulseWire();
PulseWire w_deparse_mdp_sbe <- mkPulseWire();
PulseWire w_deparse_mdp_refreshbook <- mkPulseWire();
PulseWire w_deparse_group0 <- mkPulseWire();
PulseWire w_deparse_group1 <- mkPulseWire();
PulseWire w_deparse_group2 <- mkPulseWire();
PulseWire w_deparse_group3 <- mkPulseWire();
PulseWire w_deparse_group4 <- mkPulseWire();
PulseWire w_deparse_group5 <- mkPulseWire();
PulseWire w_deparse_group6 <- mkPulseWire();
PulseWire w_deparse_group7 <- mkPulseWire();
PulseWire w_deparse_group8 <- mkPulseWire();
PulseWire w_deparse_group9 <- mkPulseWire();
`endif // DEPARSER_STATE
