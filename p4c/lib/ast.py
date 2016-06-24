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

import math
import re
import functools
import json
import logging
import os
import sys
import traceback

logger = logging.getLogger(__name__)

class Template(object):
    def __init__(self, template, pdict=[]):
        self.template = template
        self.pdict = pdict

    def __repr__(self):
        return self.template % self.pdict

    def emit(self, builder):
        builder.emitIndent()
        builder.append(self.template % self.pdict)

class InterfaceMixin:
    def getSubinterface(self, name):
        subinterfaceName = name
        if not globalv.globalvars.has_key(subinterfaceName):
            return None
        subinterface = globalv.globalvars[subinterfaceName]
        #print 'subinterface', subinterface, subinterface
        return subinterface
    def parentClass(self, default):
        rv = default if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
        return rv

def dtInfo(arg):
    rc = {}
    if hasattr(arg, 'name'):
        rc['name'] = arg.name
        if lookupTable.get(arg.name):
            rc['name'] = lookupTable[arg.name]
    if hasattr(arg, 'type') and arg.type != 'Type':
        rc['type'] = arg.type
        if lookupTable.get(arg.type):
            rc['type'] = lookupTable[arg.type]
    if hasattr(arg, 'params'):
        if arg.params is not None and arg.params != []:
            rc['params'] = [dtInfo(p) for p in arg.params]
    if hasattr(arg, 'elements'):
        if arg.type == 'Enum':
            rc['elements'] = arg.elements
        else:
            rc['elements'] = [piInfo(p) for p in arg.elements]
    return rc

def piInfo(pitem):
    rc = {}
    rc['pname'] = pitem.name
    rc['ptype'] = dtInfo(pitem.type)
    if hasattr(pitem, 'oldtype'):
        rc['oldtype'] = dtInfo(pitem.oldtype)
    return rc

def declInfo(mitem):
    rc = {}
    rc['dname'] = mitem.name
    rc['dparams'] = []
    for pitem in mitem.params:
        rc['dparams'].append(piInfo(pitem))
    return rc

def classInfo(item):
    rc = {
        'Package': os.path.splitext(os.path.basename(item.package))[0],
        'cname': item.name,
        'cdecls': [],
    }
    for mitem in item.decls:
        rc['cdecls'].append(declInfo(mitem))
    return rc

class Method:
    def __init__(self, name, return_type, params):
        self.type = 'Method'
        self.name = name
        self.return_type = return_type
        self.params = params

    def __repr__(self):
        sparams = [p.__repr__() for p in self.params]
        return '<method: %s %s %s>' % (self.name, self.return_type, self.params)

    def emit(self, builder):
        builder.emitIndent()
        builder.append("method {} {} ({});".format(self.return_type, self.name, self.params))
        builder.newline()

    def instantiate(self):
        return self

class Function:
    def __init__(self, name, return_type, params):
        self.type = 'Function'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        if not self.params:
            return '<function: %s %s NONE>' % (self.name, self.return_type)
        sparams = map(str, self.params)
        return '<function: %s %s %s>' % (self.name, self.return_type, sparams)

    def emit(self, builder):
        builder.append("function {} {}".format(self.return_type, self.name))
        builder.newline()

class Variable:
    def __init__(self, name, t, value):
        self.type = 'Variable'
        self.name = name
        self.type = t
        self.value = value
        if t and t.type == 'Type' and t.name == 'Integer' and value and value.type == 'Type':
            lookupTable[name] = value.name
    def __repr__(self):
        return '<variable: %s : %s>' % (self.name, self.type)

class Interface(InterfaceMixin):
    def __init__(self, name="unknown", params=[], subinterfaces=[],
                       typeDefType=[], methodProto=[]):
        """
        @param
        @param subinterfaces: instances of subinterface of type Interface
        """
        self.type = 'Interface'
        self.name = name
        self.params = params
        self.subinterfaces = subinterfaces
        self.typeDefType = typeDefType
        self.methodProto = methodProto

    def interfaceType(self):
        return Type(self.name,self.params)

    def __repr__(self):
        return '{interface: %s (%s) : %s}' % (self.name, self.params, self.typeDefType)

    def emitSubinterfaceDecl(self, builder):
        builder.emitIndent()
        builder.append("interface {} {};".format(self.typeDefType, self.name))
        builder.newline()

    def emit(self, builder):
        builder.append("interface {};".format(self.name));
        builder.newline()
        builder.increaseIndent()
        for s in self.subinterfaces:
            s.emitSubinterfaceDecl(builder)
        for s in self.methodProto:
            s.emit(builder)
        builder.decreaseIndent()
        # print list = methods, if any
        builder.append("endinterface")
        builder.newline()

class Typeclass:
    def __init__(self, name):
        self.name = name
        self.type = 'TypeClass'
    def __repr__(self):
        return '{typeclass %s}' % (self.name)

class TypeclassInstance:
    def __init__(self, name, params, provisos, decl):
        self.name = name
        self.params = params
        self.provisos = provisos
        self.decl = decl
        self.type = 'TypeclassInstance'
    def __repr__(self):
        return '{typeclassinstance %s %s}' % (self.name, self.params)

class Module:
    def __init__(self, name, params, interface, provisos, decls, stmt):
        self.type = 'Module'
        self.name = name
        self.interface = interface
        self.params = params # #(formalParams)
        self.provisos = provisos
        self.decls = decls
        self.stmt = stmt

    def __repr__(self):
        return '{module: %s %s}' % (self.name, self.decls)

    def emit(self, builder):
        # module {identifier} {params} ({args}) [provisos];
        builder.append("module {} ({});".format(self.name, self.interface))
        builder.newline()
        builder.increaseIndent()
        for s in self.stmt:
            s.emit(builder)
            builder.newline()
        builder.decreaseIndent()
        builder.append("endmodule")
        builder.newline()

class Rule:
    def __init__(self, name, ruleCond, actionStmt):
        self.name = name
        self.ruleCond = ruleCond
        self.actionStmt = actionStmt

    def emit(self, builder):
        builder.emitIndent()
        if self.ruleCond:
            builder.append("rule {} if ({});".format(self.name, self.ruleCond))
        else:
            builder.append("rule {};".format(self.name))
        builder.newline()
        builder.increaseIndent()
        for s in self.actionStmt:
            s.emit(builder)
            builder.newline()
        builder.decreaseIndent()
        builder.emitIndent()
        builder.append("endrule")
        builder.newline()

class EnumElement:
    def __init__(self, name, qualifiers, value):
        self.qualifiers = qualifiers
        self.value = value
    def __repr__(self):
        return '{enumelt: %s}' % (self.name)

class Enum:
    def __init__(self, elements):
        self.type = 'Enum'
        self.elements = elements
    def __repr__(self):
        return '{enum: %s}' % (self.elements)
    def instantiate(self, paramBindings):
        return self

class StructMember:
    def __init__(self, t, name):
        self.type = t
        self.name = name
    def __repr__(self):
        return '{field: %s %s}' % (self.type, self.name)
    def instantiate(self, paramBindings):
        return StructMember(self.type.instantiate(paramBindings), self.name)

class Struct:
    def __init__(self, elements):
        self.type = 'Struct'
        self.elements = elements
    def __repr__(self):
        return '{struct: %s}' % (self.elements)
    def instantiate(self, paramBindings):
        return Struct([e.instantiate(paramBindings) for e in self.elements])

class TypeDef:
    def __init__(self, tdtype, name, params):
        self.name = name
        self.params = params
        self.type = 'TypeDef'
        self.tdtype = tdtype
        if tdtype and tdtype.type != 'Type':
            tdtype.name = name
        self.type = 'TypeDef'
    def __repr__(self):
        return '{typedef: %s %s}' % (self.tdtype, self.name)

class Param:
    def __init__(self, name, t):
        self.name = name
        self.type = t
    def __repr__(self):
        return '{param %s: %s}' % (self.name, self.type)
    def instantiate(self, paramBindings):
        return Param(self.name,
                     self.type.instantiate(paramBindings))

class Type:
    def __init__(self, name, params):
        self.type = 'Type'
        self.name = name
        if params:
            self.params = params
        else:
            self.params = []
    def __repr__(self):
        sparams = map(str, self.params)
        return '{type: %s %s}' % (self.name, sparams)
    def instantiate(self, paramBindings):
        #print 'Type.instantiate', self.name, paramBindings
        if paramBindings.has_key(self.name):
            return paramBindings[self.name]
        else:
            return Type(self.name, [p.instantiate(paramBindings) for p in self.params])

class Case:
    def __init__(self, expression):
        self.expression = expression
        self.casePatItem = dict()
        self.casePatStmt = {} # {'casePat' : [stmt]}
        self.defaultItem = []

    def __repr__(self):
        return '{case %s: %s}' % (self.expression)

    def emit(self, builder):
        builder.emitIndent()
        builder.appendLine("case ({}) matches".format(self.expression))
        builder.increaseIndent()
        for k, v in self.casePatItem.items():
            builder.emitIndent()
            builder.appendLine("{}: begin".format(v))
            builder.increaseIndent()
            for s in self.casePatStmt[k]:
                s.emit(builder)
                builder.newline()
            builder.decreaseIndent()
            builder.emitIndent()
            builder.appendLine("end")
        builder.decreaseIndent()
        builder.emitIndent()
        builder.append("end")

class If:
    def __init__(self, expression, stmt):
        self.expression = expression
        self.stmt = stmt

    def emit(self, builder):
        builder.emitIndent()
        builder.append("if ({}) begin".format(self.expression))
        builder.newline()
        builder.increaseIndent()
        for s in self.stmt:
            s.emit(builder)
            builder.newline()
        builder.decreaseIndent()
        builder.emitIndent()
        builder.append("end")

class Else:
    def __init__(self, stmt):
        self.stmt = stmt

    def emit(self, builder):
        builder.emitIndent()
        builder.append("else begin")
        builder.newline()
        builder.increaseIndent()
        for s in self.stmt:
            s.emit(builder)
            builder.newline()
        builder.decreaseIndent()
        builder.emitIndent()
        builder.append("end")

class Reg:
    def __init__(self, name, rw, value):
        pass

    def emitDecl(self, builder):
        pass

    def emit(self, builder):
        pass

