
typedef enum {
  StateParseStart,
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
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  Wire#(Bit#(240)) w_parse_tcp_options_data <- mkDWire(0);
  PulseWire w_parse_tcp_options_parse_mss <- mkPulseWireOR();
  PulseWire w_parse_wscale_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_wscale <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_sack <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_start <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_nop <- mkPulseWireOR();
  PulseWire w_parse_sack_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_parse_start <- mkPulseWireOR();
  PulseWire w_parse_nop_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_start <- mkPulseWireOR();
  PulseWire w_parse_ts_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_ts <- mkPulseWireOR();
  PulseWire w_parse_mss_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_start <- mkPulseWireOR();
  PulseWire w_parse_end_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_parse_tcp_options <- mkPulseWireOR();
  PulseWire w_parse_tcp_options_parse_end <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_tcp <- mkPulseWireOR();
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(ParserState) rg_parse_state <- mkReg(StateParseStart);
  Wire#(ParserState) parse_state_w <- mkDWire(StateParseStart);
  Reg#(Bit#(32)) rg_offset <- mkReg(0);
  PulseWire parse_done <- mkPulseWire();
  Reg#(Bit#(128)) rg_tmp_parse_ethernet <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
  Reg#(Bit#(240)) rg_tmp_parse_tcp <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_tcp_options <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_end <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_nop <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_mss <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_wscale <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_sack <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_ts <- mkReg(0);
  Reg#(Bit#(2)) rg_tmp_stats_metadata$flow_map_index <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_stats_metadata$dummy <- mkReg(0);
  Reg#(Bit#(8)) rg_tmp_options_wscale$wscale <- mkReg(0);
  Reg#(Bit#(16)) rg_tmp_options_mss$mss <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_ipv4$dstAddr <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_tcp$seqNo <- mkReg(0);
  Reg#(Bit#(48)) rg_tmp_intrinsic_metadata$ingress_global_timestamp <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_stats_metadata$senderIP <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_ipv4$srcAddr <- mkReg(0);
  Reg#(Bit#(16)) rg_tmp_tcp$window <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_tcp$ackNo <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_stats_metadata$dummy2 <- mkReg(0);
  Reg#(Bit#(32)) rg_tmp_routing_metadata$nhop_ipv4 <- mkReg(0);
  Reg#(Bit#(9)) rg_tmp_standard_metadata$egress_port <- mkReg(0);
  function Action succeed_and_next(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= offset;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      data_in_ff.deq;
      rg_offset <= 0;
    endaction
  endfunction
  function Action push_phv(ParserState ty);
    action
      MetadataT meta = defaultValue;
      meta.stats_metadata$flow_map_index = tagged Valid rg_tmp_stats_metadata$flow_map_index;
      meta.stats_metadata$dummy = tagged Valid rg_tmp_stats_metadata$dummy;
      meta.options_wscale$wscale = tagged Valid rg_tmp_options_wscale$wscale;
      meta.options_mss$mss = tagged Valid rg_tmp_options_mss$mss;
      meta.ipv4$dstAddr = tagged Valid rg_tmp_ipv4$dstAddr;
      meta.tcp$seqNo = tagged Valid rg_tmp_tcp$seqNo;
      meta.intrinsic_metadata$ingress_global_timestamp = tagged Valid rg_tmp_intrinsic_metadata$ingress_global_timestamp;
      meta.stats_metadata$senderIP = tagged Valid rg_tmp_stats_metadata$senderIP;
      meta.ipv4$srcAddr = tagged Valid rg_tmp_ipv4$srcAddr;
      meta.tcp$window = tagged Valid rg_tmp_tcp$window;
      meta.tcp$ackNo = tagged Valid rg_tmp_tcp$ackNo;
      meta.stats_metadata$dummy2 = tagged Valid rg_tmp_stats_metadata$dummy2;
      meta.routing_metadata$nhop_ipv4 = tagged Valid rg_tmp_routing_metadata$nhop_ipv4;
      meta.standard_metadata$egress_port = tagged Valid rg_tmp_standard_metadata$egress_port;
      meta_in_ff.enq(meta);
    endaction
  endfunction
  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%d) Parser State %h offset %h, %h", $time, state, offset, data);
      end
    endaction
  endfunction
  function Action compute_next_state_parse_ethernet(Bit#(16) etherType);
    action
      let v = {etherType};
      case (v) matches
        'h0800: begin
          w_parse_ethernet_parse_ipv4.send();
        end
        default: begin
          w_parse_ethernet_parse_start.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_ipv4(Bit#(8) protocol);
    action
      let v = {protocol};
      case (v) matches
        'h06: begin
          w_parse_ipv4_parse_tcp.send();
        end
        default: begin
          w_parse_ipv4_parse_start.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_tcp(Bit#(1) syn);
    action
      let v = {syn};
      case (v) matches
        'h01: begin
          w_parse_tcp_parse_tcp_options.send();
        end
        default: begin
          w_parse_tcp_parse_start.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_tcp_options(Bit#(8) parse_tcp_options_counter, Bit#(8) current);
    action
      let v = {parse_tcp_options_counter, current};
      case (v) matches
        'h0000: begin
          w_parse_tcp_options_parse_end.send();
        end
        'h0001: begin
          w_parse_tcp_options_parse_nop.send();
        end
        'h0002: begin
          w_parse_tcp_options_parse_mss.send();
        end
        'h0003: begin
          w_parse_tcp_options_parse_wscale.send();
        end
        'h0004: begin
          w_parse_tcp_options_parse_sack.send();
        end
        'h0008: begin
          w_parse_tcp_options_parse_ts.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_end();
    action
      w_parse_end_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_nop();
    action
      w_parse_nop_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_mss();
    action
      w_parse_mss_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_wscale();
    action
      w_parse_wscale_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_sack();
    action
      w_parse_sack_parse_tcp_options.send();
    endaction
  endfunction
  function Action compute_next_state_parse_ts();
    action
      w_parse_ts_parse_tcp_options.send();
    endaction
  endfunction
  rule rl_start_state if (rg_parse_state == StateParseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state <= StateParseEthernet;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  let data_this_cycle = data_in_ff.first.data;
  rule rl_parse_parse_ethernet_0 if ((rg_parse_state == StateParseEthernet) && (rg_offset == 0));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(0, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ethernet));
    Bit#(0) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(128) data = {data_this_cycle, data_last_cycle};
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let ethernet_t = extract_ethernet_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ethernet(ethernet_t.etherType);
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    rg_tmp_parse_ipv4 <= zeroExtend(pack(unparsed));
    succeed_and_next(16);
  endrule

  rule rl_parse_parse_ipv4_0 if ((rg_parse_state == StateParseIpv4) && (rg_offset == 16));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_ipv4 <= zeroExtend(data);
    succeed_and_next(144);
  endrule

  rule rl_parse_parse_ipv4_1 if ((rg_parse_state == StateParseIpv4) && (rg_offset == 144));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let ipv4_t = extract_ipv4_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    rg_tmp_parse_tcp <= zeroExtend(pack(unparsed));
    succeed_and_next(112);
  endrule

  // accumulate all option data
  rule rl_parse_parse_tcp_0 if ((rg_parse_state == StateParseTcp) && (rg_offset == 112));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(112, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_tcp));
    Bit#(112) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(240) data = {data_this_cycle, data_last_cycle};
    Vector#(240, Bit#(1)) dataVec = unpack(data);
    let tcp_t = extract_tcp_t(pack(takeAt(0, dataVec)));
    let tcp$dataOffset = tcp_t.dataOffset;
    let v = ( ( tcp$dataOffset * 'h4 ) - 'h14 );
    my_metadata$parse_tcp_options_counter <= v;
    compute_next_state_parse_tcp(v);
    Vector#(80, Bit#(1)) unparsed = takeAt(160, dataVec);
    w_parse_tcp_options_data <= data; // pack(unparsed)
  endrule

  rule rl_parse_tcp_options if ((rg_parse_state == StateParseTcp) && (rg_offset == 112) && (w_parse_tcp_parse_tcp_options));
    Vector#(240, Bit#(1)) dataVec = unpack(w_parse_tcp_options_data);
    let lookahead = extract_lookahead_t(pack(takeAt(160, dataVec)));
    compute_next_state_parse_tcp_options(my_metadata_t.parse_tcp_options_counter, pack(lookahead));
  endrule

  rule rl_parse_nop if ((rg_parse_state == StateParseTcp) && (w_parse_tcp_options_parse_nop));
    Vector#(240, Bit#(1)) dataVec = unpack(w_parse_tcp_options_data);
    let options_nop_t = extract_options_nop_t(pack(takeAt(160, dataVec)));
    compute_next_state_parse_nop();
  endrule

  rule rl_parse_ts if ((rg_parse_state == StateParseTcp) && (w_parse_tcp_options_parse_ts));
    Vector#(240, Bit#(1)) dataVec = unpack(w_parse_ts_data);
    let options_ts_t = extract_options_ts_t(pack(takeAt(160, dataVec)));
    compute_next_state_parse_ts();
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule


