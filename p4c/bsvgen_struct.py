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

import math
import astbsv as ast
import logging
from sourceCodeBuilder import SourceCodeBuilder
from utils import CamelCase, camelCase, GetFieldWidth, p4name
from collections import OrderedDict
from bsvgen_keyword import Keywords

STRUCT_DEFAULT="""\
instance DefaultValue#(%(name)s);
  defaultValue = unpack(0);
endinstance
"""

STRUCT_MASK="""\
instance DefaultMask#(%(name)s);
  defaultMask = unpack(maxBound);
endinstance
"""

EXTRACT_TEMP="""\
function %(name)s extract_%(lname)s(Bit#(%(width)s) data);
  return unpack(byteSwap(data));
endfunction
"""

def avoid_bsv_keyword(word):
    if word in Keywords:
        word = "_" + word
    return word

class Struct(object):
    def __init__(self, struct_attrs):
        self.name = struct_attrs['name']
        self.stmt = []
        fields = struct_attrs['fields']
        e = []
        for f, l in fields:
            if f[0].isupper():
                f = f[0].lower() + f
            e.append(ast.StructMember("Bit#(%s)"%(l), avoid_bsv_keyword(f)))
        self.struct = ast.Struct(CamelCase(self.name), e)
        self._add_defaults(fields)

    def _add_defaults(self, fields):
        self.stmt.append(ast.Template(STRUCT_DEFAULT, {"name": CamelCase(self.name)}))
        self.stmt.append(ast.Template(STRUCT_MASK, {"name": CamelCase(self.name)}))
        _sum = 0
        for _, l in fields:
            _sum += l
        self.stmt.append(ast.Template(EXTRACT_TEMP, {"name": CamelCase(self.name), "lname": self.name, "width": _sum}))

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emitTypeDefStruct(builder)
        for s in self.stmt:
            builder.emitIndent()
            s.emit(builder)
            builder.newline()
        builder.newline()

class StructM(object):
    def __init__(self, name, members, runtime_data=[], bypass_map=None):
        self.name = name
        self.members = members
        self.runtime_data = runtime_data
        self.bypass_map = bypass_map
        e = []
        e.append(ast.StructMember("PacketInstance", "pkt"))
        for m in members:
            _m = p4name(m)
            e.append(ast.StructMember("Bit#(%s)"%(GetFieldWidth(m)), _m))
        for r in runtime_data:
            e.append(ast.StructMember("Bit#(%s)"%(r[0]), "runtime_%s_%d"%(r[1], r[0])))
        self.struct = ast.Struct(name, e)

    def build_match_expr(self):
        e = ["pkt: .pkt"]
        for m in self.members:
            _m = p4name(m)
            e.append("%s: .%s" % (_m, _m))
        for m in self.runtime_data:
            e.append("runtime_%s_%d: .runtime_%s" % (m[1], m[0], m[1]))
        return ", ".join(e)

    def build_case_expr(self):
        e = ["pkt: pkt"]
        for m in self.members:
            fullname = p4name(m)
            field = m[1]
            e.append("%s: %s" % (fullname, field))
        for m in self.runtime_data:
            e.append("runtime_%s_%d: resp.runtime_%s" % (m[1], m[0], m[1]))
        return ", ".join(e)

    def get_members(self):
        e = []
        for m in self.members:
            e.append(p4name(m))
        return e

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emit(builder)
        #builder.newline()

    def emit_typedef_struct (self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emitTypeDefStruct(builder)
        #builder.newline()

class StructT(object):
    def __init__(self, name):
        self.name = name
        self.struct = self._build()

    def _build(self):
        e = []
        e.append(ast.StructMember("PacketInstance", "pkt"))
        e.append(ast.StructMember("MetadataT", "meta"))
        struct = ast.Struct(self.name, e)
        return struct

    def emit(self, builder):
        self.struct.emitTypeDefStruct(builder)

class StructMetadata(object):
    """
    TODO: improve to share code with StructM
    """
    def __init__(self, name, ir):
        self.name = name

        metadata = ir.global_metadata;
        fields = []
        for header, flds in metadata.items():
            for f in flds:
                name = "%s$%s" % (header, f[1])
                fields.append(ast.StructMember("Maybe#(Bit#(%s))"%(f[0]), name))
                avoid_bsv_keyword(f[1])
        # valid fields
        #for it in ir.parsers.values():
        #    for h in it.header_instances.values():
        #        name = "valid_%s" % (camelCase(h))
        #        fields.append(ast.StructMember("Maybe#(Bit#(0))", name))

        self.struct = ast.Struct(self.name, fields)

    def emitDefault(self, builder):
        default = ast.Template(STRUCT_DEFAULT, {"name": "MetadataT"})
        default.emit(builder)

    def emit(self, builder):
        self.struct.emitTypeDefStruct(builder)
        self.emitDefault(builder)

class StructTableReqT(object):
    def __init__(self, name, key):
        self.name = name
        fields = []
        total_width = 0
        pad_width = 0
        for k in key:
            if k['match_type'] == 'valid':
                total_width += 1
                name = 'valid_%s' % (k['target'].translate(None, "[]"))
                fields.append(ast.StructMember("Bool", name))
            else:
                width = GetFieldWidth(k['target'])
                total_width += width
                name = p4name(k['target'])
                fields.append(ast.StructMember("Bit#(%s)" %(width), name))
        if (total_width % 9):
            pad_width = 9 - total_width % 9
            fields.insert(0, ast.StructMember("Bit#(%s)" %(pad_width), "padding"))

        self.struct = ast.Struct("%sReqT"%(CamelCase(self.name)), fields)
        self.width = total_width + pad_width

    def emit(self, builder):
        self.struct.emitTypeDefStruct(builder)

class StructTableRspT(object):
    def __init__(self, name, actions, action_info):
        def findActionInfo(action_info, action):
            for at in action_info:
                if at['name'] == action[1]:
                    return at
        self.name = name
        elements = []
        atype = "%sActionT" %(CamelCase(name))
        elements.append(ast.EnumElement("DEFAULT_%s"%(name.upper()), "", 0))
        for idx, at in enumerate(actions):
            elements.append(ast.EnumElement(at.lstrip('_').upper(), "", idx))
        self.enum = ast.Enum(atype, elements)
        fields = []
        field_set = set()
        fields.append(ast.StructMember(atype, "_action"))
        dwidth = 0
        for at in enumerate(actions):
            info = findActionInfo(action_info, at)
            runtime_data = info['runtime_data']
            for data in runtime_data:
                data_width = data['bitwidth']
                data_name = "runtime_%s"%(data['name'])
                if data_name not in field_set:
                    fields.append(ast.StructMember("Bit#(%s)" %(data_width), data_name))
                    field_set.add(data_name)
                    dwidth += data_width
        self.struct = ast.Struct("%sRspT"%(CamelCase(self.name)), fields)
        self.width = int(math.ceil(math.log(len(actions) + 1, 2))) + dwidth

    def emit(self, builder):
        self.enum.emit(builder)
        self.struct.emitTypeDefStruct(builder)

