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
} %(name)s deriving (Bits, Eq);

instance DefaultValue#(%(name)s);
  defaultValue = unpack(0);
endinstance
instance DefaultMask#(%(name)s);
  defaultMask = unpack(maxBound);
endinstance

instance FShow#(%(name)s);
  function Fmt fshow(%(name)s p);
    return $format("%(name)s: %(printf)s", %(printv)s);
  endfunction
endinstance

function %(name)s extract_%(name)s(Bit#(%(width)s) data);
  Vector#(%(width)s, Bit#(1)) dataVec = unpack(data);
%(extract)s
  %(name)s hdr = defaultValue;
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

    pmap = {'name': CamelCase(struct.name),
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
        print value, state
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

FSM_TEMPLATE = '''
  Stmt stmt_%(name)s =
  seq
%(parse_step)s
  endseq;
  FSM fsm_%(name)s <- mkFSM(stmt_%(name)s);
  rule start_fsm if (start_wire);
    fsm_%(name)s.start;
  endrule
  rule clear_fsm if (clear_wire);
    fsm_%(name)s.abort;
  endrule
'''
IF_NEXT_STATE_TEMPLATE = '''\
    if (nextState == State%(next_state)s) begin
      unparsed_%(parse_state)s_fifo.enq(pack(unparsed));
    end'''
NEXT_STATE_TEMPLATE = '''\
    let nextState = compute_next_state(hdr.%(field)s);
    if (verbose) $display("Goto state ", nextState);
%(ifnext)s
    next_state_wire[0] <= tagged Valid nextState;'''
def apply_comp_next_state(node, intf_get):
    ''' TODO '''
    smap = {}
    name = node.name
    bbcase = [x for x in node.control_state.basic_block if type(x) is not str]
    if len(bbcase) == 0:
        return "    next_state_wire[0] <= tagged Valid StateParseStart;"
    field = str.split(bbcase[0][0], '==')[0].strip()
    smap['field'] = field
    source = []
    if name in intf_get:
        for state in intf_get[name]:
            source.append(IF_NEXT_STATE_TEMPLATE % {'next_state': CamelCase(state),
                                                    'parse_state': state})
    smap['ifnext'] = "\n".join(source)
    return NEXT_STATE_TEMPLATE % smap
STEP_TEMPLATE = '''  action
    let data_this_cycle = packet_in_wire;
%(carry_in)s%(concat)s%(internal)s%(unpack)s%(extract)s%(carry_out)s%(next_state)s
  endaction'''
def reset_smap():
    smap = {}
    smap['carry_in'] = ""
    smap['concat'] = ""
    smap['internal'] = ""
    smap['unpack'] = ""
    smap['extract'] = ""
    smap['carry_out'] = ""
    smap['next_state'] = ""
    return smap
def gen_parse_stmt(node, json):
    ''' expand parser state machine into bluespec '''
    pmap = {}
    name = node.name
    header = node.local_header.name
    pmap['name'] = name
    source = []
    carry_in = '    let data_last_cycle <- toGet({}).get;\n'
    concat = '    Bit#({}) data = {{data_this_cycle{}}};\n'
    internal = '    internal_fifo_{}.enq(data);\n'
    unpack = '    Vector#({}, Bit#(1)) dataVec = unpack(data);\n'
    extract = '    let hdr = extract_{}(pack(takeAt(0, dataVec)));\n    $display(fshow(hdr));\n'
    carry_out = '    Vector#({}, Bit#(1)) unparsed = takeAt({}, dataVec);\n'
    print 'xxx', json.parser[name].parse_step
    for index, step in enumerate(json.parser[name].parse_step):
        smap = reset_smap()
        if name in json.parser[name].intf_put:
            for cname, clen in json.parser[name].intf_put.items():
                smap['carry_in'] = carry_in.format('unparsed_'+cname+'_fifo')
            smap['concat'] = concat.format(step, ", data_last_cycle")
            smap['internal'] = internal.format(step)
        if len(json.parser[name].parse_step) == 1:
            smap['unpack'] = unpack.format(step)
            smap['extract'] = extract.format(CamelCase(header))
            carry_out_width = json.parser[name].intf_get.items()[0][1]
            smap['carry_out'] = carry_out.format(carry_out_width, 0)
            smap['next_state'] = apply_comp_next_state(node, json.parser[name].intf_get)
        source.append(STEP_TEMPLATE % smap)
    for index, step in enumerate(json.parser[name].parse_step[1:-1]):
        smap = reset_smap()
        smap['carry_in'] = carry_in.format('internal_fifo_{}'.format(json.parser[name].parse_step[index]))
        smap['concat'] = concat.format(step, ', data_last_cycle')
        smap['internal'] = internal.format(step)
        source.append(STEP_TEMPLATE % smap)
    last_step = (x for x in [json.parser[name].parse_step[-1]] if len(json.parser[name].parse_step) > 1)
    for step in last_step:
        smap = reset_smap()
        smap['carry_in'] = carry_in.format('internal_fifo_{}'.format(json.parser[name].parse_step[-2]))
        smap['concat'] = concat.format(step, ', data_last_cycle')
        smap['unpack'] = unpack.format(step)
        smap['extract'] = extract.format(CamelCase(header))
        smap['carry_out'] = carry_out.format(0, 0)
        smap['next_state'] = apply_comp_next_state(node, json.parser[name].intf_get)
        source.append(STEP_TEMPLATE % smap)
    pmap['parse_step'] = "\n".join(source)
    return FSM_TEMPLATE % pmap

"""
class.Interface
-- name
-- methods, decls
-- subinterfacename
subinterfacename = [Put#(Bit#(112)), Get#(Bit#(176)), Get#(Bit#(16))]
decls = [method start, method clear]
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

PARSE_STATE_TEMPLATE = '''
interface %(name)s;
%(intf_put)s
%(intf_get)s
  method Action start;
  method Action stop;
endinterface
module mkState%(name)s#(Reg#(ParserState) state, FIFOF#(EtherData) datain)(%(name)s);
  let verbose = False;
%(unparsed_in_fifo)s
%(unparsed_out_fifo)s
%(internal_fifo)s
%(parsed_out_fifo)s
  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(%(n)s, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire clear_wire <- mkPulseWire();
  (* fire_when_enabled *)
  rule arbitrate_outgoing_state if (state == State%(name)s);
    Vector#(%(n)s, Bool) next_state_valid = replicate(False);
    Bool stateSet = False;
    for (Integer port=0; port<%(n)s; port=port+1) begin
      next_state_valid[port] = isValid(next_state_wire[port]);
      if (!stateSet && next_state_valid[port]) begin
        stateSet = True;
        ParserState next_state = fromMaybe(?, next_state_wire[port]);
        state <= next_state;
      end
    end
  endrule
%(compute_next_state)s
  rule load_packet if (state == State%(name)s);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
  endrule
%(stmt)s
  method start = start_wire.send;
  method stop = clear_wire.send;
%(intf_unparsed)s
%(intf_parsed_out)s
endmodule
'''
def generate_parse_state(node, structmap, json):
    ''' expand json configuration into bluespec
    TODO: break down to smaller pieces
    '''
    pmap = {}
    pmap['name'] = CamelCase(node.name)

    tput = "  interface Put#(Bit#({})) {};"
    tputmap = json.parser[node.name].intf_put
    pmap['intf_put'] = "\n".join([tput.format(v, x) for x, v in tputmap.items()])

    tget = "  interface Get#(Bit#({})) {};"
    tgetmap = json.parser[node.name].intf_get
    pmap['intf_get'] = "\n".join([tget.format(v, x) for x, v in tgetmap.items()])

    tfifo_in = "  FIFOF#(Bit#({})) unparsed_{}_fifo <- mkBypassFIFOF;"
    tfifo_out = "  FIFOF#(Bit#({})) unparsed_{}_fifo <- mkSizedFIFOF(1);"
    pmap['unparsed_in_fifo'] = "\n".join([tfifo_in.format(v, x) for x, v in tputmap.items()])
    pmap['unparsed_out_fifo'] = "\n".join([tfifo_out.format(v, x) for x, v in tgetmap.items()])

    # internal fifos
    tinternal = '  FIFOF#(Bit#({})) internal_fifo_{} <- mkSizedFIFOF(1);'
    pmap['internal_fifo'] = "\n".join([tinternal.format(x, x) for x in json.parser[node.name].parse_step[:-1]])

    # only if output is required
    tout = "  FIFOF#(Bit#({})) parsed_{}_fifo <- mkFIFOF;"
    outfield = []
    pmap['parsed_out_fifo'] = "\n".join([tout.format(x, x) for x in outfield])

    # next state
    pmap['n'] = 4
    pmap['compute_next_state'] = expand_next_state(0, 'Parser', json.parser[node.name])
    pmap['stmt'] = gen_parse_stmt(node, json)
    tunparse = "  interface {} = toGet(unparsed_{}_fifo);"
    pmap['intf_unparsed'] = "\n".join([tunparse.format(x, x) for x in tgetmap])
    pmap['intf_parsed_out'] = ""
    return PARSE_STATE_TEMPLATE % (pmap)

PARSE_EPILOG_TEMPLATE = '''
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
%(states)s
%(connections)s
  rule start if (start_fsm);
    if (!started) begin
%(start_states)s
      started <= True;
    end
  endrule

  rule clear if (!start_fsm && curr_state == StateParseStart);
    if (started) begin
%(stop_states)s
      started <= False;
    end
  endrule
  interface frameIn = toPut(data_in_fifo);
  interface meta = toGet(metadata_out_fifo);
endmodule
'''
def generate_parse_epilog(states, json):
    ''' TODO '''
    pmap = {}
    tstates = '  {} {} <- mkState{}(curr_state, data_in_fifo);'
    pmap['states'] = "\n".join([tstates.format(CamelCase(x), x, CamelCase(x))
                                for x in states])
    tconn = '  mkConnection({a}.{b}, {b}.{a});'
    conn = []
    for start, item in json.parser.items():
        for end, _ in item.intf_put.items():
            conn.append(tconn.format(a=start, b=end))
    pmap['connections'] = "\n".join(conn)
    tstart = '      {}.start;'
    pmap['start_states'] = "\n".join([tstart.format(x) for x in states])
    tstop = '      {}.stop;'
    pmap['stop_states'] = "\n".join([tstop.format(x) for x in states])
    return PARSE_EPILOG_TEMPLATE % (pmap)

#FIXME: need to encapsulate to deparser

def apply(temp, json):
    return [temp.format(v, x) for x, v in json.items()]

def spaces(indent):
    return ' ' * 2 * indent

def expand_intf_put(indent, json):
    temp = spaces(indent) + "interface Put#(EtherData) {};"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_intf_get(indent, json):
    temp = spaces(indent) + "interface Get#(EtherData) {};"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_data_in(indent, json):
    temp = spaces(indent) + "FIFOF#(EtherData) {}_fifo <- mkBypassFIFOF;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_data_out(indent, json):
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
def expand_statement(indent, json):
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
  method Action clear;
endinterface
module mkState%(CamelCaseName)s#(Reg#(DeparserState) state, FIFOF#(EtherData) datain, FIFOF#(EtherData) dataout, FIFOF#(%(headertype)s) meta_fifo, FIFOF#(%(headertype)s) mask_fifo)(%(CamelCaseName)s);
  let verbose = False;
  Wire#(EtherData) packet_in_wire <- mkDWire(defaultValue);
%(data_in_fifo)s
%(data_out_fifo)s
  PulseWire start_wire <- mkPulseWire;
  PulseWire clear_wire <- mkPulseWire;
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
  rule clear_fsm if (clear_wire);
    fsm_%(name)s.abort;
  endrule
  method start = start_wire.send;
  method clear = clear_wire.send;
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
    pmap['intf_put'] = expand_intf_put(1, json.intf_put)
    pmap['intf_get'] = expand_intf_get(1, json.intf_get)
    pmap['data_in_fifo'] = expand_data_in(1, json.intf_put)
    pmap['data_out_fifo'] = expand_data_out(1, json.intf_get)
    pmap['compute_next_state'] = expand_next_state(1, "Deparser", json)
    pmap['statement'] = expand_statement(1, json)
    pmap['intf_data_out'] = ""
    pmap['intf_ctrl_out'] = ""
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

def expand_deparse_state(indent, json):
    temp = spaces(indent) + "{C} {c} <- mkState{C}(curr_state, data_in_fifo, data_out_fifo, {c}_meta_fifo, {c}_mask_fifo);"
    return "\n".join([temp.format(C=CamelCase(x), c=x) for x, _ in json.items()])

def expand_connect_deparse_state(indent, json):
    connections = []
    temp = spaces(indent) + "mkConnection({a}.{b}, {b}.{a});"
    for state, values in json.items():
        for conn in values.intf_get.keys():
            connections.append(temp.format(a=state, b=conn))
    return "\n".join(connections)

def expand_deparse_state_start(indent, json):
    temp = spaces(indent) + "{}.start;"
    return "\n".join([temp.format(x) for x, _ in json.items()])

def expand_deparse_state_stop(indent, json):
    temp = spaces(indent) + "{}.clear;"
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
  rule clear if (!start_fsm && curr_state == StateDeparseIdle);
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
    pmap["meta_in_fifo"] = ""
    pmap["mask_in_fifo"] = ""
    pmap["metadata_func"] = ""
    pmap["deparse_state"] = expand_deparse_state(indent + 1, json.deparser)
    pmap["connect_state"] = expand_connect_deparse_state(indent + 1, json.deparser)
    pmap["deparse_state_start"] = expand_deparse_state_start(indent + 3, json.deparser)
    pmap["deparse_state_stop"] = expand_deparse_state_stop(indent + 3, json.deparser)
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

