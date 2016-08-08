`ifdef DEPARSER_STRUCT
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseIpv4
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
  dbprint(3, $format("load ethernet"));
endrule
rule rl_deparse_ethernet_send if ((deparse_state_ff.first == StateDeparseEthernet) && (rg_buffered[0] >= 112));
  succeed_and_next(112);
  w_deparse_ipv4.send();
  deparse_state_ff.deq;
endrule
rule rl_deparse_ipv4_next if (w_deparse_ipv4);
  deparse_state_ff.enq(StateDeparseIpv4);
  fetch_next_header(160);
endrule
rule rl_deparse_ipv4_load if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] < 160));
  UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);
  UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(cExtend(n_bits_used));
  dbprint(3, $format("load ipv4 %h %d %d", data_this_cycle, n_bytes_used, n_bits_used));
endrule
rule rl_deparse_ipv4_send if ((deparse_state_ff.first == StateDeparseIpv4) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
  w_deparse_ipv4_start.send();
endrule
rule rl_deparse_ipv4_start if (w_deparse_ipv4_start);
  fetch_next_header(0);
  header_done[0] <= True;
endrule
`endif // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_deparse_ethernet <- mkPulseWire();
PulseWire w_deparse_ipv4 <- mkPulseWire();
PulseWire w_deparse_ipv4_start <- mkPulseWire();
`endif // DEPARSER_STATE
