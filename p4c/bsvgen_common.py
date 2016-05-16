'''
Common template for bsv generation
'''

import re
from dotmap import DotMap
from collections import OrderedDict
from pif_ir.bir.objects.bir_struct import BIRStruct
from pif_ir.bir.objects.table import Table

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
// Copyright (c) 2016 Cornell University

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
def generate_license(serializer):
    serializer.append(LICENSE)

IMPORT_TEMPLATE = '''
%(imports)s
'''
def generate_import_statements(serializer):
    ''' TODO '''
    pmap = {}
    import_modules = ["Connectable", "DefaultValue", "FIFO", "FIFOF", "FShow",
                      "GetPut", "List", "StmtFSM", "SpecialFIFOs", "Vector",
                      "Ethernet", "ClientServer", "DbgDefs", "PacketBuffer", 
                      "Pipe", "MatchTable", "MatchTableSim", "Utils"]
    pmap['imports'] = "\n".join(["import {}::*;".format(x) for x in sorted(import_modules)])
    serializer.append(IMPORT_TEMPLATE % (pmap))


TYPEDEF_TEMPLATE = '''
typedef struct {
%(field)s
} %(CamelCaseName)s deriving (Bits, Eq);

instance DefaultValue#(%(CamelCaseName)s);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(%(CamelCaseName)s);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(%(CamelCaseName)s);
  function Fmt fshow(%(CamelCaseName)s p);
    return $format("%(CamelCaseName)s: %(printf)s", %(printv)s);
  endfunction
endinstance

function %(CamelCaseName)s extract_%(name)s(Bit#(%(width)s) data);
  Vector#(%(width)s, Bit#(1)) dataVec = unpack(data);
%(extract)s
  %(CamelCaseName)s hdr = defaultValue;
%(pack)s
  return hdr;
endfunction
'''

def generate_typedef(struct):
    ''' TODO '''
    assert isinstance(struct, BIRStruct)

    typedef_fields = []
    printf = []
    printv = []
    extract = []
    extract_template = '  Vector#({s}, Bit#(1)) {f} = takeAt({o}, dataVec);'
    pack = []

    width = sum([x for x in struct.fields.values()])

    offset = 0
    for field, size in struct.fields.items():
        typedef_fields.append('  Bit#({w}) {v};'.format(w=size,
                                                       v=field))
        printf.append('{f}=%h'.format(f=field))
        printv.append('p.{v}'.format(v=field))
        extract.append(extract_template.format(s=size, f=field, o=offset))
        pack.append('  hdr.{f} = pack({f});'.format(f=field))
        offset += size

    pmap = {'name': struct.name,
            'CamelCaseName': CamelCase(struct.name),
            'field': '\n'.join(typedef_fields),
            'printf': ', '.join(printf),
            'printv': ', '.join(printv),
            'width': width,
            'extract': '\n'.join(extract),
            'pack': '\n'.join(pack)}
    return TYPEDEF_TEMPLATE % (pmap)

COMPUTE_NEXT_STATE = '''
  function %(state)s compute_next_state(Bit#(%(width)s) v);
    %(state)s nextState = %(init_state)s;
    case (byteSwap(v)) matches
%(branch)s
      default: begin
        nextState = %(init_state)s;
      end
    endcase
    return nextState;
  endfunction
'''
def expand_next_state(indent, state, json):
    ''' cases, width '''
    def process(branch):
        value = branch.value.replace("0x", "'h")
        state = CamelCase(branch.next_state)
        return (value, state)

    if not json.has_key('compute_next_state'):
        return '' #empty line
    if json.compute_next_state.branch == []:
        return ""
    tcase = "      {}: begin\n        nextState = State{};\n      end"
    pmap = {}
    pmap['branch'] = "\n".join([tcase.format(*process(x)) for x in json.compute_next_state.branch])
    pmap['width'] = json.compute_next_state.width
    pmap['state'] = "ParserState" if (state == 'Parser') else "DeparserState"
    pmap['init_state'] = "StateParseStart" if (state == 'Parser') else "StateDeparseIdle"
    return COMPUTE_NEXT_STATE % pmap

def expand_parse_carry_in(indent, step, json):
    temp = []
    if step.first_step:
        for x, _ in json.items():
            temp.append(spaces(indent) + "let data_last_cycle <- toGet(unparsed_{}_fifo).get;".format(x))
    else:
        temp.append(spaces(indent) + "let data_last_cycle <- toGet(internal_fifo_{}).get;".format(step.carry_len))
    return "\n".join(temp)

def expand_parse_concat(indent, step, json):
    temp = []
    if step.first_step and step.carry_len != 0:
        temp.append(spaces(indent) + "Bit#({}) data = {{data_this_cycle, data_last_cycle}};".format(step.curr_len))
    elif not step.first_step:
        temp.append(spaces(indent) + "Bit#({}) data = {{data_this_cycle, data_last_cycle}};".format(step.curr_len))
    return "\n".join(temp)

def expand_parse_carry_out(indent, step, json):
    temp = []
    if step.last_step:
        temp.append(spaces(indent) + "Vector#({}, Bit#(1)) unparsed = takeAt({}, dataVec);".format(step.carry_out_len, step.carry_out_offset))
    return "\n".join(temp)

def expand_parse_internal(indent, step, json):
    temp = []
    if not step.last_step:
        temp.append(spaces(indent) + "internal_fifo_{}.enq(data);".format(step.curr_len))
    return "\n".join(temp)

def expand_parse_unpack(indent, step, json):
    temp = []
    if step.first_step and step.last_step:
        temp.append(spaces(indent) + "Vector#({}, Bit#(1)) dataVec = unpack(data_this_cycle);".format(step.curr_len))
    elif step.last_step:
        temp.append(spaces(indent) + "Vector#({}, Bit#(1)) dataVec = unpack(data);".format(step.curr_len))
    return "\n".join(temp)

def expand_parse_extract(indent, step, json):
    temp = []
    if step.last_step:
        temp.append(spaces(indent) + "let {hdr} = extract_{hdr}(pack(takeAt(0, dataVec)));".format(hdr=json.headertype))
    return "\n".join(temp)

def expand_parse_next_state(indent, step, json):
    temp = []
    if step.last_step:
        if len(json.compute_next_state.branch):
            temp.append(spaces(indent) + "let nextState = compute_next_state({}.{});".format(json.headertype, json.compute_next_state.field))
            for x in json.compute_next_state.branch:
                temp.append(spaces(indent) + "if (nextState == State{}) begin".format(CamelCase(x.next_state)))
                temp.append(spaces(indent+1) + "unparsed_{}_fifo.enq(pack(unparsed));".format(x.next_state))
                temp.append(spaces(indent) + "end")
            temp.append(spaces(indent) + "state <= nextState;")
        else:
            temp.append(spaces(indent) + "state <= StateParseStart;")
    return "\n".join(temp)

PARSE_STEP='''\
  action
    let data_this_cycle = packet_in_wire;
%(carry_in)s
%(concat)s
%(internal)s
%(unpack)s
%(carry_out)s
%(extract)s
%(next_state)s
  endaction'''
'''
'''
def expand_parse_step(indent, step, json):
    pmap = {}
    pmap['carry_in'] = expand_parse_carry_in(indent, step, json.intf_put)
    pmap['concat'] = expand_parse_concat(indent, step, json)
    pmap['internal'] = expand_parse_internal(indent, step, json)
    pmap['unpack'] = expand_parse_unpack(indent, step, json)
    pmap['extract'] = expand_parse_extract(indent, step, json)
    pmap['carry_out'] = expand_parse_carry_out(indent, step, json.intf_put)
    pmap['next_state'] = expand_parse_next_state(indent, step, json)
    return PARSE_STEP % pmap

PARSE_STMT='''\
  Stmt %(name)s =
  seq
%(parse_step)s
  endseq;'''
def expand_parse_statement(indent, json):
    pmap = {}
    pmap['name'] = json.name
    pmap['parse_step'] = "\n".join([expand_parse_step(indent + 1, step, json) for step in json.parse_step])
    return PARSE_STMT % pmap

