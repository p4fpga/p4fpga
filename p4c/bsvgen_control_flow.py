'''
Control flow with bsv backend
'''

from pif_ir.bir.objects.control_flow import ControlFlow
from pif_ir.bir.utils.validate import check_control_state
from bsvgen_control_state import BSVControlState
from programSerializer import ProgramSerializer
from bsvgen_common import generate_parse_epilog,\
                          generate_parse_state, generate_control_flow, \
                          generate_parse_state_enum, generate_parse_state_init, \
                          generate_deparse_state_enum, \
                          generate_deparse_state, generate_deparse_top, \
                          generate_deparse_idle
import pprint


def json_parser_compute_next_state(structmap, node, json):
    ''' populate json with next state info '''
    fmap = structmap[node.local_header.name].fields
    bbcase = [x for x in node.control_state.basic_block if type(x) is not str]
    print bbcase
    if len(bbcase) == 0:
        return
    print 'init'
    json.parser[node.name].compute_next_state['cases'] = bbcase
    field = str.split(bbcase[0][0], '==')[0].strip()
    width = fmap[field]
    json.parser[node.name].compute_next_state['width'] = width

def parse_dfs(bbmap, structmap, node, stack, prev_bits, visited, json):
    '''
    should run during json_serialize stage.
    DFS to fill codegen data struct
    walk parse tree to collect required info for bsv
    '''
    visited.add(node.name)
    stack.append(node.name)

    curr_bits = prev_bits
    curr_bits += 128

    header = node.local_header.name
    width = sum([x for _, x in structmap[header].fields.items()])

    json_parser_compute_next_state(structmap, node, json)

    if not json.parser[node.name].parse_step:
        json.parser[node.name].parse_step = []

    while curr_bits < width:
        json.parser[node.name].parse_step.append(curr_bits)
        curr_bits += 128
    json.parser[node.name].parse_step.append(curr_bits)

    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            next_bits = curr_bits - width
            #print 'next_bits', next_header, stack[-1], next_bits
            if not json.parser[stack[-1]].intf_get:
                json.parser[stack[-1]].intf_get = {}
            json.parser[next_header].intf_put[stack[-1]] = next_bits
            json.parser[stack[-1]].intf_get[next_header] = next_bits
            parse_dfs(bbmap, structmap, bbmap[block[1]], stack, next_bits, visited, json)
    stack.pop()

def generate_parse_body(serializer, json, bbmap, structmap, node, stack, visited=None):
    ''' walk parser tree '''
    if visited is None:
        visited = set()
    visited.add(node.name)
    stack.append(node.name)
    serializer.append(generate_parse_state(node, structmap, json))
    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            generate_parse_body(serializer, json, bbmap, structmap, bbmap[block[1]], stack, visited)
    stack.pop()

def json_deparser_compute_next_state(structmap, node, json):
    ''' populate json with next state info '''
    fmap = structmap[node.local_header.name].fields
    bbcase = [x for x in node.control_state.basic_block if type(x) is not str]
    if len(bbcase) == 0:
        return
    json.deparser[node.name].compute_next_state['cases'] = bbcase
    field = str.split(bbcase[0][0], '==')[0].strip()
    width = fmap[field]
    json.deparser[node.name].compute_next_state['width'] = width

def deparse_dfs(bbmap, structmap, node, stack, prev_bits, visited, json):
    '''
    should run during serialize_json stage.
    DFS to fill codegen data struct
    walk parse tree to collect required info for bsv
    '''
    visited.add(node.name)
    stack.append(node.name)

    curr_bits = prev_bits
    if not json.deparser[node.name].deparse_step:
        json.deparser[node.name].deparse_step = []
    if curr_bits != 0:
        json.deparser[node.name].deparse_step.append(curr_bits)

    header = node.local_header.name
    width = sum([x for _, x in structmap[header].fields.items()])

    json_deparser_compute_next_state(structmap, node, json)

    while curr_bits < width:
        curr_bits += 128
        json.deparser[node.name].deparse_step.append(128) #FIXME
        #print 'nnn', node.name, curr_bits, width

    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            next_bits = curr_bits - width
            #print 'next_bits', next_header, stack[-1], next_bits
            json.deparser[next_header].intf_put[stack[-1]] = next_bits
            json.deparser[stack[-1]].intf_get[next_header] = next_bits
            deparse_dfs(bbmap, structmap, bbmap[block[1]], stack, next_bits, visited, json)
    stack.pop()

def generate_deparse_body(serializer, json, bbmap, node, stack, visited=None):
    ''' walk deparser tree '''
    if visited is None:
        visited = set()
    visited.add(node.name)
    stack.append(node.name)
    generate_deparse_state(serializer, json.deparser[node.name])
    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header in visited:
            continue
        generate_deparse_body(serializer, json, bbmap, bbmap[block[1]], stack, visited)
    stack.pop()

class BSVControlFlow(ControlFlow):
    ''' TODO '''
    def __init__(self, name, control_flow_attrs, basic_blocks, structs, bir_parser):
        super(BSVControlFlow, self).__init__(name, control_flow_attrs, basic_blocks, bir_parser)
        cf = control_flow_attrs['start_control_state']
        check_control_state(self.name, cf)
        self.control_state = BSVControlState(cf, None, bir_parser)
        self.structs = structs

    def generate_deparser(self, serializer, json):
        ''' TODO: move dfs to serialize '''
        stack = []
        visited = set()
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        deparse_dfs(self.basic_blocks, self.structs, start_block, stack, 0, visited, json)
        serializer.append(generate_deparse_state_enum(json))
        generate_deparse_idle(serializer)
        generate_deparse_body(serializer, json, self.basic_blocks, start_block, [], set())
        serializer.append(generate_deparse_top(0, json))

    def generate_parser(self, serializer, json):
        ''' TODO: move dfs to serialize '''
        stack = []
        visited = set()
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        json.control_flow.parser.start = start_block.name
        parse_dfs(self.basic_blocks, self.structs, start_block, stack, 0, visited, json)
        serializer.append(generate_parse_state_enum(json))
        serializer.append(generate_parse_state_init(json))
        generate_parse_body(serializer, json, self.basic_blocks, self.structs, start_block, [])
        serializer.append(generate_parse_epilog(visited, json))

    def bsvgen(self, serializer, json):
        ''' generate control flow from json '''
        assert isinstance(serializer, ProgramSerializer)
        if self.name == 'parser':
            self.generate_parser(serializer, json)
        elif self.name == 'deparser':
            self.generate_deparser(serializer, json)
        else:
            serializer.append(generate_control_flow(self))
            #self.next_processor.bsvgen()

