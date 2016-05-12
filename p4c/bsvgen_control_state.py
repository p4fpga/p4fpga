'''
Control state with bsv backend
'''

from pif_ir.bir.objects.control_state import ControlState
from pif_ir.bir.utils.exceptions import BIRError
from programSerializer import ProgramSerializer

class BSVControlState(ControlState):
    '''
    TODO
    '''
    def __init__(self, control_state_attr, header, bir_parser):
        super(BSVControlState, self).__init__(control_state_attr, header,
                                              bir_parser)

    def _get_offset(self):
        ''' TODO '''

    def _get_basic_block(self):
        ''' TODO '''
        blocks = []
        for cond in self.basic_block:
            if isinstance(cond, str):
                blocks.append(cond)
            else:
                blocks.append(cond[1])
        return blocks

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)
        basic_blocks = self._get_basic_block()
        for block in basic_blocks:
            if block == '$done$':
                continue