PARSE_STATE_ENUM='''\
typedef enum {
%(enum)s
} ParserState deriving (Bits, Eq, FShow);
'''
def generate_parse_state_enum(json):
    temp ="  State{}"
    pmap = {}
    enums = ["  StateParseStart"] + [temp.format(CamelCase(x)) for x in json.parser]
    pmap['enum'] = ',\n'.join(enums)
    return PARSE_STATE_ENUM % pmap

PARSE_STATE_INIT='''\
module mkStateParseStart#(Reg#(ParserState) state, FIFOF#(EtherData) datain, Wire#(Bool) start_fsm)(Empty);
  rule load_packet if (state == StateParseStart);
    let v = datain.first;
    if (v.sop) begin
      state <= State%(init_state)s;
      start_fsm <= True;
    end
    else begin
      datain.deq;
      start_fsm <= False;
    end
  endrule
endmodule
'''
def generate_parse_state_init(json):
    pmap = {}
    pmap['init_state'] = CamelCase(json.control_flow.parser.start)
    return PARSE_STATE_INIT % (pmap)

def expand_parse_intf_put_decl(indent, json):
    temp = spaces(indent) + "interface Put#(Bit#({})) {};"
    return "\n".join([temp.format(v, x) for x, v in json.items()])

def expand_parse_intf_put_defs(indent, json):
    temp = spaces(indent) + "interface {} = toPut(unparsed_{}_fifo);"
    return "\n".join([temp.format(x, x) for x, _ in json.items()])

def expand_parse_intf_get_decl(indent, json):
    temp = spaces(indent) + "interface Get#(Bit#({})) {};"
    return "\n".join([temp.format(v, x) for x, v in json.items()])

def expand_parse_intf_get_defs(indent, json):
    temp = spaces(indent) + "interface {} = toGet(unparsed_{}_fifo);"
    return "\n".join([temp.format(x, x) for x, _ in json.items()])

def expand_parse_data_in(indent, json):
    temp = spaces(indent) + "FIFOF#(Bit#({})) unparsed_{}_fifo <- mkBypassFIFOF;"
    return "\n".join([temp.format(v, x) for x, v in json.items()])

def expand_parse_data_out(indent, json):
    temp = spaces(indent) + "FIFO#(Bit#({})) unparsed_{}_fifo <- mkFIFO;"
    return "\n".join([temp.format(v, x) for x, v in json.items()])


PARSE_STATE_TEMPLATE = '''
interface %(CamelCaseName)s;
%(intf_put)s
%(intf_get)s
  method Action start;
  method Action stop;
endinterface
module mkState%(CamelCaseName)s#(Reg#(ParserState) state, FIFOF#(EtherData) datain, FIFOF#(ParserState) parseStateFifo)(%(CamelCaseName)s);
  let verbose = False;
%(data_in_fifo)s
%(data_out_fifo)s
  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(4, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire stop_wire <- mkPulseWire();
  (* fire_when_enabled *)
  rule arbitrate_outgoing_state if (state == State%(CamelCaseName)s);
    Vector#(4, Bool) next_state_valid = replicate(False);
    Bool stateSet = False;
    for (Integer port=0; port<4; port=port+1) begin
      next_state_valid[port] = isValid(next_state_wire[port]);
      if (!stateSet && next_state_valid[port]) begin
        stateSet = True;
        ParserState next_state = fromMaybe(?, next_state_wire[port]);
        state <= next_state;
      end
    end
  endrule
%(compute_next_state)s
  rule load_packet if (state == State%(CamelCaseName)s);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
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
def generate_parse_state(serializer, node, structmap, json):
    ''' expand json configuration into bluespec '''
    pmap = {}
    pmap['name'] = json.name
    pmap['CamelCaseName'] = CamelCase(json.name)
    pmap['intf_put'] = expand_parse_intf_put_decl(1, json.intf_put)
    pmap['intf_get'] = expand_parse_intf_get_decl(1, json.intf_get)
    pmap['data_in_fifo'] = expand_parse_data_in(1, json.intf_put)
    pmap['data_out_fifo'] = expand_parse_data_out(1, json.intf_get)
    pmap['compute_next_state'] = expand_next_state(1, 'Parser', json)
    pmap['statement'] = expand_parse_statement(1, json)
    pmap['intf_data_out'] = expand_parse_intf_get_defs(1, json.intf_get)
    pmap['intf_ctrl_out'] = expand_parse_intf_put_defs(1, json.intf_put)
    serializer.append(PARSE_STATE_TEMPLATE % (pmap))

PARSE_TOP_TEMPLATE = '''
interface Parser;
  interface Put#(EtherData) frameIn;
  interface Get#(MetadataT) meta;
