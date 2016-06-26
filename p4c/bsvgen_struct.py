# Copyright (c) 2016 Han Wang
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

import logging
from lib.sourceCodeBuilder import SourceCodeBuilder
from lib.utils import CamelCase
import lib.ast as ast

STRUCT_DEFAULT="""\
instance DefaultValue#(%(name)s);
  defaultValue = unpack(0);
endinstance"""

STRUCT_MASK="""\
instance DefaultMask#(%(name)s);
  defaultMask = unpack(maxBound);
endinstance"""

def field_width(field, header_types, headers):
    print field
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

class Struct(object):
    def __init__(self, struct_attrs):
        self.name = struct_attrs['name']
        self.stmt = []
        fields = struct_attrs['fields']
        e = []
        for f, l in fields:
            e.append(ast.StructMember("Bit#(%s)"%(l), f))
        self.struct = ast.Struct(CamelCase(self.name), e)
        self._add_defaults()

    def _add_defaults(self):
        self.stmt.append(ast.Template(STRUCT_DEFAULT, {"name": CamelCase(self.name)}))
        self.stmt.append(ast.Template(STRUCT_MASK, {"name": CamelCase(self.name)}))

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emitTypeDefStruct(builder)
        for s in self.stmt:
            builder.emitIndent()
            s.emit(builder)
            builder.newline()
        builder.newline()

class StructM(object):
    def __init__(self, name, members, header_types, headers, runtime_data=[]):
        self.name = name
        self.members = members
        self.runtime_data = runtime_data
        e = []
        e.append(ast.StructMember("PacketInstance", "pkt"))
        for m in members:
            e.append(ast.StructMember("Bit#(%s)"%(field_width(m, header_types, headers)), m[1]))
        for r in runtime_data:
            e.append(ast.StructMember("Bit#(%s)"%(r[0]), "runtime_%s"%(r[1])))
        self.struct = ast.Struct(name, e)

    def build_match_expr(self):
        e = ["pkt: .pkt"]
        for m in self.members:
            e.append("%s: .%s" % (m[1], m[1]))
        for m in self.runtime_data:
            e.append("runtime_%s: .runtime_%s" % (m[1], m[1]))
        return ", ".join(e)

    def build_case_expr(self):
        e = ["pkt: pkt"]
        #print self.members
        for m in self.members:
            e.append("%s: %s" % (m[1], m[1]))
        for m in self.runtime_data:
            e.append("runtime_%s: runtime_%s" % (m[1], m[1]))
        return ", ".join(e)

    def get_members(self):
        e = []
        for m in self.members:
            e.append("$".join(m))
        return e

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emit(builder)
        builder.newline()

    def emit_typedef_struct (self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.struct.emitTypeDefStruct(builder)
        builder.newline()

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
    def __init__(self, name, ir, header_types, headers):
        self.name = name

        metadata = set()
        fields = []
        for it in ir.basic_blocks.values():
            for f in it.request.members:
                if f not in metadata:
                    width = field_width(f, header_types, headers)
                    name = "$".join(f)
                    fields.append(ast.StructMember("Maybe#(Bit#(%s))"%(width), name))
                    metadata.add(f)
            for f in it.response.members:
                if f not in metadata:
                    width = field_width(f, header_types, headers)
                    name = "$".join(f)
                    fields.append(ast.StructMember("Maybe#(Bit#(%s))"%(width), name))
                    metadata.add(f)
            # add runtime data to metadata
            for f in it.runtime_data:
                width = f[0]
                name = "runtime_%s" %(f[1])
                fields.append(ast.StructMember("Maybe#(Bit#(%s))"%(width), name))
        self.struct = ast.Struct(self.name, fields)

    def emit(self, builder):
        self.struct.emitTypeDefStruct(builder)

class StructTableReqT(object):
    def __init__(self, name, key, header_types, headers):
        self.name = name
        fields = []
        total_width = 0
        for k in key:
            width = field_width(k['target'], header_types, headers)
            total_width += width
            name = "$".join(k['target'])
            fields.append(ast.StructMember("Bit#(%s)" %(width), name))
        pad_width = 9 - total_width % 9
        if pad_width != 0:
            fields.append(ast.StructMember("Bit#(%s)" %(pad_width), "padding"))

        self.struct = ast.Struct("%sReqT"%(CamelCase(self.name)), fields)

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
        for idx, at in enumerate(actions):
            elements.append(ast.EnumElement(at, "", idx))
        self.enum = ast.Enum(atype, elements)
        fields = []
        fields.append(ast.StructMember(atype, "_action"))
        for at in enumerate(actions):
            info = findActionInfo(action_info, at)
            runtime_data = info['runtime_data']
            for data in runtime_data:
                data_width = data['bitwidth']
                data_name = data['name']
                fields.append(ast.StructMember("Bit#(%s)" %(data_width), data_name))
        self.struct = ast.Struct("%sRspT"%(CamelCase(self.name)), fields)

    def emit(self, builder):
        self.enum.emit(builder)
        self.struct.emitTypeDefStruct(builder)

