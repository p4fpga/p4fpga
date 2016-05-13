'''
Control flow with bsv backend
'''

from pif_ir.bir.objects.control_flow import ControlFlow
from pif_ir.bir.utils.validate import check_control_state
from bsvgen_control_state import BSVControlState
from programSerializer import ProgramSerializer
from bsvgen_common import generate_parse_epilog,\
                          generate_parse_state, generate_control_flow, \
                          generate_deparse_state, generate_deparse_top
import pprint

def parse_dfs(bbmap, structmap, node, stack, prev_bits, visited, json):
    '''
    DFS to fill codegen data struct
    walk parse tree to collect required info for bsv
    '''
    visited.add(node.name)
    stack.append(node.name)

    curr_bits = prev_bits
    curr_bits += 128

    header = node.local_header.name
    width = sum([x for _, x in structmap[header].fields.items()])

    if node.name not in json.parse_step:
        json.parse_step[node.name] = []

    while curr_bits < width:
        json.parse_step[node.name].append(curr_bits)
        curr_bits += 128
    json.parse_step[node.name].append(curr_bits)

    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            next_bits = curr_bits - width
            #print 'next_bits', next_header, stack[-1], next_bits
            if next_header not in json.putmap:
                json.putmap[next_header] = {}
            if stack[-1] not in json.getmap:
                json.getmap[stack[-1]] = {}
            json.putmap[next_header][stack[-1]] = next_bits
            json.getmap[stack[-1]][next_header] = next_bits
            parse_dfs(bbmap, structmap, bbmap[block[1]], stack,
                next_bits, visited, json)
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

def deparse_dfs(bbmap, structmap, node, stack, prev_bits, visited, json):
    '''
    DFS to fill codegen data struct
    walk parse tree to collect required info for bsv
    '''
    visited.add(node.name)
    stack.append(node.name)

    curr_bits = prev_bits
    if node.name not in json.deparse_step:
        json.deparse_step[node.name] = []
    if curr_bits != 0:
        json.deparse_step[node.name].append(curr_bits)

    header = node.local_header.name
    width = sum([x for _, x in structmap[header].fields.items()])

    while curr_bits < width:
        curr_bits += 128
        json.deparse_step[node.name].append(128) #FIXME
        print 'nnn', node.name, curr_bits, width

    print 'nnn deparsestep', json.deparse_step
    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        print 'nnn next header', next_header
        print 'nnn visited', visited
        if next_header not in visited:
            next_bits = curr_bits - width
            print 'next_bits', next_header, stack[-1], next_bits
            if next_header not in json.putmap:
                json.putmap[next_header] = {}
            if stack[-1] not in json.getmap:
                json.getmap[stack[-1]] = {}
            json.putmap[next_header][stack[-1]] = next_bits
            json.getmap[stack[-1]][next_header] = next_bits
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
        super(BSVControlFlow, self).__init__(name, control_flow_attrs,
                                             basic_blocks, bir_parser)
        cf = control_flow_attrs['start_control_state']
        check_control_state(self.name, cf)
        self.control_state = BSVControlState(cf, None, bir_parser)
        self.structs = structs

    def generate_deparser(self, serializer, json):
        stack = []
        visited = set()
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        deparse_dfs(self.basic_blocks, self.structs, start_block, stack, 0, visited, json)
        print 'vvv', json.getmap
        print 'vvv', json.putmap
        generate_deparse_body(serializer, json, self.basic_blocks, start_block, stack, visited)
        serializer.append(generate_deparse_top())

    def generate_parser(self, serializer, json):
        stack = []
        visited = set()
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        parse_dfs(self.basic_blocks, self.structs, start_block, stack, 0, visited, json)
        generate_parse_body(serializer, json, self.basic_blocks, self.structs, start_block, [])
        serializer.append(generate_parse_epilog(visited, json.putmap))

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

