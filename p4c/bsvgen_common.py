'''
Common template for bsv generation
'''

import re
import astbsv as ast
from ast_util import apply_if_verbosity, apply_action_block
from collections import OrderedDict

def get_camel_case(column_name):
    ''' TODO '''
    return re.sub('_([a-z])', lambda match: match.group(1).upper(), column_name)

def convert(name):
    ''' TODO '''
    string = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', string).lower()

def camelCase(name):
    ''' camelCase '''
    output = ''.join(x for x in name.title() if x.isalnum())
    return output[0].lower() + output[1:]

def CamelCase(name):
    ''' CamelCase '''
    output = ''.join(x for x in name.title() if x.isalnum())
    return output

LICENSE ='''\
// Copyright (c) 2016 P4FPGA Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
'''
def emit_license(builder):
    builder.append(LICENSE)

IMPORT_TEMPLATE = '''
%(imports)s
'''
def emit_import(builder):
    ''' TODO '''
    pmap = {}
    import_modules = ["Connectable", "DefaultValue", "FIFO", "FIFOF", "FShow",
                      "GetPut", "List", "StmtFSM", "SpecialFIFOs", "Vector",
                      "Ethernet", "ClientServer", "DbgDefs", "PacketBuffer", 
                      "Pipe", "MatchTable", "Utils", "TxRx",
                      "Register", "BuildVector", "CBus", "MIMO", "BUtils",
                      "ConfigReg", "PrintTrace", "StructGenerated"]
    pmap['imports'] = "\n".join(["import {}::*;".format(x) for x in sorted(import_modules)])
    builder.append(IMPORT_TEMPLATE % (pmap))

def build_funct_verbosity():
    TMP1 = "Reg#(int) cf_verbosity <- mkConfigRegU;"
    stmt = []
    stmt.append(ast.Template(TMP1))
    rl_stmt = []
    rl_stmt.append(ast.Template("action"))
    rl_stmt.append(ast.Template("if (cf_verbosity > fromInteger(level)) begin"))
    rl_stmt.append(ast.Template("  $display(\"(%%d) \", $time, msg);"))
    rl_stmt.append(ast.Template("end"))
    rl_stmt.append(ast.Template("endaction"))
    funct = ast.Function("dbprint", 'Action', 'Integer level, Fmt msg', rl_stmt)
    stmt.append(funct)
    return stmt

def build_funct_dbg3():
    stmt = []
    stmt.append(ast.Template("$display(\"(%%0d) \", $time, msg);"))
    ifstmt = apply_if_verbosity(3, stmt)
    ablock = apply_action_block(ifstmt)
    funct = ast.Function("dbg3", 'Action', 'Fmt msg', ablock)
    return funct

# Deparser
def apply(temp, json):
    return [temp.format(v, x) for x, v in json.items()]

def spaces(indent):
    return ' ' * 2 * indent

def expand_deparse_intf_put_decl(indent, json):
    temp = spaces(indent) + "interface Put#(EtherData) {};"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_deparse_intf_put_defs(indent, json):
    temp = spaces(indent) + "interface {} = toPut({}_fifo);"
    return "\n".join([temp.format(x, x) for x, _ in json.items()])

def expand_deparse_intf_get_decl(indent, json):
    temp = spaces(indent) + "interface Get#(EtherData) {};"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_deparse_intf_get_defs(indent, json):
    temp = spaces(indent) + "interface {} = toGet({}_fifo);"
    return "\n".join([temp.format(x, x) for x, _ in json.items()])

def expand_deparse_data_in(indent, json):
    temp = spaces(indent) + "FIFOF#(EtherData) {}_fifo <- mkBypassFIFOF;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_deparse_data_out(indent, json):
    temp = spaces(indent) + "FIFO#(EtherData) {}_fifo <- mkFIFO;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

