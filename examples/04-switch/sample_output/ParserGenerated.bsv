
`ifdef PARSER_STRUCT
typedef enum {
  StateStart,
  StateParseEthernet,
  StateParseLlcHeader,
  StateParseSnapHeader,
  StateParseVlan,
  StateParseQinq,
  StateParseQinqVlan,
  StateParseMpls,
  StateParseMplsBos,
  StateParseMplsInnerIpv4,
  StateParseMplsInnerIpv6,
  StateParseIpv4,
  StateParseIpv4InIp,
  StateParseIpv6InIp,
  StateParseIpv6,
  StateParseIcmp,
  StateParseTcp,
  StateParseUdp,
  StateParseGpeIntHeader,
  StateParseIntHeader,
  StateParseIntVal,
  StateParseAllIntMetaValueHeders,
  StateParseGre,
  StateParseGreIpv4,
  StateParseGreIpv6,
  StateParseNvgre,
  StateParseErspanT3,
  StateParseArpRarp,
  StateParseArpRarpIpv4,
  StateParseEompls,
  StateParseVxlan,
  StateParseVxlanGpe,
  StateParseGeneve,
  StateParseInnerIpv4,
  StateParseInnerIcmp,
  StateParseInnerTcp,
  StateParseInnerUdp,
  StateParseInnerIpv6,
  StateParseInnerEthernet,
  StateParseSflow,
  StateParseFabricHeader,
  StateParseFabricHeaderUnicast,
  StateParseFabricHeaderMulticast,
  StateParseFabricHeaderMirror,
  StateParseFabricHeaderCpu,
  StateParseFabricSflowHeader,
  StateParseFabricPayloadHeader,
  StateParseSetPrioMed,
  StateParseSetPrioHigh
} ParserState deriving (Bits, Eq, FShow);
`endif //PARSER_STRUCT

