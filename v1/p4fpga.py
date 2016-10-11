# Copyright 2016 P4FPGA Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Mid-end pass for P4FPGA compiler
# For now, it takes p4c-bmv2 json as frontend output, and generates
# P4FPGA-specific representation
#
# TODO: replace this module with a more proper c++ pass.

import math, json
import config
import pprint
import astbsv as ast
import logging
from collections import OrderedDict
from bsvgen_program import Program
from bsvgen_control import Control
from bsvgen_parser import Parser
from bsvgen_deparser import Deparser
from bsvgen_basic_block import BasicBlock
from bsvgen_table import Table
from bsvgen_struct import Struct, StructT, StructMetadata
from utils import CamelCase, GetHeaderWidth, GetFieldWidth, GetState
from utils import GetHeaderInState, BuildExpression, GetTransitionKey
from utils import GetHeaderWidthInState, p4name, GetHeaderType
from ast_util import ParseState

logger = logging.getLogger(__name__)

def process_global_metadata(ir):
    '''
    Build a dictionary of metadata organized as dictioanry
    with packet header as key, and list of tuple(width, field) as value.
    '''
    metadata = {}
    def add_field (header, field):
        if header not in metadata:
            metadata[header] = set()
        metadata[header].add(field)

    for it in ir.basic_blocks.values():
        for f in it.request.members:
            if f not in metadata:
                width = GetFieldWidth(f)
                if type(f) == tuple:
                    header = f[0].translate(None, "[]")
                    field = f[1]
                add_field(header, (width, field))
        for f in it.response.members:
            if f not in metadata:
                width = GetFieldWidth(f)
                if type(f) == tuple:
                    header = f[0].translate(None, "[]")
                    field = f[1]
                add_field(header, (width, field))
        for f in it.runtime_data:
            if f not in metadata:
                width = f[0]
                header = 'runtime'
                field = "%s_%d" %(f[1], f[0])
                add_field(header, (width, field))

    for f in ir.controls.values():
        for _, v in f.tables.items():
            for k in v.key:
                d = k['target']
                if type(k['target']) == list:
                    d = tuple(k['target'])
                if d not in metadata:
                    width = GetFieldWidth(k['target'])
                    if type(d) is tuple:
                        header = d[0]
                        field = d[1]
                    add_field(header, (width, field))
    # save to ir object
    return metadata

def render_runtime_types(ir, json_dict):
    # metadata req/rsp
    ir.structs['metadata_request'] = StructT("MetadataRequest")
    ir.structs['metadata_response'] = StructT("MetadataResponse")

    #responses = []
    for pipeline in json_dict['pipelines']:
        name = pipeline['name']
        for t in sorted(pipeline['tables'], key=lambda k: k['name']):
            responses = []
            tname = t['name']
            tnext = t['actions']
            for n in tnext:
                sname = "%s%sRspT" % (CamelCase(tname), CamelCase(n))
                stmt = []
                stmt.append(ast.StructMember("PacketInstance", "pkt"))
                stmt.append(ast.StructMember("MetadataT", "meta"))
                responses.append(ast.Struct(sname, stmt))
            union_name = "%sResponse" % CamelCase(tname)
            ir.structs[union_name] = ast.TypeDef("union tagged", union_name, responses)
    ir.structs['metadata'] = StructMetadata("MetadataT", ir)

def render_header_types(ir, json_dict):
    for s in json_dict["header_types"]:
        name = s['name']
        struct = Struct(s)
        ir.structs[name] = struct

class ParseRule():
    def __init__(self, id=0, width=0, offset=0):
        self.id = id
        self.width = width
        self.offset = offset

    def __repr__(self):
        return "id:%s width:%s off:%s" % (self.id, self.width, self.offset)

    #define @property

map_state = OrderedDict() # id -> state

def render_parsers(ir, json_dict):
    parsers = json_dict['parsers']
    assert (len(parsers) == 1), "Only one parser is supported."
    parser = parsers[0]

    for idx, state in enumerate(parser['parse_states']):
        _id = state['id']
        _name = state['name']
        parse_state = ParseState(_id, _name)
        map_state[_id] = parse_state
        parse_state.transitions = state['transitions']
        parse_state.parse_ops = state['parser_ops']
        parse_state.transition_keys = GetTransitionKey(state)
        if parse_state.parse_ops == []:
            parse_state.state_type = ParseState.EMPTY
    ir.parsers['parser'] = Parser(map_state, ir.global_metadata)

def render_deparsers(ir, json_dict):
    deparsers = json_dict['deparsers']
    assert (len(deparsers) == 1), "Only one deparser is supported."
    deparser = deparsers[0]
    deparse_states = deparser['order']
    deparse_state0 = deparse_states[0]
    for idx, state in enumerate(deparse_states):
        print 'deparser', idx, state
    ir.deparsers['deparser'] = Deparser(deparse_states)

def render_pipelines(ir, json_dict):
    '''
        Control Flow and Table.
        ** optimization to be done.
    '''
    pipelines = json_dict["pipelines"]
    for pipeline in pipelines:
        name = pipeline["name"]
        control = Control(name)

        control.init_table = pipeline['init_table']

        for t in sorted(pipeline["tables"], key=lambda k: k['name'], reverse=False):
            tname = t['name']
            basic_blocks = ir.basic_blocks
            control.tables[tname] = Table(t, basic_blocks, json_dict)
            for idx, action in sorted(enumerate(t['actions'])):
                basic_block = ir.basic_blocks[action]
                control.basic_blocks.append(basic_block)

        for c in sorted(pipeline["conditionals"]):
            cname = c['name']
            expr = []
            metadata = []
            BuildExpression(c["expression"], expr, metadata)
            #print "xxxxx", expr
            if expr[1] == "valid":
                _expr = "isValid(%s)" % ("meta."+"_".join(expr[1:-1]))
            else:
                _expr = " ".join(expr)
            #print 'zaaa', cname, metadata
            control.conditionals[cname] = {'expression': _expr,
                                           'true_next': c['true_next'],
                                           'false_next': c['false_next'],
                                           'metadata': metadata}
            control.entry.append(cname)

        # registers
        control.registers = json_dict['register_arrays']

        ir.controls[name] = control

def render_basic_blocks(ir, json_dict):
    '''
        Basic blocks implements P4 actions.
        ** optimization to be done.
    '''
    actions = json_dict["actions"]
    # sort actions by name to ensure generated code are consistent every time.
    for action in sorted(actions, key=lambda k: k['name'], reverse=False):
        name = action["name"]
        basicblock = BasicBlock(action, json_dict)
        ir.basic_blocks[name] = basicblock

def ir_create(json_dict):
    ir = Program("program", "ir_meta.yml")
    config.jsondata = json_dict
    config.ir = ir
    render_header_types(ir, json_dict)
    render_deparsers(ir, json_dict)
    render_basic_blocks(ir, json_dict)
    render_pipelines(ir, json_dict)
    ir.global_metadata = process_global_metadata(ir)
    render_runtime_types(ir, json_dict)
    render_parsers(ir, json_dict)
    return ir

