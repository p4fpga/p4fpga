'''
Common template for bsv generation
'''

import re
from dotmap import DotMap
from collections import OrderedDict
from pif_ir.bir.objects.bir_struct import BIRStruct
from pif_ir.bir.objects.table import Table
from AST import Function

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

def expand_metadata_request(indent, name):
    temp = []
    temp.append(spaces(indent) + "struct {")
    temp.append(spaces(indent+1) + "PacketInstance pkt;")
    temp.append(spaces(indent+1) + "MetadataT meta;")
    temp.append(spaces(indent) + "}} {}TableRequest;".format(CamelCase(name)))
    return "\n".join(temp)

def expand_metadata_response(indent, name):
    temp = []
    temp.append(spaces(indent) + "struct {")
    temp.append(spaces(indent+1) + "PacketInstance pkt;")
    temp.append(spaces(indent+1) + "MetadataT meta;")
    temp.append(spaces(indent) + "}} {}TableResponse;".format(CamelCase(name)))
    return "\n".join(temp)

METADATA_TYPED_UNION='''
typedef union tagged {
%(request)s
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } ForwardQueueRequest;
  struct {
    PacketInstance pkt;
    MetadataT meta;
  } DefaultRequest;
} MetadataRequest deriving (Bits, Eq, FShow);

typedef union tagged {
%(response)s
} MetadataResponse deriving (Bits, Eq, FShow);

typedef Client#(MetadataRequest, MetadataResponse) MetadataClient;
typedef Server#(MetadataRequest, MetadataResponse) MetadataServer;
'''
def generate_metadata_union(serializer, json):
    pmap = {}
    requests = []
    responses = []
    for x in json.table.keys():
        requests.append(expand_metadata_request(1, x))
        responses.append(expand_metadata_response(1, x))
    pmap['request'] = "\n".join(requests)
    pmap['response'] = "\n".join(responses)
    serializer.append(METADATA_TYPED_UNION % pmap)

def expand_basicblock_request(indent, name):
    temp = []
    temp.append(spaces(indent) + "struct {")
    temp.append(spaces(indent+1) + "PacketInstance pkt;")
    #FIXME
    temp.append(spaces(indent) + "}} {}Request;".format(CamelCase(name)))
    return "\n".join(temp)

def expand_basicblock_response(indent, name):
    temp = []
    temp.append(spaces(indent) + "struct {")
    temp.append(spaces(indent+1) + "PacketInstance pkt;")
    temp.append(spaces(indent) + "}} {}Response;".format(CamelCase(name)))
    return "\n".join(temp)

BASICBLOCK_TYPED_UNION='''
typedef union tagged {
%(request)s
} BBRequest deriving (Bits, Eq, FShow);

typedef union tagged {
%(response)s
} BBResponse deriving (Bits, Eq, FShow);

typedef Client#(BBRequest, BBResponse) BBClient;
typedef Server#(BBRequest, BBResponse) BBServer;
'''
def generate_basicblock_union(serializer, json):
    pmap = {}
    requests = []
    responses = []
    for x in json.basicblock.keys():
        if len(json.basicblock[x].local_table):
            continue
        requests.append(expand_basicblock_request(1, x))
        responses.append(expand_basicblock_response(1, x))
    pmap['request'] = "\n".join(requests)
    pmap['response'] = "\n".join(responses)
    serializer.append(BASICBLOCK_TYPED_UNION % pmap)


def build_ast_next_state():
    ''' ast node for next state function '''
    funct = Function(name="compute_next_state",
                     return_type="ParserState",
                     params=["Bit#(32) v"])
    print funct

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
    build_ast_next_state()

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

def expand_bb_client_decl(indent, json):
    temp = []
    for idx, _ in enumerate(json.next_control_state):
        temp.append(spaces(indent) + "interface BBClient next_control_state_{};".format(idx));
    return "\n".join(temp)