`ifdef PARSER_FUNCTION
function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if ((v & 'hfe00) == 'h0000) begin
      dbprint(3, $format("transit to parse_llc_header"));
      w_parse_ethernet_parse_llc_header.send();
    end
    else if ((v & 'hfa00) == 'h0000) begin
      dbprint(3, $format("transit to parse_llc_header"));
      w_parse_ethernet_parse_llc_header.send();
    end
    else if (v == 'h9000) begin
      dbprint(3, $format("transit to parse_fabric_header"));
      w_parse_ethernet_parse_fabric_header.send();
    end
    else if (v == 'h8100) begin
      dbprint(3, $format("transit to parse_vlan"));
      w_parse_ethernet_parse_vlan.send();
    end
    else if (v == 'h9100) begin
      dbprint(3, $format("transit to parse_qinq"));
      w_parse_ethernet_parse_qinq.send();
    end
    else if (v == 'h8847) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_ethernet_parse_mpls.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_ethernet_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_ethernet_parse_ipv6.send();
    end
    else if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp_rarp"));
      w_parse_ethernet_parse_arp_rarp.send();
    end
    else if (v == 'h88cc) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_ethernet_parse_set_prio_high.send();
    end
    else if (v == 'h8809) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_ethernet_parse_set_prio_high.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ethernet_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_llc_header(Bit#(8) dsap, Bit#(8) ssap);
  action
    let v = {dsap, ssap};
    if (v == 'haaaa) begin
      dbprint(3, $format("transit to parse_snap_header"));
      w_parse_llc_header_parse_snap_header.send();
    end
    else if (v == 'hfefe) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_llc_header_parse_set_prio_med.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_llc_header_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_snap_header(Bit#(16) type_);
  action
    let v = {type_};
    if (v == 'h8100) begin
      dbprint(3, $format("transit to parse_vlan"));
      w_parse_snap_header_parse_vlan.send();
    end
    else if (v == 'h9100) begin
      dbprint(3, $format("transit to parse_qinq"));
      w_parse_snap_header_parse_qinq.send();
    end
    else if (v == 'h8847) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_snap_header_parse_mpls.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_snap_header_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_snap_header_parse_ipv6.send();
    end
    else if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp_rarp"));
      w_parse_snap_header_parse_arp_rarp.send();
    end
    else if (v == 'h88cc) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_snap_header_parse_set_prio_high.send();
    end
    else if (v == 'h8809) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_snap_header_parse_set_prio_high.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_snap_header_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_vlan(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h8847) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_vlan_parse_mpls.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_vlan_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_vlan_parse_ipv6.send();
    end
    else if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp_rarp"));
      w_parse_vlan_parse_arp_rarp.send();
    end
    else if (v == 'h88cc) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_vlan_parse_set_prio_high.send();
    end
    else if (v == 'h8809) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_vlan_parse_set_prio_high.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_vlan_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_qinq(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h8100) begin
      dbprint(3, $format("transit to parse_qinq_vlan"));
      w_parse_qinq_parse_qinq_vlan.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_qinq_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_qinq_vlan(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h8847) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_qinq_vlan_parse_mpls.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_qinq_vlan_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_qinq_vlan_parse_ipv6.send();
    end
    else if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp_rarp"));
      w_parse_qinq_vlan_parse_arp_rarp.send();
    end
    else if (v == 'h88cc) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_qinq_vlan_parse_set_prio_high.send();
    end
    else if (v == 'h8809) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_qinq_vlan_parse_set_prio_high.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_qinq_vlan_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_mpls(Bit#(1) bos);
  action
    let v = {bos};
    if (v == 'h00) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_mpls_parse_mpls.send();
    end
    else if (v == 'h01) begin
      dbprint(3, $format("transit to parse_mpls_bos"));
      w_parse_mpls_parse_mpls_bos.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_mpls_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_mpls_bos(Bit#(4) current);
  action
    let v = {current};
    if (v == 'h04) begin
      dbprint(3, $format("transit to parse_mpls_inner_ipv4"));
      w_parse_mpls_bos_parse_mpls_inner_ipv4.send();
    end
    else if (v == 'h06) begin
      dbprint(3, $format("transit to parse_mpls_inner_ipv6"));
      w_parse_mpls_bos_parse_mpls_inner_ipv6.send();
    end
    else begin
      dbprint(3, $format("transit to parse_eompls"));
      w_parse_mpls_bos_parse_eompls.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_mpls_inner_ipv4();
  action
    dbprint(3, $format("transit to parse_inner_ipv4"));
    w_parse_mpls_inner_ipv4_parse_inner_ipv4.send();
  endaction
endfunction
function Action compute_next_state_parse_mpls_inner_ipv6();
  action
    dbprint(3, $format("transit to parse_inner_ipv6"));
    w_parse_mpls_inner_ipv6_parse_inner_ipv6.send();
  endaction
endfunction
function Action compute_next_state_parse_ipv4(Bit#(13) fragOffset, Bit#(4) ihl, Bit#(8) protocol);
  action
    let v = {fragOffset, ihl, protocol};
    if (v == 'h00000501) begin
      dbprint(3, $format("transit to parse_icmp"));
      w_parse_ipv4_parse_icmp.send();
    end
    else if (v == 'h00000506) begin
      dbprint(3, $format("transit to parse_tcp"));
      w_parse_ipv4_parse_tcp.send();
    end
    else if (v == 'h00000511) begin
      dbprint(3, $format("transit to parse_udp"));
      w_parse_ipv4_parse_udp.send();
    end
    else if (v == 'h0000052f) begin
      dbprint(3, $format("transit to parse_gre"));
      w_parse_ipv4_parse_gre.send();
    end
    else if (v == 'h00000504) begin
      dbprint(3, $format("transit to parse_ipv4_in_ip"));
      w_parse_ipv4_parse_ipv4_in_ip.send();
    end
    else if (v == 'h00000529) begin
      dbprint(3, $format("transit to parse_ipv6_in_ip"));
      w_parse_ipv4_parse_ipv6_in_ip.send();
    end
    else if (v == 'h00000002) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv4_parse_set_prio_med.send();
    end
    else if (v == 'h00000058) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv4_parse_set_prio_med.send();
    end
    else if (v == 'h00000059) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv4_parse_set_prio_med.send();
    end
    else if (v == 'h00000067) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv4_parse_set_prio_med.send();
    end
    else if (v == 'h00000070) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv4_parse_set_prio_med.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_ipv4_in_ip();
  action
    dbprint(3, $format("transit to parse_inner_ipv4"));
    w_parse_ipv4_in_ip_parse_inner_ipv4.send();
  endaction
endfunction
function Action compute_next_state_parse_ipv6_in_ip();
  action
    dbprint(3, $format("transit to parse_inner_ipv6"));
    w_parse_ipv6_in_ip_parse_inner_ipv6.send();
  endaction
endfunction
function Action compute_next_state_parse_ipv6(Bit#(8) nextHdr);
  action
    let v = {nextHdr};
    if (v == 'h3a) begin
      dbprint(3, $format("transit to parse_icmp"));
      w_parse_ipv6_parse_icmp.send();
    end
    else if (v == 'h06) begin
      dbprint(3, $format("transit to parse_tcp"));
      w_parse_ipv6_parse_tcp.send();
    end
    else if (v == 'h04) begin
      dbprint(3, $format("transit to parse_ipv4_in_ip"));
      w_parse_ipv6_parse_ipv4_in_ip.send();
    end
    else if (v == 'h11) begin
      dbprint(3, $format("transit to parse_udp"));
      w_parse_ipv6_parse_udp.send();
    end
    else if (v == 'h2f) begin
      dbprint(3, $format("transit to parse_gre"));
      w_parse_ipv6_parse_gre.send();
    end
    else if (v == 'h29) begin
      dbprint(3, $format("transit to parse_ipv6_in_ip"));
      w_parse_ipv6_parse_ipv6_in_ip.send();
    end
    else if (v == 'h58) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv6_parse_set_prio_med.send();
    end
    else if (v == 'h59) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv6_parse_set_prio_med.send();
    end
    else if (v == 'h67) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv6_parse_set_prio_med.send();
    end
    else if (v == 'h70) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_ipv6_parse_set_prio_med.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_ipv6_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_icmp(Bit#(16) typeCode);
  action
    let v = {typeCode};
    if ((v & 'hfe00) == 'h8200) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_icmp_parse_set_prio_med.send();
    end
    else if ((v & 'hfc00) == 'h8400) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_icmp_parse_set_prio_med.send();
    end
    else if ((v & 'hff00) == 'h8800) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_icmp_parse_set_prio_med.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_icmp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_tcp(Bit#(16) dstPort);
  action
    let v = {dstPort};
    if (v == 'h00b3) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_tcp_parse_set_prio_med.send();
    end
    else if (v == 'h027f) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_tcp_parse_set_prio_med.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_tcp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_udp(Bit#(16) dstPort);
  action
    let v = {dstPort};
    if (v == 'h12b5) begin
      dbprint(3, $format("transit to parse_vxlan"));
      w_parse_udp_parse_vxlan.send();
    end
    else if (v == 'h17c1) begin
      dbprint(3, $format("transit to parse_geneve"));
      w_parse_udp_parse_geneve.send();
    end
    else if (v == 'h12b6) begin
      dbprint(3, $format("transit to parse_vxlan_gpe"));
      w_parse_udp_parse_vxlan_gpe.send();
    end
    else if (v == 'h0043) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h0044) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h0222) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h0223) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h0208) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h0209) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h07c1) begin
      dbprint(3, $format("transit to parse_set_prio_med"));
      w_parse_udp_parse_set_prio_med.send();
    end
    else if (v == 'h18c7) begin
      dbprint(3, $format("transit to parse_sflow"));
      w_parse_udp_parse_sflow.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_udp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_gpe_int_header();
  action
    dbprint(3, $format("transit to parse_int_header"));
    w_parse_gpe_int_header_parse_int_header.send();
  endaction
endfunction
function Action compute_next_state_parse_int_header(Bit#(5) rsvd1, Bit#(8) total_hop_cnt);
  action
    let v = {rsvd1, total_hop_cnt};
    if (v == 'h0000) begin
      dbprint(3, $format("transit to start"));
      w_parse_int_header_start.send();
    end
    else if ((v & 'h0f00) == 'h0000) begin
      dbprint(3, $format("transit to parse_int_val"));
      w_parse_int_header_parse_int_val.send();
    end
    else if ((v & 'h0000) == 'h0000) begin
      dbprint(3, $format("transit to start"));
      w_parse_int_header_start.send();
    end
    else begin
      dbprint(3, $format("transit to parse_all_int_meta_value_heders"));
      w_parse_int_header_parse_all_int_meta_value_heders.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_int_val(Bit#(1) bos);
  action
    let v = {bos};
    if (v == 'h00) begin
      dbprint(3, $format("transit to parse_int_val"));
      w_parse_int_val_parse_int_val.send();
    end
    else if (v == 'h01) begin
      dbprint(3, $format("transit to parse_inner_ethernet"));
      w_parse_int_val_parse_inner_ethernet.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_all_int_meta_value_heders();
  action
    dbprint(3, $format("transit to parse_int_val"));
    w_parse_all_int_meta_value_heders_parse_int_val.send();
  endaction
endfunction
function Action compute_next_state_parse_gre(Bit#(1) cc, Bit#(1) cr, Bit#(1) ck, Bit#(1) cs, Bit#(1) s, Bit#(3) recurse, Bit#(5) flags, Bit#(3) ver, Bit#(16) proto);
  action
    let v = {cc, cr, ck, cs, s, recurse, flags, ver, proto};
    if (v == 'h00000100000000006558) begin
      dbprint(3, $format("transit to parse_nvgre"));
      w_parse_gre_parse_nvgre.send();
    end
    else if (v == 'h00000000000000000800) begin
      dbprint(3, $format("transit to parse_gre_ipv4"));
      w_parse_gre_parse_gre_ipv4.send();
    end
    else if (v == 'h000000000000000086dd) begin
      dbprint(3, $format("transit to parse_gre_ipv6"));
      w_parse_gre_parse_gre_ipv6.send();
    end
    else if (v == 'h000000000000000022eb) begin
      dbprint(3, $format("transit to parse_erspan_t3"));
      w_parse_gre_parse_erspan_t3.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_gre_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_gre_ipv4();
  action
    dbprint(3, $format("transit to parse_inner_ipv4"));
    w_parse_gre_ipv4_parse_inner_ipv4.send();
  endaction
endfunction
function Action compute_next_state_parse_gre_ipv6();
  action
    dbprint(3, $format("transit to parse_inner_ipv6"));
    w_parse_gre_ipv6_parse_inner_ipv6.send();
  endaction
endfunction
function Action compute_next_state_parse_nvgre();
  action
    dbprint(3, $format("transit to parse_inner_ethernet"));
    w_parse_nvgre_parse_inner_ethernet.send();
  endaction
endfunction
function Action compute_next_state_parse_erspan_t3();
  action
    dbprint(3, $format("transit to parse_inner_ethernet"));
    w_parse_erspan_t3_parse_inner_ethernet.send();
  endaction
endfunction
function Action compute_next_state_parse_arp_rarp(Bit#(16) protoType);
  action
    let v = {protoType};
    if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_arp_rarp_ipv4"));
      w_parse_arp_rarp_parse_arp_rarp_ipv4.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_arp_rarp_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_arp_rarp_ipv4();
  action
    dbprint(3, $format("transit to parse_set_prio_med"));
    w_parse_arp_rarp_ipv4_parse_set_prio_med.send();
  endaction
endfunction
function Action compute_next_state_parse_eompls();
  action
    dbprint(3, $format("transit to parse_inner_ethernet"));
    w_parse_eompls_parse_inner_ethernet.send();
  endaction
endfunction
function Action compute_next_state_parse_vxlan();
  action
    dbprint(3, $format("transit to parse_inner_ethernet"));
    w_parse_vxlan_parse_inner_ethernet.send();
  endaction
endfunction
function Action compute_next_state_parse_vxlan_gpe(Bit#(8) flags, Bit#(8) next_proto);
  action
    let v = {flags, next_proto};
    if ((v & 'h08ff) == 'h0805) begin
      dbprint(3, $format("transit to parse_gpe_int_header"));
      w_parse_vxlan_gpe_parse_gpe_int_header.send();
    end
    else begin
      dbprint(3, $format("transit to parse_inner_ethernet"));
      w_parse_vxlan_gpe_parse_inner_ethernet.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_geneve(Bit#(2) ver, Bit#(6) optLen, Bit#(16) protoType);
  action
    let v = {ver, optLen, protoType};
    if (v == 'h00006558) begin
      dbprint(3, $format("transit to parse_inner_ethernet"));
      w_parse_geneve_parse_inner_ethernet.send();
    end
    else if (v == 'h00000800) begin
      dbprint(3, $format("transit to parse_inner_ipv4"));
      w_parse_geneve_parse_inner_ipv4.send();
    end
    else if (v == 'h000086dd) begin
      dbprint(3, $format("transit to parse_inner_ipv6"));
      w_parse_geneve_parse_inner_ipv6.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_geneve_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_inner_ipv4(Bit#(13) fragOffset, Bit#(4) ihl, Bit#(8) protocol);
  action
    let v = {fragOffset, ihl, protocol};
    if (v == 'h00000501) begin
      dbprint(3, $format("transit to parse_inner_icmp"));
      w_parse_inner_ipv4_parse_inner_icmp.send();
    end
    else if (v == 'h00000506) begin
      dbprint(3, $format("transit to parse_inner_tcp"));
      w_parse_inner_ipv4_parse_inner_tcp.send();
    end
    else if (v == 'h00000511) begin
      dbprint(3, $format("transit to parse_inner_udp"));
      w_parse_inner_ipv4_parse_inner_udp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_inner_ipv4_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_inner_icmp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_inner_icmp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_inner_tcp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_inner_tcp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_inner_udp();
  action
    dbprint(3, $format("transit to start"));
    w_parse_inner_udp_start.send();
  endaction
endfunction
function Action compute_next_state_parse_inner_ipv6(Bit#(8) nextHdr);
  action
    let v = {nextHdr};
    if (v == 'h3a) begin
      dbprint(3, $format("transit to parse_inner_icmp"));
      w_parse_inner_ipv6_parse_inner_icmp.send();
    end
    else if (v == 'h06) begin
      dbprint(3, $format("transit to parse_inner_tcp"));
      w_parse_inner_ipv6_parse_inner_tcp.send();
    end
    else if (v == 'h11) begin
      dbprint(3, $format("transit to parse_inner_udp"));
      w_parse_inner_ipv6_parse_inner_udp.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_inner_ipv6_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_inner_ethernet(Bit#(16) etherType);
  action
    let v = {etherType};
    if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_inner_ipv4"));
      w_parse_inner_ethernet_parse_inner_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_inner_ipv6"));
      w_parse_inner_ethernet_parse_inner_ipv6.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_inner_ethernet_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_sflow();
  action
    dbprint(3, $format("transit to start"));
    w_parse_sflow_start.send();
  endaction
endfunction
function Action compute_next_state_parse_fabric_header(Bit#(3) packetType);
  action
    let v = {packetType};
    if (v == 'h01) begin
      dbprint(3, $format("transit to parse_fabric_header_unicast"));
      w_parse_fabric_header_parse_fabric_header_unicast.send();
    end
    else if (v == 'h02) begin
      dbprint(3, $format("transit to parse_fabric_header_multicast"));
      w_parse_fabric_header_parse_fabric_header_multicast.send();
    end
    else if (v == 'h03) begin
      dbprint(3, $format("transit to parse_fabric_header_mirror"));
      w_parse_fabric_header_parse_fabric_header_mirror.send();
    end
    else if (v == 'h05) begin
      dbprint(3, $format("transit to parse_fabric_header_cpu"));
      w_parse_fabric_header_parse_fabric_header_cpu.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_fabric_header_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_fabric_header_unicast();
  action
    dbprint(3, $format("transit to parse_fabric_payload_header"));
    w_parse_fabric_header_unicast_parse_fabric_payload_header.send();
  endaction
endfunction
function Action compute_next_state_parse_fabric_header_multicast();
  action
    dbprint(3, $format("transit to parse_fabric_payload_header"));
    w_parse_fabric_header_multicast_parse_fabric_payload_header.send();
  endaction
endfunction
function Action compute_next_state_parse_fabric_header_mirror();
  action
    dbprint(3, $format("transit to parse_fabric_payload_header"));
    w_parse_fabric_header_mirror_parse_fabric_payload_header.send();
  endaction
endfunction
function Action compute_next_state_parse_fabric_header_cpu(Bit#(16) reasonCode);
  action
    let v = {reasonCode};
    if (v == 'h0004) begin
      dbprint(3, $format("transit to parse_fabric_sflow_header"));
      w_parse_fabric_header_cpu_parse_fabric_sflow_header.send();
    end
    else begin
      dbprint(3, $format("transit to parse_fabric_payload_header"));
      w_parse_fabric_header_cpu_parse_fabric_payload_header.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_fabric_sflow_header();
  action
    dbprint(3, $format("transit to parse_fabric_payload_header"));
    w_parse_fabric_sflow_header_parse_fabric_payload_header.send();
  endaction
endfunction
function Action compute_next_state_parse_fabric_payload_header(Bit#(16) etherType);
  action
    let v = {etherType};
    if ((v & 'hfe00) == 'h0000) begin
      dbprint(3, $format("transit to parse_llc_header"));
      w_parse_fabric_payload_header_parse_llc_header.send();
    end
    else if ((v & 'hfa00) == 'h0000) begin
      dbprint(3, $format("transit to parse_llc_header"));
      w_parse_fabric_payload_header_parse_llc_header.send();
    end
    else if (v == 'h8100) begin
      dbprint(3, $format("transit to parse_vlan"));
      w_parse_fabric_payload_header_parse_vlan.send();
    end
    else if (v == 'h9100) begin
      dbprint(3, $format("transit to parse_qinq"));
      w_parse_fabric_payload_header_parse_qinq.send();
    end
    else if (v == 'h8847) begin
      dbprint(3, $format("transit to parse_mpls"));
      w_parse_fabric_payload_header_parse_mpls.send();
    end
    else if (v == 'h0800) begin
      dbprint(3, $format("transit to parse_ipv4"));
      w_parse_fabric_payload_header_parse_ipv4.send();
    end
    else if (v == 'h86dd) begin
      dbprint(3, $format("transit to parse_ipv6"));
      w_parse_fabric_payload_header_parse_ipv6.send();
    end
    else if (v == 'h0806) begin
      dbprint(3, $format("transit to parse_arp_rarp"));
      w_parse_fabric_payload_header_parse_arp_rarp.send();
    end
    else if (v == 'h88cc) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_fabric_payload_header_parse_set_prio_high.send();
    end
    else if (v == 'h8809) begin
      dbprint(3, $format("transit to parse_set_prio_high"));
      w_parse_fabric_payload_header_parse_set_prio_high.send();
    end
    else begin
      dbprint(3, $format("transit to start"));
      w_parse_fabric_payload_header_start.send();
    end
  endaction
endfunction
function Action compute_next_state_parse_set_prio_med();
  action
    dbprint(3, $format("transit to start"));
    w_parse_set_prio_med_start.send();
  endaction
endfunction
function Action compute_next_state_parse_set_prio_high();
  action
    dbprint(3, $format("transit to start"));
    w_parse_set_prio_high_start.send();
  endaction
endfunction
`endif // PARSER_FUNCTION

