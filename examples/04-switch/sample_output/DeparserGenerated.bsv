`ifdef DEPARSER_STRUCT
typedef enum {
  StateDeparseStart,
  StateDeparseEthernet,
  StateDeparseFabricHeader,
  StateDeparseFabricHeaderMulticast,
  StateDeparseFabricHeaderCpu,
  StateDeparseFabricHeaderSflow,
  StateDeparseFabricHeaderUnicast,
  StateDeparseFabricHeaderMirror,
  StateDeparseFabricPayloadHeader,
  StateDeparseLlcHeader,
  StateDeparseSnapHeader,
  StateDeparseVlanTag0,
  StateDeparseVlanTag1,
  StateDeparseIpv4,
  StateDeparseMpls0,
  StateDeparseMpls1,
  StateDeparseMpls2,
  StateDeparseIpv6,
  StateDeparseTcp,
  StateDeparseUdp,
  StateDeparseVxlanGpe,
  StateDeparseVxlanGpeIntHeader,
  StateDeparseIntHeader,
  StateDeparseIntSwitchIdHeader,
  StateDeparseIntIngressPortIdHeader,
  StateDeparseIntHopLatencyHeader,
  StateDeparseIntQOccupancyHeader,
  StateDeparseIntIngressTstampHeader,
  StateDeparseIntEgressPortIdHeader,
  StateDeparseIntQCongestionHeader,
  StateDeparseIntEgressPortTxUtilizationHeader,
  StateDeparseIntVal0,
  StateDeparseIntVal1,
  StateDeparseIntVal2,
  StateDeparseIntVal3,
  StateDeparseIntVal4,
  StateDeparseIntVal5,
  StateDeparseIntVal6,
  StateDeparseIntVal7,
  StateDeparseIntVal8,
  StateDeparseIntVal9,
  StateDeparseIntVal10,
  StateDeparseIntVal11,
  StateDeparseIntVal12,
  StateDeparseIntVal13,
  StateDeparseIntVal14,
  StateDeparseIntVal15,
  StateDeparseIntVal16,
  StateDeparseIntVal17,
  StateDeparseIntVal18,
  StateDeparseIntVal19,
  StateDeparseIntVal20,
  StateDeparseIntVal21,
  StateDeparseIntVal22,
  StateDeparseIntVal23,
  StateDeparseGenv,
  StateDeparseVxlan,
  StateDeparseSflow,
  StateDeparseGre,
  StateDeparseErspanT3Header,
  StateDeparseNvgre,
  StateDeparseInnerEthernet,
  StateDeparseInnerIpv4,
  StateDeparseInnerIpv6,
  StateDeparseInnerUdp,
  StateDeparseInnerIcmp,
  StateDeparseInnerTcp,
  StateDeparseIcmp,
  StateDeparseArpRarp,
  StateDeparseArpRarpIpv4
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
rule rl_deparse_fabric_header_next if (w_deparse_fabric_header);
  deparse_state_ff.enq(StateDeparseFabricHeader);
  fetch_next_header(40);
endrule
rule rl_deparse_fabric_header_load if ((deparse_state_ff.first == StateDeparseFabricHeader) && (rg_buffered[0] < 40));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_send if ((deparse_state_ff.first == StateDeparseFabricHeader) && (rg_buffered[0] >= 40));
  succeed_and_next(40);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_header_multicast_next if (w_deparse_fabric_header_multicast);
  deparse_state_ff.enq(StateDeparseFabricHeaderMulticast);
  fetch_next_header(56);
endrule
rule rl_deparse_fabric_header_multicast_load if ((deparse_state_ff.first == StateDeparseFabricHeaderMulticast) && (rg_buffered[0] < 56));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_multicast_send if ((deparse_state_ff.first == StateDeparseFabricHeaderMulticast) && (rg_buffered[0] >= 56));
  succeed_and_next(56);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_header_cpu_next if (w_deparse_fabric_header_cpu);
  deparse_state_ff.enq(StateDeparseFabricHeaderCpu);
  fetch_next_header(72);
endrule
rule rl_deparse_fabric_header_cpu_load if ((deparse_state_ff.first == StateDeparseFabricHeaderCpu) && (rg_buffered[0] < 72));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_cpu_send if ((deparse_state_ff.first == StateDeparseFabricHeaderCpu) && (rg_buffered[0] >= 72));
  succeed_and_next(72);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_header_sflow_next if (w_deparse_fabric_header_sflow);
  deparse_state_ff.enq(StateDeparseFabricHeaderSflow);
  fetch_next_header(16);
endrule
rule rl_deparse_fabric_header_sflow_load if ((deparse_state_ff.first == StateDeparseFabricHeaderSflow) && (rg_buffered[0] < 16));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_sflow_send if ((deparse_state_ff.first == StateDeparseFabricHeaderSflow) && (rg_buffered[0] >= 16));
  succeed_and_next(16);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_header_unicast_next if (w_deparse_fabric_header_unicast);
  deparse_state_ff.enq(StateDeparseFabricHeaderUnicast);
  fetch_next_header(24);
endrule
rule rl_deparse_fabric_header_unicast_load if ((deparse_state_ff.first == StateDeparseFabricHeaderUnicast) && (rg_buffered[0] < 24));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_unicast_send if ((deparse_state_ff.first == StateDeparseFabricHeaderUnicast) && (rg_buffered[0] >= 24));
  succeed_and_next(24);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_header_mirror_next if (w_deparse_fabric_header_mirror);
  deparse_state_ff.enq(StateDeparseFabricHeaderMirror);
  fetch_next_header(32);
endrule
rule rl_deparse_fabric_header_mirror_load if ((deparse_state_ff.first == StateDeparseFabricHeaderMirror) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_header_mirror_send if ((deparse_state_ff.first == StateDeparseFabricHeaderMirror) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_fabric_payload_header_next if (w_deparse_fabric_payload_header);
  deparse_state_ff.enq(StateDeparseFabricPayloadHeader);
  fetch_next_header(16);
endrule
rule rl_deparse_fabric_payload_header_load if ((deparse_state_ff.first == StateDeparseFabricPayloadHeader) && (rg_buffered[0] < 16));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_fabric_payload_header_send if ((deparse_state_ff.first == StateDeparseFabricPayloadHeader) && (rg_buffered[0] >= 16));
  succeed_and_next(16);
  deparse_state_ff.deq;
endrule
rule rl_deparse_llc_header_next if (w_deparse_llc_header);
  deparse_state_ff.enq(StateDeparseLlcHeader);
  fetch_next_header(24);
endrule
rule rl_deparse_llc_header_load if ((deparse_state_ff.first == StateDeparseLlcHeader) && (rg_buffered[0] < 24));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_llc_header_send if ((deparse_state_ff.first == StateDeparseLlcHeader) && (rg_buffered[0] >= 24));
  succeed_and_next(24);
  deparse_state_ff.deq;
endrule
rule rl_deparse_snap_header_next if (w_deparse_snap_header);
  deparse_state_ff.enq(StateDeparseSnapHeader);
  fetch_next_header(40);
endrule
rule rl_deparse_snap_header_load if ((deparse_state_ff.first == StateDeparseSnapHeader) && (rg_buffered[0] < 40));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_snap_header_send if ((deparse_state_ff.first == StateDeparseSnapHeader) && (rg_buffered[0] >= 40));
  succeed_and_next(40);
  deparse_state_ff.deq;
endrule
rule rl_deparse_vlan_tag_0_next if (w_deparse_vlan_tag_0);
  deparse_state_ff.enq(StateDeparseVlanTag0);
  fetch_next_header(32);
endrule
rule rl_deparse_vlan_tag_0_load if ((deparse_state_ff.first == StateDeparseVlanTag0) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_vlan_tag_0_send if ((deparse_state_ff.first == StateDeparseVlanTag0) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_vlan_tag_1_next if (w_deparse_vlan_tag_1);
  deparse_state_ff.enq(StateDeparseVlanTag1);
  fetch_next_header(32);
endrule
rule rl_deparse_vlan_tag_1_load if ((deparse_state_ff.first == StateDeparseVlanTag1) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_vlan_tag_1_send if ((deparse_state_ff.first == StateDeparseVlanTag1) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
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
rule rl_deparse_mpls0_next if (w_deparse_mpls0);
  deparse_state_ff.enq(StateDeparseMpls0);
  fetch_next_header(32);
endrule
rule rl_deparse_mpls0_load if ((deparse_state_ff.first == StateDeparseMpls0) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mpls0_send if ((deparse_state_ff.first == StateDeparseMpls0) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_mpls1_next if (w_deparse_mpls1);
  deparse_state_ff.enq(StateDeparseMpls1);
  fetch_next_header(32);
endrule
rule rl_deparse_mpls1_load if ((deparse_state_ff.first == StateDeparseMpls1) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mpls1_send if ((deparse_state_ff.first == StateDeparseMpls1) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_mpls2_next if (w_deparse_mpls2);
  deparse_state_ff.enq(StateDeparseMpls2);
  fetch_next_header(32);
endrule
rule rl_deparse_mpls2_load if ((deparse_state_ff.first == StateDeparseMpls2) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_mpls2_send if ((deparse_state_ff.first == StateDeparseMpls2) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
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
rule rl_deparse_vxlan_gpe_next if (w_deparse_vxlan_gpe);
  deparse_state_ff.enq(StateDeparseVxlanGpe);
  fetch_next_header(64);
endrule
rule rl_deparse_vxlan_gpe_load if ((deparse_state_ff.first == StateDeparseVxlanGpe) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_vxlan_gpe_send if ((deparse_state_ff.first == StateDeparseVxlanGpe) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_vxlan_gpe_int_header_next if (w_deparse_vxlan_gpe_int_header);
  deparse_state_ff.enq(StateDeparseVxlanGpeIntHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_vxlan_gpe_int_header_load if ((deparse_state_ff.first == StateDeparseVxlanGpeIntHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_vxlan_gpe_int_header_send if ((deparse_state_ff.first == StateDeparseVxlanGpeIntHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_header_next if (w_deparse_int_header);
  deparse_state_ff.enq(StateDeparseIntHeader);
  fetch_next_header(64);
endrule
rule rl_deparse_int_header_load if ((deparse_state_ff.first == StateDeparseIntHeader) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_header_send if ((deparse_state_ff.first == StateDeparseIntHeader) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_switch_id_header_next if (w_deparse_int_switch_id_header);
  deparse_state_ff.enq(StateDeparseIntSwitchIdHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_switch_id_header_load if ((deparse_state_ff.first == StateDeparseIntSwitchIdHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_switch_id_header_send if ((deparse_state_ff.first == StateDeparseIntSwitchIdHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_ingress_port_id_header_next if (w_deparse_int_ingress_port_id_header);
  deparse_state_ff.enq(StateDeparseIntIngressPortIdHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_ingress_port_id_header_load if ((deparse_state_ff.first == StateDeparseIntIngressPortIdHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_ingress_port_id_header_send if ((deparse_state_ff.first == StateDeparseIntIngressPortIdHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_hop_latency_header_next if (w_deparse_int_hop_latency_header);
  deparse_state_ff.enq(StateDeparseIntHopLatencyHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_hop_latency_header_load if ((deparse_state_ff.first == StateDeparseIntHopLatencyHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_hop_latency_header_send if ((deparse_state_ff.first == StateDeparseIntHopLatencyHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_q_occupancy_header_next if (w_deparse_int_q_occupancy_header);
  deparse_state_ff.enq(StateDeparseIntQOccupancyHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_q_occupancy_header_load if ((deparse_state_ff.first == StateDeparseIntQOccupancyHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_q_occupancy_header_send if ((deparse_state_ff.first == StateDeparseIntQOccupancyHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_ingress_tstamp_header_next if (w_deparse_int_ingress_tstamp_header);
  deparse_state_ff.enq(StateDeparseIntIngressTstampHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_ingress_tstamp_header_load if ((deparse_state_ff.first == StateDeparseIntIngressTstampHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_ingress_tstamp_header_send if ((deparse_state_ff.first == StateDeparseIntIngressTstampHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_egress_port_id_header_next if (w_deparse_int_egress_port_id_header);
  deparse_state_ff.enq(StateDeparseIntEgressPortIdHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_egress_port_id_header_load if ((deparse_state_ff.first == StateDeparseIntEgressPortIdHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_egress_port_id_header_send if ((deparse_state_ff.first == StateDeparseIntEgressPortIdHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_q_congestion_header_next if (w_deparse_int_q_congestion_header);
  deparse_state_ff.enq(StateDeparseIntQCongestionHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_q_congestion_header_load if ((deparse_state_ff.first == StateDeparseIntQCongestionHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_q_congestion_header_send if ((deparse_state_ff.first == StateDeparseIntQCongestionHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_egress_port_tx_utilization_header_next if (w_deparse_int_egress_port_tx_utilization_header);
  deparse_state_ff.enq(StateDeparseIntEgressPortTxUtilizationHeader);
  fetch_next_header(32);
endrule
rule rl_deparse_int_egress_port_tx_utilization_header_load if ((deparse_state_ff.first == StateDeparseIntEgressPortTxUtilizationHeader) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_egress_port_tx_utilization_header_send if ((deparse_state_ff.first == StateDeparseIntEgressPortTxUtilizationHeader) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val0_next if (w_deparse_int_val0);
  deparse_state_ff.enq(StateDeparseIntVal0);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val0_load if ((deparse_state_ff.first == StateDeparseIntVal0) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val0_send if ((deparse_state_ff.first == StateDeparseIntVal0) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val1_next if (w_deparse_int_val1);
  deparse_state_ff.enq(StateDeparseIntVal1);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val1_load if ((deparse_state_ff.first == StateDeparseIntVal1) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val1_send if ((deparse_state_ff.first == StateDeparseIntVal1) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val2_next if (w_deparse_int_val2);
  deparse_state_ff.enq(StateDeparseIntVal2);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val2_load if ((deparse_state_ff.first == StateDeparseIntVal2) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val2_send if ((deparse_state_ff.first == StateDeparseIntVal2) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val3_next if (w_deparse_int_val3);
  deparse_state_ff.enq(StateDeparseIntVal3);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val3_load if ((deparse_state_ff.first == StateDeparseIntVal3) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val3_send if ((deparse_state_ff.first == StateDeparseIntVal3) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val4_next if (w_deparse_int_val4);
  deparse_state_ff.enq(StateDeparseIntVal4);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val4_load if ((deparse_state_ff.first == StateDeparseIntVal4) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val4_send if ((deparse_state_ff.first == StateDeparseIntVal4) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val5_next if (w_deparse_int_val5);
  deparse_state_ff.enq(StateDeparseIntVal5);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val5_load if ((deparse_state_ff.first == StateDeparseIntVal5) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val5_send if ((deparse_state_ff.first == StateDeparseIntVal5) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val6_next if (w_deparse_int_val6);
  deparse_state_ff.enq(StateDeparseIntVal6);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val6_load if ((deparse_state_ff.first == StateDeparseIntVal6) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val6_send if ((deparse_state_ff.first == StateDeparseIntVal6) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val7_next if (w_deparse_int_val7);
  deparse_state_ff.enq(StateDeparseIntVal7);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val7_load if ((deparse_state_ff.first == StateDeparseIntVal7) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val7_send if ((deparse_state_ff.first == StateDeparseIntVal7) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val8_next if (w_deparse_int_val8);
  deparse_state_ff.enq(StateDeparseIntVal8);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val8_load if ((deparse_state_ff.first == StateDeparseIntVal8) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val8_send if ((deparse_state_ff.first == StateDeparseIntVal8) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val9_next if (w_deparse_int_val9);
  deparse_state_ff.enq(StateDeparseIntVal9);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val9_load if ((deparse_state_ff.first == StateDeparseIntVal9) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val9_send if ((deparse_state_ff.first == StateDeparseIntVal9) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val10_next if (w_deparse_int_val10);
  deparse_state_ff.enq(StateDeparseIntVal10);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val10_load if ((deparse_state_ff.first == StateDeparseIntVal10) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val10_send if ((deparse_state_ff.first == StateDeparseIntVal10) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val11_next if (w_deparse_int_val11);
  deparse_state_ff.enq(StateDeparseIntVal11);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val11_load if ((deparse_state_ff.first == StateDeparseIntVal11) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val11_send if ((deparse_state_ff.first == StateDeparseIntVal11) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val12_next if (w_deparse_int_val12);
  deparse_state_ff.enq(StateDeparseIntVal12);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val12_load if ((deparse_state_ff.first == StateDeparseIntVal12) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val12_send if ((deparse_state_ff.first == StateDeparseIntVal12) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val13_next if (w_deparse_int_val13);
  deparse_state_ff.enq(StateDeparseIntVal13);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val13_load if ((deparse_state_ff.first == StateDeparseIntVal13) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val13_send if ((deparse_state_ff.first == StateDeparseIntVal13) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val14_next if (w_deparse_int_val14);
  deparse_state_ff.enq(StateDeparseIntVal14);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val14_load if ((deparse_state_ff.first == StateDeparseIntVal14) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val14_send if ((deparse_state_ff.first == StateDeparseIntVal14) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val15_next if (w_deparse_int_val15);
  deparse_state_ff.enq(StateDeparseIntVal15);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val15_load if ((deparse_state_ff.first == StateDeparseIntVal15) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val15_send if ((deparse_state_ff.first == StateDeparseIntVal15) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val16_next if (w_deparse_int_val16);
  deparse_state_ff.enq(StateDeparseIntVal16);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val16_load if ((deparse_state_ff.first == StateDeparseIntVal16) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val16_send if ((deparse_state_ff.first == StateDeparseIntVal16) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val17_next if (w_deparse_int_val17);
  deparse_state_ff.enq(StateDeparseIntVal17);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val17_load if ((deparse_state_ff.first == StateDeparseIntVal17) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val17_send if ((deparse_state_ff.first == StateDeparseIntVal17) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val18_next if (w_deparse_int_val18);
  deparse_state_ff.enq(StateDeparseIntVal18);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val18_load if ((deparse_state_ff.first == StateDeparseIntVal18) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val18_send if ((deparse_state_ff.first == StateDeparseIntVal18) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val19_next if (w_deparse_int_val19);
  deparse_state_ff.enq(StateDeparseIntVal19);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val19_load if ((deparse_state_ff.first == StateDeparseIntVal19) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val19_send if ((deparse_state_ff.first == StateDeparseIntVal19) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val20_next if (w_deparse_int_val20);
  deparse_state_ff.enq(StateDeparseIntVal20);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val20_load if ((deparse_state_ff.first == StateDeparseIntVal20) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val20_send if ((deparse_state_ff.first == StateDeparseIntVal20) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val21_next if (w_deparse_int_val21);
  deparse_state_ff.enq(StateDeparseIntVal21);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val21_load if ((deparse_state_ff.first == StateDeparseIntVal21) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val21_send if ((deparse_state_ff.first == StateDeparseIntVal21) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val22_next if (w_deparse_int_val22);
  deparse_state_ff.enq(StateDeparseIntVal22);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val22_load if ((deparse_state_ff.first == StateDeparseIntVal22) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val22_send if ((deparse_state_ff.first == StateDeparseIntVal22) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_int_val23_next if (w_deparse_int_val23);
  deparse_state_ff.enq(StateDeparseIntVal23);
  fetch_next_header(32);
endrule
rule rl_deparse_int_val23_load if ((deparse_state_ff.first == StateDeparseIntVal23) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_int_val23_send if ((deparse_state_ff.first == StateDeparseIntVal23) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_genv_next if (w_deparse_genv);
  deparse_state_ff.enq(StateDeparseGenv);
  fetch_next_header(64);
endrule
rule rl_deparse_genv_load if ((deparse_state_ff.first == StateDeparseGenv) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_genv_send if ((deparse_state_ff.first == StateDeparseGenv) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_vxlan_next if (w_deparse_vxlan);
  deparse_state_ff.enq(StateDeparseVxlan);
  fetch_next_header(64);
endrule
rule rl_deparse_vxlan_load if ((deparse_state_ff.first == StateDeparseVxlan) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_vxlan_send if ((deparse_state_ff.first == StateDeparseVxlan) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_sflow_next if (w_deparse_sflow);
  deparse_state_ff.enq(StateDeparseSflow);
  fetch_next_header(224);
endrule
rule rl_deparse_sflow_load if ((deparse_state_ff.first == StateDeparseSflow) && (rg_buffered[0] < 224));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_sflow_send if ((deparse_state_ff.first == StateDeparseSflow) && (rg_buffered[0] >= 224));
  succeed_and_next(224);
  deparse_state_ff.deq;
endrule
rule rl_deparse_gre_next if (w_deparse_gre);
  deparse_state_ff.enq(StateDeparseGre);
  fetch_next_header(32);
endrule
rule rl_deparse_gre_load if ((deparse_state_ff.first == StateDeparseGre) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_gre_send if ((deparse_state_ff.first == StateDeparseGre) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_erspan_t3_header_next if (w_deparse_erspan_t3_header);
  deparse_state_ff.enq(StateDeparseErspanT3Header);
  fetch_next_header(96);
endrule
rule rl_deparse_erspan_t3_header_load if ((deparse_state_ff.first == StateDeparseErspanT3Header) && (rg_buffered[0] < 96));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_erspan_t3_header_send if ((deparse_state_ff.first == StateDeparseErspanT3Header) && (rg_buffered[0] >= 96));
  succeed_and_next(96);
  deparse_state_ff.deq;
endrule
rule rl_deparse_nvgre_next if (w_deparse_nvgre);
  deparse_state_ff.enq(StateDeparseNvgre);
  fetch_next_header(32);
endrule
rule rl_deparse_nvgre_load if ((deparse_state_ff.first == StateDeparseNvgre) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_nvgre_send if ((deparse_state_ff.first == StateDeparseNvgre) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_ethernet_next if (w_deparse_inner_ethernet);
  deparse_state_ff.enq(StateDeparseInnerEthernet);
  fetch_next_header(112);
endrule
rule rl_deparse_inner_ethernet_load if ((deparse_state_ff.first == StateDeparseInnerEthernet) && (rg_buffered[0] < 112));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_ethernet_send if ((deparse_state_ff.first == StateDeparseInnerEthernet) && (rg_buffered[0] >= 112));
  succeed_and_next(112);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_ipv4_next if (w_deparse_inner_ipv4);
  deparse_state_ff.enq(StateDeparseInnerIpv4);
  fetch_next_header(160);
endrule
rule rl_deparse_inner_ipv4_load if ((deparse_state_ff.first == StateDeparseInnerIpv4) && (rg_buffered[0] < 160));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_ipv4_send if ((deparse_state_ff.first == StateDeparseInnerIpv4) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_ipv6_next if (w_deparse_inner_ipv6);
  deparse_state_ff.enq(StateDeparseInnerIpv6);
  fetch_next_header(320);
endrule
rule rl_deparse_inner_ipv6_load if ((deparse_state_ff.first == StateDeparseInnerIpv6) && (rg_buffered[0] < 320));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_ipv6_send if ((deparse_state_ff.first == StateDeparseInnerIpv6) && (rg_buffered[0] >= 320));
  succeed_and_next(320);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_udp_next if (w_deparse_inner_udp);
  deparse_state_ff.enq(StateDeparseInnerUdp);
  fetch_next_header(64);
endrule
rule rl_deparse_inner_udp_load if ((deparse_state_ff.first == StateDeparseInnerUdp) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_udp_send if ((deparse_state_ff.first == StateDeparseInnerUdp) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_icmp_next if (w_deparse_inner_icmp);
  deparse_state_ff.enq(StateDeparseInnerIcmp);
  fetch_next_header(32);
endrule
rule rl_deparse_inner_icmp_load if ((deparse_state_ff.first == StateDeparseInnerIcmp) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_icmp_send if ((deparse_state_ff.first == StateDeparseInnerIcmp) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_inner_tcp_next if (w_deparse_inner_tcp);
  deparse_state_ff.enq(StateDeparseInnerTcp);
  fetch_next_header(160);
endrule
rule rl_deparse_inner_tcp_load if ((deparse_state_ff.first == StateDeparseInnerTcp) && (rg_buffered[0] < 160));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_inner_tcp_send if ((deparse_state_ff.first == StateDeparseInnerTcp) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
endrule
rule rl_deparse_icmp_next if (w_deparse_icmp);
  deparse_state_ff.enq(StateDeparseIcmp);
  fetch_next_header(32);
endrule
rule rl_deparse_icmp_load if ((deparse_state_ff.first == StateDeparseIcmp) && (rg_buffered[0] < 32));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_icmp_send if ((deparse_state_ff.first == StateDeparseIcmp) && (rg_buffered[0] >= 32));
  succeed_and_next(32);
  deparse_state_ff.deq;
endrule
rule rl_deparse_arp_rarp_next if (w_deparse_arp_rarp);
  deparse_state_ff.enq(StateDeparseArpRarp);
  fetch_next_header(64);
endrule
rule rl_deparse_arp_rarp_load if ((deparse_state_ff.first == StateDeparseArpRarp) && (rg_buffered[0] < 64));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_arp_rarp_send if ((deparse_state_ff.first == StateDeparseArpRarp) && (rg_buffered[0] >= 64));
  succeed_and_next(64);
  deparse_state_ff.deq;
endrule
rule rl_deparse_arp_rarp_ipv4_next if (w_deparse_arp_rarp_ipv4);
  deparse_state_ff.enq(StateDeparseArpRarpIpv4);
  fetch_next_header(160);
endrule
rule rl_deparse_arp_rarp_ipv4_load if ((deparse_state_ff.first == StateDeparseArpRarpIpv4) && (rg_buffered[0] < 160));
  rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  move_buffered_amt(128);
endrule
rule rl_deparse_arp_rarp_ipv4_send if ((deparse_state_ff.first == StateDeparseArpRarpIpv4) && (rg_buffered[0] >= 160));
  succeed_and_next(160);
  deparse_state_ff.deq;
endrule
`endif // DEPARSER_RULES
`ifdef DEPARSER_STATE
PulseWire w_deparse_ethernet <- mkPulseWire();
PulseWire w_deparse_fabric_header <- mkPulseWire();
PulseWire w_deparse_fabric_header_multicast <- mkPulseWire();
PulseWire w_deparse_fabric_header_cpu <- mkPulseWire();
PulseWire w_deparse_fabric_header_sflow <- mkPulseWire();
PulseWire w_deparse_fabric_header_unicast <- mkPulseWire();
PulseWire w_deparse_fabric_header_mirror <- mkPulseWire();
PulseWire w_deparse_fabric_payload_header <- mkPulseWire();
PulseWire w_deparse_llc_header <- mkPulseWire();
PulseWire w_deparse_snap_header <- mkPulseWire();
PulseWire w_deparse_vlan_tag_0 <- mkPulseWire();
PulseWire w_deparse_vlan_tag_1 <- mkPulseWire();
PulseWire w_deparse_ipv4 <- mkPulseWire();
PulseWire w_deparse_mpls0 <- mkPulseWire();
PulseWire w_deparse_mpls1 <- mkPulseWire();
PulseWire w_deparse_mpls2 <- mkPulseWire();
PulseWire w_deparse_ipv6 <- mkPulseWire();
PulseWire w_deparse_tcp <- mkPulseWire();
PulseWire w_deparse_udp <- mkPulseWire();
PulseWire w_deparse_vxlan_gpe <- mkPulseWire();
PulseWire w_deparse_vxlan_gpe_int_header <- mkPulseWire();
PulseWire w_deparse_int_header <- mkPulseWire();
PulseWire w_deparse_int_switch_id_header <- mkPulseWire();
PulseWire w_deparse_int_ingress_port_id_header <- mkPulseWire();
PulseWire w_deparse_int_hop_latency_header <- mkPulseWire();
PulseWire w_deparse_int_q_occupancy_header <- mkPulseWire();
PulseWire w_deparse_int_ingress_tstamp_header <- mkPulseWire();
PulseWire w_deparse_int_egress_port_id_header <- mkPulseWire();
PulseWire w_deparse_int_q_congestion_header <- mkPulseWire();
PulseWire w_deparse_int_egress_port_tx_utilization_header <- mkPulseWire();
PulseWire w_deparse_int_val0 <- mkPulseWire();
PulseWire w_deparse_int_val1 <- mkPulseWire();
PulseWire w_deparse_int_val2 <- mkPulseWire();
PulseWire w_deparse_int_val3 <- mkPulseWire();
PulseWire w_deparse_int_val4 <- mkPulseWire();
PulseWire w_deparse_int_val5 <- mkPulseWire();
PulseWire w_deparse_int_val6 <- mkPulseWire();
PulseWire w_deparse_int_val7 <- mkPulseWire();
PulseWire w_deparse_int_val8 <- mkPulseWire();
PulseWire w_deparse_int_val9 <- mkPulseWire();
PulseWire w_deparse_int_val10 <- mkPulseWire();
PulseWire w_deparse_int_val11 <- mkPulseWire();
PulseWire w_deparse_int_val12 <- mkPulseWire();
PulseWire w_deparse_int_val13 <- mkPulseWire();
PulseWire w_deparse_int_val14 <- mkPulseWire();
PulseWire w_deparse_int_val15 <- mkPulseWire();
PulseWire w_deparse_int_val16 <- mkPulseWire();
PulseWire w_deparse_int_val17 <- mkPulseWire();
PulseWire w_deparse_int_val18 <- mkPulseWire();
PulseWire w_deparse_int_val19 <- mkPulseWire();
PulseWire w_deparse_int_val20 <- mkPulseWire();
PulseWire w_deparse_int_val21 <- mkPulseWire();
PulseWire w_deparse_int_val22 <- mkPulseWire();
PulseWire w_deparse_int_val23 <- mkPulseWire();
PulseWire w_deparse_genv <- mkPulseWire();
PulseWire w_deparse_vxlan <- mkPulseWire();
PulseWire w_deparse_sflow <- mkPulseWire();
PulseWire w_deparse_gre <- mkPulseWire();
PulseWire w_deparse_erspan_t3_header <- mkPulseWire();
PulseWire w_deparse_nvgre <- mkPulseWire();
PulseWire w_deparse_inner_ethernet <- mkPulseWire();
PulseWire w_deparse_inner_ipv4 <- mkPulseWire();
PulseWire w_deparse_inner_ipv6 <- mkPulseWire();
PulseWire w_deparse_inner_udp <- mkPulseWire();
PulseWire w_deparse_inner_icmp <- mkPulseWire();
PulseWire w_deparse_inner_tcp <- mkPulseWire();
PulseWire w_deparse_icmp <- mkPulseWire();
PulseWire w_deparse_arp_rarp <- mkPulseWire();
PulseWire w_deparse_arp_rarp_ipv4 <- mkPulseWire();
`endif // DEPARSER_STATE