def expand_bb_client_methods(indent, json):
    temp = []
    for idx, _ in enumerate(json.next_control_state):
        temp.append(spaces(indent) + "interface next_control_state_{} = (interface BBClient;".format(idx))
        temp.append(spaces(indent+1) + "interface request = toGet(bbReqFifo[{}]);".format(idx))
        temp.append(spaces(indent+1) + "interface response = toPut(bbRespFifo[{}]);".format(idx))
        temp.append(spaces(indent) + "endinterface);")
    return "\n".join(temp)

def expand_table_api(indent, json):
    temp = []
    temp.append(spaces(indent) + "method Action {}({})");
    return "\n".join(temp)

def expand_table_response(indent, basicblock, json):
    temp = []
    for idx, next_state in enumerate(basicblock.next_control_state):
        temp.append(spaces(indent) + "{}: begin".format(next_state[1][3:].upper()))
        pmap={}
        pmap['requestType'] = CamelCase(next_state[1])
        table = basicblock.local_table
        responseType = json.table[table].responseType
        #FIXME
        fields = json.struct[responseType].field
        field_list = ['pkt: pkt']
        for field in fields:
            if field == 'p4_action':
                continue
            field_list.append("{}: resp.{}".format(field, field))
        pmap['fields'] = ", ".join(field_list)
        temp.append(spaces(indent+1) + "BBRequest req = tagged %(requestType)sRequest {%(fields)s};" % pmap)
        temp.append(spaces(indent+1) + "bbReqFifo[{}].enq(req);".format(idx))
        temp.append(spaces(indent) + "end")
    return "\n".join(temp)

def expand_bb_response(indent, tbl, json):
    temp = []
    for idx, next_state in enumerate(json.next_control_state):
        temp.append(spaces(indent) + "tagged {}Response {{}}: begin".format(CamelCase(next_state[1])))
        temp.append(spaces(indent+1) + "MetadataResponse resp = tagged {}TableResponse {{pkt: pkt, meta: meta}};".format(CamelCase(tbl.name)))
        temp.append(spaces(indent+1) + "md.response.put(resp);")
        temp.append(spaces(indent) + "end")
    return "\n".join(temp)

