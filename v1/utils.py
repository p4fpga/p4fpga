# Copyright (c) 2016 P4FPGA Project
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

import config
import os, re
import pprint
import astbsv as ast

def CamelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output

def camelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output[0].lower() + output[1:]

def GetExpressionInState (state_name):
    state = GetState(state_name)
    # HACK: dealing with BMV2 json format
    for op in state['parser_ops']:
        src = []
        dst = []
        dst_hdr = []
        src_hdr = []
        if op['op'] == 'set':
            exp0 = op['parameters'][0]
            BuildExpression(exp0, dst, dst_hdr)
            exp1 = op['parameters'][1]
            if exp1['type'] == 'expression':
                if exp1['value']:
                    BuildExpression(exp1['value'], src, [])
                    return 'expression', dst, src
            elif exp1['type'] == 'hexstr':
                hexstr = hex(int(exp1['value'], 16))
                return 'field', dst, hexstr.rstrip('L')
            else:
                BuildExpression(exp1, [], src)
                return 'field', dst, src[0]
    return None, None, None

def GetFieldWidth(field):
    hty = None
    fields = None
    #print field
    for h in config.jsondata["headers"]:
        if h['name'].startswith(field[0]):
            hty = h["header_type"]
            #print field[0], h['name']
            break

    for h in config.jsondata["header_types"]:
        #print h['name'], hty
        if h["name"] == hty:
            fields = h["fields"]

    for f, width in fields:
        if f == field[1]:
            return width
    return None

def GetHeaderType(header):
    assert type(header) == str
    for h in config.jsondata["headers"]:
        if h["name"].startswith(header):
            return h["header_type"]
    return None

def GetHeaderTypeWidth(header_type):
    assert type(header_type) == str
    for h in config.jsondata["header_types"]:
        if h["name"] == header_type:
            fields = h["fields"]
            width = sum([x for _, x in fields])
            return width
    return None

def GetHeaderWidth(header):
    assert type(header) == str
    #print 'htow', header
    for h in config.jsondata["headers"]:
        if h["name"] == header:
            hty = h["header_type"]
            return GetHeaderTypeWidth(hty)
    return None

def GetHeaderWidthInState(name):
    hdr_sz = 0
    hdrs = GetHeaderInState(name)
    for hdr in hdrs:
        hdr_sz += GetHeaderWidth(hdr)
    return hdr_sz

def GetHeaderInState(state_name):
    state = GetState(state_name)
    if state is None:
        return []
    headers = []
    header_stacks = []
    stack = False
    for op in state["parser_ops"]:
        if op["op"] == "extract":
            parameters = op['parameters'][0]
            if parameters['type'] == "regular":
                value = parameters["value"]
                headers.append(value)
            elif parameters['type'] == 'stack':
                value = parameters['value']
                headers.append("%s[%d]" % (value, 0))
    return headers

def GetState(state_name):
    for s in config.jsondata['parsers'][0]['parse_states']:
        #print s['name'], state_name
        if s['name'] == state_name:
            return s
    return None

def GetStateWithId(id):
    for s in config.jsondata['parsers'][0]['parse_states']:
        if s['id'] == id:
            return s
    return None

def GetTransitionKey(state):
    keys = state['transition_key']
    for k in keys:
        if k['type'] == 'lookahead':
            k['width'] = k['value'][1] - k['value'][0]
        else:
            w = GetFieldWidth(k['value'])
            k['width'] = w
    return keys

def map_bsv(op):
    _dict = {"and" : "&&",
             "or"  : "||",
             "not" : "!",
             "valid" : "isValid"}
    if op in _dict:
        return _dict[op]
    else: 
        return op

def BuildExpression(json_data, sb=[], metadata=[]):
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
            BuildExpression(value["left"], sb, metadata)
            sb.append(op)
            BuildExpression(value["right"], sb, metadata)
            sb.append(")")
        else:
            if ((op == "+") or op == "-") and json_left is None:
                print "expr push back load const"
            else:
                BuildExpression(json_left, sb, metadata)
            sb.append(map_bsv(op))
            if (op == 'valid'):
                sb.append("(")
                if (json_right['type'] == 'header'):
                    json_right['value'] = "meta.valid_%s" % json_right['value']
                BuildExpression(json_right, sb, metadata)
                sb.append(")")
            else:
                BuildExpression(json_right, sb, metadata)
            sb.append(")")
    elif (json_type == "header"):
        if type(json_value) == list:
            sb.append(p4name(json_value))
        else:
            sb.append(json_value)
        metadata.append(json_value)
    elif (json_type == "field"):
        if type(json_value) == list:
            sb.append(p4name(json_value))
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

def createDirAndOpen(f, m):
    (d, name) = os.path.split(f)
    if not os.path.exists(d):
        os.makedirs(d)
    return open(f, m)

def p4name(name):
    return "$".join(name).translate(None, "[]")
