'''
Table with bsv backend
'''

from dotmap import DotMap
from pif_ir.bir.objects.table import Table
from programSerializer import ProgramSerializer
from bsvgen_common import generate_table

class BSVTable(Table):
    ''' TODO '''
    def __init__(self, name, table_attrs):
        super(BSVTable, self).__init__(name, table_attrs)

    def serialize(self):
        json = DotMap()
        json.requestType = self.req_attrs['values']
        json.responseType = self.resp_attrs['values']
        json.dpeth = self.depth
        return json

    def bsvgen(self, serializer, json):
        ''' TODO '''
        assert isinstance(serializer, ProgramSerializer)
        serializer.append(generate_table(self, json))