UNPACKED_DATA='''\
Vector#({}, Bit#(1)) data = takeAt({}, unpack(data_this_cycle.data));\
'''
UNPACKED_UNUSED='''\
Vector#({}, Bit#(1)) unused = takeAt({}, unpack(data_this_cycle.data));\
'''
UNPACKED_META='''\
Vector#({}, Bit#(1)) curr_meta = takeAt({}, unpack(byteSwap(pack(meta_fifo.first))));\
'''
UNPACKED_MASK='''\
Vector#({}, Bit#(1)) curr_mask = takeAt({}, unpack(byteSwap(pack(mask_fifo.first))));\
'''
def expand_unpack(indent, step, json):
    temp = []
    if step.first_step and step.pkt_offset:
        temp.append(spaces(indent) + "let data_this_cycle <- toGet({}_fifo).get;".format(json.intf_put.keys()[0]))
    else:
        temp.append(spaces(indent) + "let data_this_cycle = packet_in_wire;")

    if step.pkt_offset:
        temp.append(spaces(indent) + UNPACKED_UNUSED.format(step.pkt_offset, 0))
    else:
        if step.last_step:
            temp.append(spaces(indent) + UNPACKED_UNUSED.format(128 - step.extract_len, step.extract_len))

    temp.append(spaces(indent) + UNPACKED_DATA.format(step.extract_len, step.pkt_offset))
    temp.append(spaces(indent) + UNPACKED_META.format(step.extract_len, step.meta_offset))
    temp.append(spaces(indent) + UNPACKED_MASK.format(step.extract_len, step.meta_offset))
    return "\n".join(temp)

def expand_pack(indent, step, json):
    temp = []
    if step.last_step:
        temp.append(spaces(indent) + "{} {} = unpack(pack(masked_data));".format(CamelCase(json.headertype), json.headertype))
    if step.pkt_offset:
        temp.append(spaces(indent) + "data_this_cycle.data = {pack(curr_data), pack(unused)};")
    else:
        if step.last_step:
            temp.append(spaces(indent) + "data_this_cycle.data = {pack(unused), pack(curr_data)};")
        else:
            temp.append(spaces(indent) + "data_this_cycle.data = {pack(curr_data)};")
    return "\n".join(temp)

def expand_modify(indent, json):
    temp = []
    temp.append(spaces(indent) + "let masked_data = pack(data) & pack(curr_mask);")
    temp.append(spaces(indent) + "let curr_data = masked_data | pack(curr_meta);")
    return "\n".join(temp)

def expand_next_deparse_state(indent, step, json):
    temp = []
    if step.last_step:
        if len(json.compute_next_state.branch):
            temp.append(spaces(indent) + "let nextState = compute_next_state({}.{});".format(json.headertype, json.compute_next_state.field))
            temp.append(spaces(indent) + "state <= nextState;")
            for x in json.compute_next_state.branch:
                temp.append(spaces(indent) + "if (nextState == State{}) begin".format(CamelCase(x.next_state)))
                temp.append(spaces(indent+1) + "{}_fifo.enq(data_this_cycle);".format(x.next_state))
                temp.append(spaces(indent) + "end")
        else:
            temp.append(spaces(indent) + "dataout.enq(data_this_cycle);")
            temp.append(spaces(indent) + "state <= StateDeparseIdle;")

    return "\n".join(temp)

def expand_output(indent, step, json):
    temp = []
    if (step.extract_len + step.pkt_offset == 128):
        temp.append(spaces(indent) + "dataout.enq(data_this_cycle);")
    return "\n".join(temp)

def expand_fifo_dequeue(indent, step, json):
    temp = []
    if step.last_step:
        temp.append(spaces(indent) + "meta_fifo.deq;")
        temp.append(spaces(indent) + "mask_fifo.deq;")
    return "\n".join(temp)

DEPARSE_STEP='''\
  action
%(unpack)s
%(modify)s
%(pack)s
%(output)s
%(next_state)s
%(dequeue)s
  endaction'''
def expand_deparse_step(indent, step, json):
    pmap = {}
    pmap['unpack']     = expand_unpack(indent, step, json)
    pmap['pack']       = expand_pack(indent, step, json)
    pmap['modify']     = expand_modify(indent, json)
    pmap['output']     = expand_output(indent, step, json)
    pmap['next_state'] = expand_next_deparse_state(indent, step, json)
    pmap['dequeue']    = expand_fifo_dequeue(indent, step, json)
    return DEPARSE_STEP % pmap

DEPARSE_STMT='''\
  Stmt %(name)s =
  seq
%(parse_step)s
  endseq;
'''
def expand_deparse_statement(indent, json):
    pmap = {}
    pmap['name'] = json.name
    pmap['parse_step'] = "\n".join([expand_deparse_step(indent + 1, step, json) for step in json.deparse_step])
    return DEPARSE_STMT % pmap

DEPARSE_STATE_ENUM='''\
typedef enum {
%(enum)s
} DeparserState deriving (Bits, Eq, FShow);
'''
def generate_deparse_state_enum (json):
    temp = "  State{}"
    pmap = {}
    enums = ["  StateDeparseIdle"] + [temp.format(CamelCase(x)) for x in json.deparser]
    pmap['enum'] = ',\n'.join(enums)
    return DEPARSE_STATE_ENUM % pmap


DEPARSE_STATE_TEMPLATE= '''
interface %(CamelCaseName)s;
%(intf_put)s
%(intf_get)s
  method Action start;
  method Action stop;
endinterface
module mkState%(CamelCaseName)s#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, FIFOF#(%(headertype)s) meta_fifo, FIFOF#(%(headertype)s) mask_fifo)(%(CamelCaseName)s);
  let verbose = False;
  Wire#(EtherData) packet_in_wire <- mkDWire(defaultValue);
%(data_in_fifo)s
%(data_out_fifo)s
  PulseWire start_wire <- mkPulseWire;
  PulseWire stop_wire <- mkPulseWire;
%(compute_next_state)s
  rule load_packet if (state == State%(CamelCaseName)s);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current;
  endrule
%(statement)s
  FSM fsm_%(name)s <- mkFSM(%(name)s);
  rule start_fsm if (start_wire);
    fsm_%(name)s.start;
  endrule
  rule stop_fsm if (stop_wire);
    fsm_%(name)s.abort;
  endrule
  method start = start_wire.send;
  method stop = stop_wire.send;
%(intf_data_out)s
%(intf_ctrl_out)s
endmodule
'''
def generate_deparse_state(builder, json):
    ''' generate one deparse state '''
    assert isinstance(json, DotMap)
    pmap = {}
    pmap['name'] = json.name
    pmap['CamelCaseName'] = CamelCase(json.name)
    pmap['intf_put'] = expand_deparse_intf_put_decl(1, json.intf_put)
    pmap['intf_get'] = expand_deparse_intf_get_decl(1, json.intf_get)
    pmap['data_in_fifo'] = expand_deparse_data_in(1, json.intf_put)
    pmap['data_out_fifo'] = expand_deparse_data_out(1, json.intf_get)
    pmap['compute_next_state'] = expand_next_state(1, "Deparser", json)
    pmap['statement'] = expand_deparse_statement(1, json)
    pmap['intf_data_out'] = expand_deparse_intf_get_defs(1, json.intf_get);
    pmap['intf_ctrl_out'] = expand_deparse_intf_put_defs(1, json.intf_put);
    pmap['headertype'] = CamelCase(json.headertype)
    builder.append(DEPARSE_STATE_TEMPLATE % pmap)

DEPARSE_STATE_INIT='''
module mkStateDeparseIdle#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, Wire#(Bool) start_fsm)(Empty);

   rule load_packet if (state == StateDeparseIdle);
      let v = datain.first;
      if (v.sop) begin
         state <= StateDeparseEthernet;
         start_fsm <= True;
         $display("(%0d) Deparse Ethernet Start", $time);
      end
      else begin
         datain.deq;
         dataout.enq(v);
         $display("(%0d) payload ", $time, fshow(v));
         start_fsm <= False;
      end
   endrule
endmodule
'''
def generate_deparse_idle(builder):
    builder.append(DEPARSE_STATE_INIT)

def expand_meta_fifo(indent, json):
    temp = []
    for k, v in json.items():
        temp.append(spaces(indent) + "FIFOF#({}) {}_meta_fifo <- mkFIFOF;".format(CamelCase(v.headertype), k))
    return "\n".join(temp)

def expand_mask_fifo(indent, json):
    temp = []
    for k, v in json.items():
        temp.append(spaces(indent) + "FIFOF#({}) {}_mask_fifo <- mkFIFOF;".format(CamelCase(v.headertype), k))
    return "\n".join(temp)

def expand_deparse_state(indent, json):
    temp = spaces(indent) + "{C} {c} <- mkState{C}(curr_state, data_in_fifo, data_out_fifo, {c}_meta_fifo, {c}_mask_fifo);"
    return "\n".join([temp.format(C=CamelCase(x), c=x) for x, _ in json.items()])
def expand_parse_state(indent, json):
    temp = spaces(indent) + "{C} {c} <- mkState{C}(curr_state, data_in_fifo);"
    return "\n".join([temp.format(C=CamelCase(x), c=x) for x, _ in json.items()])

def expand_state_connection(indent, json):
    connections = []
    temp = spaces(indent) + "mkConnection({a}.{b}, {b}.{a});"
    for start, values in json.items():
        for end in values.intf_get.keys():
            connections.append(temp.format(a=start, b=end))
    return "\n".join(connections)

def expand_state_start(indent, json):
    temp = spaces(indent) + "{}.start;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_state_stop(indent, json):
    temp = spaces(indent) + "{}.stop;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

DEPARSE_TOP_TEMPLATE = '''
interface Deparser;
  interface PipeIn#(MetadataT) metadata;
  interface PktWriteServer writeServer;
  interface PktWriteClient writeClient;
  method DeparserPerfRec read_perf_info;
endinterface
(* synthesize *)
module mkDeparser(Deparser);
  let verbose = False;
  FIFOF#(EtherData) data_in_fifo <- mkSizedFIFOF(4);
  FIFOF#(EtherData) data_out_fifo <- mkFIFOF;
  FIFOF#(MetadataT) metadata_in_fifo <- mkFIFOF;
  Reg#(Bool) started <- mkReg(False);
  Wire#(Bool) start_fsm <- mkDWire(False);
  Reg#(DeparserState) curr_state <- mkReg(StateDeparseIdle);

  Vector#(PortMax, FIFOF#(DeparserState)) deparse_state_in_fifo <- replicateM(mkGFIFOF(False, True));
  FIFOF#(DeparserState) deparse_state_out_fifo <- mkFIFOF;
%(meta_in_fifo)s
%(mask_in_fifo)s
  (* fire_when_enabled *)
  rule arbitrate_deparse_state;
    Bool sentOne = False;
    for (Integer port = 0; port < valueOf(PortMax); port = port+1) begin
      if (!sentOne && deparse_state_in_fifo[port].notEmpty()) begin
        DeparserState state <- toGet(deparse_state_in_fifo[port]).get();
        sentOne = True;
        deparse_state_out_fifo.enq(state);
      end
    end
  endrule
  rule get_meta;
    let v <- toGet(metadata_in_fifo).get;
%(metadata_func)s
  endrule
  Empty init_state <- mkStateDeparseIdle(curr_state, data_in_fifo, data_out_fifo, start_fsm);
%(deparse_state)s
%(connect_state)s
  rule start if (start_fsm);
    if (!started) begin
%(deparse_state_start)s
      started <= True;
    end
  endrule
  rule stop if (!start_fsm && curr_state == StateDeparseIdle);
    if (started) begin
%(deparse_state_stop)s
      started <= False;
    end
  endrule
  interface PktWriteServer writeServer;
    interface writeData = toPut(data_in_fifo);
  endinterface
  interface PktWriteClient writeClient;
    interface writeData = toGet(data_out_fifo);
  endinterface
  interface metadata = toPipeIn(metadata_in_fifo);
endmodule
'''
def generate_deparse_top(indent, json):
    ''' generate deparser top module '''
    pmap = {}
    pmap["meta_in_fifo"] = expand_meta_fifo(indent + 1, json.deparser)
    pmap["mask_in_fifo"] = expand_mask_fifo(indent + 1, json.deparser)
    pmap["metadata_func"] = ""
    pmap["deparse_state"] = expand_deparse_state(indent + 1, json.deparser)
    pmap["connect_state"] = expand_state_connection(indent + 1, json.deparser)
    pmap["deparse_state_start"] = expand_state_start(indent + 3, json.deparser)
    pmap["deparse_state_stop"] = expand_state_stop(indent + 3, json.deparser)
    return DEPARSE_TOP_TEMPLATE % (pmap)