endinterface
typedef 4 PortMax;
(* synthesize *)
module mkParser(Parser);
  Reg#(ParserState) curr_state <- mkReg(StateParseStart);
  Reg#(Bool) started <- mkReg(False);
  FIFOF#(EtherData) data_in_fifo <- mkFIFOF;
  Wire#(Bool) start_fsm <- mkDWire(False);

  Vector#(PortMax, FIFOF#(ParserState)) parse_state_in_fifo <- replicateM(mkGFIFOF(False, True)); // ungarded deq
  FIFOF#(ParserState) parse_state_out_fifo <- mkFIFOF;
  FIFOF#(MetadataT) metadata_out_fifo <- mkFIFOF;

  (* fire_when_enabled *)
  rule arbitrate_parse_state;
    Bool sentOne = False;
    for (Integer port=0; port<valueOf(PortMax); port=port+1) begin
      if (!sentOne && parse_state_in_fifo[port].notEmpty()) begin
        ParserState state <- toGet(parse_state_in_fifo[port]).get;
        sentOne = True;
        parse_state_out_fifo.enq(state);
      end
    end
  endrule

  Empty init_state <- mkStateParseStart(curr_state, data_in_fifo, start_fsm);
%(parse_state)s
%(connect_state)s
  rule start if (start_fsm);
    if (!started) begin
%(parse_start_states)s
      started <= True;
    end
  endrule

  rule stop if (!start_fsm && curr_state == StateParseStart);
    if (started) begin
%(parse_stop_states)s
      started <= False;
    end
  endrule
  interface frameIn = toPut(data_in_fifo);
  interface meta = toGet(metadata_out_fifo);
endmodule
'''
def generate_parse_top(states, json):
    ''' generate parser top module '''
    pmap = {}
    pmap['parse_state'] = expand_parse_state(1, json.parser)
    pmap['connect_state'] = expand_state_connection(1, json.parser)
    pmap['parse_start_states'] = expand_state_start(3, json.parser)
    pmap['parse_stop_states'] = expand_state_stop(3, json.parser)
    return PARSE_TOP_TEMPLATE % (pmap)

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
def generate_deparse_state(serializer, json):
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
    serializer.append(DEPARSE_STATE_TEMPLATE % pmap)

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
def generate_deparse_idle(serializer):
    serializer.append(DEPARSE_STATE_INIT)

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

TABLE_TEMPLATE = '''
interface %(name)s;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface

module mk%(name)s#(Client#(MetadataRequest, MetadataResponse) md)(%(name)s);
  let verbose = True;

  FIFO#(MetadataRequest) outReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) inRespFifo <- mkFIFO;

  MatchTable#(%(depth)s, SizeOf#(%(req)s), SizeOf#(%(resp)s)) matchTable <- mkMatchTable;

  rule handleRequest;
    let v <- md.request.get;
    case (v) matches
    endcase
  endrule

  rule handleResponse;

  endrule

  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(outReqFifo);
    interface response = toPut(inRespFifo);
  endinterface);
endmodule
'''
def generate_table(tbl):
    ''' TODO '''
    assert isinstance(tbl, Table)

    pmap = {'name': CamelCase(tbl.name),
            'depth': tbl.depth,
            'req': CamelCase(tbl.req_attrs['values']),
            'resp': CamelCase(tbl.resp_attrs['values'])}
    return  TABLE_TEMPLATE % (pmap)

METADATA_FIFO_TEMPLATE = '''\
  FIFO#(MetadataRequest) %(name)sReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) %(name)sRespFifo <- mkFIFO;'''

