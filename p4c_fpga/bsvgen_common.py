'''
Common template for bsv generation
'''

import re
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
defaultValue = %(name)s {
%(value)s
};
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
    typedef_values = []
    printf = []
    printv = []
    extract = []
    extract_template = '  Vector#({s}, Bit#(1)) {f} = takeAt({o}, dataVec);'
    pack = []

    width = sum([x for x in struct.fields.values()])

    offset = 0
    for field, size in struct.fields.items():
        typedef_fields.append('  Bit#({w}) {v}'.format(w=size,
                                                       v=field))
        typedef_values.append('  {v} : 0'.format(v=field))
        printf.append('{f}=%h'.format(f=field))
        printv.append('p.{v}'.format(v=field))
        extract.append(extract_template.format(s=size, f=field, o=offset))
        pack.append('  hdr.{f} = pack({f});'.format(f=field))
        offset += size

    pmap = {'name': CamelCase(struct.name),
            'field': ',\n'.join(typedef_fields),
            'value': ',\n'.join(typedef_values),
            'printf': ', '.join(printf),
            'printv': ', '.join(printv),
            'width': width,
            'extract': '\n'.join(extract),
            'pack': '\n'.join(pack)}
    return TYPEDEF_TEMPLATE % (pmap)

TABLE_TEMPLATE = '''
interface %(name)s
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

PARSE_PROLOG_TEMPLATE = '''
%(imports)s

'''
def generate_parse_prolog():
    ''' TODO '''
    pmap = {}
    import_modules = ["Connectable", "DefaultValue", "FIFO", "FIFOF", "FShow",
                      "GetPut", "List", "StmtFSM", "SpecicalFIFOs", "Vector",
                      "Ethernet"]
    pmap['imports'] = ";\n".join(["import {}::*".format(x) for x in import_modules])
    return PARSE_PROLOG_TEMPLATE % (pmap)


PARSE_STATE_TEMPLATE = '''
interface Parse%(name)s;
  %(intf_get)s
  method Action start;
  method Action clear;
endinterface
module mkStateParse%(name)s#(Reg#(ParserState) state, FIFO#(EtherData) datain)(Parse%(name)s);
  %(unparsed_fifo)s
  %(parsed_out_fifo)s
  Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
  Vector#(%(n)s, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
  PulseWire start_wire <- mkPulseWire();
  PulseWire stop_wire <- mkPulseWire();
  (* fire_when_enabled *)
  rule arbitrate_outgoing_state if (state == StateParse%(name)s);
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

  function ParserState compute_next_state(Bit#(%(width)s) v);
    ParserState nextState = StateStart;
    case (v) matches
      %(cases)s
    endcase
    return nextState;
  endfunction

  rule load_packet if (state == StateParse%(name)s);
    let data_current <- toGet(datain).get;
    packet_in_wire <= data_current.data;
  endrule

  Stmt parse_%(name)s =
  seq
  %(parseStep)s
  endseq;

  FSM fsm_parse_%(name)s <- mkFSM(parse_%(name)s);
  rule start_fsm if (start_wire);
    fsm_parse_%(name)s.start;
  endrule
  rule clear_fsm if (clear_wire);
    fsm_parse_%(name)s.abort;
  endrule
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
def generate_parse_state(node, width):
    ''' TODO '''
    pmap = {}

    bbnext = [x for x in node.control_state.basic_block]
    pmap['name'] = node.local_header.name

    tintf = "interface Get#(Bit#({}) parse_{});"
    pmap['intf_get'] = "\n".join([tintf.format(x, x) for x in bbnext])

    tfifo = "FIFOF#(Bit#{}) unparsed_parse_{}_fifo <- mkSizedFIFOF(1);"
    pmap['unparsed_fifo'] = "\n".join([tfifo.format(x, x) for x in bbnext])

    # only if output is required
    tout = "FIFOF#(Bit#({})) parsed_{}_fifo <- mkFIFOF;"
    outfield = []
    pmap['parsed_out_fifo'] = "\n".join([tout.format(x, x) for x in outfield])

    # next state
    pmap['n'] = 4

    print 'width', width
    pmap['width'] = width
    pmap['cases'] = ""
    pmap['parseStep'] = ""
    pmap['intf_unparsed'] = ""
    pmap['intf_parsed_out'] = ""
    return PARSE_STATE_TEMPLATE % (pmap)

PARSE_EPILOG_TEMPLATE = '''
typedef 4 PortMax;
(* synthesize *)
module mkParser(Parser);
  Reg#(ParserState) curr_state <- mkReg(StateStart);
  Reg#(Bool) started <- mkReg(False);
  FIFOF#(EtherData) data_in_fifo <- mkFIFOF;
  Wire#(Bool) start_fsm <- mkDWire(False);

  Vector#(PortMax, FIFOF#(ParserState)) parse_state_in_fifo <- replicateM(mkGFIFOF(False, True));
  FIFOF#(ParserState) parse_state_out_fifo <- mkFIFOF;

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
  %(parse_states)s
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
  %(intfs)s
endmodule
'''
def generate_parse_epilog():
    ''' TODO '''
    pmap = {}
    pmap['parse_states'] = ""
    pmap['connections'] = ""
    pmap['start_states'] = ""
    pmap['stop_states'] = ""
    pmap['intfs'] = ""
    return PARSE_EPILOG_TEMPLATE % (pmap)

