'''
Basic block with bsv backend
'''

from dotmap import DotMap
from pif_ir.bir.objects.basic_block import BasicBlock
from pif_ir.bir.utils.validate import check_control_state

from bsvgen_control_state import BSVControlState
from bsvgen_common import generate_basic_block
from programSerializer import ProgramSerializer

def CamelCase(name):
    ''' CamelCase '''
    output = ''.join(x for x in name.title() if x.isalnum())
    return output

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

    def serialize_json_deparse(self):
        ''' jsondata for deparse state '''
        d = DotMap()
        d.name = self.name
        d.headertype = self.local_header.name
        d.compute_next_state.branch = []
        return d

    def serialize_json_parse(self):
        ''' jsondata for parse state '''
        p = DotMap()
        p.name = CamelCase(self.name)
        p.interface = []
        p.interface.append('method Action start;')
        p.interface.append('method Action stop;')
        p.parsed_out_fifo = []
        p.stmt = []
        p.intf_data_out = []
        p.intf_ctrl_out = []
        return p

    def serialize_json_basicblock(self):
        ''' jsondata for basicblock '''
        pass

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        #FIXME: generate parser from json
        if self.name.startswith('parse_'):
            return

        #FIXME: generate deparser from json
        if self.name.startswith('deparse_'):
            return

        serializer.append(generate_basic_block(self))
        # self.control_state.bsvgen(serializer)

