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
from utils import GetHeaderWidthInState

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
    def __init__(self, idx=0, width=0, rcvdlen=0, nextlen=0,
            firstBeat=False, lastBeat=False, offset=0):
        self.name = None
        self.idx = idx
        self.width = width
        self.rcvdlen = rcvdlen
        self.nextlen = nextlen
        self.firstBeat = firstBeat
        self.lastBeat = lastBeat
        self.offset = offset

    def __repr__(self):
        return "idx:%s width:%s rl:%s nl:%s fb:%s lb:%s off:%s" % (self.idx,
                self.width, self.rcvdlen, self.nextlen, self.firstBeat,
                self.lastBeat, self.offset)

    #define @property

# Generate ParseState Object from parseGraph
class ParseState(object):
    def __init__(self, id, name):
        self.id = id
        self.name = name
        self.rules = []
        self.len = 0
        self.prevStates = set()
        self.transitions = set()
        self.unparsedBits = set()
        self.rcvdlens = set()

        self._num_rules = 0

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

    @property
    def num_rules(self):
        return self._num_rules

    @num_rules.setter
    def num_rules(self, value):
        self._num_rules = value

def build_prev_state_map(state_id):
    # build map: state -> prev_state
    prev_states = set()
    for state in config.jsondata['parsers'][0]['parse_states']:
        _id = state['id']
        _transitions = state['transitions']
        if _id != state_id:
            continue
        for t in _transitions:
            next_state_name = t['next_state']
            next_state = GetState(next_state_name)
            if not t['next_state']: #ignore null state
                continue
            next_state_id = next_state['id']
            if _id < next_state_id:
                prev_states.add(_id)
            else:
                logger.debug('skipped transition %s -> %s'%(state['name'], next_state_name))
    print 'yyy', prev_states
    return prev_states

def build_transitions_map():
    pass

def to_num_rules(header_width, unparsed_bits):
    print 'w:%s, u:%s' % (header_width, unparsed_bits)
    n_cycles = int(math.ceil((header_width - unparsed_bits) / float(config.DP_WIDTH)))
    return n_cycles

# build map: state -> unparsed_bits
def build_unparsed_bits_map():
    global map_state, parser
    set_unparsed_bits = set()
    for state in parser['parse_states']:
        _id = state['id']
        state_name = state['name']
        hdr_sz = GetHeaderWidthInState(state)
        prev_states = map_state[_id].prevStates
        #prev_states = get_prev_state(_id)
        if len(prev_states) == 0:
            #n_rules = to_num_rules(hdr_sz, 0)
            unparsed_bits = to_unparsed_bits(0, n_rules, hdr_sz)
            #map_unparsed_bits[_id] = unparsed_bits
            set_unparsed_bits.add((0, unparsed_bits))

        print 'xxx id=%s prevStates=%s' %(_id, prev_states)
        for p in prev_states:
            #prev_unparsed_bits = get_unparsed_bits(p)
            prev_unparsed_bits = map_state[p].unparsedBits
            if prev_unparsed_bits is not None:
                print 'xxx', prev_unparsed_bits
                map_state[_id].num_rules = to_num_rules(hdr_sz, prev_unparsed_bits)
                unparsed_bits = to_unparsed_bits(prev_unparsed_bits, n_rules, hdr_sz)
                #map_unparsed_bits[_id] = unparsed_bits
                set_unparsed_bits.add((p, unparsed_bits))
    return set_unparsed_bits

map_state = OrderedDict() # id -> state
parser = None

def render_parsers(ir, json_dict):
    global parser
    """ """
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

    def get_num_rules(_id):
        if _id not in map_parse_state_num_rules:
            return None
        return map_parse_state_num_rules[_id]

    def to_unparsed_bits(prev_unparsed_bits, n_cycles, hdr_sz):
        unparsed_bits = prev_unparsed_bits + n_cycles * config.DP_WIDTH - hdr_sz
        return unparsed_bits

    def to_rcvd_len(prev_unparsed_bits, n_cycles):
        return n_cycles * config.DP_WIDTH + prev_unparsed_bits

    def get_prev_state(id):
        assert type(id) is int
        if id not in map_parse_state_reverse:
            return []
        return map_parse_state_reverse[id]

    def get_unparsed_bits(_id):
        assert type(_id) is int
        if _id not in map_unparsed_bits:
            return 0
        return map_unparsed_bits[_id]

    # build map: state -> rcvd_len
    #FIXME: maybe this is not necessary
    def build_map_rcvd_len():
        for state in parser['parse_states']:
            _id = state['id']
            state_name = state['name']
            hdr_sz = GetHeaderWidthInState(state)
            #prev_states = get_prev_state(_id)
            if len(prev_states) == 0:
                print 'no prev-state', state_name
                n_rules = to_num_rules(hdr_sz, 0)
                rcvd_len = to_rcvd_len(0, n_rules)
                map_rcvd_len[_id] = rcvd_len

            for p in prev_states:
                prev_unparsed_bits = get_unparsed_bits(p)
                if prev_unparsed_bits is not None:
                    n_rules = to_num_rules(hdr_sz, prev_unparsed_bits)
                    rcvd_len = to_rcvd_len(prev_unparsed_bits, n_rules)
                    map_rcvd_len[_id] = rcvd_len

    # build map: state -> transition, transition_key
    def build_map_transitions():
        for state in parser['parse_states']:
            _name = state['name']
            transitions[_name] = state['transitions']
            transition_key[_name] = GetTransitionKey(state)
 
    #build_prev_state_map()
    #build_map_unparse_bits()
    build_map_rcvd_len()
    build_map_transitions()

    for state in parser['parse_states']:
        print state['id'], state['name']
    pprint.pprint(list(map_parse_state_reverse.items()))
    pprint.pprint(list(map_unparsed_bits.items()))
    pprint.pprint(list(map_rcvd_len.items()))
    pprint.pprint(list(map_parse_state_num_rules.items()))
    #pprint.pprint(list(transitions.items()))
    #pprint.pprint(list(transition_key.items()))

    rules = OrderedDict()
    for idx, state in enumerate(parser['parse_states']):
        _id = state['id']
        state_name = state['name']
        parse_state = ParseState(_id, state_name)
        map_state[_id] = parse_state
        parse_state.prevStates = build_prev_state_map(_id)
        parse_state.transitions = build_transitions_map()
        parse_state.unparsedBits = build_unparsed_bits_map()
        #parse_state.rcvdlen = map_rcvd_len[_id]

    for idx, state in enumerate(parser['parse_states']):
        _id = state['id']
        state_name = state['name']
        n_rules = get_num_rules(_id)
        if n_rules is None:
            continue
        rcvd_len = map_rcvd_len[_id]
        unparsed_bits = map_unparsed_bits[_id]
        hdr_sz = GetHeaderWidthInState(state)
        parse_rules = []

        if n_rules == 0:
            map_merged_to_prev_state[state_name] = True
            rule = ParseRule(0, hdr_sz, 0, 0, True, True)
            map_state[_id].setRule(rule)
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
                map_state[_id].setRule(rule)
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
    #render_parsers(ir, json_dict)
    render_deparsers(ir, json_dict)
    render_basic_blocks(ir, json_dict)
    render_pipelines(ir, json_dict)
    render_runtime_types(ir, json_dict)
    return ir

