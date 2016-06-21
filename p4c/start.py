#!/usr/bin/python
''' P4FPGA BIR compiler prototype
    It translates HLIR to BIR and generates Bluespec from BIR
'''

#import p4_hlir as p4hlir

import argparse
import math
import sys
import os
import yaml
from collections import OrderedDict
from p4_hlir.main import HLIR
from p4_hlir.hlir import p4
from p4_hlir.hlir import p4_parse_state, p4_action, p4_table, p4_header_instance
from p4_hlir.hlir import p4_parse_state_keywords, p4_conditional_node
from p4_hlir.hlir import p4_control_flow, p4_expression
from p4_hlir.hlir.p4_imperatives import p4_signature_ref
from p4_hlir.hlir.analysis_utils import retrieve_from_one_action, get_all_subfields
from p4_hlir.hlir.p4_tables import p4_control_flow_to_table_graph
from compilationException import CompilationException

from p4c_bm import gen_json

_include_valid = False

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

# Base Class for struct
class Struct(object):
    ''' struct '''
    required_attributes = ['fields']
    def __init__(self, hlir):
        self.hlir = hlir
        self.name = None
        self.fields = []

    def dump(self):
        ''' dump struct to yaml '''
        dump = OrderedDict()
        dump['type'] = 'struct'
        dump['fields'] = self.fields
        return dump

class Metadata(Struct):
    ''' struct to represent internal metadata '''
    def __init__(self, meta):
        super(Metadata, self).__init__(meta)
        self.name = meta['name'] + '_t'
        for name, width in meta['fields'].items():
            self.fields.append({name: width})

class Header(Struct):
    ''' struct to represent packet header '''
    def __init__(self, hdr):
        super(Header, self).__init__(hdr)
        self.name = hdr.name + '_t'
        for tmp in hdr.fields:
            self.fields.append({tmp.name: tmp.width})

class TableRequest(Struct):
    ''' struct to represent table request '''
    def __init__(self, tbl):
        super(TableRequest, self).__init__(tbl)
        self.name = tbl.name + '_req_t'
        for field, _, _ in tbl.match_fields:
            self.fields.append({field.name: field.width})

class TableResponse(Struct):
    ''' struct to represent table response '''
    def __init__(self, tbl):
        super(TableResponse, self).__init__(tbl)
        self.name = tbl.name + '_resp_t'
        #self.fields.append({'hit':1})
        num_action = int(math.ceil(math.log(len(tbl.actions), 2)))
        if num_action != 0:
            self.fields.append({'p4_action': num_action})
        for idx, action in enumerate(tbl.actions):
            for inst in action.flat_call_sequence:
                primitive = inst[0]
                args = inst[1]
                for index, arg in enumerate(args):
                    if isinstance(arg, p4_signature_ref):
                        name = action.signature[arg.idx]
                        width = action.signature_widths[arg.idx]
                        self.fields.append({name: width})

class StructInstance(object):
    def __init__(self, struct):
        self.name = None
        self.values = None
        self.visibility = 'none'

    def dump(self):
        ''' dump metadata instance to yaml '''
        dump = OrderedDict()
        dump['type'] = 'metadata'
        dump['values'] = self.values
        dump['visibility'] = self.visibility
        return dump

class TableRequestInstance(StructInstance):
    ''' TODO '''
    def __init__(self, hlir):
        super(TableRequestInstance, self).__init__(hlir)
        self.name = hlir.name + '_req'
        self.values = hlir.name + '_req_t'

class TableResponseInstance(StructInstance):
    def __init__(self, hlir):
        super(TableResponseInstance, self).__init__(hlir)
        self.name = hlir.name + '_resp'
        self.values = hlir.name + '_resp_t'