TABLE_INST_TEMPLATE = '''\
  %(type)s %(name)s <- mk%(type)s(toMetadataClient(%(name)sReqFifo, %(name)sRespFifo));'''

BB_INST_TEMPLATE = '''\
  %(type)s %(name)s <- mk%(type)s()'''

CONN_INST_TEMPLATE = '''\
  mkConnection(%(from)s, %(to)s);'''

COND_TEMPLATE = '''\
        if (%(expr)s) : begin
          MetadataRequest req = tagged %(Name)sLookupRequest {pkt: pkt, meta: meta};
          %(name)sReqFifo.enq(req);
        end'''

CONTROL_STATE_TEMPLATE = '''
  rule %(name)s_next_control_state:
    let v <- toGet(%(fifo)s).get;
    case (v) matches
      tagged %(type)s {pkt: .pkt, meta: .meta} : begin
%(cond)s
      end
    endcase
  endrule'''

CONTROL_FLOW_TEMPLATE = '''
interface %(name)s;
endinterface

module mk%(name)s#(Vector#(numClients, MetadataClient) mdc)(%(name)s);
  let verbose = True;
  FIFOF#(MetadataRequest) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  Vector#(numClients, MetadataServer) mds = newVector;
  for (Integer i=0; i<valueOf(numClients); i=i+1) begin
    mds[i] = (interface MetadataServer;
      interface Put request = toPut(defaultReqFifo);
      interface Get response = toGet(defaultRespFifo);
    endinterface);
  end
  mkConnection(mdc, mds);
%(meta_fifo)s
  function MetadataClient toMetadataClient(FIFO#(MetadataRequest) reqFifo,
                                           FIFO#(MetadataResponse) respFifo);
    MetadataClient ret_ifc;
    ret_ifc = (interface MetadataClient;
      interface Get request = toGet(reqFifo);
      interface Put response = toPut(respFifo);
    endinterface);
    return ret_ifc;
  endfunction
%(table)s

%(basic_block)s
%(connection)s

%(control_state)s
endmodule
'''
def generate_control_flow(control_flow):
    ''' TODO '''
    def generate_control_state(cond_list, control_states, moduleName=None, request=False):
        print 'controlstate', moduleName
        cond = []
        for item in cond_list:
            name = item[1][3:] #remove leading 'bb_'
            cond.append(COND_TEMPLATE%({'expr': item[0],
                                        'name': camelCase(name),
                                        'Name': CamelCase(name)}))

        if request:
            fifo = camelCase(moduleName) + 'ReqFifo'
            rtype = CamelCase(moduleName) + 'Request'
        else:
            fifo = camelCase(moduleName) + 'RespFifo'
            rtype = CamelCase(moduleName) + 'Response'

        control_states.append(\
            CONTROL_STATE_TEMPLATE%({'name': moduleName,
                                     'fifo': fifo,
                                     'type': rtype,
                                     'cond': '\n'.join(cond)}))

    pmap = {}
    pmap['name'] = CamelCase(control_flow.name)

    fifos = []
    tables = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            typename = CamelCase(block.local_table.name)
            instname = camelCase(block.local_table.name)
            inst = TABLE_INST_TEMPLATE % ({'name': instname, 'type': typename})
            fifo = METADATA_FIFO_TEMPLATE % ({'name': instname})
            tables.append(inst)
            fifos.append(fifo)
    pmap['meta_fifo'] = "\n".join(fifos)
    pmap['table'] = "\n".join(tables)

    blocks = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            continue
        if block.local_header:
            continue
        if block.instructions.instructions != []:
            blocks.append(BB_INST_TEMPLATE%({'type': CamelCase(block.name),
                                             'name': block.name}))
    pmap['basic_block'] = "\n".join(blocks)

    connections = []
    for table in control_flow.basic_blocks.values():
        if table.local_table:
            for idx, block in enumerate(table.control_state.basic_block):
                if block == '$done$':
                    continue
                from_node = "{}.{}_{}".format(camelCase(table.local_table.name),
                                              'next_control_state', idx)
                to_node = "{}.{}".format(block[1], 'prev_control_state')
                connections.append(CONN_INST_TEMPLATE%({'from': from_node,
                                                        'to': to_node}))
    pmap['connection'] = "\n".join(connections)

    fmap = OrderedDict() # map (table, [cond])
    tmap = {} # map (cond, table)
    control_states = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            for item in block.control_state.basic_block[:-1]:
                if block.local_table.name not in fmap:
                    fmap[block.local_table.name] = []
                fmap[block.local_table.name].append(item[1])
            continue
        if block.local_header:
            # ignore parse state
            continue

        for item in block.control_state.basic_block[:-1]:
            if block.name not in tmap:
                tmap[block.name] = []
            tmap[block.name].append(item)

    cond_list = control_flow.control_state.basic_block[:-1]
    generate_control_state(cond_list, control_states,
                           moduleName='default', request=True)

    for table, conditions in fmap.items():
        cond_list = [tmap[c] for c in conditions if c in tmap]
        for cond in cond_list:
            generate_control_state(cond, control_states, moduleName=table)
    pmap['control_state'] = "\n".join(control_states)
    return CONTROL_FLOW_TEMPLATE % pmap

