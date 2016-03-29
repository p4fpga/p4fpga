# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import P4_SIGNED, P4_SATURATING
from llvmScalarType import *

def CamelCase(st):
    output = ''.join(x for x in st.title() if x.isalnum())
    return output

class LLVMField(object):
    __doc__ = "represents a field in a struct type, not in an instance"

    def __init__(self, hlirParentType, name, widthInBits, attributes):
        self.name = name
        self.width = widthInBits
        self.hlirType = hlirParentType
        signed = False

        if P4_SIGNED in attributes:
            signed = True
        if P4_SATURATING in attributes:
            raise NotSupportedException(
                "{0}.{1}: Saturated types", self.hlirType, self.name)

        try:
            self.type = LLVMScalarType(
                self.hlirType, widthInBits, signed)
        except CompilationException, e:
            raise CompilationException(
                e.isBug, "{0}.{1}: {2}", hlirParentType, self.name, e.show())

    def widthInBits(self):
        return self.width


class LLVMStructType(LLVMType):
    # Abstract base class for HeaderType and MetadataType.
    # They are both represented by a p4 header_type
    def __init__(self, hlirHeader):
        super(LLVMStructType, self).__init__(hlirHeader)
        self.name = hlirHeader.name
        self.fields = []

        for (fieldName, fieldSize) in self.hlirType.layout.items():
            attributes = self.hlirType.attributes[fieldName]
            field = LLVMField(
                hlirHeader, fieldName, fieldSize, attributes)
            self.fields.append(field)

    def serialize(self, serializer):
        assert isinstance(serializer, ProgramSerializer)

        # struct definition
        serializer.appendLine("typedef struct {")
        serializer.blockStart()
        for field in self.fields:
            serializer.emitIndent()
            serializer.appendLine("""Bit#({width}) {name};""".format(width=field.widthInBits(), name=field.name))
        serializer.blockEnd(False)
        serializer.appendLine("""}} {name} deriving (Bits, Eq);""".format(name=CamelCase(self.name)))
        serializer.newline()

        # default Values
        serializer.appendLine("""instance DefaultValue#({name});""".format(name=CamelCase(self.name)))
        serializer.emitIndent()
        serializer.appendLine("""defaultValue=""")
        serializer.appendLine("""{name} {{""".format(name=CamelCase(self.name)))
        serializer.blockStart()
        for field in self.fields:
            serializer.emitIndent()
            serializer.append("""{name}: 0""".format(name=field.name))
            if (field != self.fields[-1]):
                serializer.appendLine(",")
            else:
                serializer.appendLine("")
        serializer.blockEnd(False)
        serializer.appendLine("""};""")
        serializer.appendLine("""endinstance""")
        serializer.newline()

        # fshow support
        serializer.appendLine("""instance FShow#({name});""".format(name=CamelCase(self.name)))
        serializer.blockStart()
        serializer.emitIndent()
        serializer.appendLine("""function Fmt fshow({name} p);""".format(name=CamelCase(self.name)))
        serializer.blockStart()
        serializer.emitIndent()
        serializer.append("""return $format("{name}: """.format(name=CamelCase(self.name)))
        for field in self.fields:
            if (field != self.fields[-1]):
                serializer.append("""{name}=%h, """.format(name=field.name))
            else:
                serializer.append("""{name}=%h" """.format(name=field.name))
        for field in self.fields:
            if (field != self.fields[-1]):
                serializer.append(""", p.{name}""".format(name=field.name))
            else:
                serializer.append(""", p.{name});""".format(name=field.name))
        serializer.newline()
        serializer.blockEnd(False)
        serializer.appendLine("""endfunction""")
        serializer.blockEnd(False)
        serializer.appendLine("""endinstance""")
        serializer.newline()

        # extract function
        serializer.appendLine("function {Name} extract_{name}(Bit#({width}) data);".format(Name=CamelCase(self.name), name=self.name[:-2], width=self.widthInBits())) #FIXME
        serializer.blockStart()
        index = 0
        serializer.emitIndent()
        serializer.appendLine("Vector#({width}, Bit#(1)) dataVec=unpack(data);".format(width=self.widthInBits()))
        for field in self.fields:
            serializer.emitIndent()
            serializer.appendLine("""Vector#({width}, Bit#(1)) {name} = takeAt({index}, dataVec);""".format(width=field.widthInBits(), name=field.name, index=index))
            index += field.widthInBits()
        serializer.emitIndent()
        serializer.appendLine("{name} {inst} = defaultValue;".format(name=CamelCase(self.name), inst=self.name))
        for field in self.fields:
            serializer.emitIndent()
            serializer.appendLine("""{name}.{field} = pack({field});""".format(name=self.name, field=field.name))
        serializer.emitIndent()
        serializer.appendLine("return {name};".format(name=self.name))
        serializer.blockEnd(False)
        serializer.appendLine("endfunction")
        serializer.newline()

    def declare(self, serializer, identifier, asPointer):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(identifier, str)
        assert isinstance(asPointer, bool)

        serializer.appendFormat("struct {0} ", self.name)
        if asPointer:
            serializer.append("*")
        serializer.append(identifier)

    def widthInBits(self):
        return self.hlirType.length * 8

    def getField(self, name):
        assert isinstance(name, str)

        for f in self.fields:
            assert isinstance(f, LLVMField)
            if f.name == name:
                return f
        raise CompilationException(
            True, "Could not locate field {0}.{1}", self, name)


class LLVMHeaderType(LLVMStructType):
    def __init__(self, hlirHeader):
        super(LLVMHeaderType, self).__init__(hlirHeader)
        #validField = LLVMField(hlirHeader, "valid", 1, set())
        ## check that no "valid" field exists already
        #for f in self.fields:
        #    if f.name == "valid":
        #        raise CompilationException(
        #            True,
        #            "Header type contains a field named `valid': {0}",
        #            f)
        #self.fields.append(validField)

    def emitInitializer(self, serializer):
        assert isinstance(serializer, ProgramSerializer)

    def declareArray(self, serializer, identifier, size):
        assert isinstance(serializer, ProgramSerializer)

class LLVMMetadataType(LLVMStructType):
    def __init__(self, hlirHeader):
        super(LLVMMetadataType, self).__init__(hlirHeader)

    def emitInitializer(self, serializer):
        assert isinstance(serializer, ProgramSerializer)