class MetadataInstance(StructInstance):
    def __init__(self, meta):
        super(MetadataInstance, self).__init__(meta)
        self.name = meta['name']
        self.values = meta['name'] + '_t'

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
            curr_types[field[1].value] += 1
        for key, value in curr_types.items():
            if value != 0:
                self.match_type = match_types[key]

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
            next_ = kwargs['cond']
            self.build_action(basicBlock, next_)
        elif isinstance(basicBlock, p4_table):
            self.name = 'bb_' + basicBlock.name
            self.build_table(basicBlock)
        else:
            raise NotImplementedError

    def build_parser_state(self, parse_state):
        ''' build parser basic block '''
        self.local_header = parse_state.latest_extraction.header_type.name
        branch_on = map(lambda v: v.name, parse_state.branch_on)
        self.instructions = []
        for branch in parse_state.branch_on:
            #if type extract/set_metadata
            dst = 'meta.{}${}'.format(branch.instance, branch.name)
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
        branch_on = map(lambda v: "{}${}".format(v.instance, v.name), deparse_state.branch_on)
        self.instructions = []
        branch_to = deparse_state.branch_to.items()
        next_offset = "$offset$ + {}".format(
            deparse_state.latest_extraction.header_type.length * 8)
        next_state = ['$done$']
        for val, state in branch_to:
            if isinstance(val, p4_parse_state_keywords):
                continue
            match_expr = "{} == {}".format(branch_on[0], hex(val))
            next_state.insert(0, [match_expr, 'de'+state.name])
        self.next_control_state = [[next_offset], next_state]

    def build_action(self, action, next_):
        ''' build action basic block '''
        def meta(field):
            ''' add field to meta '''
            if isinstance(field, int):
                return field
            return 'meta.{}'.format(str(field).replace(".", "_")) if field else None

        def print_cond(cond):
            if cond.op == 'valid':
                return 'meta.{}_{} == 1'.format(cond.op, cond.right)
            else:
                left = meta(cond.left)
                right = meta(cond.right)
                return ("("+(str(left)+" " if left else "")+
                        cond.op+" "+
                        str(right)+")")

        def get_next_control_state(next_, next_control_state):
            ''' TODO '''
            if isinstance(next_, p4_conditional_node):
                expr = print_cond(next_.condition)
                name = 'bb_' + next_.next_[True].name
                next_control_state.append([expr, name])
                for cond in next_.next_.values():
                    if isinstance(cond, p4_conditional_node):
                        get_next_control_state(cond, next_control_state)

        def print_instruction(inst):
            instructions = []
            primitive_name = inst[0].name
            args = inst[1]
            if inst[0].name in ['register_read', 'register_write']:
                params=[]
                for param in inst[1]:
                    params.append(str(param))
                instructions.append(['O', inst[0].name, params])
            elif inst[0].name in ['modify_field']:
                dst = "meta.{}${}".format(args[0].instance.name, args[0].name)
                for index, arg in enumerate(args):
                    if isinstance(arg, p4_signature_ref):
                        instructions.append(['V', dst, action.signature[arg.idx]])
                    elif isinstance(arg, int):
                        instructions.append(['V', dst, hex(arg)])
            elif inst[0].name in ['clone_ingress_pkt_to_egress',
                                  'clone_egress_pkt_to_egress']:
                pass
            elif inst[0].name in ['resubmit']:
                pass
            elif inst[0].name in ['generate_digest']:
                pass
            elif inst[0].name in ['recirculate']:
                pass
            elif inst[0].name in ['modify_field_with_hash_based_offset']:
                pass
            elif inst[0].name in ['no_op']:
                print 'nop'
                pass
            elif inst[0].name in ['drop']:
                pass
            elif inst[0].name in ['count']:
                pass
            elif inst[0].name in ['truncate']:
                pass
            elif inst[0].name in ['execute_meter']:
                pass
            elif inst[0].name in ['push', 'pop']:
                pass
            elif inst[0].name in ['add_header', 'remove_header', 'copy_header']:
                raise NotImplementedError
            else:
                print vars(inst[1][0])
                #raise NotImplementedError
            return instructions

        # instructions
        instructions = []
        for inst in action.flat_call_sequence:
            instructions.extend(print_instruction(inst))
        self.instructions = instructions

        # next_control_state
        next_control_state = []
        get_next_control_state(next_, next_control_state)
        next_control_state.append('$done$')
        self.next_control_state = [[0], next_control_state]

    def build_table(self, table):
        ''' build table basic block '''
        self.local_table = table.name
        self.instructions = []
        next_state = []
        for index, action in enumerate(table.actions):
            action_name = 'bb_' + action.name
            if len(table.actions) > 1:
                pred = "p4_action == {}".format(index+1)
                next_state.append([pred, action_name])
        next_state.append("$done$")
        self.next_control_state = [[0], next_state]

    def dump(self):
        ''' dump basic block to yaml '''
        dump = OrderedDict()
        if isinstance(self.basic_block, p4_parse_state):
            dump['type'] = 'basic_block'
            dump['local_header'] = self.local_header
            dump['instructions'] = self.instructions
            dump['next_control_state'] = self.next_control_state
        elif isinstance(self.basic_block, p4_action):
            dump['type'] = 'basic_block'
            dump['instructions'] = self.instructions
            dump['next_control_state'] = self.next_control_state
        elif isinstance(self.basic_block, p4_table):
            dump['type'] = 'basic_block'
            dump['local_table'] = self.local_table
            dump['instructions'] = self.instructions
            dump['next_control_state'] = self.next_control_state
        else:
            raise NotImplementedError
        return dump

# Base Class for Control Flow
class ControlFlowBase(object):
    ''' control_flow '''
    required_attributes = ['start_control_state']
    def __init__(self, controlFlow):
        self.start_control_state = OrderedDict()
        self.name = None

    def dump(self):
        ''' dump control flow to yaml '''
        dump = OrderedDict()
        dump['type'] = 'control_flow'
        dump['start_control_state'] = self.start_control_state
        return dump

class ControlFlow(ControlFlowBase):
    def __init__(self, controlFlow, **kwargs):
        super(ControlFlow, self).__init__(controlFlow)
        self.name = 'ingress'
        if 'index' in kwargs:
            self.name = "{}_{}".format(self.name, kwargs['index'])
        if 'start_control_state' in kwargs:
            start_states = kwargs['start_control_state']
        start_control_state = []
        print 'xxx control', start_states
        if isinstance(start_states, p4_table):
            name = 'bb_' + start_states.name
            start_control_state.append(name)
        elif isinstance(start_states, list):
            print 'bbb', start_states
            for state in start_states:
                expr = state[0]
                name = state[1]
                start_control_state.append([expr, name])
        else:
            print 'xxx', start_states
        start_control_state.append('$done$')
        self.start_control_state = [[0], start_control_state]

class Parser(ControlFlowBase):
    ''' parser '''
    def __init__(self, parser):
        super(Parser, self).__init__(parser)
        self.control_flow = parser
        self.name = 'parser'
        self.build()

    def build(self):
        ''' TODO '''
        name = self.control_flow.return_statement[1]
        self.start_control_state = [[0], [name]]

class Deparser(ControlFlowBase):
    ''' deparser '''
    def __init__(self, deparser):
        super(Deparser, self).__init__(deparser)
        self.control_flow = deparser
        self.name = 'deparser'
        self.build()

    def build(self):
        ''' TODO '''
        name = 'de' + self.control_flow.return_statement[1]
        self.start_control_state = [[0], [name]]

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
                self.metadata[hdr.name] = Header(hdr)

        for tbl in self.hlir.p4_tables.values():
            inst = TableRequestInstance(tbl)
            self.metadata[inst.name] = inst

        for tbl in self.hlir.p4_tables.values():
            inst = TableResponseInstance(tbl)
            self.metadata[inst.name] = inst

        inst = OrderedDict()
        inst['name'] = 'metadata'
        self.metadata[inst['name']] = MetadataInstance(inst)

    def build_structs(self):
        ''' create struct object '''
        # struct from packet header
        for hdr in self.hlir.p4_header_instances.values():
            if not hdr.metadata:
                struct = Header(hdr)
                self.structs[struct.name] = struct

        for tbl in self.hlir.p4_tables.values():
            req = TableRequest(tbl)
            self.structs[req.name] = req

        for tbl in self.hlir.p4_tables.values():
            resp = TableResponse(tbl)
            self.structs[resp.name] = resp

        inst = OrderedDict()
        inst['name'] = 'metadata_t'
        inst['fields'] = OrderedDict()
        # metadata from match table key
        for tbl in self.hlir.p4_tables.values():
            for field, _, _ in tbl.match_fields:
                key = "{}${}".format(field.instance, field.name)
                inst['fields'][key] = field.width
        # metadata from parser
        for state in self.hlir.p4_parse_states.values():
            for branch_on in state.branch_on:
                key = "{}${}".format(branch_on.instance, branch_on.name)
                inst['fields'][key] = branch_on.width
        # metadata from action
        for tbl in self.hlir.p4_tables.values():
            for action, next_ in tbl.next_.items():
                if isinstance(action, p4_action):
                    _, _, fields = retrieve_from_one_action(action)
                    for field in fields:
                        key = "{}${}".format(field.instance, field.name)
                        inst['fields'][key] = field.width

        self.structs[inst['name']] = Metadata(inst)

    def build_tables(self):
        ''' create table object '''
        for tbl in self.hlir.p4_tables.values():
            self.tables[tbl.name] = Table(tbl)

    def build_basic_blocks(self):
        ''' create basic blocks '''
        for tbl in self.hlir.p4_tables.values():
            basic_block = BasicBlock(tbl)
            self.basic_blocks[basic_block.name] = basic_block

    def build_parsers(self):
        ''' create parser and its states '''
        for state in self.hlir.p4_parse_states.values():
            if state.name == 'start':
                control_flow = Parser(state)
                self.control_flow[control_flow.name] = control_flow
            else:
                basic_block = BasicBlock(state)
                self.basic_blocks[basic_block.name] = basic_block

    def build_deparsers(self):
        ''' create parser and its states '''
        for state in self.hlir.p4_parse_states.values():
            if state.name == 'start':
                control_flow = Deparser(state)
                self.control_flow[control_flow.name] = control_flow
            else:
                basic_block = BasicBlock(state, deparse=True)
                self.basic_blocks[basic_block.name] = basic_block

    def build_match_actions(self):
        ''' build match & action pipeline stage '''
        for table in self.hlir.p4_tables.values():
            for action, next_ in table.next_.items():
                basic_block = BasicBlock(action, cond=next_)
                self.basic_blocks[basic_block.name] = basic_block

    def build_control_flows(self):
        ''' TODO '''
        ''' build action basic block '''
        def meta(field):
            ''' add field to meta '''
            if isinstance(field, int):
                return field
            return 'meta.{}'.format(str(field).replace(".", "_")) if field else None

        # map from p4_expression to p4_condition
        cond_map = {}
        for cond in self.hlir.p4_conditional_nodes.values():
            cond_map[cond.condition] = cond

        def print_cond(cond):
            if cond.op == 'valid':
                return 'meta.{}${} == 1'.format(cond.op, cond.right)
            elif cond.op == 'and':
                left = print_cond(cond.left)
                right = print_cond(cond.right)
                return ("("+(str(left)+" " if left else "")+
                        cond.op+" "+
                        str(right)+")")
            else:
                left = meta(cond.left)
                right = meta(cond.right)
                return ("("+(str(left)+" " if left else "")+
                        cond.op+" "+
                        str(right)+")")

        def get_next_control_state(state, next_control_state, visited):
            if isinstance(state, p4_conditional_node):
                expr = print_cond(state.condition) 
                for foo, branch in state.next_.items(): # True or False
                    if branch == None:
                        continue
                    if isinstance(branch, p4_conditional_node) and branch not in visited:
                        get_next_control_state(branch, next_control_state, visited)
                    else:
                        visited.add(branch)
                        name = 'bb_' + branch.name
                        next_control_state.append([expr, name])

        for index, control_flow in enumerate(self.hlir.p4_control_flows.values()):
            entry_point, _ = p4_control_flow_to_table_graph(self.hlir, control_flow)
            next_control_state = []
            visited = set()
            if isinstance(entry_point, p4_conditional_node):
                get_next_control_state(entry_point, next_control_state, visited)
            else:
                next_control_state = entry_point
            control_flow = ControlFlow(control_flow, index=index, start_control_state=next_control_state)
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
        #print self.hlir.p4_egress_ptr

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
            yaml.safe_dump(self.bir_yaml, stream, default_flow_style=False,
                           indent=4)

def compile_hlir(hlir):
    ''' translate HLIR to BIR '''
    # list of yaml objects
    bir = MetaIR(hlir)
    return bir

class CompileResult(object):
    ''' TODO '''
    def __init__(self, kind, error):
        self.kind = kind
        self.error = error

    def __str__(self):
        if self.kind == "OK":
            return 'compilation successful.'
        else:
            return 'compilation failed with error: ' + self.error

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

    js_program = gen_json.json_dict_create(hlir)

    try:
        bir = compile_hlir(hlir)
        if options.yaml:
            bir.pprint_yaml(os.path.splitext(options.file)[0]+'.yml')
    except CompilationException, e:
        print CompileResult("exception", e.show())

if __name__ == "__main__":
    #hanw: fix pyyaml to print OrderedDict()
    yaml.SafeDumper.add_representer(
        OrderedDict, lambda dumper, value: represent_odict(
            dumper, u'tag:yaml.org,2002:map', value))
    main()
