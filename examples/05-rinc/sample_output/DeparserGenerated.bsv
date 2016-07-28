`ifdef DEPARSER_STRUCT
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4,
  StateDeparseTcp,
  StateDeparseOptionsMss,
  StateDeparseOptionsSack,
  StateDeparseOptionsTs,
  StateDeparseOptionsNop0,
  StateDeparseOptionsNop1,
  StateDeparseOptionsNop2,
  StateDeparseOptionsWscale,
  StateDeparseOptionsEnd
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
rule rl_deparse_tcp_next if (w_deparse_tcp);
  deparse_state_ff.enq(StateDeparseTcp);
  fetch_next_header(160);
endrule
rule rl_deparse_tcp_load if ((deparse_state_ff.first == StateDeparseTcp) && (rg_buffered[0] < 160));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_tcp_send if ((deparse_state_ff.first == StateDeparseTcp) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_mss_next if (w_deparse_options_mss);
  deparse_state_ff.enq(StateDeparseOptionsMss);
  fetch_next_header(32);
endrule
rule rl_deparse_options_mss_load if ((deparse_state_ff.first == StateDeparseOptionsMss) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_mss_send if ((deparse_state_ff.first == StateDeparseOptionsMss) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_sack_next if (w_deparse_options_sack);
  deparse_state_ff.enq(StateDeparseOptionsSack);
  fetch_next_header(16);
endrule
rule rl_deparse_options_sack_load if ((deparse_state_ff.first == StateDeparseOptionsSack) && (rg_buffered[0] < 16));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_sack_send if ((deparse_state_ff.first == StateDeparseOptionsSack) && (rg_buffered[0] >= 16));
  succeed_and_next(16);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_ts_next if (w_deparse_options_ts);
  deparse_state_ff.enq(StateDeparseOptionsTs);
  fetch_next_header(80);
endrule
rule rl_deparse_options_ts_load if ((deparse_state_ff.first == StateDeparseOptionsTs) && (rg_buffered[0] < 80));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_ts_send if ((deparse_state_ff.first == StateDeparseOptionsTs) && (rg_buffered[0] >= 80));
  succeed_and_next(80);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_nop0_next if (w_deparse_options_nop0);
  deparse_state_ff.enq(StateDeparseOptionsNop0);
  fetch_next_header(8);
endrule
rule rl_deparse_options_nop0_load if ((deparse_state_ff.first == StateDeparseOptionsNop0) && (rg_buffered[0] < 8));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_nop0_send if ((deparse_state_ff.first == StateDeparseOptionsNop0) && (rg_buffered[0] >= 8));
  succeed_and_next(8);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_nop1_next if (w_deparse_options_nop1);
  deparse_state_ff.enq(StateDeparseOptionsNop1);
  fetch_next_header(8);
endrule
rule rl_deparse_options_nop1_load if ((deparse_state_ff.first == StateDeparseOptionsNop1) && (rg_buffered[0] < 8));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_nop1_send if ((deparse_state_ff.first == StateDeparseOptionsNop1) && (rg_buffered[0] >= 8));
  succeed_and_next(8);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_nop2_next if (w_deparse_options_nop2);
  deparse_state_ff.enq(StateDeparseOptionsNop2);
  fetch_next_header(8);
endrule
rule rl_deparse_options_nop2_load if ((deparse_state_ff.first == StateDeparseOptionsNop2) && (rg_buffered[0] < 8));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_nop2_send if ((deparse_state_ff.first == StateDeparseOptionsNop2) && (rg_buffered[0] >= 8));
  succeed_and_next(8);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_wscale_next if (w_deparse_options_wscale);
  deparse_state_ff.enq(StateDeparseOptionsWscale);
  fetch_next_header(24);
endrule
rule rl_deparse_options_wscale_load if ((deparse_state_ff.first == StateDeparseOptionsWscale) && (rg_buffered[0] < 24));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_wscale_send if ((deparse_state_ff.first == StateDeparseOptionsWscale) && (rg_buffered[0] >= 24));
  succeed_and_next(24);
  deparse_state_ff.deq;
endrule
rule rl_deparse_options_end_next if (w_deparse_options_end);
  deparse_state_ff.enq(StateDeparseOptionsEnd);
  fetch_next_header(8);
endrule
rule rl_deparse_options_end_load if ((deparse_state_ff.first == StateDeparseOptionsEnd) && (rg_buffered[0] < 8));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_options_end_send if ((deparse_state_ff.first == StateDeparseOptionsEnd) && (rg_buffered[0] >= 8));
  succeed_and_next(8);
  deparse_state_ff.deq;
endrule
`endif // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_deparse_ethernet <- mkPulseWire();
PulseWire w_deparse_ipv4 <- mkPulseWire();
PulseWire w_deparse_tcp <- mkPulseWire();
PulseWire w_deparse_options_mss <- mkPulseWire();
PulseWire w_deparse_options_sack <- mkPulseWire();
PulseWire w_deparse_options_ts <- mkPulseWire();
PulseWire w_deparse_options_nop0 <- mkPulseWire();
PulseWire w_deparse_options_nop1 <- mkPulseWire();
PulseWire w_deparse_options_nop2 <- mkPulseWire();
PulseWire w_deparse_options_wscale <- mkPulseWire();
PulseWire w_deparse_options_end <- mkPulseWire();
`endif // DEPARSER_STATE
