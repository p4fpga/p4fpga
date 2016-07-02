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

def CamelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output

def camelCase(name):
    output = ''.join(x for x in name.title() if x.isalnum())
    return output[0].lower() + output[1:]

def header_type_to_width (header_type, json_dict):
    assert type(header_type) == str
    for h in json_dict["header_types"]:
        if h["name"] == header_type:
            fields = h["fields"]
            width = sum([x for _, x in fields])
            return width
    return None

def header_to_width (header, json_dict):
    assert type(header) == str
    #print 'htow', header
    for h in json_dict["headers"]:
        if h["name"] == header:
            hty = h["header_type"]
            return header_type_to_width(hty, json_dict)
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

def header_to_header_type(header, json_dict):
    assert type(header) == str
    for h in json_dict["headers"]:
        if h["name"] == header:
            return h["header_type"]
    return None


