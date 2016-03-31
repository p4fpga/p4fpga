#!/usr/bin/python
''' P4FPGA BIR compiler prototype
    It translates HLIR to BIR and generates Bluespec from BIR
'''

import argparse
import math
import sys
import yaml
from collections import OrderedDict
from p4_hlir.main import HLIR
from p4_hlir.hlir import p4_parse_state, p4_action, p4_table, p4_header_instance

# Print OrderedDict() to standard yaml
# from http://blog.elsdoerfer.name/2012/07/26/make-pyyaml-output-an-ordereddict/
def represent_odict(dump, tag, mapping, flow_style=None):
    '''Like BaseRepresenter.represent_mapping, but does not issue the sort() '''
    value = []
    node = yaml.MappingNode(tag, value, flow_style=flow_style)
    if dump.alias_key is not None:
        dump.represented_objects[dump.alias_key] = node
        best_style = True
    if hasattr(mapping, 'items'):
        mapping = mapping.items()
    for item_key, item_value in mapping:
        node_key = dump.represent_data(item_key)
        node_value = dump.represent_data(item_value)
        if not (isinstance(node_key, yaml.ScalarNode) and not node_key.style):
            best_style = False
        if not (isinstance(node_value, yaml.ScalarNode) and not node_value.style):
            best_style = False
        value.append((node_key, node_value))
    if flow_style is None:
        if dump.default_flow_style is not None:
            node.flow_style = dump.default_flow_style
        else:
            node.flow_style = best_style
    return node

# Class definition derived from bir_meta.yaml
class Struct(object):
    ''' struct '''
    required_attributes = ['fields']
    def __init__(self, hlir, **kwargs):
        assert (isinstance(hlir, p4_header_instance)
                or isinstance(hlir, p4_table))

        self.hlir = hlir
        self.name = hlir.name # set default name
        self.kwargs = kwargs
        self.fields = []

        if isinstance(hlir, p4_header_instance):
            self.build_header()
        elif isinstance(hlir, p4_table):
            print kwargs['field']
            self.build_table(kwargs['field'])

    def build_table(self, field_width=None):
        ''' build table request and response struct '''
        if self.kwargs['type'] == 'request':
            self.name = self.hlir.name + "_req_t"
            for field in self.hlir.match_fields:
                p4_field = field[0]
                #p4_match_type = field[1]
                self.fields.append({p4_field.name : field_width[p4_field.name]})
        elif self.kwargs['type'] == 'response':
            self.name = self.hlir.name + "_resp_t"
            self.fields.append({'hit': 1})
            p4_action_width = int(math.ceil(math.log(len(self.hlir.actions)+1)))
            self.fields.append({'p4_action': p4_action_width})
            for index, action in enumerate(self.hlir.actions):
                action_name = "action_{}_arg{}".format(index, 0)
                self.fields.append({action_name : sum(action.signature_widths)})

    def build_header(self):
        ''' build header struct '''
        for tmp_field in self.hlir.fields:
            self.fields.append({tmp_field.name: tmp_field.width})

    def dump(self):
        ''' dump struct to yaml '''
        dump = OrderedDict()
        dump['type'] = 'struct'
        dump['fields'] = self.fields
        return dump

class Metadata(object):
    ''' metadata '''
    required_attributes = ['values', 'visibility', 'value_inits']
    def __init__(self, hlir):
        assert isinstance(hlir, p4_header_instance)
        self.hlir = hlir
        self.name = hlir.name # set default name
        self.fields = []
        if isinstance(hlir, p4_header_instance):
            self.build_metadata()

    def build_metadata(self):
        ''' build metadata struct '''
        for tmp_field in self.hlir.fields:
            self.fields.append({tmp_field.name: tmp_field.width})

    def dump(self):
        ''' dump metadata to yaml '''
        dump = OrderedDict()
        dump['type'] = 'struct'
        dump['fields'] = self.fields
        return dump

class Table(object):
    ''' tables '''
    required_attributes = ['match_type', 'depth', 'request',
                           'response', 'operations']
    def __init__(self, table):
        match_types = {'P4_MATCH_EXACT': 'exact',
                       'P4_MATCH_TERNARY': 'ternary'}
        curr_types = {'P4_MATCH_TERNARY': 0,
                      'P4_MATCH_EXACT': 0}
        for field in table.match_fields:
            curr_types[field[1].value] += 1
        self.match_type = None
        for key, value in curr_types.items():
            if value != 0:
                self.match_type = match_types[key]
        assert self.match_type != None
        self.depth = table.size
        self.request = table.name + '_req_t'
        self.response = table.name + '_resp_t'

    def dump(self):
        ''' dump table to yaml '''
        dump = OrderedDict()
        dump['type'] = 'table'
        dump['match_type'] = self.match_type
        dump['depth'] = self.depth
        dump['request'] = self.request
        dump['response'] = self.response
        dump['operations'] = []
        return dump

class OtherModule(object):
    ''' other_module '''
    required_attributes = ['operations']
    def __init__(self):
        pass

class BasicBlock(object):
    ''' basic_block '''
    required_attributes = ['local_header', 'local_table',
                           'instructions', 'next_control_state']
    def __init__(self, basicBlock):
        if isinstance(basicBlock, p4_parse_state):
            self.local_header = basicBlock.latest_extraction
            self.instructions = None # [] or V meta.type_ type_
            self.next_control_state = None # $(branch_on) type_ == 0x0800, (branch_to) parse_ipv4
            print basicBlock.latest_extraction
            print 'next_control_state', basicBlock.branch_on, basicBlock.branch_to
        elif isinstance(basicBlock, p4_action):
            self.instructions = None
            self.next_control_state = None
            #print vars(basicBlock)
        elif isinstance(basicBlock, p4_table):
            self.local_table = basicBlock.name
            self.instructions = None
            self.next_control_state = None
            #print vars(basicBlock)
            #request action
            #response actions

class ControlFlow(object):
    ''' control_flow '''
    required_attributes = ['start_control_state']
    def __init__(self, controlFlow):
        # offset
        # basic_block
        pass

class ProcessorLayout(object):
    ''' processor_layout '''
    required_attributes = ['format', 'implementation']
    def __init__(self, hlirParser):
        # format: list
        # implementation:
        # - parser
        # - ingress_control
        # - deparser
        pass

class OtherProcessor(object):
    ''' other_processor '''
    required_attributes = ['class']
    def __init__(self):
        pass

class MetaIR(object):
    ''' meta_ir_types '''
    required_attributes = ['struct', 'metadata', 'table', 'other_module',
                           'basic_block', 'control_flow', 'other_processor',
                           'processor_layout']
    def __init__(self, hlir):
        assert isinstance(hlir, HLIR)
        self.hlir = hlir
        self.bir_yaml = OrderedDict()
        self.field_width = OrderedDict()

        self.processor_layout = OrderedDict()
        self.tables = OrderedDict()
        self.structs = OrderedDict()
        self.basic_blocks = OrderedDict()
        self.metadata = OrderedDict()
        self.table_initialization = OrderedDict()

        self.construct()

    def build_metadatas(self):
        ''' create metadata object '''
        for hdr in self.hlir.p4_header_instances.values():
            if hdr.metadata:
                self.metadata[hdr.name] = Metadata(hdr)
            print 'metadata instance', hdr, hdr.metadata

    def build_structs(self):
        ''' create struct object '''
        for hdr in self.hlir.p4_header_instances.values():
            if not hdr.metadata:
                self.structs[hdr.name] = Struct(hdr)
            print 'header instances', hdr, hdr.max_index, hdr.metadata

        for tbl in self.hlir.p4_tables.values():
            field_width = OrderedDict()
            for match_field in tbl.match_fields:
                field = match_field[0]
                field_width[field.name] = self.field_width[str(field)]
            req = Struct(tbl, type="request", field=field_width)
            self.structs[req.name] = req

        for tbl in self.hlir.p4_tables.values():
            field_width = OrderedDict()
            # table response fields
            resp = Struct(tbl, type="response", field=field_width)
            self.structs[resp.name] = resp

    def build_tables(self):
        ''' create table object '''
        for tbl in self.hlir.p4_tables.values():
            self.tables[tbl.name] = Table(tbl)

    def build_basic_blocks(self):
        ''' create basic blocks '''
        for tbl in self.hlir.p4_tables.values():
            self.basic_blocks[tbl.name] = BasicBlock(tbl)

        for state in self.hlir.p4_parse_states.values():
            self.basic_blocks[state.name] = BasicBlock(state)

        for action in self.hlir.p4_actions.values():
            self.basic_blocks[action.name] = BasicBlock(action)
            print 'p4action', action

    def build_parsers(self):
        ''' create parser and its states '''
        pass

    def build_match_actions(self):
        ''' build match & action pipeline stage '''

    def build_control_flows(self):
        ''' build control flow '''
        for cond in self.hlir.p4_conditional_nodes.values():
            print 'conditional', cond

        for ingress in self.hlir.p4_ingress_ptr.keys():
            print 'ingress', ingress

    def prepare_local_var(self):
        ''' process hlir to setup commonly used variables '''
        for hdr in self.hlir.p4_header_instances.values():
            for field in hdr.fields:
                path = ".".join([hdr.name, field.name])
                self.field_width[path] = field.width

    def construct(self):
        ''' HLIR -> BIR '''

        self.prepare_local_var() # local variables to simply style

        self.build_structs()
        self.build_metadatas()
        self.build_tables()
        self.build_basic_blocks()
        self.build_match_actions()
        self.build_control_flows()

        print self.hlir.p4_egress_ptr

        # other module
        for cntr in self.hlir.p4_counters.values():
            print 'p4counter', cntr

        # other processor

    def pprint_yaml(self):
        ''' pretty print to yaml '''
        for name, inst in self.structs.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.metadata.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.tables.items():
            self.bir_yaml[name] = inst.dump()
        yaml.safe_dump(self.bir_yaml, sys.stdout, default_flow_style=False)

def compile_hlir(hlir):
    ''' translate HLIR to BIR '''
    # list of yaml objects
    bir = MetaIR(hlir)
    return bir

def main():
    ''' entry point '''
    argparser = argparse.ArgumentParser(
        description="P4FPGA P4 to Bluespec Compiler")
    argparser.add_argument('-f', '--file', required=True,
                           help='Input P4 program')
    argparser.add_argument('-y', '--yaml', action='store_true', required=False,
                           help="Output yaml")
    options = argparser.parse_args()

    hlir = HLIR(options.file)
    hlir.build()

    bir = compile_hlir(hlir)

    if options.yaml:
        bir.pprint_yaml()

if __name__ == "__main__":
    #hanw: fix pyyaml to print OrderedDict()
    yaml.SafeDumper.add_representer(
        OrderedDict, lambda dumper, value: represent_odict(
            dumper, u'tag:yaml.org,2002:map', value))
    main()
