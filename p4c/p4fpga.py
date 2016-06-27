# Copyright 2016 Han Wang
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

from collections import OrderedDict
from pprint import pprint
from bsvgen_program import Program
from bsvgen_control import Control
from bsvgen_basic_block import BasicBlock
from bsvgen_table import Table
from bsvgen_struct import Struct, StructT, StructMetadata
from lib.utils import CamelCase
import lib.ast as ast

def render_runtime_types(ir, json_dict):
    # metadata req/rsp
    ir.structs['metadata_request'] = StructT("MetadataRequest")
    ir.structs['metadata_response'] = StructT("MetadataResponse")

    # metadata
    header_types = json_dict['header_types']
    header_instances = json_dict['headers']
    ir.structs['metadata'] = StructMetadata("MetadataT", ir, header_types, header_instances)

def render_header_types(ir, json_dict):
    for s in json_dict["header_types"]:
        name = s['name']
        struct = Struct(s)
        ir.structs[name] = struct

def render_parsers(ir, json_dict):
    # TODO: generate IR_basic_block objects
    stack = []
    visited = set()
    parse_rules = OrderedDict()

    parsers = json_dict["parsers"]
    assert (len(parsers) == 1), "only one parser is supported."
    parser = parsers[0]

    str_init_state = parser["init_state"]
    lst_parse_states = parser["parse_states"]

    def name_to_parse_state (name):
        for state in lst_parse_states:
            if state["name"] == name:
                return state
        return None

    def state_to_header (state):
        assert type(state) == OrderedDict
        for op in state["parser_ops"]:
            if op["op"] == "extract":
                parameters = op["parameters"][0]
                value = parameters["value"]
                return value
        return None

    def header_type_to_width (header_type):
        assert type(header_type) == str
        for h in json_dict["header_types"]:
            if h["name"] == header_type:
                fields = h["fields"]
                width = sum([x for _, x in fields])
                return width
        return None

    def header_to_width (header):
        assert type(header) == str
        for h in json_dict["headers"]:
            if h["name"] == header:
                hty = h["header_type"]
                return header_type_to_width(hty)
        return None

    def expand_parse_state (curr_offset, header_width):
        ''' expand parse_state to multiple cycles if needed '''
        parse_steps = []
        first_step = True
        last_step = False
        step_id = 0
        while curr_offset < header_width:
            parse_step = OrderedDict()
            parse_step["id"] = step_id
            parse_step["carry_len"] = curr_offset - 128
            parse_step["curr_len"] = curr_offset
            if (curr_offset > header_width):
                parse_step["carry_out_len"] = curr_offset - header_width
            parse_step["first_step"] = first_step
            if first_step:
                first_step = False
            parse_step["last_step"] = last_step
            curr_offset += 128
            step_id += 1
            parse_steps.append(parse_step)
        parse_step = OrderedDict()
        parse_step["id"] = step_id
        parse_step["carry_len"] = curr_offset - 128
        parse_step["curr_len"] = curr_offset
        parse_step["carry_out_len"] = curr_offset - header_width
        parse_step["carry_out_offset"] = header_width
        parse_step["first_step"] = first_step
        parse_step["last_step"] = True
        parse_steps.append(parse_step)
        return parse_steps

    def walk_parse_states (prev_bits, state):
        name = state["name"]
        visited.add(name)
        stack.append(name)

        curr_bits = prev_bits
        curr_bits += 128

        header = state_to_header(state)
        if header:
            width = header_to_width(header)
            num_steps = expand_parse_state(prev_bits, width)
            parse_rules[name] = num_steps

        for t in state["transitions"]:
            next_state_name = t["next_state"]
            if next_state_name:
                next_state = name_to_parse_state(next_state_name)
                walk_parse_states(0, next_state)
        stack.pop()

    obj_init_state = name_to_parse_state(str_init_state)
    walk_parse_states(0, obj_init_state)
    ir["parse_rules"] = parse_rules

def render_deparsers(ir, json_dict):
    # TODO: generate IR_basic_block objects
    pass

def build_expression(json_data, sb=[], metadata=[]):
    if not json_data:
        return
    json_type = json_data["type"]
    json_value = json_data["value"]
    if (json_type == "expression"):
        op = json_value["op"]
        json_left = json_value["left"]
        json_right = json_value["right"]

        sb.append("(")
        if (op == "?"):
            json_cond = json_data["cond"]
            build_expression(value["left"], sb, metadata)
            sb.append(op)
            build_expression(value["right"], sb, metadata)
            sb.append(")")
        else:
            if ((op == "+") or op == "-") and json_left is None:
                print "expr push back load const"
            else:
                build_expression(json_left, sb, metadata)
            sb.append(op)
            build_expression(json_right, sb, metadata)
            sb.append(")")
    elif (json_type == "header"):
        if type(json_value) == list:
            sb.append("$".join(json_value))
        else:
            sb.append(json_value)
        metadata.append(json_value)
    elif (json_type == "field"):
        if type(json_value) == list:
            sb.append("$".join(json_value))
        else:
            sb.append(json_value)
        metadata.append(json_value)
    elif (json_type == "bool"):
        sb.append(json_value)
    elif (json_type == "hexstr"):
        sb.append(json_value)
    elif (json_type == "local"):
        sb.append(json_value)
    elif (json_type == "register"):
        sb.append(json_value)
    else:
        assert "Error: unimplemented expression type", json_type

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

        for t in sorted(pipeline["tables"]):
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
            build_expression(c["expression"], expr, metadata)
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
    render_header_types(ir, json_dict)
    #render_parsers(ir, json_dict)
    #render_deparsers(ir, json_dict)
    render_basic_blocks(ir, json_dict)
    render_pipelines(ir, json_dict)
    render_runtime_types(ir, json_dict)
    return ir