`ifdef PARSER_RULES
(* mutually_exclusive="rl_parse_fabric_payload_header_parse_llc_header, rl_parse_set_prio_med_start, rl_parse_all_int_meta_value_heders_parse_int_val, rl_parse_geneve_start, rl_parse_mpls_inner_ipv4_parse_inner_ipv4, rl_parse_vlan_start, rl_parse_qinq_vlan_parse_arp_rarp, rl_parse_llc_header_parse_set_prio_med, rl_parse_fabric_payload_header_parse_ipv4, rl_parse_icmp_parse_set_prio_med, rl_parse_fabric_payload_header_parse_ipv6, rl_parse_inner_ethernet_parse_inner_ipv6, rl_parse_ipv4_parse_ipv4_in_ip, rl_parse_inner_ethernet_parse_inner_ipv4, rl_parse_inner_ipv4_parse_inner_udp, rl_parse_ipv4_parse_ipv6_in_ip, rl_parse_arp_rarp_parse_arp_rarp_ipv4, rl_parse_vlan_parse_ipv6, rl_parse_ipv4_parse_tcp, rl_parse_vlan_parse_ipv4, rl_parse_fabric_payload_header_start, rl_parse_set_prio_high_start, rl_parse_int_header_parse_all_int_meta_value_heders, rl_parse_ipv6_start, rl_parse_ipv6_parse_icmp, rl_parse_erspan_t3_parse_inner_ethernet, rl_parse_fabric_header_multicast_parse_fabric_payload_header, rl_parse_vxlan_parse_inner_ethernet, rl_parse_gre_start, rl_parse_eompls_parse_inner_ethernet, rl_parse_snap_header_parse_vlan, rl_parse_ethernet_parse_qinq, rl_parse_int_header_start, rl_parse_ipv6_parse_ipv6_in_ip, rl_parse_fabric_header_parse_fabric_header_multicast, rl_parse_snap_header_parse_ipv6, rl_parse_mpls_parse_mpls, rl_parse_snap_header_parse_ipv4, rl_parse_ethernet_parse_vlan, rl_parse_ipv6_parse_udp, rl_parse_gre_ipv6_parse_inner_ipv6, rl_parse_gpe_int_header_parse_int_header, rl_parse_ipv4_start, rl_parse_inner_ethernet_start, rl_parse_fabric_header_cpu_parse_fabric_payload_header, rl_parse_udp_parse_vxlan_gpe, rl_parse_qinq_vlan_parse_ipv4, rl_parse_qinq_vlan_parse_ipv6, rl_parse_vlan_parse_arp_rarp, rl_parse_fabric_payload_header_parse_mpls, rl_parse_mpls_bos_parse_mpls_inner_ipv4, rl_parse_mpls_bos_parse_mpls_inner_ipv6, rl_parse_inner_ipv6_start, rl_parse_ethernet_parse_mpls, rl_parse_int_header_parse_int_val, rl_parse_arp_rarp_ipv4_parse_set_prio_med, rl_parse_ethernet_parse_fabric_header, rl_parse_inner_ipv6_parse_inner_udp, rl_parse_qinq_vlan_parse_set_prio_high, rl_parse_qinq_start, rl_parse_snap_header_parse_mpls, rl_parse_fabric_payload_header_parse_vlan, rl_parse_fabric_header_parse_fabric_header_mirror, rl_parse_fabric_header_unicast_parse_fabric_payload_header, rl_parse_ipv6_parse_ipv4_in_ip, rl_parse_fabric_header_start, rl_parse_fabric_header_mirror_parse_fabric_payload_header, rl_parse_gre_ipv4_parse_inner_ipv4, rl_parse_udp_parse_set_prio_med, rl_parse_gre_parse_erspan_t3, rl_parse_udp_start, rl_parse_gre_parse_gre_ipv4, rl_parse_gre_parse_gre_ipv6, rl_parse_ethernet_parse_set_prio_high, rl_parse_vxlan_gpe_parse_inner_ethernet, rl_parse_inner_udp_start, rl_parse_fabric_sflow_header_parse_fabric_payload_header, rl_parse_inner_tcp_start, rl_start_parse_ethernet, rl_parse_vlan_parse_mpls, rl_parse_llc_header_start, rl_parse_sflow_start, rl_parse_fabric_payload_header_parse_arp_rarp, rl_parse_mpls_bos_parse_eompls, rl_parse_arp_rarp_start, rl_parse_int_val_parse_int_val, rl_parse_inner_ipv4_parse_inner_tcp, rl_parse_ipv6_parse_gre, rl_parse_ipv4_parse_set_prio_med, rl_parse_tcp_parse_set_prio_med, rl_parse_inner_ipv4_parse_inner_icmp, rl_parse_qinq_parse_qinq_vlan, rl_parse_udp_parse_geneve, rl_parse_inner_ipv6_parse_inner_tcp, rl_parse_geneve_parse_inner_ipv4, rl_parse_geneve_parse_inner_ipv6, rl_parse_geneve_parse_inner_ethernet, rl_parse_nvgre_parse_inner_ethernet, rl_parse_ethernet_start, rl_parse_qinq_vlan_start, rl_parse_fabric_header_parse_fabric_header_cpu, rl_parse_fabric_header_parse_fabric_header_unicast, rl_parse_udp_parse_vxlan, rl_parse_tcp_start, rl_parse_int_val_parse_inner_ethernet, rl_parse_ethernet_parse_arp_rarp, rl_parse_snap_header_parse_arp_rarp, rl_parse_mpls_start, rl_parse_llc_header_parse_snap_header, rl_parse_udp_parse_sflow, rl_parse_vxlan_gpe_parse_gpe_int_header, rl_parse_vlan_parse_set_prio_high, rl_parse_ipv6_in_ip_parse_inner_ipv6, rl_parse_snap_header_parse_qinq, rl_parse_ipv4_parse_udp, rl_parse_inner_ipv6_parse_inner_icmp, rl_parse_ipv6_parse_tcp, rl_parse_ipv6_parse_set_prio_med, rl_parse_fabric_payload_header_parse_qinq, rl_parse_mpls_inner_ipv6_parse_inner_ipv6, rl_parse_ethernet_parse_ipv4, rl_parse_ethernet_parse_ipv6, rl_parse_snap_header_parse_set_prio_high, rl_parse_ipv4_parse_gre, rl_parse_ethernet_parse_llc_header, rl_parse_ipv4_parse_icmp, rl_parse_qinq_vlan_parse_mpls, rl_parse_ipv4_in_ip_parse_inner_ipv4, rl_parse_mpls_parse_mpls_bos, rl_parse_gre_parse_nvgre, rl_parse_icmp_start, rl_parse_inner_ipv4_start, rl_parse_snap_header_start, rl_parse_fabric_payload_header_parse_set_prio_high, rl_parse_inner_icmp_start, rl_parse_fabric_header_cpu_parse_fabric_sflow_header" *)
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
rule rl_parse_ethernet_parse_llc_header if ((w_parse_ethernet_parse_llc_header));
  parse_state_ff.enq(StateParseLlcHeader);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_llc_header"));
  fetch_next_header0(24);
endrule
rule rl_parse_ethernet_parse_fabric_header if ((w_parse_ethernet_parse_fabric_header));
  parse_state_ff.enq(StateParseFabricHeader);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_fabric_header"));
  fetch_next_header0(40);
endrule
rule rl_parse_ethernet_parse_vlan if ((w_parse_ethernet_parse_vlan));
  parse_state_ff.enq(StateParseVlan);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_vlan"));
  fetch_next_header0(32);
endrule
rule rl_parse_ethernet_parse_qinq if ((w_parse_ethernet_parse_qinq));
  parse_state_ff.enq(StateParseQinq);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_qinq"));
  fetch_next_header0(32);
endrule
rule rl_parse_ethernet_parse_mpls if ((w_parse_ethernet_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_mpls"));
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
rule rl_parse_ethernet_parse_arp_rarp if ((w_parse_ethernet_parse_arp_rarp));
  parse_state_ff.enq(StateParseArpRarp);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_arp_rarp"));
  fetch_next_header0(64);
endrule
rule rl_parse_ethernet_parse_set_prio_high if ((w_parse_ethernet_parse_set_prio_high));
  parse_state_ff.enq(StateParseSetPrioHigh);
  dbprint(3, $format("%s -> %s", "parse_ethernet", "parse_set_prio_high"));
  fetch_next_header0(0);
endrule
rule rl_parse_ethernet_start if ((w_parse_ethernet_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ethernet", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_llc_header_load if ((parse_state_ff.first == StateParseLlcHeader) && (rg_buffered[0] < 24));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_llc_header_extract if ((parse_state_ff.first == StateParseLlcHeader) && (rg_buffered[0] >= 24));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let llc_header_t = extract_llc_header_t(truncate(data));
  compute_next_state_parse_llc_header(llc_header_t.dsap,llc_header_t.ssap);
  rg_tmp[0] <= zeroExtend(data >> 24);
  succeed_and_next(24);
  dbprint(3, $format("extract %s", "parse_llc_header"));
  parse_state_ff.deq;
endrule
rule rl_parse_llc_header_parse_snap_header if ((w_parse_llc_header_parse_snap_header));
  parse_state_ff.enq(StateParseSnapHeader);
  dbprint(3, $format("%s -> %s", "parse_llc_header", "parse_snap_header"));
  fetch_next_header0(40);
endrule
rule rl_parse_llc_header_parse_set_prio_med if ((w_parse_llc_header_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_llc_header", "parse_set_prio_med"));
  fetch_next_header0(0);
endrule
rule rl_parse_llc_header_start if ((w_parse_llc_header_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_llc_header", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_snap_header_load if ((parse_state_ff.first == StateParseSnapHeader) && (rg_buffered[0] < 40));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_snap_header_extract if ((parse_state_ff.first == StateParseSnapHeader) && (rg_buffered[0] >= 40));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let snap_header_t = extract_snap_header_t(truncate(data));
  compute_next_state_parse_snap_header(snap_header_t.type_);
  rg_tmp[0] <= zeroExtend(data >> 40);
  succeed_and_next(40);
  dbprint(3, $format("extract %s", "parse_snap_header"));
  parse_state_ff.deq;
endrule
rule rl_parse_snap_header_parse_vlan if ((w_parse_snap_header_parse_vlan));
  parse_state_ff.enq(StateParseVlan);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_vlan"));
  fetch_next_header0(32);
endrule
rule rl_parse_snap_header_parse_qinq if ((w_parse_snap_header_parse_qinq));
  parse_state_ff.enq(StateParseQinq);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_qinq"));
  fetch_next_header0(32);
endrule
rule rl_parse_snap_header_parse_mpls if ((w_parse_snap_header_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_mpls"));
  fetch_next_header0(32);
endrule
rule rl_parse_snap_header_parse_ipv4 if ((w_parse_snap_header_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_snap_header_parse_ipv6 if ((w_parse_snap_header_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_snap_header_parse_arp_rarp if ((w_parse_snap_header_parse_arp_rarp));
  parse_state_ff.enq(StateParseArpRarp);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_arp_rarp"));
  fetch_next_header0(64);
endrule
rule rl_parse_snap_header_parse_set_prio_high if ((w_parse_snap_header_parse_set_prio_high));
  parse_state_ff.enq(StateParseSetPrioHigh);
  dbprint(3, $format("%s -> %s", "parse_snap_header", "parse_set_prio_high"));
  fetch_next_header0(0);
endrule
rule rl_parse_snap_header_start if ((w_parse_snap_header_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_snap_header", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_vlan_load if ((parse_state_ff.first == StateParseVlan) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_vlan_extract if ((parse_state_ff.first == StateParseVlan) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let vlan_tag_t = extract_vlan_tag_t(truncate(data));
  compute_next_state_parse_vlan(vlan_tag_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_vlan"));
  parse_state_ff.deq;
endrule
rule rl_parse_vlan_parse_mpls if ((w_parse_vlan_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_vlan", "parse_mpls"));
  fetch_next_header0(32);
endrule
rule rl_parse_vlan_parse_ipv4 if ((w_parse_vlan_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_vlan", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_vlan_parse_ipv6 if ((w_parse_vlan_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_vlan", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_vlan_parse_arp_rarp if ((w_parse_vlan_parse_arp_rarp));
  parse_state_ff.enq(StateParseArpRarp);
  dbprint(3, $format("%s -> %s", "parse_vlan", "parse_arp_rarp"));
  fetch_next_header0(64);
endrule
rule rl_parse_vlan_parse_set_prio_high if ((w_parse_vlan_parse_set_prio_high));
  parse_state_ff.enq(StateParseSetPrioHigh);
  dbprint(3, $format("%s -> %s", "parse_vlan", "parse_set_prio_high"));
  fetch_next_header0(0);
endrule
rule rl_parse_vlan_start if ((w_parse_vlan_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_vlan", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_qinq_load if ((parse_state_ff.first == StateParseQinq) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_qinq_extract if ((parse_state_ff.first == StateParseQinq) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let vlan_tag_t = extract_vlan_tag_t(truncate(data));
  compute_next_state_parse_qinq(vlan_tag_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_qinq"));
  parse_state_ff.deq;
endrule
rule rl_parse_qinq_parse_qinq_vlan if ((w_parse_qinq_parse_qinq_vlan));
  parse_state_ff.enq(StateParseQinqVlan);
  dbprint(3, $format("%s -> %s", "parse_qinq", "parse_qinq_vlan"));
  fetch_next_header0(32);
endrule
rule rl_parse_qinq_start if ((w_parse_qinq_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_qinq", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_qinq_vlan_load if ((parse_state_ff.first == StateParseQinqVlan) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_qinq_vlan_extract if ((parse_state_ff.first == StateParseQinqVlan) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let vlan_tag_t = extract_vlan_tag_t(truncate(data));
  compute_next_state_parse_qinq_vlan(vlan_tag_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_qinq_vlan"));
  parse_state_ff.deq;
endrule
rule rl_parse_qinq_vlan_parse_mpls if ((w_parse_qinq_vlan_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "parse_mpls"));
  fetch_next_header0(32);
endrule
rule rl_parse_qinq_vlan_parse_ipv4 if ((w_parse_qinq_vlan_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_qinq_vlan_parse_ipv6 if ((w_parse_qinq_vlan_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_qinq_vlan_parse_arp_rarp if ((w_parse_qinq_vlan_parse_arp_rarp));
  parse_state_ff.enq(StateParseArpRarp);
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "parse_arp_rarp"));
  fetch_next_header0(64);
endrule
rule rl_parse_qinq_vlan_parse_set_prio_high if ((w_parse_qinq_vlan_parse_set_prio_high));
  parse_state_ff.enq(StateParseSetPrioHigh);
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "parse_set_prio_high"));
  fetch_next_header0(0);
endrule
rule rl_parse_qinq_vlan_start if ((w_parse_qinq_vlan_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_qinq_vlan", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_load if ((parse_state_ff.first == StateParseMpls) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_extract if ((parse_state_ff.first == StateParseMpls) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  //compute_next_state_parse_mpls(None.bos);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_mpls"));
  parse_state_ff.deq;
endrule
rule rl_parse_mpls_parse_mpls if ((w_parse_mpls_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_mpls", "parse_mpls"));
  fetch_next_header0(32);
endrule
rule rl_parse_mpls_parse_mpls_bos if ((w_parse_mpls_parse_mpls_bos));
  Vector#(512, Bit#(1)) buffer = unpack(rg_tmp[1]);
  Bit#(8) lookahead = pack(takeAt(0, buffer));
  dbprint(3, $format("look ahead %h, %h", lookahead, rg_tmp[1]));
  compute_next_state_parse_mpls_bos(lookahead);
  dbprint(3, $format("counter", lookahead ));
  dbprint(3, $format("%s -> %s", "parse_mpls", "parse_mpls_bos"));
  fetch_next_header0(0);
endrule
rule rl_parse_mpls_start if ((w_parse_mpls_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_mpls", "start"));
  fetch_next_header0(0);
endrule
rule rl_parse_mpls_bos_parse_mpls_inner_ipv4 if ((w_parse_mpls_bos_parse_mpls_inner_ipv4));
  parse_state_ff.enq(StateParseMplsInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_mpls_bos", "parse_mpls_inner_ipv4"));
  fetch_next_header1(0);
endrule
rule rl_parse_mpls_bos_parse_mpls_inner_ipv6 if ((w_parse_mpls_bos_parse_mpls_inner_ipv6));
  parse_state_ff.enq(StateParseMplsInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_mpls_bos", "parse_mpls_inner_ipv6"));
  fetch_next_header1(0);
endrule
rule rl_parse_mpls_bos_parse_eompls if ((w_parse_mpls_bos_parse_eompls));
  parse_state_ff.enq(StateParseEompls);
  dbprint(3, $format("%s -> %s", "parse_mpls_bos", "parse_eompls"));
  fetch_next_header1(0);
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_inner_ipv4_load if ((parse_state_ff.first == StateParseMplsInnerIpv4) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_inner_ipv4_extract if ((parse_state_ff.first == StateParseMplsInnerIpv4) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mpls_inner_ipv4();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_mpls_inner_ipv4"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h9;
endrule
rule rl_parse_mpls_inner_ipv4_parse_inner_ipv4 if ((w_parse_mpls_inner_ipv4_parse_inner_ipv4));
  parse_state_ff.enq(StateParseInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_mpls_inner_ipv4", "parse_inner_ipv4"));
  fetch_next_header0(160);
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_inner_ipv6_load if ((parse_state_ff.first == StateParseMplsInnerIpv6) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_mpls_inner_ipv6_extract if ((parse_state_ff.first == StateParseMplsInnerIpv6) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_mpls_inner_ipv6();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_mpls_inner_ipv6"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h9;
endrule
rule rl_parse_mpls_inner_ipv6_parse_inner_ipv6 if ((w_parse_mpls_inner_ipv6_parse_inner_ipv6));
  parse_state_ff.enq(StateParseInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_mpls_inner_ipv6", "parse_inner_ipv6"));
  fetch_next_header0(320);
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
  compute_next_state_parse_ipv4(ipv4_t.fragOffset,ipv4_t.ihl,ipv4_t.protocol);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_ipv4"));
  parse_state_ff.deq;
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
rule rl_parse_ipv4_parse_gre if ((w_parse_ipv4_parse_gre));
  parse_state_ff.enq(StateParseGre);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_gre"));
  fetch_next_header0(32);
endrule
rule rl_parse_ipv4_parse_ipv4_in_ip if ((w_parse_ipv4_parse_ipv4_in_ip));
  parse_state_ff.enq(StateParseIpv4InIp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_ipv4_in_ip"));
  fetch_next_header0(0);
endrule
rule rl_parse_ipv4_parse_ipv6_in_ip if ((w_parse_ipv4_parse_ipv6_in_ip));
  parse_state_ff.enq(StateParseIpv6InIp);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_ipv6_in_ip"));
  fetch_next_header0(0);
endrule
rule rl_parse_ipv4_parse_set_prio_med if ((w_parse_ipv4_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_ipv4", "parse_set_prio_med"));
  fetch_next_header0(0);
endrule
rule rl_parse_ipv4_start if ((w_parse_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_ipv4", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_in_ip_load if ((parse_state_ff.first == StateParseIpv4InIp) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ipv4_in_ip_extract if ((parse_state_ff.first == StateParseIpv4InIp) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_ipv4_in_ip();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_ipv4_in_ip"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h3;
endrule
rule rl_parse_ipv4_in_ip_parse_inner_ipv4 if ((w_parse_ipv4_in_ip_parse_inner_ipv4));
  parse_state_ff.enq(StateParseInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_ipv4_in_ip", "parse_inner_ipv4"));
  fetch_next_header0(160);
endrule
(* fire_when_enabled *)
rule rl_parse_ipv6_in_ip_load if ((parse_state_ff.first == StateParseIpv6InIp) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_ipv6_in_ip_extract if ((parse_state_ff.first == StateParseIpv6InIp) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_ipv6_in_ip();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_ipv6_in_ip"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h3;
endrule
rule rl_parse_ipv6_in_ip_parse_inner_ipv6 if ((w_parse_ipv6_in_ip_parse_inner_ipv6));
  parse_state_ff.enq(StateParseInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_ipv6_in_ip", "parse_inner_ipv6"));
  fetch_next_header0(320);
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
  let ipv6_t = extract_ipv6_t(truncate(data));
  compute_next_state_parse_ipv6(ipv6_t.nextHdr);
  rg_tmp[0] <= zeroExtend(data >> 320);
  succeed_and_next(320);
  dbprint(3, $format("extract %s", "parse_ipv6"));
  parse_state_ff.deq;
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
rule rl_parse_ipv6_parse_ipv4_in_ip if ((w_parse_ipv6_parse_ipv4_in_ip));
  parse_state_ff.enq(StateParseIpv4InIp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_ipv4_in_ip"));
  fetch_next_header0(0);
endrule
rule rl_parse_ipv6_parse_udp if ((w_parse_ipv6_parse_udp));
  parse_state_ff.enq(StateParseUdp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_ipv6_parse_gre if ((w_parse_ipv6_parse_gre));
  parse_state_ff.enq(StateParseGre);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_gre"));
  fetch_next_header0(32);
endrule
rule rl_parse_ipv6_parse_ipv6_in_ip if ((w_parse_ipv6_parse_ipv6_in_ip));
  parse_state_ff.enq(StateParseIpv6InIp);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_ipv6_in_ip"));
  fetch_next_header0(0);
endrule
rule rl_parse_ipv6_parse_set_prio_med if ((w_parse_ipv6_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_ipv6", "parse_set_prio_med"));
  fetch_next_header0(0);
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
  let icmp_t = extract_icmp_t(truncate(data));
  compute_next_state_parse_icmp(icmp_t.typeCode);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_icmp"));
  parse_state_ff.deq;
  l3_metadata$lkp_outer_l4_sport[0] <= icmptypeCode;
endrule
rule rl_parse_icmp_parse_set_prio_med if ((w_parse_icmp_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_icmp", "parse_set_prio_med"));
  fetch_next_header0(0);
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
  let tcp_t = extract_tcp_t(truncate(data));
  compute_next_state_parse_tcp(tcp_t.dstPort);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_tcp"));
  parse_state_ff.deq;
  l3_metadata$lkp_outer_l4_sport[0] <= tcpsrcPort;
endrule
rule rl_parse_tcp_parse_set_prio_med if ((w_parse_tcp_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_tcp", "parse_set_prio_med"));
  fetch_next_header0(0);
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
  let udp_t = extract_udp_t(truncate(data));
  compute_next_state_parse_udp(udp_t.dstPort);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_udp"));
  parse_state_ff.deq;
  l3_metadata$lkp_outer_l4_sport[0] <= udpsrcPort;
endrule
rule rl_parse_udp_parse_vxlan if ((w_parse_udp_parse_vxlan));
  parse_state_ff.enq(StateParseVxlan);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_vxlan"));
  fetch_next_header0(64);
endrule
rule rl_parse_udp_parse_geneve if ((w_parse_udp_parse_geneve));
  parse_state_ff.enq(StateParseGeneve);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_geneve"));
  fetch_next_header0(64);
endrule
rule rl_parse_udp_parse_vxlan_gpe if ((w_parse_udp_parse_vxlan_gpe));
  parse_state_ff.enq(StateParseVxlanGpe);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_vxlan_gpe"));
  fetch_next_header0(64);
endrule
rule rl_parse_udp_parse_set_prio_med if ((w_parse_udp_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_set_prio_med"));
  fetch_next_header0(0);
endrule
rule rl_parse_udp_parse_sflow if ((w_parse_udp_parse_sflow));
  parse_state_ff.enq(StateParseSflow);
  dbprint(3, $format("%s -> %s", "parse_udp", "parse_sflow"));
  fetch_next_header0(224);
endrule
rule rl_parse_udp_start if ((w_parse_udp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_udp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_gpe_int_header_load if ((parse_state_ff.first == StateParseGpeIntHeader) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_gpe_int_header_extract if ((parse_state_ff.first == StateParseGpeIntHeader) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_gpe_int_header();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_gpe_int_header"));
  parse_state_ff.deq;
  int_metadata$gpe_int_hdr_len[0] <= vxlan_gpe_int_headerlen;
endrule
rule rl_parse_gpe_int_header_parse_int_header if ((w_parse_gpe_int_header_parse_int_header));
  parse_state_ff.enq(StateParseIntHeader);
  dbprint(3, $format("%s -> %s", "parse_gpe_int_header", "parse_int_header"));
  fetch_next_header0(64);
endrule
(* fire_when_enabled *)
rule rl_parse_int_header_load if ((parse_state_ff.first == StateParseIntHeader) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_int_header_extract if ((parse_state_ff.first == StateParseIntHeader) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let int_header_t = extract_int_header_t(truncate(data));
  compute_next_state_parse_int_header(int_header_t.rsvd1,int_header_t.total_hop_cnt);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_int_header"));
  parse_state_ff.deq;
  int_metadata$instruction_cnt[0] <= int_headerins_cnt;
endrule
rule rl_parse_int_header_start if ((w_parse_int_header_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_int_header", "start"));
  fetch_next_header0(0);
endrule
rule rl_parse_int_header_parse_int_val if ((w_parse_int_header_parse_int_val));
  parse_state_ff.enq(StateParseIntVal);
  dbprint(3, $format("%s -> %s", "parse_int_header", "parse_int_val"));
  fetch_next_header0(32);
endrule
rule rl_parse_int_header_parse_all_int_meta_value_heders if ((w_parse_int_header_parse_all_int_meta_value_heders));
  parse_state_ff.enq(StateParseAllIntMetaValueHeders);
  dbprint(3, $format("%s -> %s", "parse_int_header", "parse_all_int_meta_value_heders"));
  fetch_next_header0(256);
endrule
(* fire_when_enabled *)
rule rl_parse_int_val_load if ((parse_state_ff.first == StateParseIntVal) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_int_val_extract if ((parse_state_ff.first == StateParseIntVal) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  //compute_next_state_parse_int_val(None.bos);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_int_val"));
  parse_state_ff.deq;
endrule
rule rl_parse_int_val_parse_int_val if ((w_parse_int_val_parse_int_val));
  parse_state_ff.enq(StateParseIntVal);
  dbprint(3, $format("%s -> %s", "parse_int_val", "parse_int_val"));
  fetch_next_header0(32);
endrule
rule rl_parse_int_val_parse_inner_ethernet if ((w_parse_int_val_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_int_val", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_all_int_meta_value_heders_load if ((parse_state_ff.first == StateParseAllIntMetaValueHeders) && (rg_buffered[0] < 256));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_all_int_meta_value_heders_extract if ((parse_state_ff.first == StateParseAllIntMetaValueHeders) && (rg_buffered[0] >= 256));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_all_int_meta_value_heders();
  rg_tmp[0] <= zeroExtend(data >> 256);
  succeed_and_next(256);
  dbprint(3, $format("extract %s", "parse_all_int_meta_value_heders"));
  parse_state_ff.deq;
endrule
rule rl_parse_all_int_meta_value_heders_parse_int_val if ((w_parse_all_int_meta_value_heders_parse_int_val));
  parse_state_ff.enq(StateParseIntVal);
  dbprint(3, $format("%s -> %s", "parse_all_int_meta_value_heders", "parse_int_val"));
  fetch_next_header0(32);
endrule
(* fire_when_enabled *)
rule rl_parse_gre_load if ((parse_state_ff.first == StateParseGre) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_gre_extract if ((parse_state_ff.first == StateParseGre) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let gre_t = extract_gre_t(truncate(data));
  compute_next_state_parse_gre(gre_t.C,gre_t.R,gre_t.K,gre_t.S,gre_t.s,gre_t.recurse,gre_t.flags,gre_t.ver,gre_t.proto);
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_gre"));
  parse_state_ff.deq;
endrule
rule rl_parse_gre_parse_nvgre if ((w_parse_gre_parse_nvgre));
  parse_state_ff.enq(StateParseNvgre);
  dbprint(3, $format("%s -> %s", "parse_gre", "parse_nvgre"));
  fetch_next_header0(32);
endrule
rule rl_parse_gre_parse_gre_ipv4 if ((w_parse_gre_parse_gre_ipv4));
  parse_state_ff.enq(StateParseGreIpv4);
  dbprint(3, $format("%s -> %s", "parse_gre", "parse_gre_ipv4"));
  fetch_next_header0(0);
endrule
rule rl_parse_gre_parse_gre_ipv6 if ((w_parse_gre_parse_gre_ipv6));
  parse_state_ff.enq(StateParseGreIpv6);
  dbprint(3, $format("%s -> %s", "parse_gre", "parse_gre_ipv6"));
  fetch_next_header0(0);
endrule
rule rl_parse_gre_parse_erspan_t3 if ((w_parse_gre_parse_erspan_t3));
  parse_state_ff.enq(StateParseErspanT3);
  dbprint(3, $format("%s -> %s", "parse_gre", "parse_erspan_t3"));
  fetch_next_header0(96);
endrule
rule rl_parse_gre_start if ((w_parse_gre_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_gre", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_gre_ipv4_load if ((parse_state_ff.first == StateParseGreIpv4) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_gre_ipv4_extract if ((parse_state_ff.first == StateParseGreIpv4) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_gre_ipv4();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_gre_ipv4"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h2;
endrule
rule rl_parse_gre_ipv4_parse_inner_ipv4 if ((w_parse_gre_ipv4_parse_inner_ipv4));
  parse_state_ff.enq(StateParseInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_gre_ipv4", "parse_inner_ipv4"));
  fetch_next_header0(160);
endrule
(* fire_when_enabled *)
rule rl_parse_gre_ipv6_load if ((parse_state_ff.first == StateParseGreIpv6) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_gre_ipv6_extract if ((parse_state_ff.first == StateParseGreIpv6) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_gre_ipv6();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_gre_ipv6"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h2;
endrule
rule rl_parse_gre_ipv6_parse_inner_ipv6 if ((w_parse_gre_ipv6_parse_inner_ipv6));
  parse_state_ff.enq(StateParseInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_gre_ipv6", "parse_inner_ipv6"));
  fetch_next_header0(320);
endrule
(* fire_when_enabled *)
rule rl_parse_nvgre_load if ((parse_state_ff.first == StateParseNvgre) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_nvgre_extract if ((parse_state_ff.first == StateParseNvgre) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_nvgre();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_nvgre"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h5;
endrule
rule rl_parse_nvgre_parse_inner_ethernet if ((w_parse_nvgre_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_nvgre", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_erspan_t3_load if ((parse_state_ff.first == StateParseErspanT3) && (rg_buffered[0] < 96));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_erspan_t3_extract if ((parse_state_ff.first == StateParseErspanT3) && (rg_buffered[0] >= 96));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_erspan_t3();
  rg_tmp[0] <= zeroExtend(data >> 96);
  succeed_and_next(96);
  dbprint(3, $format("extract %s", "parse_erspan_t3"));
  parse_state_ff.deq;
endrule
rule rl_parse_erspan_t3_parse_inner_ethernet if ((w_parse_erspan_t3_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_erspan_t3", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_arp_rarp_load if ((parse_state_ff.first == StateParseArpRarp) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_arp_rarp_extract if ((parse_state_ff.first == StateParseArpRarp) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let arp_rarp_t = extract_arp_rarp_t(truncate(data));
  compute_next_state_parse_arp_rarp(arp_rarp_t.protoType);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_arp_rarp"));
  parse_state_ff.deq;
endrule
rule rl_parse_arp_rarp_parse_arp_rarp_ipv4 if ((w_parse_arp_rarp_parse_arp_rarp_ipv4));
  parse_state_ff.enq(StateParseArpRarpIpv4);
  dbprint(3, $format("%s -> %s", "parse_arp_rarp", "parse_arp_rarp_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_arp_rarp_start if ((w_parse_arp_rarp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_arp_rarp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_arp_rarp_ipv4_load if ((parse_state_ff.first == StateParseArpRarpIpv4) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_arp_rarp_ipv4_extract if ((parse_state_ff.first == StateParseArpRarpIpv4) && (rg_buffered[0] >= 160));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_arp_rarp_ipv4();
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_arp_rarp_ipv4"));
  parse_state_ff.deq;
endrule
rule rl_parse_arp_rarp_ipv4_parse_set_prio_med if ((w_parse_arp_rarp_ipv4_parse_set_prio_med));
  parse_state_ff.enq(StateParseSetPrioMed);
  dbprint(3, $format("%s -> %s", "parse_arp_rarp_ipv4", "parse_set_prio_med"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_eompls_load if ((parse_state_ff.first == StateParseEompls) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_eompls_extract if ((parse_state_ff.first == StateParseEompls) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_eompls();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_eompls"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h6;
endrule
rule rl_parse_eompls_parse_inner_ethernet if ((w_parse_eompls_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_eompls", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_vxlan_load if ((parse_state_ff.first == StateParseVxlan) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_vxlan_extract if ((parse_state_ff.first == StateParseVxlan) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_vxlan();
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_vxlan"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'h1;
endrule
rule rl_parse_vxlan_parse_inner_ethernet if ((w_parse_vxlan_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_vxlan", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_vxlan_gpe_load if ((parse_state_ff.first == StateParseVxlanGpe) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_vxlan_gpe_extract if ((parse_state_ff.first == StateParseVxlanGpe) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let vxlan_gpe_t = extract_vxlan_gpe_t(truncate(data));
  compute_next_state_parse_vxlan_gpe(vxlan_gpe_t.flags,vxlan_gpe_t.next_proto);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_vxlan_gpe"));
  parse_state_ff.deq;
  tunnel_metadata$ingress_tunnel_type[0] <= 'hc;
endrule
rule rl_parse_vxlan_gpe_parse_gpe_int_header if ((w_parse_vxlan_gpe_parse_gpe_int_header));
  parse_state_ff.enq(StateParseGpeIntHeader);
  dbprint(3, $format("%s -> %s", "parse_vxlan_gpe", "parse_gpe_int_header"));
  fetch_next_header0(32);
endrule
rule rl_parse_vxlan_gpe_parse_inner_ethernet if ((w_parse_vxlan_gpe_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_vxlan_gpe", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
(* fire_when_enabled *)
rule rl_parse_geneve_load if ((parse_state_ff.first == StateParseGeneve) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_geneve_extract if ((parse_state_ff.first == StateParseGeneve) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let genv_t = extract_genv_t(truncate(data));
  compute_next_state_parse_geneve(genv_t.ver,genv_t.optLen,genv_t.protoType);
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_geneve"));
  parse_state_ff.deq;
  tunnel_metadata$tunnel_vni[0] <= genvvni;
endrule
rule rl_parse_geneve_parse_inner_ethernet if ((w_parse_geneve_parse_inner_ethernet));
  parse_state_ff.enq(StateParseInnerEthernet);
  dbprint(3, $format("%s -> %s", "parse_geneve", "parse_inner_ethernet"));
  fetch_next_header0(112);
endrule
rule rl_parse_geneve_parse_inner_ipv4 if ((w_parse_geneve_parse_inner_ipv4));
  parse_state_ff.enq(StateParseInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_geneve", "parse_inner_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_geneve_parse_inner_ipv6 if ((w_parse_geneve_parse_inner_ipv6));
  parse_state_ff.enq(StateParseInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_geneve", "parse_inner_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_geneve_start if ((w_parse_geneve_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_geneve", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ipv4_load if ((parse_state_ff.first == StateParseInnerIpv4) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ipv4_extract if ((parse_state_ff.first == StateParseInnerIpv4) && (rg_buffered[0] >= 160));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ipv4_t = extract_ipv4_t(truncate(data));
  compute_next_state_parse_inner_ipv4(ipv4_t.fragOffset,ipv4_t.ihl,ipv4_t.protocol);
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_inner_ipv4"));
  parse_state_ff.deq;
  ipv4_metadata$lkp_ipv4_sa[0] <= inner_ipv4srcAddr;
endrule
rule rl_parse_inner_ipv4_parse_inner_icmp if ((w_parse_inner_ipv4_parse_inner_icmp));
  parse_state_ff.enq(StateParseInnerIcmp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv4", "parse_inner_icmp"));
  fetch_next_header0(32);
endrule
rule rl_parse_inner_ipv4_parse_inner_tcp if ((w_parse_inner_ipv4_parse_inner_tcp));
  parse_state_ff.enq(StateParseInnerTcp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv4", "parse_inner_tcp"));
  fetch_next_header0(160);
endrule
rule rl_parse_inner_ipv4_parse_inner_udp if ((w_parse_inner_ipv4_parse_inner_udp));
  parse_state_ff.enq(StateParseInnerUdp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv4", "parse_inner_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_inner_ipv4_start if ((w_parse_inner_ipv4_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_ipv4", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_icmp_load if ((parse_state_ff.first == StateParseInnerIcmp) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_icmp_extract if ((parse_state_ff.first == StateParseInnerIcmp) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_inner_icmp();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_inner_icmp"));
  parse_state_ff.deq;
  l3_metadata$lkp_l4_sport[0] <= inner_icmptypeCode;
endrule
rule rl_parse_inner_icmp_start if ((w_parse_inner_icmp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_icmp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_tcp_load if ((parse_state_ff.first == StateParseInnerTcp) && (rg_buffered[0] < 160));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_tcp_extract if ((parse_state_ff.first == StateParseInnerTcp) && (rg_buffered[0] >= 160));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_inner_tcp();
  rg_tmp[0] <= zeroExtend(data >> 160);
  succeed_and_next(160);
  dbprint(3, $format("extract %s", "parse_inner_tcp"));
  parse_state_ff.deq;
  l3_metadata$lkp_l4_sport[0] <= inner_tcpsrcPort;
endrule
rule rl_parse_inner_tcp_start if ((w_parse_inner_tcp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_tcp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_udp_load if ((parse_state_ff.first == StateParseInnerUdp) && (rg_buffered[0] < 64));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_udp_extract if ((parse_state_ff.first == StateParseInnerUdp) && (rg_buffered[0] >= 64));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_inner_udp();
  rg_tmp[0] <= zeroExtend(data >> 64);
  succeed_and_next(64);
  dbprint(3, $format("extract %s", "parse_inner_udp"));
  parse_state_ff.deq;
  l3_metadata$lkp_l4_sport[0] <= inner_udpsrcPort;
endrule
rule rl_parse_inner_udp_start if ((w_parse_inner_udp_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_udp", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ipv6_load if ((parse_state_ff.first == StateParseInnerIpv6) && (rg_buffered[0] < 320));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ipv6_extract if ((parse_state_ff.first == StateParseInnerIpv6) && (rg_buffered[0] >= 320));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ipv6_t = extract_ipv6_t(truncate(data));
  compute_next_state_parse_inner_ipv6(ipv6_t.nextHdr);
  rg_tmp[0] <= zeroExtend(data >> 320);
  succeed_and_next(320);
  dbprint(3, $format("extract %s", "parse_inner_ipv6"));
  parse_state_ff.deq;
  ipv6_metadata$lkp_ipv6_sa[0] <= inner_ipv6srcAddr;
endrule
rule rl_parse_inner_ipv6_parse_inner_icmp if ((w_parse_inner_ipv6_parse_inner_icmp));
  parse_state_ff.enq(StateParseInnerIcmp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv6", "parse_inner_icmp"));
  fetch_next_header0(32);
endrule
rule rl_parse_inner_ipv6_parse_inner_tcp if ((w_parse_inner_ipv6_parse_inner_tcp));
  parse_state_ff.enq(StateParseInnerTcp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv6", "parse_inner_tcp"));
  fetch_next_header0(160);
endrule
rule rl_parse_inner_ipv6_parse_inner_udp if ((w_parse_inner_ipv6_parse_inner_udp));
  parse_state_ff.enq(StateParseInnerUdp);
  dbprint(3, $format("%s -> %s", "parse_inner_ipv6", "parse_inner_udp"));
  fetch_next_header0(64);
endrule
rule rl_parse_inner_ipv6_start if ((w_parse_inner_ipv6_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_ipv6", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ethernet_load if ((parse_state_ff.first == StateParseInnerEthernet) && (rg_buffered[0] < 112));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_inner_ethernet_extract if ((parse_state_ff.first == StateParseInnerEthernet) && (rg_buffered[0] >= 112));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let ethernet_t = extract_ethernet_t(truncate(data));
  compute_next_state_parse_inner_ethernet(ethernet_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 112);
  succeed_and_next(112);
  dbprint(3, $format("extract %s", "parse_inner_ethernet"));
  parse_state_ff.deq;
  l2_metadata$lkp_mac_sa[0] <= inner_ethernetsrcAddr;
endrule
rule rl_parse_inner_ethernet_parse_inner_ipv4 if ((w_parse_inner_ethernet_parse_inner_ipv4));
  parse_state_ff.enq(StateParseInnerIpv4);
  dbprint(3, $format("%s -> %s", "parse_inner_ethernet", "parse_inner_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_inner_ethernet_parse_inner_ipv6 if ((w_parse_inner_ethernet_parse_inner_ipv6));
  parse_state_ff.enq(StateParseInnerIpv6);
  dbprint(3, $format("%s -> %s", "parse_inner_ethernet", "parse_inner_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_inner_ethernet_start if ((w_parse_inner_ethernet_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_inner_ethernet", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_sflow_load if ((parse_state_ff.first == StateParseSflow) && (rg_buffered[0] < 224));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_sflow_extract if ((parse_state_ff.first == StateParseSflow) && (rg_buffered[0] >= 224));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_sflow();
  rg_tmp[0] <= zeroExtend(data >> 224);
  succeed_and_next(224);
  dbprint(3, $format("extract %s", "parse_sflow"));
  parse_state_ff.deq;
endrule
rule rl_parse_sflow_start if ((w_parse_sflow_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_sflow", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_load if ((parse_state_ff.first == StateParseFabricHeader) && (rg_buffered[0] < 40));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_extract if ((parse_state_ff.first == StateParseFabricHeader) && (rg_buffered[0] >= 40));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let fabric_header_t = extract_fabric_header_t(truncate(data));
  compute_next_state_parse_fabric_header(fabric_header_t.packetType);
  rg_tmp[0] <= zeroExtend(data >> 40);
  succeed_and_next(40);
  dbprint(3, $format("extract %s", "parse_fabric_header"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_header_parse_fabric_header_unicast if ((w_parse_fabric_header_parse_fabric_header_unicast));
  parse_state_ff.enq(StateParseFabricHeaderUnicast);
  dbprint(3, $format("%s -> %s", "parse_fabric_header", "parse_fabric_header_unicast"));
  fetch_next_header0(24);
endrule
rule rl_parse_fabric_header_parse_fabric_header_multicast if ((w_parse_fabric_header_parse_fabric_header_multicast));
  parse_state_ff.enq(StateParseFabricHeaderMulticast);
  dbprint(3, $format("%s -> %s", "parse_fabric_header", "parse_fabric_header_multicast"));
  fetch_next_header0(56);
endrule
rule rl_parse_fabric_header_parse_fabric_header_mirror if ((w_parse_fabric_header_parse_fabric_header_mirror));
  parse_state_ff.enq(StateParseFabricHeaderMirror);
  dbprint(3, $format("%s -> %s", "parse_fabric_header", "parse_fabric_header_mirror"));
  fetch_next_header0(32);
endrule
rule rl_parse_fabric_header_parse_fabric_header_cpu if ((w_parse_fabric_header_parse_fabric_header_cpu));
  parse_state_ff.enq(StateParseFabricHeaderCpu);
  dbprint(3, $format("%s -> %s", "parse_fabric_header", "parse_fabric_header_cpu"));
  fetch_next_header0(72);
endrule
rule rl_parse_fabric_header_start if ((w_parse_fabric_header_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_fabric_header", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_unicast_load if ((parse_state_ff.first == StateParseFabricHeaderUnicast) && (rg_buffered[0] < 24));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_unicast_extract if ((parse_state_ff.first == StateParseFabricHeaderUnicast) && (rg_buffered[0] >= 24));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_fabric_header_unicast();
  rg_tmp[0] <= zeroExtend(data >> 24);
  succeed_and_next(24);
  dbprint(3, $format("extract %s", "parse_fabric_header_unicast"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_header_unicast_parse_fabric_payload_header if ((w_parse_fabric_header_unicast_parse_fabric_payload_header));
  parse_state_ff.enq(StateParseFabricPayloadHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_header_unicast", "parse_fabric_payload_header"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_multicast_load if ((parse_state_ff.first == StateParseFabricHeaderMulticast) && (rg_buffered[0] < 56));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_multicast_extract if ((parse_state_ff.first == StateParseFabricHeaderMulticast) && (rg_buffered[0] >= 56));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_fabric_header_multicast();
  rg_tmp[0] <= zeroExtend(data >> 56);
  succeed_and_next(56);
  dbprint(3, $format("extract %s", "parse_fabric_header_multicast"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_header_multicast_parse_fabric_payload_header if ((w_parse_fabric_header_multicast_parse_fabric_payload_header));
  parse_state_ff.enq(StateParseFabricPayloadHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_header_multicast", "parse_fabric_payload_header"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_mirror_load if ((parse_state_ff.first == StateParseFabricHeaderMirror) && (rg_buffered[0] < 32));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_mirror_extract if ((parse_state_ff.first == StateParseFabricHeaderMirror) && (rg_buffered[0] >= 32));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_fabric_header_mirror();
  rg_tmp[0] <= zeroExtend(data >> 32);
  succeed_and_next(32);
  dbprint(3, $format("extract %s", "parse_fabric_header_mirror"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_header_mirror_parse_fabric_payload_header if ((w_parse_fabric_header_mirror_parse_fabric_payload_header));
  parse_state_ff.enq(StateParseFabricPayloadHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_header_mirror", "parse_fabric_payload_header"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_cpu_load if ((parse_state_ff.first == StateParseFabricHeaderCpu) && (rg_buffered[0] < 72));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_header_cpu_extract if ((parse_state_ff.first == StateParseFabricHeaderCpu) && (rg_buffered[0] >= 72));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let fabric_header_cpu_t = extract_fabric_header_cpu_t(truncate(data));
  compute_next_state_parse_fabric_header_cpu(fabric_header_cpu_t.reasonCode);
  rg_tmp[0] <= zeroExtend(data >> 72);
  succeed_and_next(72);
  dbprint(3, $format("extract %s", "parse_fabric_header_cpu"));
  parse_state_ff.deq;
  ingress_metadata$bypass_lookups[0] <= fabric_header_cpureasonCode;
endrule
rule rl_parse_fabric_header_cpu_parse_fabric_sflow_header if ((w_parse_fabric_header_cpu_parse_fabric_sflow_header));
  parse_state_ff.enq(StateParseFabricSflowHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_header_cpu", "parse_fabric_sflow_header"));
  fetch_next_header0(16);
endrule
rule rl_parse_fabric_header_cpu_parse_fabric_payload_header if ((w_parse_fabric_header_cpu_parse_fabric_payload_header));
  parse_state_ff.enq(StateParseFabricPayloadHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_header_cpu", "parse_fabric_payload_header"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_sflow_header_load if ((parse_state_ff.first == StateParseFabricSflowHeader) && (rg_buffered[0] < 16));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_sflow_header_extract if ((parse_state_ff.first == StateParseFabricSflowHeader) && (rg_buffered[0] >= 16));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_fabric_sflow_header();
  rg_tmp[0] <= zeroExtend(data >> 16);
  succeed_and_next(16);
  dbprint(3, $format("extract %s", "parse_fabric_sflow_header"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_sflow_header_parse_fabric_payload_header if ((w_parse_fabric_sflow_header_parse_fabric_payload_header));
  parse_state_ff.enq(StateParseFabricPayloadHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_sflow_header", "parse_fabric_payload_header"));
  fetch_next_header0(16);
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_payload_header_load if ((parse_state_ff.first == StateParseFabricPayloadHeader) && (rg_buffered[0] < 16));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_fabric_payload_header_extract if ((parse_state_ff.first == StateParseFabricPayloadHeader) && (rg_buffered[0] >= 16));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  let fabric_payload_header_t = extract_fabric_payload_header_t(truncate(data));
  compute_next_state_parse_fabric_payload_header(fabric_payload_header_t.etherType);
  rg_tmp[0] <= zeroExtend(data >> 16);
  succeed_and_next(16);
  dbprint(3, $format("extract %s", "parse_fabric_payload_header"));
  parse_state_ff.deq;
endrule
rule rl_parse_fabric_payload_header_parse_llc_header if ((w_parse_fabric_payload_header_parse_llc_header));
  parse_state_ff.enq(StateParseLlcHeader);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_llc_header"));
  fetch_next_header0(24);
endrule
rule rl_parse_fabric_payload_header_parse_vlan if ((w_parse_fabric_payload_header_parse_vlan));
  parse_state_ff.enq(StateParseVlan);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_vlan"));
  fetch_next_header0(32);
endrule
rule rl_parse_fabric_payload_header_parse_qinq if ((w_parse_fabric_payload_header_parse_qinq));
  parse_state_ff.enq(StateParseQinq);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_qinq"));
  fetch_next_header0(32);
endrule
rule rl_parse_fabric_payload_header_parse_mpls if ((w_parse_fabric_payload_header_parse_mpls));
  parse_state_ff.enq(StateParseMpls);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_mpls"));
  fetch_next_header0(32);
endrule
rule rl_parse_fabric_payload_header_parse_ipv4 if ((w_parse_fabric_payload_header_parse_ipv4));
  parse_state_ff.enq(StateParseIpv4);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_ipv4"));
  fetch_next_header0(160);
endrule
rule rl_parse_fabric_payload_header_parse_ipv6 if ((w_parse_fabric_payload_header_parse_ipv6));
  parse_state_ff.enq(StateParseIpv6);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_ipv6"));
  fetch_next_header0(320);
endrule
rule rl_parse_fabric_payload_header_parse_arp_rarp if ((w_parse_fabric_payload_header_parse_arp_rarp));
  parse_state_ff.enq(StateParseArpRarp);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_arp_rarp"));
  fetch_next_header0(64);
endrule
rule rl_parse_fabric_payload_header_parse_set_prio_high if ((w_parse_fabric_payload_header_parse_set_prio_high));
  parse_state_ff.enq(StateParseSetPrioHigh);
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "parse_set_prio_high"));
  fetch_next_header0(0);
endrule
rule rl_parse_fabric_payload_header_start if ((w_parse_fabric_payload_header_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_fabric_payload_header", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_set_prio_med_load if ((parse_state_ff.first == StateParseSetPrioMed) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_set_prio_med_extract if ((parse_state_ff.first == StateParseSetPrioMed) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_set_prio_med();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_set_prio_med"));
  parse_state_ff.deq;
  intrinsic_metadata$priority[0] <= 'h3;
endrule
rule rl_parse_set_prio_med_start if ((w_parse_set_prio_med_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_set_prio_med", "start"));
  fetch_next_header0(0);
endrule
(* fire_when_enabled *)
rule rl_parse_set_prio_high_load if ((parse_state_ff.first == StateParseSetPrioHigh) && (rg_buffered[0] < 0));
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
    rg_tmp[0] <= zeroExtend(data);
    move_shift_amt(128);
  end
endrule
(* fire_when_enabled *)
rule rl_parse_set_prio_high_extract if ((parse_state_ff.first == StateParseSetPrioHigh) && (rg_buffered[0] >= 0));
  let data = rg_tmp[0];
  if (isValid(data_ff.first)) begin
    data_ff.deq;
    data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];
  end
  report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);
  compute_next_state_parse_set_prio_high();
  rg_tmp[0] <= zeroExtend(data >> 0);
  succeed_and_next(0);
  dbprint(3, $format("extract %s", "parse_set_prio_high"));
  parse_state_ff.deq;
  intrinsic_metadata$priority[0] <= 'h5;
endrule
rule rl_parse_set_prio_high_start if ((w_parse_set_prio_high_start));
  parse_done[0] <= True;
  w_parse_done.send();
  dbprint(3, $format("%s -> %s", "parse_set_prio_high", "start"));
  fetch_next_header0(0);
endrule
`endif // PARSER_RULES