TABLE_TEMPLATE = '''

(* synthesize *)
module mkMatchTable_%(depth)s_%(name)sTable(MatchTable#(%(depth)s, SizeOf#(%(reqType)s), SizeOf#(%(respType)s)));
  MatchTable#(%(depth)s, SizeOf#(%(reqType)s), SizeOf#(%(respType)s)) ifc <- mkMatchTable();
  return ifc;
endmodule

interface %(name)sTable;
%(bb_client)s
%(table_api)s
endinterface

module mk%(CamelCaseName)sTable#(MetadataClient md)(%(CamelCaseName)sTable);
  let verbose = True;
  MatchTable#(%(depth)s, SizeOf#(%(reqType)s), SizeOf#(%(respType)s)) matchTable <- mkMatchTable_%(depth)s_%(CamelCaseName)sTable();
  Vector#(%(bbcount)s, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);
  Vector#(%(bbcount)s, FIFOF#(BBResponse)) bbRespFifo <- replicateM(mkFIFOF);
  Vector#(%(bbcount)s, Bool) readyBits = map(fifoNotEmpty, bbRespFifo);

  Bool interruptStatus = False;
  Bit#(16) readyChannel = -1;
  for (Integer i = %(bbcountMinusOne)s; i>=0; i=i-1) begin
    if (readyBits[i]) begin
      interruptStatus = True;
      readyChannel = fromInteger(i);
    end
  end

  FIFO#(PacketInstance) packetPipelineFifo <- mkFIFO;
  Vector#(2, FIFO#(MetadataT)) metadataPipelineFifo <- replicateM(mkFIFO);

  rule handle_%(CamelCaseName)s_request;
    let v <- md.request.get;
    case (v) matches
      tagged %(CamelCaseName)sTableRequest {pkt: .pkt, meta: .meta}: begin
%(tableRequest)s
        matchTable.lookupPort.request.put(pack(req));
        packetPipelineFifo.enq(pkt);
        metadataPipelineFifo[0].enq(meta);
      end
    endcase
  endrule

  rule handle_%(CamelCaseName)s_response;
    let v <- matchTable.lookupPort.response.get;
    let pkt <- toGet(packetPipelineFifo).get;
    let meta <- toGet(metadataPipelineFifo).get;
    if (v matches tagged Valid .data) begin
      %(respType)s resp = unpack(data);
      case (resp.p4_action) matches
%(p4_actions)s
      endcase
      meta.%(name)s$p4_action = tagged Valid resp.p4_action;
      metadataPipelineFifo[1].enq(meta);
    end
  endrule

  rule bb_response if (interruptStatus);
    let v <- toGet(bbRespFifo[readyChannel]).get;
    let meta <- toGet(metadataPipelineFifo[1]).get;
    case (v) matches
%(bb_actions)s
    endcase
  endrule
%(bb_client_methods)s
endmodule
'''
def generate_table(tbl, json):
    ''' generate basicblock for table '''
    assert isinstance(tbl, Table)
    pmap = {}
    pmap['name'] = tbl.name
    pmap['CamelCaseName'] = CamelCase(tbl.name)

    bb_clients = []
    for _, value in json.basicblock.items():
        if value.local_table == tbl.name:
            bb_clients.append(expand_bb_client_decl(1, value))
    pmap['bb_client'] = "\n".join(bb_clients)
    pmap['table_api'] = expand_table_api(1, json)
    pmap['depth'] =  tbl.depth
    pmap['reqType'] = CamelCase(tbl.req_attrs['values'])
    pmap['respType'] = CamelCase(tbl.resp_attrs['values'])
    pmap['bbcount'] = 2
    pmap['bbcountMinusOne'] = 1
    pmap['tableRequest'] = ""

    table_responses = []
    for _, basicblock in json.basicblock.items():
        if basicblock.local_table == tbl.name:
            table_responses.append(expand_table_response(4, basicblock, json))
    pmap['p4_actions'] = "\n".join(table_responses)

    bb_responses = []
    for _, value in json.basicblock.items():
        if value.local_table == tbl.name:
            bb_responses.append(expand_bb_response(3, tbl, value))
    pmap['bb_actions'] = "\n".join(bb_responses)

    bb_client_defs = []
    for name, value in json.basicblock.items():
        if value.local_table != tbl.name:
            continue
        bb_client_defs.append(expand_bb_client_methods(1, value))
    pmap['bb_client_methods'] = "\n".join(bb_client_defs)
    return  TABLE_TEMPLATE % (pmap)

def expand_metadata_fifo(indent, control_flow):
    temp = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            instname = camelCase(block.local_table.name)
            temp.append(spaces(indent) + "FIFO#(MetadataRequest) {}ReqFifo <- mkFIFO;".format(instname))
            temp.append(spaces(indent) + "FIFO#(MetadataResponse) {}RespFifo <- mkFIFO;".format(instname))
    return "\n".join(temp)

def expand_tables(indent, control_flow):
    TABLE_INST_TEMPLATE = '''%(type)sTable %(name)sTable <- mk%(type)sTable(toGPClient(%(name)sReqFifo, %(name)sRespFifo));'''
    temp = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            typename = CamelCase(block.local_table.name)
            instname = camelCase(block.local_table.name)
            inst = spaces(indent) + TABLE_INST_TEMPLATE % ({'name': instname, 'type': typename})
            temp.append(inst)
    return "\n".join(temp)

def expand_basic_block(indent, control_flow):
    BB_INST_TEMPLATE = '''%(type)s %(name)s <- mk%(type)s();'''
    temp = []
    for block in control_flow.basic_blocks.values():
        if block.local_table:
            continue
        if block.local_header:
            continue
        #if block.instructions.instructions != []:
        temp.append(spaces(indent) + BB_INST_TEMPLATE%({'type': CamelCase(block.name), 'name': block.name}))
    return "\n".join(temp)
 
