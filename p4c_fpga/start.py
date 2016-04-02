#!/usr/bin/python
''' P4FPGA BIR compiler prototype
    It translates HLIR to BIR and generates Bluespec from BIR
'''

import argparse
import math
import sys
import os
import yaml
from collections import OrderedDict
from p4_hlir.main import HLIR
from p4_hlir.hlir import p4_parse_state, p4_action, p4_table, p4_header_instance
from p4_hlir.hlir import p4_parse_state_keywords

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
        self.name = self.name + '_t'
        print 'build header', self.name
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

class MetadataInstance(object):
    ''' metadata instance '''
    required_attributes = ['type', 'values', 'visibility']
    def __init__(self, hlir, **kwargs):
        self.name = None
        self.values = None
        self.visibility = 'none'
        self.kwargs = kwargs
        self.build(hlir)

    def build(self, hlir):
        ''' build metadata instance '''
        if self.kwargs['type'] == 'request':
            self.name = hlir.name + '_req'
            self.values = hlir.name + '_req_t'
        elif self.kwargs['type'] == 'response':
            self.name = hlir.name + '_resp'
            self.values = hlir.name + '_resp_t'

    def dump(self):
        ''' dump metadata instance to yaml '''
        dump = OrderedDict()
        dump['type'] = 'metadata'
        dump['values'] = self.values
        dump['visibility'] = self.visibility
        return dump

class Table(object):
    ''' tables '''
    required_attributes = ['match_type', 'depth', 'request',
                           'response', 'operations']
    def __init__(self, table):
        self.depth = table.min_size
        self.request = table.name + '_req_t'
        self.response = table.name + '_resp_t'
        self.match_type = None
        self.build_table(table)

    def build_table(self, table):
        ''' build table '''
        match_types = {'P4_MATCH_EXACT': 'exact',
                       'P4_MATCH_TERNARY': 'ternary'}
        curr_types = {'P4_MATCH_TERNARY': 0,
                      'P4_MATCH_EXACT': 0}
        for field in table.match_fields:
            print 'ff', table.name, field
            curr_types[field[1].value] += 1
        for key, value in curr_types.items():
            if value != 0:
                print 'ff', key, value
                self.match_type = match_types[key]

    def dump(self):
        ''' dump table to yaml '''
        #assert self.match_type != None
        dump = OrderedDict()
        dump['type'] = 'table'
        dump['match_type'] = self.match_type
        dump['depth'] = self.depth
        dump['request'] = self.request
        dump['response'] = self.response
        dump['operations'] = []
        return dump

class BasicBlock(object):
    ''' basic_block '''
    required_attributes = ['local_header', 'local_table',
                           'instructions', 'next_control_state']
    def __init__(self, basicBlock, **kwargs):
        self.local_header = None
        self.local_table = None
        self.instructions = None
        self.next_control_state = None
        self.basic_block = basicBlock

        if isinstance(basicBlock, p4_parse_state):
            self.name = basicBlock.name
            if 'deparse' in kwargs and kwargs['deparse']:
                self.name = 'de' + self.name
                self.build_deparser_state(basicBlock)
            else:
                self.build_parser_state(basicBlock)
        elif isinstance(basicBlock, p4_action):
            self.name = 'bb_' + basicBlock.name
            self.build_action(basicBlock)
        elif isinstance(basicBlock, p4_table):
            self.name = 'bb_' + basicBlock.name
            self.build_table(basicBlock)

    def build_parser_state(self, parse_state):
        ''' build parser basic block '''
        self.local_header = parse_state.latest_extraction.header_type.name
        branch_on = map(lambda v: v.name, parse_state.branch_on)
        self.instructions = []
        for branch in parse_state.branch_on:
            #if type extract/set_metadata
            dst = 'meta.{}'.format(branch.name)
            inst = ['V', dst, branch.name]
            self.instructions.append(inst)
        branch_to = parse_state.branch_to.items()
        next_offset = "$offset$ + {}".format(
            parse_state.latest_extraction.header_type.length * 8)
        next_state = ['$done$']
        for val, state in branch_to:
            if isinstance(val, p4_parse_state_keywords):
                continue
            match_expr = "{} == {}".format(branch_on[0], hex(val))
            next_state.insert(0, [match_expr, state.name])
        self.next_control_state = [[next_offset], next_state]

    def build_deparser_state(self, deparse_state):
        ''' build deparser basic block '''
        self.local_header = deparse_state.latest_extraction.header_type.name
        branch_on = map(lambda v: v.name, deparse_state.branch_on)
        self.instructions = []
        branch_to = deparse_state.branch_to.items()
        next_offset = "$offset$ + {}".format(
            deparse_state.latest_extraction.header_type.length * 8)
        next_state = ['$done$']
        for val, state in branch_to:
            if isinstance(val, p4_parse_state_keywords):
                continue
            match_expr = "{} == {}".format(branch_on[0], hex(val))
            next_state.insert(0, [match_expr, state.name])
        self.next_control_state = [[next_offset], next_state]

    def build_action(self, action):
        ''' build action basic block '''
        self.instructions = []
        self.next_control_state = [0, ['$done$']]

    def build_table(self, table):
        ''' build table basic block '''
        self.local_table = table.name
        self.instructions = []
        self.next_control_state = [[0], ['$done$']]

    def dump(self):
        ''' dump basic block to yaml '''
        dump = OrderedDict()
        if isinstance(self.basic_block, p4_parse_state):
            dump['type'] = 'basic_block'
            dump['local_header'] = self.local_header
            dump['instructions'] = self.instructions
            dump['next_control_state'] = self.next_control_state
        elif (isinstance(self.basic_block, p4_action) or
              isinstance(self.basic_block, p4_table)):
            dump['type'] = 'basic_block'
            dump['local_table'] = self.local_table
            dump['instructions'] = self.instructions
            dump['next_control_state'] = self.next_control_state
        return dump

