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

import math
import config
import pprint
import astbsv as ast
from collections import OrderedDict
from bsvgen_program import Program
from bsvgen_control import Control
from bsvgen_parser import Parser
from bsvgen_deparser import Deparser
from bsvgen_basic_block import BasicBlock
from bsvgen_table import Table
from bsvgen_struct import Struct, StructT, StructMetadata
from utils import CamelCase, GetHeaderWidth
from utils import GetHeaderInState, buildExpression

def render_runtime_types(ir, json_dict):
    # metadata req/rsp
    ir.structs['metadata_request'] = StructT("MetadataRequest")

    responses = []
    for pipeline in json_dict['pipelines']:
        name = pipeline['name']
        for t in sorted(pipeline['tables'], key=lambda k: k['name']):
            tname = t['name']
            tnext = t['actions']
            for n in tnext:
                sname = "%s%sRspT" % (CamelCase(tname), CamelCase(n))
                stmt = []
                stmt.append(ast.StructMember("PacketInstance", "pkt"))
                stmt.append(ast.StructMember("MetadataT", "meta"))
                responses.append(ast.Struct(sname, stmt))
    ir.structs['metadata_response'] = ast.TypeDef("union tagged", "MetadataResponse", responses)
    ir.structs['metadata'] = StructMetadata("MetadataT", ir)

def render_header_types(ir, json_dict):
    for s in json_dict["header_types"]:
        name = s['name']
        struct = Struct(s)
        ir.structs[name] = struct

class ParseRule():
    def __init__(self, idx=0, width=0, rcvdLen=0, nextLen=0,
            firstBeat=False, lastBeat=False, offset=0):
        self.name = None
        self.idx = idx
        self.width = width
        self.rcvdLen = rcvdLen
        self.nextLen = nextLen
        self.firstBeat = firstBeat
        self.lastBeat = lastBeat
        self.offset = offset

    def __repr__(self):
        return "idx:%s width:%s rl:%s nl:%s fb:%s lb:%s off:%s" % (self.idx,
                self.width, self.rcvdLen, self.nextLen, self.firstBeat,
                self.lastBeat, self.offset)

