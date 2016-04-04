'''
Basic block with bsv backend
'''

from pif_ir.bir.objects.basic_block import BasicBlock
from pif_ir.bir.utils.validate import check_control_state

from bsvgen_control_state import BSVControlState
from programSerializer import ProgramSerializer

class BSVBasicBlock(BasicBlock):
    ''' TODO '''
    def __init__(self, name, bb_attrs, bir_headers, bir_tables,
                 bir_other_modules, bir_parser):
        super(BSVBasicBlock, self).__init__(name, bb_attrs, bir_headers,
                                            bir_tables, bir_other_modules,
                                            bir_parser)

        check_control_state(self.name, bb_attrs['next_control_state'])
        self.control_state = BSVControlState(bb_attrs['next_control_state'],
                                             self.local_header,
                                             bir_parser)

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        # self.instructions
        print 'generate', self.control_state, self.local_header.name
        return self.control_state.bsvgen(serializer)

