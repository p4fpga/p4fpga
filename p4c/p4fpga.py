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

logger = logging.getLogger(__name__)

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


# Generate ParseState Object from parseGraph
#
class ParseState(object):
    def __init__(self, id, name):
        self.id = id
        self.name = name
        self.rules = []
        self.len = 0
        self.prevStates = set()
        self.transitions = set()

    def __repr__(self):
        return "ParseState: %s %s %s %s" % (self.id, self.prevStates, self.transitions, self.rules)

    def setPrevState(self, prevState):
        if prevState not in self.prevStates:
            self.prevStates.add(prevState)

    def setTransition(self, transition):
        if transition not in self.transitions:
            self.transitions.add(transition)

    def setRule(self, rule):
        self.rules.append(rule)

    def setLen(self, plen):
        self.len = plen

def render_parsers(ir, json_dict):
    """ """
    parsers = json_dict['parsers']
    assert (len(parsers) == 1), "Only one parser is supported."
    parser = parsers[0]

    map_state = OrderedDict() # id -> state

    map_parse_state_reverse = {}
    map_merged_to_prev_state = {}
    map_unparsed_bits = {}
    map_parse_state_num_rules = {}
    map_rcvd_len = {}
    header_stacks = dict()
    transitions = OrderedDict()
    transition_key = OrderedDict()

    def to_num_rules(state, header_width, unparsed_bits):
        assert type(state) is str
        print 'w:%s, u:%s' % (header_width, unparsed_bits)
        n_cycles = int(math.ceil((header_width - unparsed_bits) / float(config.DP_WIDTH)))
        map_parse_state_num_rules[state] = n_cycles
        return n_cycles

    def get_num_rules(state):
        if state not in map_parse_state_num_rules:
            return None
        return map_parse_state_num_rules[state]

    def to_unparsed_bits(prev_unparsed_bits, n_cycles, hdr_sz):
        unparsed_bits = prev_unparsed_bits + n_cycles * config.DP_WIDTH - hdr_sz
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
        if state not in map_parse_state_reverse:
            return []
        return map_parse_state_reverse[state]

    def get_unparsed_bits(state):
        assert type(state) is str
        if state not in map_unparsed_bits:
            return 0
        return map_unparsed_bits[state]

    def build_map_inversed_transition():
        # build map: state -> prev_state
        for state in parser['parse_states']:
            _transitions = state['transitions']
            for t in _transitions:
                next_state_name = t['next_state']
                next_state = GetState(next_state_name)
                if not t['next_state']: #ignore null state
                    continue
                if next_state_name not in map_parse_state_reverse:
                    map_parse_state_reverse[next_state_name] = set()
                if state['id'] < next_state['id']:
                    map_parse_state_reverse[t['next_state']].add(state['name'])
                else:
                    logger.debug('skipped return transition %s -> %s'%(state['name'], next_state_name))

    # build map: state -> unparsed_bits
    def build_map_unparse_bits():
        for state in parser['parse_states']:
            state_name = state['name']
            hdr_sz = to_header_size(state)
            prev_states = get_prev_state(state_name)
            print prev_states
            if len(prev_states) == 0:
                n_rules = to_num_rules(state_name, hdr_sz, 0)
                unparsed_bits = to_unparsed_bits(0, n_rules, hdr_sz)
                map_unparsed_bits[state_name] = unparsed_bits

            for p in prev_states:
                prev_unparsed_bits = get_unparsed_bits(p)
                if prev_unparsed_bits is not None:
                    n_rules = to_num_rules(state_name, hdr_sz, prev_unparsed_bits)
                    unparsed_bits = to_unparsed_bits(prev_unparsed_bits, n_rules, hdr_sz)
                    map_unparsed_bits[state_name] = unparsed_bits

    # build map: state -> rcvd_len
    def build_map_rcvd_len():
        for state in parser['parse_states']:
            state_name = state['name']
            hdr_sz = to_header_size(state)
            prev_states = get_prev_state(state_name)
            if len(prev_states) == 0:
                print 'no prev-state', state_name
                n_rules = to_num_rules(state_name, hdr_sz, 0)
                rcvd_len = to_rcvd_len(0, n_rules)
                map_rcvd_len[state_name] = rcvd_len

            for p in prev_states:
                prev_unparsed_bits = get_unparsed_bits(p)
                if prev_unparsed_bits is not None:
                    n_rules = to_num_rules(state_name, hdr_sz, prev_unparsed_bits)
                    rcvd_len = to_rcvd_len(prev_unparsed_bits, n_rules)
                    map_rcvd_len[state_name] = rcvd_len

    # build map: state -> transition, transition_key
    def build_map_transitions():
        for state in parser['parse_states']:
            _name = state['name']
            transitions[_name] = state['transitions']
            transition_key[_name] = GetTransitionKey(state)
 
    build_map_inversed_transition()
    build_map_unparse_bits()
    build_map_rcvd_len()
    build_map_transitions()

    #pprint.pprint(list(map_parse_state_reverse.items()))
    #pprint.pprint(list(map_unparsed_bits.items()))
    #pprint.pprint(list(map_rcvd_len.items()))
    #pprint.pprint(list(transitions.items()))
    #pprint.pprint(list(transition_key.items()))

    # build parse rules
    rules = OrderedDict()
    for idx, state in enumerate(parser['parse_states']):
        id = state['id']
        name = state['name']
        parse_state = ParseState(id, name)
        map_state[id] = parse_state

        #parse_state.rcvd_len = map_rcvd_len[id]

    for idx, state in enumerate(parser['parse_states']):
        id = state['id']
        state_name = state['name']
        n_rules = get_num_rules(state_name)
        if n_rules is None:
            continue
        rcvd_len = map_rcvd_len[state_name]
        unparsed_bits = map_unparsed_bits[state_name]
        hdr_sz = to_header_size(state)
        parse_rules = []

        # append rule to state
        # decide type of Rule
        #print 

        if n_rules == 0:
            map_merged_to_prev_state[state_name] = True
            rule = ParseRule( 0, hdr_sz, 0, 0, True, True)
            map_state[id].setRule(rule)
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
                rule = ParseRule( idx, hdr_sz, curr_len,
                                 bits_to_next_state, first_element, last_element)
                map_state[id].setRule(rule)
        rules[state_name] = parse_rules
    # pprint.pprint(list(rules.items()))
    ir.parsers['parser'] = Parser(rules, transitions, transition_key, map_merged_to_prev_state, map_parse_state_reverse, map_state)

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