class ControlFlow(object):
    ''' control_flow '''
    required_attributes = ['start_control_state']
    def __init__(self, controlFlow, **kwargs):
        self.name = kwargs['name']
        self.start_control_state = OrderedDict()
        if isinstance(controlFlow, p4_parse_state):
            self.build_parse(controlFlow, kwargs['deparse'])
        elif isinstance(controlFlow, p4_table):
            self.build_ingress(controlFlow)

    def build_parse(self, control_flow, deparse=False):
        ''' build control flow object '''
        name = control_flow.return_statement[1]
        if deparse:
            name = 'de'+name
        #FIXME
        self.start_control_state = [[0], [name]]

    def build_ingress(self, ingress):
        ''' ingress node '''
        name = 'bb_' + ingress.name
        #FIXME
        self.start_control_state = [[0], [name]]

    def dump(self):
        ''' dump control flow to yaml '''
        dump = OrderedDict()
        dump['type'] = 'control_flow'
        dump['start_control_state'] = self.start_control_state
        return dump

class ProcessorLayout(object):
    ''' processor_layout '''
    required_attributes = ['format', 'implementation']
    def __init__(self, control_flows):
        self.implementation = []
        self.build(control_flows)

    def build(self, control_flows):
        ''' build processor layout '''
        for ctrl in control_flows:
            self.implementation.append(ctrl)

    def dump(self):
        ''' dump processor layout to yaml '''
        dump = OrderedDict()
        dump['type'] = 'processor_layout'
        dump['format'] = 'list'
        dump['implementation'] = self.implementation
        return dump

class OtherModule(object):
    ''' other_module '''
    required_attributes = ['operations']
    def __init__(self):
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
        self.control_flow = OrderedDict()
        self.table_initialization = OrderedDict()

        self.construct()

    def build_metadatas(self):
        ''' create metadata object '''
        for hdr in self.hlir.p4_header_instances.values():
            if hdr.metadata:
                self.metadata[hdr.name] = Metadata(hdr)

        for tbl in self.hlir.p4_tables.values():
            inst = MetadataInstance(tbl, type='request')
            self.metadata[inst.name] = inst
            print 'mm metadata instance', inst.name

        for tbl in self.hlir.p4_tables.values():
            inst = MetadataInstance(tbl, type='response')
            self.metadata[inst.name] = inst

    def build_structs(self):
        ''' create struct object '''
        for hdr in self.hlir.p4_header_instances.values():
            if not hdr.metadata:
                struct = Struct(hdr)
                self.structs[struct.name] = struct
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
            basic_block = BasicBlock(tbl)
            self.basic_blocks[basic_block.name] = basic_block
        #for action in self.hlir.p4_actions.values():
        #    self.basic_blocks[action.name] = BasicBlock(action)
        #    print 'p4action', action

    def build_parsers(self):
        ''' create parser and its states '''
        for state in self.hlir.p4_parse_states.values():
            if state.name == 'start':
                control_flow = ControlFlow(state, name='parser', deparse=False)
                self.control_flow[control_flow.name] = control_flow
            else:
                basic_block = BasicBlock(state)
                self.basic_blocks[basic_block.name] = basic_block

    def build_deparsers(self):
        ''' create parser and its states '''
        for state in self.hlir.p4_parse_states.values():
            if state.name == 'start':
                control_flow = ControlFlow(state, name='deparser', deparse=True)
                self.control_flow[control_flow.name] = control_flow
            else:
                basic_block = BasicBlock(state, deparse=True)
                self.basic_blocks[basic_block.name] = basic_block

    def build_match_actions(self):
        ''' build match & action pipeline stage '''

    def build_control_flows(self):
        ''' build control flow '''
        for index, ingress in enumerate(self.hlir.p4_ingress_ptr.keys()):
            name = 'ingress_control_{}'.format(index)
            control_flow = ControlFlow(ingress, name=name)
            self.control_flow[control_flow.name] = control_flow

    def build_processor_layout(self):
        ''' build processor layout '''
        self.processor_layout['a_p4_switch'] = ProcessorLayout(
            self.control_flow)

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
        self.build_parsers()
        self.build_match_actions()
        self.build_control_flows()
        self.build_deparsers()
        self.build_processor_layout()
        print self.hlir.p4_egress_ptr

        # other module
        for cntr in self.hlir.p4_counters.values():
            print 'p4counter', cntr

        # other processor

    def pprint_yaml(self, filename):
        ''' pretty print to yaml '''
        for name, inst in self.structs.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.metadata.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.tables.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.basic_blocks.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.control_flow.items():
            self.bir_yaml[name] = inst.dump()
        for name, inst in self.processor_layout.items():
            self.bir_yaml[name] = inst.dump()
        with open(filename, 'w') as stream:
            yaml.safe_dump(self.bir_yaml, stream, default_flow_style=False)

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
        bir.pprint_yaml(os.path.splitext(options.file)[0]+'.yml')

if __name__ == "__main__":
    #hanw: fix pyyaml to print OrderedDict()
    yaml.SafeDumper.add_representer(
        OrderedDict, lambda dumper, value: represent_odict(
            dumper, u'tag:yaml.org,2002:map', value))
    main()
