'''
Basic block with bsv backend
'''

from pif_ir.bir.objects.basic_block import BasicBlock
from pif_ir.bir.utils.validate import check_control_state

from bsvgen_control_state import BSVControlState
from bsvgen_common import generate_basic_block
from programSerializer import ProgramSerializer

# BSVBasicBlock should be an AST node
class BSVBasicBlock(BasicBlock):
    ''' TODO '''
    def __init__(self, name, bb_attrs, bir_headers, bir_tables,
                 bir_other_modules, bir_parser):
        super(BSVBasicBlock, self).__init__(name, bb_attrs, bir_headers,
                                            bir_tables, bir_other_modules,
                                            bir_parser)

        # control_state contains decls, interface info
        check_control_state(self.name, bb_attrs['next_control_state'])
        self.control_state = BSVControlState(bb_attrs['next_control_state'],
                                             self.local_header,
                                             bir_parser)

        # create Interface instance
        # - token interface
        # - reg_read, in sequence or in parallel
        # - reg_write, in sequence or in parallel

        ### create Param instance

        # create moduleContext
        print 'block', bb_attrs['instructions']
        # reg_read, reg_read, reg_read, reg_write
        # create Module instance

    def build_rule(self, inp, outp):
        ''' TODO '''
        rule = {}
        rule['get'] = inp
        rule['put'] = outp
        return rule

    def serialize(self):
        json = {}

        prev_control_state = []
        prev_control_state.append('BBRequest')

        reg_access = []

        interface = [ prev_control_state , reg_access ]
        json['interface'] = interface

        rules = {}
        # extract these info
        inp = { 'type': 'packetInstance', 'name': 'curr_packet' }
        outp = []
        rules['bb_request'] = self.build_rule(inp, outp)
        rules['bb_response'] = self.build_rule(inp, outp)
        json['rule'] = rules
        return json

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        #FIXME
        if self.name.startswith('parse_'):
            return

        if self.name.startswith('deparse_'):
            return

        serializer.append(generate_basic_block(self))
        # need control state info
        # self.control_state.bsvgen(serializer)