def render_parsers(ir, json_dict):
    """ """
    pp = pprint.PrettyPrinter(indent=4)
    parsers = json_dict['parsers']
    assert (len(parsers) == 1), "Only one parser is supported."
    parser = parsers[0]

    map_parse_state_reverse = {}
    map_merged_to_prev_state = {}
    map_unparsed_bits = {}
    map_parse_state_num_rules = {}
    map_rcvd_len = {}
    header_stacks = dict()
    transitions = OrderedDict()
    transition_key = OrderedDict()

    def name_to_transition_key (name):
        """
        map parse state to keys used for transition to next state.
        """
        keys = []
        for state in parser['parse_states']:
            if state["name"] == name:
                keys = state['transition_key']

        for k in keys:
            w = key_to_width(k['value'])
            k['width'] = w
        return keys

    def key_to_width (key):
        header = key[0]
        field = key[1]
        for h in json_dict['headers']:
            if h['name'] == header:
                hty = h['header_type']
                for t in json_dict['header_types']:
                    if t['name'] == hty:
                        fields = t['fields']
                        for f in fields:
                            if f[0] == field:
                                return f[1]
        return None

    def to_num_rules(state, header_width, unparsed_bits):
        assert type(state) is str
        print 'w:%s, u:%s' % (header_width, unparsed_bits)
        n_cycles = int(math.ceil((header_width - unparsed_bits) / float(config.DP_WIDTH)))
        map_parse_state_num_rules[state_name] = n_cycles
        return n_cycles

    def get_num_rules(state):
        if state not in map_parse_state_num_rules:
            return None
        return map_parse_state_num_rules[state]

    def to_unparsed_bits(prev_unparsed_bits, n_cycles, hdr_sz):
        unparsed_bits = prev_unparsed_bits + n_cycles * config.DP_WIDTH - hdr_sz
        print unparsed_bits
        return unparsed_bits

    def to_header_size(state):
        hdr_sz = 0
        state_name = state['name']
        hdrs = GetHeaderInState(state_name)
        print hdrs
        for hdr in hdrs:
            hdr_sz += GetHeaderWidth(hdr)
        return hdr_sz

    def to_rcvd_len(prev_unparsed_bits, n_cycles):
        return n_cycles * config.DP_WIDTH + prev_unparsed_bits

    def get_prev_state(state):
        assert type(state) is str
        if state == 'start':
            return []
        else:
            #FIXME: what if there are more than one prev_state?
            prev_state = map_parse_state_reverse[state]
            return prev_state

    def get_unparsed_bits(state):
        assert type(state) is str
        if state == 'start':
            return 0
        if state not in map_unparsed_bits:
            print 'TTTT'
            return None # uninitialized
        return map_unparsed_bits[state]

    # build map: state -> prev_state
    for idx, state in enumerate(parser['parse_states']):
        _transitions = state['transitions']
        for t in _transitions:
            next_state = t['next_state']
            if not t['next_state']: #ignore null state
                continue
            if next_state not in map_parse_state_reverse:
                map_parse_state_reverse[next_state] = set()
            map_parse_state_reverse[t['next_state']].add(state['name'])
    pp.pprint(map_parse_state_reverse)

    # build map: state -> unparsed_bits, state -> rcvd_len
    for idx, state in enumerate(parser['parse_states']):
        state_name = state['name']
        hdr_sz = to_header_size(state)
        prev_states = get_prev_state(state_name)
        print 'TTTT', idx, state_name, hdr_sz, prev_states
        if len(prev_states) == 0:
            n_rules = to_num_rules(state_name, hdr_sz, 0)
            unparsed_bits = to_unparsed_bits(0, n_rules, hdr_sz)
            rcvd_len = to_rcvd_len(0, n_rules)
            map_unparsed_bits[state_name] = unparsed_bits
            map_rcvd_len[state_name] = rcvd_len
            print 'xxx %s %s %s %s prev_unparsed:%s rcvdlen:%s unparsed:%s'%(state_name, prev_states, hdr_sz, n_rules, 0, rcvd_len, unparsed_bits)

        for p in prev_states:
            prev_unparsed_bits = get_unparsed_bits(p)
            if prev_unparsed_bits is not None:
                n_rules = to_num_rules(state_name, hdr_sz, prev_unparsed_bits)
                unparsed_bits = to_unparsed_bits(prev_unparsed_bits, n_rules, hdr_sz)
                rcvd_len = to_rcvd_len(prev_unparsed_bits, n_rules)
                map_unparsed_bits[state_name] = unparsed_bits
                map_rcvd_len[state_name] = rcvd_len
                print 'xxx %s %s %s %s prev_unparsed:%s rcvdlen:%s unparsed:%s'%(state_name, prev_states, hdr_sz, n_rules, prev_unparsed_bits, rcvd_len, unparsed_bits)
    print 'map_unparsed_bit', map_unparsed_bits
    print 'map_rcvd_len', map_rcvd_len

    # build map: state -> transition, transition_key
    for idx, state in enumerate(parser['parse_states']):
        state_name = state['name']
        transitions[state_name] = state['transitions']
        transition_key[state_name] = name_to_transition_key(state_name)
    print 'transitions', transitions
    print 'transition_key', transition_key

    # build parse rules
    rules = OrderedDict()
    for idx, state in enumerate(parser['parse_states']):
        state_name = state['name']
        print 'idx %s, state %s' % (idx, state_name)
        n_rules = get_num_rules(state_name)
        print 'n_rules', n_rules
        if n_rules is None:
            continue
        rcvd_len = map_rcvd_len[state_name]
        unparsed_bits = map_unparsed_bits[state_name]
        hdr_sz = to_header_size(state)
        parse_rules = []
        print "xxx", state_name, rcvd_len

        if n_rules == 0:
            map_merged_to_prev_state[state_name] = True
            rule = ParseRule(0, hdr_sz, 0, 0, True, True)
            parse_rules.append(rule)
        else:
            map_merged_to_prev_state[state_name] = False
            bits_to_next_state = None
            for idx in range(n_rules):
                first_element = False
                last_element = False
                if idx == range(n_rules)[0]:
                    first_element = True
                if idx == range(n_rules)[-1]:
                    last_element = True
                    bits_to_next_state = unparsed_bits
                curr_len = rcvd_len - (config.DP_WIDTH) * (n_rules - 1 - idx)
                #print "xxx", state_name, curr_len
                rule = ParseRule(idx, hdr_sz, curr_len,
                                 bits_to_next_state, first_element, last_element)
                parse_rules.append(rule)
        rules[state_name] = parse_rules
    print 'rules', rules
    # create Parser object for codegen
    ir.parsers['parser'] = Parser(rules, transitions, transition_key, map_merged_to_prev_state, map_parse_state_reverse)

def render_deparsers(ir, json_dict):
    deparsers = json_dict['deparsers']
    assert (len(deparsers) == 1), "Only one deparser is supported."
    deparser = deparsers[0]
    deparse_states = deparser['order']
    deparse_state0 = deparse_states[0]
    for idx, state in enumerate(deparse_states):
        print idx, state
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
            buildExpression(c["expression"], expr, metadata)
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
    render_parsers(ir, json_dict)
    render_deparsers(ir, json_dict)
    render_basic_blocks(ir, json_dict)
    render_pipelines(ir, json_dict)
    render_runtime_types(ir, json_dict)
    return ir

