# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import P4_AUTO_WIDTH
from llvmType import *
from compilationException import *
from programSerializer import ProgramSerializer


class LLVMScalarType(LLVMType):
    __doc__ = "Represents a scalar type"
    def __init__(self, parent, widthInBits, isSigned):
        super(LLVMScalarType, self).__init__(None)
        assert isinstance(widthInBits, int)
        assert isinstance(isSigned, bool)
        self.width = widthInBits
        self.isSigned = isSigned
        if widthInBits is P4_AUTO_WIDTH:
            raise NotSupportedException("{0} Variable-width field", parent)

    def widthInBits(self):
        return self.width

    @staticmethod
    def bytesRequired(width):
        return (width + 7) / 8

    def alignment(self):
        if self.width <= 8:
            return 1
        elif self.width <= 16:
            return 2
        elif self.width <= 32:
            return 4
        else:
            return 1  # Char array

    def declareArray(self, serializer, identifier, size):
        raise CompilationException(
            True, "Arrays of base type not expected in P4")

    def declare(self, serializer, identifier):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(identifier, str)
        serializer.appendLine("""Bit#({width}) {name};""".format(width=self.width, name=identifier))

    def emitInitializer(self, serializer):
        assert isinstance(serializer, ProgramSerializer)
        serializer.append("0")
