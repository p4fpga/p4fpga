'''
Struct with bsv backend
'''

from pif_ir.bir.objects.bir_struct import BIRStruct
from programSerializer import ProgramSerializer
from bsvgen_common import generate_typedef

class BSVBIRStruct(BIRStruct):
    '''
    TODO
    '''
    def __init__(self, name, struct_attrs):
        super(BSVBIRStruct, self).__init__(name, struct_attrs)

    def serialize(self):
        ''' Serialize struct to JSON '''
        json = {}
        return json

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)
        out = generate_typedef(self)
        serializer.append(out)