def expand_connection(indent, control_flow):
    CONN_INST_TEMPLATE = '''mkConnection(%(from)s, %(to)s);'''
    temp = []
    for table in control_flow.basic_blocks.values():
        if table.local_table:
            for idx, block in enumerate(table.control_state.basic_block):
                if block == '$done$':
                    continue
                from_node = "{}Table.{}_{}".format(camelCase(table.local_table.name),
                                              'next_control_state', idx)
                to_node = "{}.{}".format(block[1], 'prev_control_state')
                temp.append(spaces(indent) + CONN_INST_TEMPLATE%({'from': from_node, 'to': to_node}))
    return "\n".join(temp)
 
def generate_default_control_state(indent, control_flow, json):
    temp = []
    temp.append(spaces(indent) + "rule default_next_control_state if (defaultReqFifo.first matches tagged DefaultRequest {pkt: .pkt, meta: .meta});")
    temp.append(spaces(indent+1) + "defaultReqFifo.deq;")
    for next_state in control_flow.control_state.basic_block:
        if next_state == "$done$":
            continue
        if isinstance(next_state, list):
            next_state = next_state[1]
        next_table = json.basicblock[next_state]
        temp.append(spaces(indent+1) + "MetadataRequest req = tagged {}TableRequest {{pkt: pkt, meta: meta}};".format(CamelCase(next_table.local_table)))
        temp.append(spaces(indent+1) + "{}ReqFifo.enq(req);".format(next_table.local_table))
    temp.append(spaces(indent) + "endrule")
    return "\n".join(temp)

def generate_table_control_state(indent, table, json):
    temp = []
    pmap = {}
    print table.local_table
    pmap['name'] = table.local_table
    pmap['CamelCaseName'] = CamelCase(table.local_table)
    temp.append(spaces(indent) + "rule %(name)s_next_control_state if (%(name)sRespFifo.first matches tagged %(CamelCaseName)sTableResponse {pkt: .pkt, meta: .meta});" % pmap)
    temp.append(spaces(indent+1) + "{}RespFifo.deq;".format(table.local_table))
    temp.append(spaces(indent+1) + "if (meta.{}$p4_action matches tagged Valid .data) begin".format(table.local_table))
    temp.append(spaces(indent+2) + "case (data) matches")
    for next_state in table.next_control_state:
        if next_state == "$done$":
            continue
        _, v = str.split(next_state[0], "==")
        temp.append(spaces(indent+3) + "{}: begin".format(v))
        temp.append(spaces(indent+4) + "MetadataRequest req = tagged ForwardQueueRequest {pkt: pkt, meta: meta};")
        temp.append(spaces(indent+4) + "currPacketFifo.enq(req);")
        temp.append(spaces(indent+3) + "end")
    temp.append(spaces(indent+2) + "endcase")
    temp.append(spaces(indent+1) + "end")
    temp.append(spaces(indent) + "endrule")
    return "\n".join(temp)

def expand_control_state(indent, control_flow, json):
    ''' Function to optmize for paxos '''
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

    # generate default Rule
    cond_list = control_flow.control_state.basic_block[:-1]
    control_states.append(generate_default_control_state(1, control_flow, json))

    # generate rule for each table
    for next_state in control_flow.control_state.basic_block:
        if next_state == "$done$":
            continue
        if isinstance(next_state, list):
            next_state = next_state[1]
        next_table = json.basicblock[next_state]
        control_states.append(generate_table_control_state(1, next_table, json))
    return "\n".join(control_states)

