// ====== PARSER ======
import GetPut::*;
import Ethernet::*;
import FIFOF::*;
import Vector::*;
import DbgDefs::*;
import DefaultValue::*;
import main::*;

typedef enum {
  StateDefault,
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
  // buffer for two cycle worthy of data, maybe we can optimize this.
  Reg#(Bit#(256)) rg_parse_tcp_options_data[2] <- mkCReg(2, 0);
  PulseWire w_parse_tcp_options_parse_default <- mkPulseWireOR();
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
  Reg#(Bool) rg_parse_tcp_parse_tcp_options <- mkReg(False);
  Reg#(int) cr_verbosity[2] <- mkCRegU(2);
  FIFOF#(int) cr_verbosity_ff <- mkFIFOF;
  rule set_verbosity;
    let x = cr_verbosity_ff.first;
    cr_verbosity_ff.deq;
    cr_verbosity[1] <= x;
  endrule

  Wire#(Bit#(32)) w_curr_unparsed_bits <- mkDWire(0);
  Reg#(Bit#(32)) w_next_header_len[2] <- mkCReg(2, 0);
  Wire#(Bit#(8)) w_parse_tcp_options <- mkDWire(0);
  FIFOF#(EtherData) data_in_ff <- mkFIFOF;
  FIFOF#(MetadataT) meta_in_ff <- mkFIFOF;
  Reg#(ParserState) rg_parse_state[3] <- mkCReg(3, StateDefault);
  Wire#(ParserState) parse_state_w <- mkDWire(StateDefault);
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
  Reg#(Bit#(48)) rg_tmp_ethernet$dstAddr <- mkReg(0);
  Reg#(Bit#(8)) my_metadata$parse_tcp_options_counter[2] <- mkCReg(2, 0);
  function Action succeed_and_next(Bit#(32) offset);
    action
      $display("(%0d) unparsed_bit %h", $time, offset);
      w_curr_unparsed_bits <= offset;
      rg_offset <= offset;
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      w_next_header_len[0] <= len;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      w_curr_unparsed_bits <= offset;
      rg_offset <= 0;
    endaction
  endfunction
  function Action push_phv(ParserState ty);
    action
      MetadataT meta = defaultValue;
      meta.ethernet$dstAddr = tagged Valid rg_tmp_ethernet$dstAddr;
      meta_in_ff.enq(meta);
    endaction
  endfunction
  function Action report_parse_action(ParserState state, Bit#(32) offset, Bit#(128) data);
    action
      if (cr_verbosity[0] > 0) begin
        $display("(%0d) Parser State %h offset %h, %h", $time, state, offset, data);
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
      $display("sync %h", syn);
      case (v) matches
        'h01: begin
          $display("parse options %h", syn);
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
      case (parse_tcp_options_counter) matches
        'h00: begin
          $display("(%0d) to start state", $time);
          w_parse_tcp_options_parse_default.send();
        end
        default: begin
          $display("(%0d) tcp option look ahead %h", $time, current);
          case (current) matches
            'h00: begin
              w_parse_tcp_options_parse_end.send();
            end
            'h01: begin
              w_parse_tcp_options_parse_nop.send();
            end
            'h02: begin
              w_parse_tcp_options_parse_mss.send();
            end
            'h03: begin
              w_parse_tcp_options_parse_wscale.send();
            end
            'h04: begin
              w_parse_tcp_options_parse_sack.send();
            end
            'h08: begin
              w_parse_tcp_options_parse_ts.send();
            end
          endcase
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

  rule rl_start_state if (rg_parse_state[0] == StateDefault);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state[0] <= StateParseEthernet;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  let data_this_cycle = data_in_ff.first.data;

  rule rl_deq_data_in_ff (w_curr_unparsed_bits < w_next_header_len[1]);
    $display("(%0d) first %h", $time, data_this_cycle);
    data_in_ff.deq;
  endrule

  rule rl_parse_parse_ethernet_0 if ((rg_parse_state[0] == StateParseEthernet) && (rg_offset == 0));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(0, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ethernet));
    Bit#(0) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(128) data = {data_this_cycle, data_last_cycle};
    Vector#(128, Bit#(1)) dataVec = unpack(data);
    let ethernet_t = extract_ethernet_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ethernet(ethernet_t.etherType);
    Vector#(16, Bit#(1)) unparsed = takeAt(112, dataVec);
    rg_tmp_parse_ipv4 <= zeroExtend(pack(unparsed));
    $display("(%0d) ethernet", $time);
    succeed_and_next(16);
  endrule

  (* mutually_exclusive = "rl_parse_ethernet_parse_ipv4,rl_parse_ethernet_parse_start" *)
  rule rl_parse_ethernet_parse_ipv4 if ((rg_parse_state[0] == StateParseEthernet) && (w_parse_ethernet_parse_ipv4));
    rg_parse_state[0] <= StateParseIpv4;
    fetch_next_header(160);
  endrule

  rule rl_parse_ethernet_parse_start if ((rg_parse_state[0] == StateParseEthernet) && (w_parse_ethernet_parse_start));
    rg_parse_state[0] <= StateDefault;
    fetch_next_header(0);
  endrule

  rule rl_parse_parse_ipv4_0 if ((rg_parse_state[0] == StateParseIpv4) && (rg_offset == 16));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_ipv4 <= zeroExtend(data);
    $display("(%0d) ipv4", $time);
    succeed_and_next(144);
  endrule

  rule rl_parse_parse_ipv4_1 if ((rg_parse_state[0] == StateParseIpv4) && (rg_offset == 144));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let ipv4_t = extract_ipv4_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    rg_tmp_parse_tcp <= zeroExtend(pack(unparsed));
    $display("(%0d) ipv4_1", $time);
    succeed_and_next(112);
  endrule

  (* mutually_exclusive = "rl_parse_ipv4_parse_start" *)
  rule rl_parse_ipv4_parse_start if ((rg_parse_state[0] == StateParseIpv4) && (w_parse_ipv4_parse_start));
    rg_parse_state[0] <= StateDefault;
    fetch_next_header(0);
  endrule

  rule rl_parse_ipv4_parse_tcp if ((rg_parse_state[0] == StateParseIpv4) && (w_parse_ipv4_parse_tcp));
    rg_parse_state[0] <= StateParseTcp;
    fetch_next_header(160);
  endrule

  rule rl_parse_parse_tcp_0 if ((rg_parse_state[0] == StateParseTcp) && (rg_offset == 112));
    report_parse_action(rg_parse_state[0], rg_offset, data_this_cycle);
    Vector#(112, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_tcp));
    Bit#(112) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(240) data = {data_this_cycle, data_last_cycle};
    Vector#(240, Bit#(1)) dataVec = unpack(data);
    let tcp_t = extract_tcp_t(pack(takeAt(0, dataVec)));
    Bit#(8) tcp$dataOffset = zeroExtend(tcp_t.dataOffset);
    let v = ( ( tcp$dataOffset * 'h4 ) - 20 );
    my_metadata$parse_tcp_options_counter[0] <= zeroExtend(v);
    compute_next_state_parse_tcp(tcp_t.syn);
    Vector#(80, Bit#(1)) unparsed = takeAt(160, dataVec);
    $display("(%0d) unparsed %h", $time, pack(unparsed));
    rg_parse_tcp_options_data[0] <= zeroExtend(pack(unparsed));
    Vector#(8, Bit#(1)) lookahead = takeAt(160, dataVec);
    w_parse_tcp_options <= pack(lookahead);
  endrule

  // do we wait a few cycles to accumulate all option data ??
  (* mutually_exclusive = "rl_parse_tcp_parse_tcp_options, rl_start_state" *)
  rule rl_parse_tcp_parse_tcp_options if (w_parse_tcp_parse_tcp_options);
    $display("(%0d) data %h %h", $time, w_parse_tcp_options, data_this_cycle);
    compute_next_state_parse_tcp_options(my_metadata$parse_tcp_options_counter[1], w_parse_tcp_options);
    rg_parse_state[0] <= StateParseTcpOptions;
    $display("(%0d) parse tcp options %h %h", $time, my_metadata$parse_tcp_options_counter[1], w_parse_tcp_options);
  endrule

  (* mutually_exclusive = "rl_parse_tcp_parse_ts, rl_parse_tcp_parse_nop, rl_parse_tcp_parse_end, rl_parse_tcp_parse_default, rl_parse_tcp_parse_mss, rl_parse_tcp_parse_sack" *)
  rule rl_parse_tcp_parse_ts if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_ts));
    rg_parse_state[1] <= StateParseTs;
  endrule

  rule rl_parse_tcp_parse_nop if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_nop));
    rg_parse_state[1] <= StateParseNop;
  endrule

  rule rl_parse_tcp_parse_end if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_end));
    rg_parse_state[1] <= StateParseEnd;
  endrule

  rule rl_parse_tcp_parse_mss if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_mss));
    rg_parse_state[1] <= StateParseMss;
  endrule

  rule rl_parse_tcp_parse_sack if ((rg_parse_state[1] == StateParseTcpOptions) && (w_parse_tcp_options_parse_sack));
    rg_parse_state[1] <= StateParseSack;
  endrule

  rule rl_parse_tcp_parse_default if ((rg_parse_state[1] == StateParseTcpOptions) && w_parse_tcp_options_parse_default);
    $display("back to start");
    rg_parse_state[1] <= StateDefault;
  endrule

  // extract and control flow
  rule rl_parse_ts if (rg_parse_state[0] == StateParseTs);
    Vector#(256, Bit#(1)) dataVec = unpack(rg_parse_tcp_options_data[1]);
    let options_ts_t = extract_options_ts_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_ts();
    $display("(%0d) ts data %h", $time, rg_parse_tcp_options_data[1]);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 10;
    succeed_and_next(8);
    fetch_next_header(8);
    Vector#(176, Bit#(1)) _tmp = takeAt(80, dataVec);
    Bit#(8) lookahead = data_this_cycle[7:0];
    rg_parse_tcp_options_data[1] <= zeroExtend(data_this_cycle);
    w_parse_tcp_options <= pack(lookahead);
    $display("(%0d) PARSE TS", $time);
  endrule

  rule rl_return_parse_ts if (w_parse_ts_parse_tcp_options);
    w_parse_tcp_parse_tcp_options.send();
  endrule

  rule rl_parse_nop if (rg_parse_state[0] == StateParseNop);
    Vector#(256, Bit#(1)) dataVec = unpack(rg_parse_tcp_options_data[1]);
    let options_nop_t = extract_options_nop_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_nop();
    succeed_and_next(48);
    $display("(%0d) nop data %h", $time, rg_parse_tcp_options_data[1]);
    Vector#(8, Bit#(1)) lookahead = takeAt(8, dataVec);
    w_parse_tcp_options <= pack(lookahead);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 1;
    Vector#(248, Bit#(1)) _tmp = takeAt(8, dataVec);
    rg_parse_tcp_options_data[1] <= zeroExtend(pack(_tmp));
    $display("(%0d) PARSE NOP", $time);
  endrule

  rule rl_return_parse_nop if (w_parse_nop_parse_tcp_options);
    w_parse_tcp_parse_tcp_options.send();
  endrule

  rule rl_parse_end if (rg_parse_state[0] == StateParseEnd);
    Vector#(256, Bit#(1)) dataVec = unpack(rg_parse_tcp_options_data[1]);
    let options_end_t = extract_options_end_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_end();
    succeed_and_next(0);
    $display("(%0d) end data %h", $time, rg_parse_tcp_options_data[1]);
    Vector#(8, Bit#(1)) lookahead = takeAt(8, dataVec);
    w_parse_tcp_options <= pack(lookahead);
    $display("(%0d) lookahead %h", $time, pack(lookahead));
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 1;
    Vector#(248, Bit#(1)) _tmp = takeAt(8, dataVec);
    rg_parse_tcp_options_data[1] <= zeroExtend(pack(_tmp));
    $display("(%0d) PARSE END", $time);
  endrule

  rule rl_return_parse_end if (w_parse_end_parse_tcp_options);
    w_parse_tcp_parse_tcp_options.send();
  endrule

  rule rl_parse_mss if (rg_parse_state[0] == StateParseMss);
    Vector#(256, Bit#(1)) dataVec = unpack(rg_parse_tcp_options_data[1]);
    let option_mss_t = extract_options_mss_t(pack(takeAt(0, dataVec)));
    compute_next_state_parse_mss();
    succeed_and_next(56);
    $display("(%0d) mss data %h", $time, rg_parse_tcp_options_data[1]);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 4;
    Vector#(224, Bit#(1)) _tmp = takeAt(32, dataVec);
    rg_parse_tcp_options_data[1] <= zeroExtend(pack(_tmp));
    Vector#(8, Bit#(1)) lookahead = takeAt(32, dataVec);
    $display("(%0d) lookahead %h", $time, pack(lookahead));
    w_parse_tcp_options <= pack(lookahead);
    $display("(%0d) PARSE MSS", $time);
  endrule

  rule rl_return_parse_mss if (w_parse_mss_parse_tcp_options);
    $display("go to parse tcp options");
    w_parse_tcp_parse_tcp_options.send();
  endrule

  rule rl_parse_sack if (rg_parse_state[0] == StateParseSack);
    Vector#(256, Bit#(1)) dataVec = unpack(rg_parse_tcp_options_data[1]);
    let option_sack_t = extract_options_sack_t(pack(takeAt(0, dataVec)));
    $display("(%0d) sack data %h", $time, rg_parse_tcp_options_data[1]);
    compute_next_state_parse_sack();
    succeed_and_next(32);
    my_metadata$parse_tcp_options_counter[0] <= my_metadata$parse_tcp_options_counter[0] - 2;
    Vector#(240, Bit#(1)) _tmp = takeAt(16, dataVec);
    rg_parse_tcp_options_data[1] <= zeroExtend(pack(_tmp));
    Vector#(8, Bit#(1)) lookahead = takeAt(16, dataVec);
    w_parse_tcp_options <= pack(lookahead);
    $display("(%0d) PARSE SACK", $time);
  endrule

  rule rl_return_parse_sack if (w_parse_sack_parse_tcp_options);
    w_parse_tcp_parse_tcp_options.send();
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule

