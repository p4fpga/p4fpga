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
import os

def CamelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output

def camelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output[0].lower() + output[1:]

def header_type_to_width (header_type):
    assert type(header_type) == str
    for h in config.jsondata["header_types"]:
        if h["name"] == header_type:
            fields = h["fields"]
            width = sum([x for _, x in fields])
            return width
    return None

def header_to_width (header):
    assert type(header) == str
    #print 'htow', header
    for h in config.jsondata["headers"]:
        if h["name"] == header:
            hty = h["header_type"]
            return header_type_to_width(hty)
    return None

def field_to_width (field, json_dict):
    assert type(field) is list
    hty = None
    fields = None
    for h in json_dict["headers"]:
        if h["name"] == field[0]:
            hty = h["header_type"]
            #print hty

    for h in json_dict["header_types"]:
        if h["name"] == hty:
            fields = h["fields"]
    for f, width in fields:
        if f == field[1]:
            #print field, width
            return width

def header_to_header_type(header):
    assert type(header) == str
    for h in config.jsondata["headers"]:
        if h["name"] == header:
            return h["header_type"]
    return None

def field_width(field, header_types, headers):
    #print field, header_types, headers
    header_type = None
    for h in headers:
        if h['name'] == field[0]:
            header_type = h['header_type']
    for f in header_types:
        if f['name'] == header_type:
            for p in f['fields']:
                if p[0] == field[1]:
                    return p[1]
    return None

def state_name_to_state (state_name):
    for s in config.jsondata['parsers'][0]['parse_states']:
        if s['name'] == state_name:
            return s
    return None

def state_to_header (state_name):
    state = state_name_to_state(state_name)
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


def createDirAndOpen(f, m):
    (d, name) = os.path.split(f)
    if not os.path.exists(d):
        os.makedirs(d)
    return open(f, m)

