'''
Common template for bsv generation
'''

import re
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


TYPEDEF_TEMPLATE = '''
typedef struct {
%(field)s
} %(name)s deriving (Bits, Eq);

instance DefaultValue#(%(name)s);
  defaultValue = unpack(0);
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

PARSE_PROLOG_TEMPLATE = '''
%(imports)s
'''
def generate_parse_prolog():
    ''' TODO '''
    pmap = {}
    import_modules = ["Connectable", "DefaultValue", "FIFO", "FIFOF", "FShow",
                      "GetPut", "List", "StmtFSM", "SpecicalFIFOs", "Vector",
                      "Ethernet"]
    pmap['imports'] = "\n".join(["import {}::*;".format(x) for x in import_modules])
    return PARSE_PROLOG_TEMPLATE % (pmap)

COMPUTE_NEXT_STATE = '''
  function ParserState compute_next_state(Bit#(%(width)s) v);
    ParserState nextState = StateStart;
    case (v) matches
%(cases)s
      default: begin
        nextState = StateStart;
      end
    endcase
    return nextState;
  endfunction
'''
def func_comp_next_state(structmap, node):
    ''' TODO '''
    pmap = {}
    fmap = structmap[node.local_header.name].fields
    tcase = "      {}: begin\n        nextState = State{};\n      end"
    bbcase = [x for x in node.control_state.basic_block if type(x) is not str]
    if len(bbcase) == 0:
        return ""
    pmap['cases'] = "\n".join([tcase.format(str.split(x[0], '==')[1].strip(),
                                            CamelCase(x[1])) for x in bbcase])
    field = str.split(bbcase[0][0], '==')[0].strip()
    width = fmap[field]
    pmap['width'] = width
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
def apply_comp_next_state(node, getmap):
    ''' TODO '''
    smap = {}
    name = node.name
    bbcase = [x for x in node.control_state.basic_block if type(x) is not str]
    if len(bbcase) == 0:
        return "    next_state_wire[0] <= tagged Valid StateStart;"
    field = str.split(bbcase[0][0], '==')[0].strip()
    smap['field'] = field
    source = []
    if name in getmap:
        for state in getmap[name]:
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
def gen_parse_stmt(node, stepmap, getmap, putmap):
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
    for index, step in enumerate([stepmap[name][0]]):
        smap = reset_smap()
        if name in putmap:
            for cname, clen in putmap[name].items():
                smap['carry_in'] = carry_in.format('unparsed_'+cname)
            smap['concat'] = concat.format(step, ", data_last_cycle")
            smap['internal'] = internal.format(step)
        if len(stepmap[name]) == 1:
            smap['unpack'] = unpack.format(step)
            smap['extract'] = extract.format(CamelCase(header))
            carry_out_width = getmap[name].items()[0][1]
            smap['carry_out'] = carry_out.format(carry_out_width, 0)
            smap['next_state'] = apply_comp_next_state(node, getmap)
        source.append(STEP_TEMPLATE % smap)
    for index, step in enumerate(stepmap[name][1:-1]):
        smap = reset_smap()
        smap['carry_in'] = carry_in.format('internal_fifo_{}'.format(stepmap[name][index]))
        smap['concat'] = concat.format(step, ', data_last_cycle')
        smap['internal'] = internal.format(step)
        source.append(STEP_TEMPLATE % smap)
    last_step = (x for x in [stepmap[name][-1]] if len(stepmap[name]) > 1)
    for step in last_step:
        smap = reset_smap()
        smap['carry_in'] = carry_in.format('internal_fifo_{}'.format(stepmap[name][-2]))
        smap['concat'] = concat.format(step, ', data_last_cycle')
        smap['unpack'] = unpack.format(step)
        smap['extract'] = extract.format(name)
        smap['carry_out'] = carry_out.format(0, 0)
        smap['next_state'] = apply_comp_next_state(node, getmap)
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

PARSE_STATE_TEMPLATE = '''
interface %(name)s;
%(intf_put)s
%(intf_get)s
  method Action start;
  method Action clear;
endinterface
module mkState%(name)s#(Reg#(ParserState) state, FIFO#(EtherData) datain)(%(name)s);
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
  method Action start();
    start_wire.send();
  endmethod
  method Action stop();
    clear_wire.send();
  endmethod
%(intf_unparsed)s
%(intf_parsed_out)s
endmodule
'''
def generate_parse_state(node, structmap, getmap, putmap, stepmap):
    ''' TODO '''
    pmap = {}
    pmap['name'] = CamelCase(node.name)

    tput = "  interface Put#(Bit#({})) {};"
    tputmap = putmap[node.name] if node.name in putmap else {}
    pmap['intf_put'] = "\n".join([tput.format(v, x) for x, v in tputmap.items()])

    tget = "  interface Get#(Bit#({})) {};"
    tgetmap = getmap[node.name] if node.name in getmap else {}
    pmap['intf_get'] = "\n".join([tget.format(v, x) for x, v in tgetmap.items()])

    tfifo_in = "  FIFOF#(Bit#({})) unparsed_{}_fifo <- mkBypassFIFOF;"
    tfifo_out = "  FIFOF#(Bit#({})) unparsed_{}_fifo <- mkSizedFIFOF(1);"
    pmap['unparsed_in_fifo'] = "\n".join([tfifo_in.format(v, x) for x, v in tputmap.items()])
    pmap['unparsed_out_fifo'] = "\n".join([tfifo_out.format(v, x) for x, v in tgetmap.items()])

    # internal fifos
    tinternal = '  FIFOF#(Bit#({})) internal_fifo_{} <- mkSizedFIFOF(1);'
    pmap['internal_fifo'] = "\n".join([tinternal.format(x, x) for x in stepmap[node.name][:-1]])

    # only if output is required
    tout = "  FIFOF#(Bit#({})) parsed_{}_fifo <- mkFIFOF;"
    outfield = []
    pmap['parsed_out_fifo'] = "\n".join([tout.format(x, x) for x in outfield])

    # next state
    pmap['n'] = 4
    pmap['compute_next_state'] = func_comp_next_state(structmap, node)
    pmap['stmt'] = gen_parse_stmt(node, stepmap, getmap, putmap)
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
  Reg#(ParserState) curr_state <- mkReg(StateStart);
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

  Empty init_state <- mkStateStart(curr_state, data_in_fifo, start_fsm);
%(states)s
%(connections)s
  rule start if (start_fsm);
    if (!started) begin
%(start_states)s
      started <= True;
    end
  endrule

  rule clear if (!start_fsm && curr_state == StateStart);
    if (started) begin
%(stop_states)s
      started <= False;
    end
  endrule
  interface frameIn = toPut(data_in_fifo);
  interface meta = toGet(metadata_out_fifo);
endmodule
'''
def generate_parse_epilog(states, putmap):
    ''' TODO '''
    pmap = {}
    tstates = '  {} {} <- mkState{}(curr_state, data_in_fifo);'
    pmap['states'] = "\n".join([tstates.format(CamelCase(x), x, CamelCase(x))
                                for x in states])
    tconn = '  mkConnection({a}.{b}, {b}.{a});'
    conn = []
    for start, endp in putmap.items():
        for end, _ in endp.items():
            conn.append(tconn.format(a=start, b=end))
    pmap['connections'] = "\n".join(conn)
    tstart = '      {}.start;'
    pmap['start_states'] = "\n".join([tstart.format(x) for x in states])
    tstop = '      {}.stop;'
    pmap['stop_states'] = "\n".join([tstop.format(x) for x in states])
    return PARSE_EPILOG_TEMPLATE % (pmap)

TABLE_TEMPLATE = '''
interface %(name)s;
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface

module mk%(name)s#(Client#(MetadataRequest, MetadataResponse) md)(%(name)s);
  let verbose = True;

  FIFO#(MetadataRequest) outReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) inRespFifo <- mkFIFO;

  MatchTable#(%(depth)s, %(req)s, %(resp)s) matchTable <- mkMatchTable;

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
  FIFOF#(PacketInstance) currPacketFifo <- mkFIFOF;
  FIFO#(MetadataRequest) defaultReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) defaultRespFifo <- mkFIFO;
  Vector#(numClients, MetadataServer) mds = newVector;
  for (Integer i=0; i<valueOf(numClients); i=i+1) begin
    metadataServers[i] = (interface MetadataServer;
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
    pmap['intf'] = INTERFACE_TEMPLATE % {'name': block.name}
    pmap['module'] = MODULE_TEMPLATE % {'name': block.name,
                                        'state': "",
                                        'rule': "",
                                        'intf': ""}
    return BASIC_BLOCK_TEMPLATE % pmap