ACTION_REG_READ_TEMPLATE = '''
  rule reg_add;
    // read reg
    // reg_val.first;
    // reg_val.deq;

    // modify reg
    // let newval = reg_val op;

    // write reg
    // reg_val.write;

    // next action
  endrule
'''

ACTION_REG_WRITE_TEMPLATE = '''
%(rule)s
'''

INTF_DECL_TEMPLATE = '''
%(intf)s
'''

INTF_IMPL_TEMPLATE = '''
%(intf)s
'''

RULE_TEMPLATE = '''
%(rule)s
%(join)s
'''

STATE_TEMPLATE = '''
%(reg)s
%(fifo)s
'''

MODULE_TEMPLATE = '''
module mk%(name)s(%(name)s);
%(state)s
%(rule)s
%(intf)s
endmodule
'''

# class Interface, __repr__
INTERFACE_TEMPLATE = '''
interface %(name)s
endinterface
'''

# class Module, __repr__
BASIC_BLOCK_TEMPLATE = '''
%(intf)s
%(module)s
'''

# AST.Interface
# AST.Param
# AST.Module
#   - name
#   - moduleContext
#   - interface -> class
#   - params -> class
#   - provisos ??
#   - decls ??
def generate_basic_block (block):
    ''' Each basic block is translated to a Module
        'moduleContext' is derived from BIR instruction
        'interface', by default, it provides an #Server interface,
            additional, register access interface can be added.
        'params', currently requires no parameters
        'provisos', currently requires no provisos
        'decls', methods, and interface declaration at the end
    '''
    pmap = {}
    pmap['intf'] = INTERFACE_TEMPLATE % {'name': CamelCase(block.name)}
    pmap['module'] = MODULE_TEMPLATE % {'name': CamelCase(block.name),
                                        'state': "",
                                        'rule': "",
                                        'intf': ""}
    return BASIC_BLOCK_TEMPLATE % pmap

"""
class.Interface
-- name
-- methods, decls
-- subinterfacename
subinterfacename = [Put#(Bit#(112)), Get#(Bit#(176)), Get#(Bit#(16))]
decls = [method start, method stop]
Interface(name, [], decls, subinterfacename, packagename)

functions = []
class.Function
-- name
-- return_type
-- params

class.Type: FIFO
-- name = unparsed_0
-- params = Bit#(16)

class.Type: Wire
-- name = packet_in_wire
-- params = Bit#(128)

fifos = []
wires = []
rules = []
methods = []

class.Module
-- name
-- params = [Reg#(ParserState), FIFO#(EtherData)]
-- decls = [FIFO, Wire, rule, method, interface]
-- provisos
"""