`ifdef PARSER_STATE
PulseWire w_parse_fabric_payload_header_parse_llc_header <- mkPulseWireOR();
PulseWire w_parse_set_prio_med_start <- mkPulseWireOR();
PulseWire w_parse_all_int_meta_value_heders_parse_int_val <- mkPulseWireOR();
PulseWire w_parse_geneve_start <- mkPulseWireOR();
PulseWire w_parse_mpls_inner_ipv4_parse_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_vlan_start <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_parse_arp_rarp <- mkPulseWireOR();
PulseWire w_parse_llc_header_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_icmp_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_inner_ethernet_parse_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_ipv4_in_ip <- mkPulseWireOR();
PulseWire w_parse_inner_ethernet_parse_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_inner_ipv4_parse_inner_udp <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_ipv6_in_ip <- mkPulseWireOR();
PulseWire w_parse_arp_rarp_parse_arp_rarp_ipv4 <- mkPulseWireOR();
PulseWire w_parse_vlan_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
PulseWire w_parse_vlan_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_start <- mkPulseWireOR();
PulseWire w_parse_set_prio_high_start <- mkPulseWireOR();
PulseWire w_parse_int_header_parse_all_int_meta_value_heders <- mkPulseWireOR();
PulseWire w_parse_ipv6_start <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_icmp <- mkPulseWireOR();
PulseWire w_parse_erspan_t3_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_fabric_header_multicast_parse_fabric_payload_header <- mkPulseWireOR();
PulseWire w_parse_vxlan_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_gre_start <- mkPulseWireOR();
PulseWire w_parse_eompls_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_vlan <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_qinq <- mkPulseWireOR();
PulseWire w_parse_int_header_start <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_ipv6_in_ip <- mkPulseWireOR();
PulseWire w_parse_fabric_header_parse_fabric_header_multicast <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_mpls_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_vlan <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_udp <- mkPulseWireOR();
PulseWire w_parse_gre_ipv6_parse_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_gpe_int_header_parse_int_header <- mkPulseWireOR();
PulseWire w_parse_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_inner_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_fabric_header_cpu_parse_fabric_payload_header <- mkPulseWireOR();
PulseWire w_parse_udp_parse_vxlan_gpe <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_vlan_parse_arp_rarp <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_mpls_bos_parse_mpls_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_mpls_bos_parse_mpls_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_inner_ipv6_start <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_int_header_parse_int_val <- mkPulseWireOR();
PulseWire w_parse_arp_rarp_ipv4_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_fabric_header <- mkPulseWireOR();
PulseWire w_parse_inner_ipv6_parse_inner_udp <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_parse_set_prio_high <- mkPulseWireOR();
PulseWire w_parse_qinq_start <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_vlan <- mkPulseWireOR();
PulseWire w_parse_fabric_header_parse_fabric_header_mirror <- mkPulseWireOR();
PulseWire w_parse_fabric_header_unicast_parse_fabric_payload_header <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_ipv4_in_ip <- mkPulseWireOR();
PulseWire w_parse_fabric_header_start <- mkPulseWireOR();
PulseWire w_parse_fabric_header_mirror_parse_fabric_payload_header <- mkPulseWireOR();
PulseWire w_parse_gre_ipv4_parse_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_udp_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_gre_parse_erspan_t3 <- mkPulseWireOR();
PulseWire w_parse_udp_start <- mkPulseWireOR();
PulseWire w_parse_gre_parse_gre_ipv4 <- mkPulseWireOR();
PulseWire w_parse_gre_parse_gre_ipv6 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_set_prio_high <- mkPulseWireOR();
PulseWire w_parse_vxlan_gpe_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_inner_udp_start <- mkPulseWireOR();
PulseWire w_parse_fabric_sflow_header_parse_fabric_payload_header <- mkPulseWireOR();
PulseWire w_parse_inner_tcp_start <- mkPulseWireOR();
PulseWire w_start_parse_ethernet <- mkPulseWireOR();
PulseWire w_parse_vlan_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_llc_header_start <- mkPulseWireOR();
PulseWire w_parse_sflow_start <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_arp_rarp <- mkPulseWireOR();
PulseWire w_parse_mpls_bos_parse_eompls <- mkPulseWireOR();
PulseWire w_parse_arp_rarp_start <- mkPulseWireOR();
PulseWire w_parse_int_val_parse_int_val <- mkPulseWireOR();
PulseWire w_parse_inner_ipv4_parse_inner_tcp <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_gre <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_tcp_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_inner_ipv4_parse_inner_icmp <- mkPulseWireOR();
PulseWire w_parse_qinq_parse_qinq_vlan <- mkPulseWireOR();
PulseWire w_parse_udp_parse_geneve <- mkPulseWireOR();
PulseWire w_parse_inner_ipv6_parse_inner_tcp <- mkPulseWireOR();
PulseWire w_parse_geneve_parse_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_geneve_parse_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_geneve_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_nvgre_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_ethernet_start <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_start <- mkPulseWireOR();
PulseWire w_parse_fabric_header_parse_fabric_header_cpu <- mkPulseWireOR();
PulseWire w_parse_fabric_header_parse_fabric_header_unicast <- mkPulseWireOR();
PulseWire w_parse_udp_parse_vxlan <- mkPulseWireOR();
PulseWire w_parse_tcp_start <- mkPulseWireOR();
PulseWire w_parse_int_val_parse_inner_ethernet <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_arp_rarp <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_arp_rarp <- mkPulseWireOR();
PulseWire w_parse_mpls_start <- mkPulseWireOR();
PulseWire w_parse_llc_header_parse_snap_header <- mkPulseWireOR();
PulseWire w_parse_udp_parse_sflow <- mkPulseWireOR();
PulseWire w_parse_vxlan_gpe_parse_gpe_int_header <- mkPulseWireOR();
PulseWire w_parse_vlan_parse_set_prio_high <- mkPulseWireOR();
PulseWire w_parse_ipv6_in_ip_parse_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_qinq <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
PulseWire w_parse_inner_ipv6_parse_inner_icmp <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_tcp <- mkPulseWireOR();
PulseWire w_parse_ipv6_parse_set_prio_med <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_qinq <- mkPulseWireOR();
PulseWire w_parse_mpls_inner_ipv6_parse_inner_ipv6 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_ipv6 <- mkPulseWireOR();
PulseWire w_parse_snap_header_parse_set_prio_high <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_gre <- mkPulseWireOR();
PulseWire w_parse_ethernet_parse_llc_header <- mkPulseWireOR();
PulseWire w_parse_ipv4_parse_icmp <- mkPulseWireOR();
PulseWire w_parse_qinq_vlan_parse_mpls <- mkPulseWireOR();
PulseWire w_parse_ipv4_in_ip_parse_inner_ipv4 <- mkPulseWireOR();
PulseWire w_parse_mpls_parse_mpls_bos <- mkPulseWireOR();
PulseWire w_parse_gre_parse_nvgre <- mkPulseWireOR();
PulseWire w_parse_icmp_start <- mkPulseWireOR();
PulseWire w_parse_inner_ipv4_start <- mkPulseWireOR();
PulseWire w_parse_snap_header_start <- mkPulseWireOR();
PulseWire w_parse_fabric_payload_header_parse_set_prio_high <- mkPulseWireOR();
PulseWire w_parse_inner_icmp_start <- mkPulseWireOR();
PulseWire w_parse_fabric_header_cpu_parse_fabric_sflow_header <- mkPulseWireOR();
`endif
