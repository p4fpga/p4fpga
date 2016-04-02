'''
Table with bsv backend
'''

from pif_ir.bir.objects.table import Table
from programSerializer import ProgramSerializer

class BSVTable(Table):
    ''' TODO '''
    def __init__(self, name, table_attrs):
        super(BSVTable, self).__init__(name, table_attrs)

    def bsvgen(self, serializer):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)
        pass
