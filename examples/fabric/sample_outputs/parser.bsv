// ====== PARSER ======
import GetPut::*;
import Ethernet::*;
import fabric::*;
import FIFOF::*;
import Vector::*;
import DbgDefs::*;
import DefaultValue::*;

typedef enum {
  StateParseStart,
  StateEthernet,
  StateFabricHeader,
  StateFabricHeaderMulticast,
  StateFabricHeaderCpu,
  StateFabricHeaderMirror,
  StateFabricHeaderUnicast,
  StateFabricPayloadHeader,
  StateIpv4,
  StateUdp
} ParserState deriving (Bits, Eq);
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
  interface Put#(int) verbosity;
  method ParserPerfRec read_perf_info ();
endinterface
module mkParser  (Parser);
  Reg#(Bit#(32)) rg_next_header_len[2] <- mkCReg(2, 0);
  Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_shift_amt[2] <- mkCReg(2, 0);

  Reg#(Bit#(32)) rg_processed[3] <- mkCReg(3, 0);
  Reg#(Bit#(32)) rg_offset[2] <- mkCReg(2, 0);

  PulseWire w_parse_udp_parse_mdp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_start <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_udp <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_ipv4 <- mkPulseWireOR();
  PulseWire w_parse_ethernet_parse_fabric <- mkPulseWireOR();
  PulseWire w_parse_ipv4_parse_start <- mkPulseWireOR();
  PulseWire w_parse_fabric_header_parse_fabric_header_unicast <- mkPulseWireOR();
  PulseWire w_parse_fabric_header_unicast_fabric_payload_header <- mkPulseWireOR();
  PulseWire w_parse_fabric_header_parse_start <- mkPulseWireOR();
  PulseWire w_start_parse_ethernet <- mkPulseWireOR();
  PulseWire w_parse_fabric_header_unicast_parse_start <- mkPulseWireOR();
  PulseWire w_parse_fabric_header_parse_ipv4 <- mkPulseWireOR();
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
  PulseWire parse_done <- mkPulseWire();
  Reg#(Bit#(512)) rg_tmp <- mkReg(0);
  function Action dbg3(Fmt msg);
    action
      if (cr_verbosity[0] > 3) begin
        $display("(%0d) ", $time, msg);
      end
    endaction
  endfunction
  function Action succeed_and_next(Bit#(32) offset);
    action
      rg_buffered[0] <= rg_buffered[0] - offset;
      rg_shift_amt[0] <= rg_buffered[0] - offset;
      dbg3($format("succeed_and_next %h", rg_buffered[0] - offset));
    endaction
  endfunction
  function Action fetch_next_header(Bit#(32) len);
    action
      rg_next_header_len[0] <= len;
    endaction
  endfunction
  function Action failed_and_trap(Bit#(32) offset);
    action
      //data_in_ff.deq;
      rg_offset[0] <= 0;
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
        $display("(%0d) Parser State %h buffered %h, %h", $time, state, offset, data);
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
        'h0900: begin
          dbg3($format("fabric header"));
          w_parse_ethernet_parse_fabric.send();
        end
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
  function Action compute_next_state_parse_fabric_header(Bit#(3) packetType);
    action
      let v = {packetType};
      case (v) matches
         'h1: begin
            w_parse_fabric_header_parse_fabric_header_unicast.send();
         end
         default: begin
            w_parse_fabric_header_parse_start.send();
         end
      endcase
    endaction
  endfunction

  function Action compute_next_state_parse_fabric_header_unicast();
    action
      w_parse_fabric_header_unicast_fabric_payload_header.send();
    endaction
  endfunction

  function Action compute_next_state_parse_fabric_payload_header(Bit#(16) etherType);
    action
      let v = {etherType};
      case (v) matches
         'h800: begin
            w_parse_fabric_header_parse_ipv4.send();
         end
         default: begin
            dbg3($format("******unknown ethertype******"));
            //w_parse_fabric_payload_header_parse_start.send();
         end
      endcase
    endaction
  endfunction
  // FIXME: start state may involves parser_ops too
  rule rl_start_state if (rg_parse_state == StateParseStart);
    let v = data_in_ff.first;
    if (v.sop) begin
      rg_parse_state <= StateEthernet;
      rg_buffered[0] <= 128;
      rg_shift_amt[0] <= 0;
    end
    else begin
      data_in_ff.deq;
    end
  endrule

  rule rl_load_ff if (rg_buffered[1] < rg_next_header_len[1]);
    dbg3($format("dequeue data %h %h", rg_buffered[1], rg_next_header_len[1]));
    rg_buffered[1] <= rg_buffered[1] + 128;
    // update buffer;
    data_in_ff.deq;
  endrule

  let data_this_cycle = data_in_ff.first.data;
  rule rl_parse_ethernet_load if ((rg_parse_state == StateEthernet) && (rg_buffered[0] < 112));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
  endrule
  rule rl_parse_ethernet_extract if ((rg_parse_state == StateEthernet) && (rg_buffered[0] >= 112));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    Bit#(128) data = {data_this_cycle};
    let ethernet_t = extract_ethernet_t(truncate(data));
    dbg3($format("extract ethernet %h", ethernet_t));
    compute_next_state_parse_ethernet(ethernet_t.etherType);
    rg_tmp <= zeroExtend(data >> 112);
    succeed_and_next(112);
  endrule

  (* mutually_exclusive = "rl_parse_ethernet_parse_ipv4,rl_parse_ethernet_parse_start, rl_parse_ethernet_parse_fabric" *)
  rule rl_parse_ethernet_parse_fabric if ((rg_parse_state == StateEthernet) && (w_parse_ethernet_parse_fabric));
    rg_parse_state <= StateFabricHeader;
    fetch_next_header(40);
  endrule

  rule rl_parse_ethernet_parse_ipv4 if ((rg_parse_state == StateEthernet) && (w_parse_ethernet_parse_ipv4));
    rg_parse_state <= StateIpv4;
    fetch_next_header(160);
  endrule

  rule rl_parse_ethernet_parse_start if ((rg_parse_state == StateEthernet) && (w_parse_ethernet_parse_start));
    rg_parse_state <= StateParseStart;
    fetch_next_header(0);
  endrule

  rule rl_parse_fabric_header_load if ((rg_parse_state == StateFabricHeader) && (rg_buffered[0] < 40));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    dbg3($format("dequeue?"));
  endrule

  rule rl_parse_fabric_header_extract if ((rg_parse_state == StateFabricHeader) && (rg_buffered[0] >= 40));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;
    dbg3($format("fabric shamt %h %h", rg_shift_amt[0], rg_tmp));
    Bit#(40) header = truncate(data);
    FabricHeaderT pkt = extract_fabric_header_t(header);
    dbg3($format("extract fabric %h", header));
    compute_next_state_parse_fabric_header(pkt.packetType);
    rg_tmp <= zeroExtend(data >> 40);
    dbg3($format("fabric %h %h", data_this_cycle, data));
    succeed_and_next(40);
  endrule

  rule rl_parse_fabric_header_parse_fabric_header_unicast if ((rg_parse_state == StateFabricHeader) && (w_parse_fabric_header_parse_fabric_header_unicast));
    rg_parse_state <= StateFabricHeaderUnicast;
    dbg3($format("fabric -> unicast"));
    fetch_next_header(24);
  endrule

  rule rl_parse_fabric_header_parse_start if ((rg_parse_state == StateFabricHeader) && (w_parse_fabric_header_parse_start));
    rg_parse_state <= StateParseStart;
    dbg3($format("fabric -> start"));
    fetch_next_header(0);
  endrule

  rule rl_parse_fabric_header_unicast_load if ((rg_parse_state == StateFabricHeaderUnicast) && (rg_buffered[0] < 24));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    dbg3($format("unicast load"));
  endrule

  rule rl_parse_fabric_header_unicast_extract if ((rg_parse_state == StateFabricHeaderUnicast) && (rg_buffered[0] >= 24));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    dbg3($format("unicast shamt %h", rg_shift_amt[0]));
    let data = rg_tmp;
    Bit#(24) header = truncate(rg_tmp);
    FabricHeaderUnicastT pkt = extract_fabric_header_unicast_t(header);
    compute_next_state_parse_fabric_header_unicast();
    rg_tmp <= zeroExtend(data >> 24);
    dbg3($format("unicast extract %h", data_this_cycle));
    succeed_and_next(24);
  endrule

  rule rl_parse_fabric_header_unicast_parse_fabric_payload_header if ((rg_parse_state == StateFabricHeaderUnicast) && (w_parse_fabric_header_unicast_fabric_payload_header));
    rg_parse_state <= StateFabricPayloadHeader;
    dbg3($format("unicast -> payload"));
    fetch_next_header(16);
  endrule

  rule rl_parse_fabric_payload_header if ((rg_parse_state == StateFabricPayloadHeader) && (rg_buffered[0] >= 16));
    dbg3($format("fabric payload %h", rg_shift_amt[0]));
    let data = rg_tmp;
    Bit#(16) header = truncate(rg_tmp);
    FabricPayloadHeaderT pkt = extract_fabric_payload_header_t(header);
    compute_next_state_parse_fabric_payload_header(pkt.etherType);
    dbg3($format("payload header %h", pkt.etherType));
    rg_tmp <= zeroExtend(data >> 16);
    succeed_and_next(16);
  endrule

  rule rl_parse_fabric_payload_header_parse_ipv4 if ((rg_parse_state == StateFabricPayloadHeader) && (w_parse_fabric_header_parse_ipv4));
     rg_parse_state <= StateIpv4;
     dbg3($format("payload -> ipv4"));
     fetch_next_header(160);
  endrule

  rule rl_parse_parse_ipv4_load if ((rg_parse_state == StateIpv4) && (rg_buffered[0] < 160));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    //let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;
    dbg3($format("ipv4 load %h", data_this_cycle));
  endrule

  rule rl_parse_parse_ipv4_extract if ((rg_parse_state == StateIpv4) && (rg_buffered[0] >= 160));
    report_parse_action(rg_parse_state, rg_buffered[0], data_this_cycle);
    dbg3($format("ipv4 shamt %h", rg_shift_amt[0]));
    let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp;
    Bit#(160) header = truncate(data);
    let ipv4_t = extract_ipv4_t(header);
    compute_next_state_parse_ipv4(ipv4_t.protocol);
    dbg3($format("ipv4 extract %h", data));
    succeed_and_next(160);
  endrule

  (* mutually_exclusive = "rl_parse_ipv4_parse_start" *)
  rule rl_parse_ipv4_parse_start if ((rg_parse_state == StateIpv4) && (w_parse_ipv4_parse_start));
    rg_parse_state <= StateParseStart;
    fetch_next_header(0);
  endrule

  rule rl_parse_ipv4_parse_udp if ((rg_parse_state == StateIpv4) && (w_parse_ipv4_parse_udp));
    rg_parse_state <= StateUdp;
    fetch_next_header(64);
  endrule

  interface frameIn = toPut(data_in_ff);
  interface meta = toGet(meta_in_ff);
  interface verbosity = toPut(cr_verbosity_ff);
endmodule

