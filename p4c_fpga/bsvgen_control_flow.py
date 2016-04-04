'''
Control flow with bsv backend
'''

from pif_ir.bir.objects.control_flow import ControlFlow
from pif_ir.bir.utils.validate import check_control_state
from bsvgen_control_state import BSVControlState
from programSerializer import ProgramSerializer
from bsvgen_common import generate_parse_prolog, generate_parse_epilog,\
                          generate_parse_state

def dfs(global_bb, global_struct, serializer, node, stack, prev_bits, visited=None):
    '''
    TODO
    '''
    if not visited:
        visited = set()
    header = node.local_header.name
    visited.add(header)
    stack.append(header)

    curr_bits = prev_bits
    curr_bits += 128
    width = sum([x for _, x in global_struct[header].fields.items()])
    while curr_bits < width:
        curr_bits += 128

    serializer.append(generate_parse_state(node, width))

    for block in node.control_state.basic_block:
        if type(block) == str:
            continue
        next_header = global_bb[block[1]].control_state.header.name
        if next_header not in visited:
            next_bits = curr_bits - width
            print 'next_bits', next_header, stack[-1], next_bits
            dfs(global_bb, global_struct, serializer, global_bb[block[1]],
                stack, next_bits, visited)
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

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        stack = []
        if self.name == 'parser':
            serializer.append(generate_parse_prolog())
            basic_block = self.basic_blocks[self.control_state.basic_block[0]]
            dfs(self.basic_blocks, self.structs, serializer, basic_block, stack, 0)
            serializer.append(generate_parse_epilog())

#        offset, basic_block = self.control_state.bsvgen(serializer)
#
#        while basic_block:
#            #print "PROCESS: {}.{}".format(self.name, basic_block)
#            #print 'mmm', self.basic_blocks[basic_block]
#            offset, basic_block = self.basic_blocks[basic_block].bsvgen(serializer)
#        #self.next_processor.bsvgen()
#
#        #generate_parse_epilog()
