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

def dfs(bbmap, structmap, node, stack, prev_bits, visited, getmap, putmap, parse_step):
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

    if node.name not in parse_step:
        parse_step[node.name] = []

    while curr_bits < width:
        # parse_step
        parse_step[node.name].append(curr_bits)
        curr_bits += 128
    parse_step[node.name].append(curr_bits)

    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            next_bits = curr_bits - width
            #print 'next_bits', next_header, stack[-1], next_bits
            if next_header not in putmap:
                putmap[next_header] = {}
            if stack[-1] not in getmap:
                getmap[stack[-1]] = {}
            putmap[next_header][stack[-1]] = next_bits
            getmap[stack[-1]][next_header] = next_bits
            dfs(bbmap, structmap, bbmap[block[1]], stack,
                next_bits, visited, getmap, putmap, parse_step)
    stack.pop()

def generate_parse_body(bbmap, structmap, serializer, node, stack, getmap, putmap,
                        stepmap, visited=None):
    ''' walk parser tree '''
    if not visited:
        visited = set()
    visited.add(node.name)
    stack.append(node.name)
    serializer.append(generate_parse_state(node, structmap, getmap, putmap, stepmap))
    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = bbmap[block[1]].name
        if next_header not in visited:
            generate_parse_body(bbmap, structmap, serializer, bbmap[block[1]],
                                stack, getmap, putmap, stepmap, visited)
    stack.pop()

def generate_deparse_body(serializer, json, bbmap, node, stack, visited=None):
    ''' walk deparser tree '''
    if not visited:
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
    '''
    TODO
    '''
    def __init__(self, name, control_flow_attrs, basic_blocks, structs, bir_parser):
        super(BSVControlFlow, self).__init__(name, control_flow_attrs,
                                             basic_blocks, bir_parser)
        cf = control_flow_attrs['start_control_state']
        check_control_state(self.name, cf)
        self.control_state = BSVControlState(cf, None, bir_parser)
        self.structs = structs

    def generate_deparser(self, serializer, json):
        # first state
        stack = []
        visited = set()
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        generate_deparse_body(serializer, json, self.basic_blocks, start_block, stack, visited)
        #generate_deparse_top(serializer, json)
        serializer.append(generate_deparse_top())

    def generate_parser(self, serializer, json):
        stack = []
        visited = set()
        #FIXME: remove
        putmap = {}
        getmap = {}
        stepmap = {}
        start_block = self.basic_blocks[self.control_state.basic_block[0]]
        dfs(self.basic_blocks, self.structs, start_block, stack,
            0, visited, getmap, putmap, stepmap)
        generate_parse_body(self.basic_blocks, self.structs,
                            serializer, start_block, [],
                            getmap, putmap, stepmap)
        serializer.append(generate_parse_epilog(visited, putmap))

    def bsvgen(self, serializer, json):
        ''' generate control flow from json '''
        assert isinstance(serializer, ProgramSerializer)
        if self.name == 'parser':
            self.generate_parser(serializer, json)
        elif self.name == 'deparser':
            self.generate_deparser(serializer, json)
        else:
            print 'xxx', self.name, self.control_state
            serializer.append(generate_control_flow(self))
            #self.next_processor.bsvgen()

