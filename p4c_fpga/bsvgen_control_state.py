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
        for cond in self.basic_block:
            if isinstance(cond, str):
                return cond
            else:
                return cond[1]
        raise BIRError("didn't find basic block!")

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        print self.header
        print self.basic_block
        basic_block = self._get_basic_block()
        if basic_block == '$done$':
            basic_block = None
        return 0, basic_block

