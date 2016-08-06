// ====== PARSER ======
import GetPut::*;
import Ethernet::*;
import mdp::*;
import FIFOF::*;
import Vector::*;
import DbgDefs::*;
import DefaultValue::*;

typedef enum {
  StateParseStart,
  StateStart,
  StateParseEthernet,
  StateParseIpv4,
  StateParseUdp,
  StateParseMdp,
  StateParseMdpGroup
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  Wire#(Bit#(32)) w_curr_unparsed_bits <- mkDWire(0);
  Reg#(Bit#(32)) w_next_header_len[2] <- mkCReg(2, 0);
  Wire#(Bit#(272)) w_parse_udp_data <- mkDWire(0);
  PulseWire w_parse_udp_parse_mdp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_start <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_mdp_group_parse_mdp_group <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_start <- mkPulseWireOR();
  PulseWire w_parse_mdp_parse_mdp_group <- mkPulseWireOR();
  PulseWire w_parse_mdp_group_parse_start <- mkPulseWireOR();
  PulseWire w_start_parse_ethernet <- mkPulseWireOR();
  Reg#(Bit#(16)) event_metadata$group_size <- mkReg(0);
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
  Reg#(Bit#(0)) rg_tmp_start <- mkReg(0);
  Reg#(Bit#(128)) rg_tmp_parse_ethernet <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_ipv4 <- mkReg(0);
  Reg#(Bit#(0)) rg_tmp_parse_udp <- mkReg(0);
  Reg#(Bit#(304)) rg_tmp_parse_mdp <- mkReg(0);
  Reg#(Bit#(272)) rg_tmp_parse_mdp_group <- mkReg(0);
  function Action succeed_and_next(Bit#(32) offset);
    action
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
      //data_in_ff.deq;
      w_curr_unparsed_bits <= offset;
      rg_offset <= 0;
    endaction
  endfunction
  function Action push_phv(ParserState ty);
    action
      MetadataT meta = defaultValue;
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
  function Action compute_next_state_start();
    action
      w_start_parse_ethernet.send();
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
      $display("protocol %h", v);
      case (v) matches
        'h11: begin
          $display("branch to udp");
          w_parse_ipv4_parse_udp.send();
        end
        default: begin
          w_parse_ipv4_parse_start.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_udp(Bit#(16) dstPort);
    action
      let v = {dstPort};
      case (v) matches
        default: begin
          w_parse_udp_parse_mdp.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_mdp(Bit#(16) group_size);
    action
      let v = {group_size};
      case (v) matches
        default: begin
          w_parse_mdp_parse_mdp_group.send();
        end
      endcase
    endaction
  endfunction
  function Action compute_next_state_parse_mdp_group(Bit#(16) group_size);
    action
      let v = {group_size};
      case (v) matches
        'h0000: begin
          w_parse_mdp_group_parse_start.send();
        end
        default: begin
          w_parse_mdp_group_parse_mdp_group.send();
        end
      endcase
    endaction
  endfunction

  // FIXME: start state may involves parser_ops too
  rule rl_start_state if (rg_parse_state == StateParseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state <= StateParseEthernet;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  rule rl_deq_data_in_ff (w_curr_unparsed_bits < w_next_header_len[1]);
    data_in_ff.deq;
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

  (* mutually_exclusive = "rl_parse_ethernet_parse_ipv4,rl_parse_ethernet_parse_start" *)
  rule rl_parse_ethernet_parse_ipv4 if ((rg_parse_state == StateParseEthernet) && (w_parse_ethernet_parse_ipv4));
    rg_parse_state <= StateParseIpv4;
    fetch_next_header(160);
  endrule

  rule rl_parse_ethernet_parse_start if ((rg_parse_state == StateParseEthernet) && (w_parse_ethernet_parse_start));
    rg_parse_state <= StateParseStart;
    fetch_next_header(0);
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
    // extract
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_ipv4));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let ipv4_t = extract_ipv4_t(pack(takeAt(0, dataVec)));
    // do I need to update metadata ??
    // compute next state
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    // shift
    Vector#(112, Bit#(1)) unparsed = takeAt(160, dataVec);
    w_parse_udp_data <= data;
  endrule

  (* mutually_exclusive = "rl_parse_ipv4_parse_start" *)
  rule rl_parse_ipv4_parse_start if ((rg_parse_state == StateParseIpv4) && (w_parse_ipv4_parse_start));
    rg_parse_state <= StateParseStart;
    fetch_next_header(0);
  endrule

  rule rl_parse_udp if ((rg_parse_state == StateParseIpv4) && (rg_offset == 144) && (w_parse_ipv4_parse_udp));
    Vector#(272, Bit#(1)) dataVec = unpack(w_parse_udp_data);
    let udp_t = extract_udp_t(pack(takeAt(160, dataVec)));
    compute_next_state_parse_udp(udp_t.dstPort);
    Vector#(48, Bit#(1)) unparsed = takeAt(224, dataVec);
    rg_tmp_parse_mdp <= zeroExtend(pack(unparsed));
    succeed_and_next(48);
  endrule

  rule rl_parse_ipv4_parse_mdp if ((rg_parse_state == StateParseIpv4) && (w_parse_udp_parse_mdp));
    rg_parse_state <= StateParseMdp;
    fetch_next_header(288);
  endrule

  rule rl_parse_parse_mdp_0 if ((rg_parse_state == StateParseMdp) && (rg_offset == 48));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(48, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp));
    Bit#(48) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(176) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_mdp <= zeroExtend(data);
    succeed_and_next(176);
  endrule

  rule rl_parse_parse_mdp_1 if ((rg_parse_state == StateParseMdp) && (rg_offset == 176));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(176, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp));
    Bit#(176) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(304) data = {data_this_cycle, data_last_cycle};
    Vector#(304, Bit#(1)) dataVec = unpack(data);
    let mdp_packet_t = extract_mdp_packet_t(pack(takeAt(0, dataVec)));
    let mdp_message_t = extract_mdp_message_t(pack(takeAt(96, dataVec)));
    let mdp_sbe_t = extract_mdp_sbe_t(pack(takeAt(112, dataVec)));
    let mdIncrementalRefreshBook32 = extract_mdIncrementalRefreshBook32(pack(takeAt(176, dataVec)));
    let v = mdIncrementalRefreshBook32.noMDEntries;
    // initialize metadata to keep track of variable length header
    event_metadata$group_size <= v;
    // compute next step
    compute_next_state_parse_mdp(v);
    Vector#(16, Bit#(1)) unparsed = takeAt(288, dataVec);
    // do we need large buffer here, yes. But how large, depends on max size of variable length header...
    rg_tmp_parse_mdp_group <= zeroExtend(pack(unparsed));
    succeed_and_next(16);
  endrule

  // create an empty rule that just do dispatch.

  (* mutually_exclusive = "rl_parse_mdp_parse_mdp_group" *)
  rule rl_parse_mdp_parse_mdp_group if ((rg_parse_state == StateParseMdp) && (w_parse_mdp_parse_mdp_group));
    rg_parse_state <= StateParseMdpGroup;
    fetch_next_header(256);
  endrule

  rule rl_parse_parse_mdp_group_0 if ((rg_parse_state == StateParseMdpGroup) && (rg_offset == 16));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    Vector#(16, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp_group));
    Bit#(16) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(144) data = {data_this_cycle, data_last_cycle};
    rg_tmp_parse_mdp_group <= zeroExtend(data);
    succeed_and_next(144);
  endrule

  rule rl_parse_parse_mdp_group_1 if ((rg_parse_state == StateParseMdpGroup) && (rg_offset == 144));
    report_parse_action(rg_parse_state, rg_offset, data_this_cycle);
    // extract
    Vector#(144, Bit#(1)) tmp_dataVec = unpack(truncate(rg_tmp_parse_mdp_group));
    Bit#(144) data_last_cycle = pack(takeAt(0, tmp_dataVec));
    Bit#(272) data = {data_this_cycle, data_last_cycle};
    Vector#(272, Bit#(1)) dataVec = unpack(data);
    let mdIncrementalRefreshBook32Group = extract_mdIncrementalRefreshBook32Group(pack(takeAt(0, dataVec)));
    // update metadata
    let v = ( event_metadata$group_size - 'h1 );
    event_metadata$group_size <= v;
    // compute next state
    compute_next_state_parse_mdp_group(v);
    // shift
    Vector#(16, Bit#(1)) unparsed = takeAt(256, dataVec);
    rg_tmp_parse_mdp_group <= zeroExtend(pack(unparsed));
    // prepare for next state??
    succeed_and_next(16);
  endrule

  (* mutually_exclusive = "rl_parse_mdp_group_parse_start,rl_parse_mdp_group_parse_mdp_group" *)
  rule rl_parse_mdp_group_parse_start if ((rg_parse_state == StateParseMdpGroup) && (w_parse_mdp_group_parse_start));
    rg_parse_state <= StateParseStart;
    fetch_next_header(0);
  endrule

  rule rl_parse_mdp_group_parse_mdp_group if ((rg_parse_state == StateParseMdpGroup) && (w_parse_mdp_group_parse_mdp_group));
    rg_parse_state <= StateParseMdpGroup;
    fetch_next_header(256);
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule


