#!/usr/bin/python
''' P4FPGA BIR compiler prototype
    It translates HLIR to BIR and generates Bluespec from BIR
'''

import argparse
from collections import OrderedDict
from p4_hlir.main import HLIR
from p4_hlir.hlir import p4_parse_state, p4_action, p4_table, p4_header_instance

# Class definition derived from bir_meta.yaml
class Struct(object):
    ''' struct '''
    required_attributes = ['fields']
    def __init__(self, hlirHeader):
        if isinstance(hlirHeader, p4_header_instance):
            self.fields = OrderedDict()
            for tmp_field in hlirHeader.fields:
                self.fields[tmp_field.name] = tmp_field.width
        elif isinstance(hlirHeader, p4_table):
            print 'request'
            print 'response'
            pass

class Metadata(object):
    ''' metadata '''
    required_attributes = ['values', 'visibility', 'value_inits']
    def __init__(self, hlirMetadata):
        print hlirMetadata

class Table(object):
    ''' tables '''
    required_attributes = ['match_type', 'depth', 'request',
                           'response', 'operations']
    def __init__(self, table):
        #print vars(table)
        pass

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

class ControlFlow(object):
    ''' control_flow '''
    required_attributes = ['start_control_state']
    def __init__(self, controlFlow):
        pass

class ProcessorLayout(object):
    ''' processor_layout '''
    required_attributes = ['format', 'implementation']
    def __init__(self, hlirParser):
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

        self.processor_layout = OrderedDict()
        self.tables = OrderedDict()
        self.structs = OrderedDict()
        self.basic_blocks = OrderedDict()
        self.metadata = OrderedDict()
        self.table_initialization = OrderedDict()

        self.construct()

    def construct(self):
        ''' HLIR -> BIR '''

        # struct & metadata
        for hdr in self.hlir.p4_header_instances.values():
            print 'header instances', hdr, hdr.max_index, hdr.metadata
            if hdr.metadata:
                self.metadata[hdr.name] = Metadata(hdr)
            else:
                self.structs[hdr.name] = Struct(hdr)
            #FIXME handle stack

        # basic_block
        for state in self.hlir.p4_parse_states.values():
            self.basic_blocks[state.name] = BasicBlock(state)

        # table
        for tbl in self.hlir.p4_tables.values():
            self.basic_blocks[tbl.name] = BasicBlock(tbl)
            self.tables[tbl.name] = Table(tbl)
            self.structs[tbl.name] = Struct(tbl)

        for action in self.hlir.p4_actions.values():
            self.basic_blocks[action.name] = BasicBlock(action)
            print 'p4action', action

        # control flow
        for cond in self.hlir.p4_conditional_nodes.values():
            print 'conditional', cond

        for ingress in self.hlir.p4_ingress_ptr.keys():
            print 'ingress', ingress

        print self.hlir.p4_egress_ptr

        # other module
        for cntr in self.hlir.p4_counters.values():
            print 'p4counter', cntr

        # other processor

    def pprint_yaml(self):
        ''' pretty print to yaml '''
        pass


def compile_hlir(hlir):
    ''' translate HLIR to BIR '''
    # list of yaml objects
    bir = MetaIR(hlir)
    return bir

def main():
    ''' entry point '''
    argparser = argparse.ArgumentParser(description="P4FPGA P4 to Bluespec Compiler")
    argparser.add_argument('-f', '--file', required=True,
                           help='Input P4 program')
    options = argparser.parse_args()

    hlir = HLIR(options.file)
    hlir.build()

    bir = compile_hlir(hlir)

if __name__ == "__main__":
    main()
