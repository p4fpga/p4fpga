'''
Struct with bsv backend
'''

from pif_ir.bir.objects.bir_struct import BIRStruct
from programSerializer import ProgramSerializer

class BSVBIRStruct(BIRStruct):
    '''
    TODO
    '''
    def __init__(self, name, struct_attrs):
        super(BSVBIRStruct, self).__init__(name, struct_attrs)

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)

        print 'struct', self.fields