CONTROL_FLOW_TEMPLATE = '''
interface %(name)s;
  interface PipeOut#(MetadataRequest) eventPktSend;
endinterface

module mk%(name)s#(Vector#(numClients, MetadataClient) mdc)(%(name)s);
  let verbose = True;
  FIFOF#(MetadataRequest) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
%(meta_fifo)s
  Vector#(numClients, MetadataServer) mds = newVector;
  for (Integer i=0; i<valueOf(numClients); i=i+1) begin
    mds[i] = (interface MetadataServer;
      interface Put request = toPut(defaultReqFifo);
      interface Get response = toGet(defaultRespFifo);
    endinterface);
  end
  mkConnection(mdc, mds);
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
  interface eventPktSend = toPipeOut(currPacketFifo);
%(table_api)s
endmodule
'''
def generate_control_flow_top(control_flow, json):
    ''' generate control flow from json '''
    pmap = {}
    pmap['name'] = CamelCase(control_flow.name)
    pmap['meta_fifo'] = expand_metadata_fifo(1, control_flow)
    pmap['table'] = expand_tables(1, control_flow)
    pmap['basic_block'] = expand_basic_block(1, control_flow)
    pmap['connection'] = expand_connection(1, control_flow)
    pmap['control_state'] = expand_control_state(1, control_flow, json)
    pmap['table_api'] = ""
    return CONTROL_FLOW_TEMPLATE % pmap

def expand_bb_interface_decl(indent, json):
    temp = []
    temp.append(spaces(indent) + "interface BBServer prev_control_state;")
    return "\n".join(temp)

def expand_bb_instructions(indent, block, json):
    temp = []
    # differentiate V-type, R-type, O-type, M-type instructions
    temp.append(spaces(indent) + "let req <- toGet({}_request_fifo).get;".format(block.name))
    return "\n".join(temp)

def expand_v_type_request(indent, block, json):
    temp = []
    return "\n".join(temp)

def expand_v_type_response(indent, block, json):
    temp = []
    return "\n".join(temp)

def expand_o_type(indent, block, json):
    temp = []
    return "\n".join(temp)

def expand_r_type(indent, block, json):
    temp = []
    return "\n".join(temp)

def expand_m_type(indent, block, json):
    temp = []
    return "\n".join(temp)

def expand_bb_interface_defs(indent, block, json):
    temp = []
    temp.append(spaces(indent) + "interface prev_control_state = (interface BBServer;")
    temp.append(spaces(indent+1) + "interface request = toPut({}_request_fifo);".format(block.name))
    temp.append(spaces(indent+1) + "interface response = toGet({}_response_fifo);".format(block.name))
    temp.append(spaces(indent) + "endinterface);")
    return "\n".join(temp)

BASIC_BLOCK_TEMPLATE = '''
interface %(CamelCaseName)s;
%(prev_state_decl)s
endinterface
module mk%(CamelCaseName)s(%(CamelCaseName)s);
  FIFO#(BBRequest) %(name)s_request_fifo <- mkSizedFIFO(1);
  FIFO#(BBResponse) %(name)s_response_fifo <- mkSizedFIFO(1);
  FIFO#(PacketInstance) packetPipelineFifo <- mkSizedFIFO(1);

%(bypassFifo)s

  rule handle_bb_request;
%(instructions)s
    packetPipelineFifo.enq(pkt);
  endrule

  rule handle_bb_resp;
    let pkt <- toGet(packetPipelineFifo).get;
%(bbresponse)s
    %(name)s_response_fifo.enq(resp);
  endrule

%(prev_state_defs)s
endmodule
'''
def generate_basic_block (block, json):
    ''' TODO '''
    pmap = {}
    pmap['name'] = block.name
    pmap['CamelCaseName'] = CamelCase(block.name)
    pmap['prev_state_decl'] = expand_bb_interface_decl(1, json)
    pmap['bypassFifo'] = ""
    pmap['instructions'] = expand_bb_instructions(2, block, json)
    pmap['bbresponse'] = ""
    pmap['prev_state_defs'] = expand_bb_interface_defs(1, block, json)
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


