'''
Common template for bsv generation
'''

import re
from pif_ir.bir.objects.bir_struct import BIRStruct
from pif_ir.bir.objects.table import Table

def get_camel_case(column_name):
    ''' TODO '''
    return re.sub('_([a-z])', lambda match: match.group(1).upper(), column_name)

def convert(name):
    ''' TODO '''
    string = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', string).lower()

def camelCase(name):
    ''' camelCase '''
    output = ''.join(x for x in name.title() if x.isalnum())
    return output[0].lower() + output[1:]

def CamelCase(name):
    ''' CamelCase '''
    output = ''.join(x for x in name.title() if x.isalnum())
    return output


TYPEDEF_TEMPLATE = '''
typedef struct {
%(field)s
} %(name)s deriving (Bits, Eq);

instance DefaultValue#(%(name)s);
defaultValue = %(name)s {
%(value)s
};
endinstance

instance FShow#(%(name)s);
  function Fmt fshow(%(name)s p);
    return $format("%(name)s: %(printf)s", %(printv)s);
  endfunction
endinstance
'''

def generate_typedef(struct):
    ''' TODO '''
    assert isinstance(struct, BIRStruct)

    typedef_fields = []
    typedef_values = []
    printf = []
    printv = []

    for field, size in struct.fields.items():
        typedef_fields.append('  Bit#({w}) {v}'.format(w=size,
                                                       v=field))
        typedef_values.append('  {v} : 0'.format(v=field))
        printf.append('{f}=%h'.format(f=field))
        printv.append('p.{v}'.format(v=field))

    pmap = {'name': CamelCase(struct.name),
            'field': ',\n'.join(typedef_fields),
            'value': ',\n'.join(typedef_values),
            'printf': ', '.join(printf),
            'printv': ', '.join(printv)}
    return TYPEDEF_TEMPLATE % (pmap)

TABLE_TEMPLATE = '''
interface %(name)s
  interface Client#(MetadataRequest, MetadataResponse) next;
endinterface

module mk%(name)s#(Client#(MetadataRequest, MetadataResponse) md)(%(name)s);
  let verbose = True;

  FIFO#(MetadataRequest) outReqFifo <- mkFIFO;
  FIFO#(MetadataResponse) inRespFifo <- mkFIFO;



  interface next = (interface Client#(MetadataRequest, MetadataResponse);
    interface request = toGet(outReqFifo);
    interface response = toPut(inRespFifo);
  endinterface);
endmodule
'''

def generate_table(tbl):
    ''' TODO '''
    assert isinstance(tbl, Table)
    print 'nnn', vars(tbl)

    pmap = {'name': CamelCase(tbl.name)
            }
    return  TABLE_TEMPLATE % (pmap)

