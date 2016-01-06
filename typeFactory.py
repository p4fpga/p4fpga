# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import p4_header
from llvmStructType import *

class LLVMTypeFactory(object):
    ''' Clean up this class'''
    def __init__(self):
        self.type_map = {}

    def build(self, hlirType, asMetadata):
        name = hlirType.name
        if hlirType.name in self.type_map:
            retval = self.type_map[name]
            if ((not asMetadata and isinstance(retval, LLVMMetadataType)) or 
                (asMetadata and isinstance(retval, LLVMHeaderType))):
                raise CompilationException(
                    True, "Same type used both as a header and metadata {0}",
                    hlirType)

        if isinstance(hlirType, p4_header):
            if asMetadata:
                type = LLVMMetadataType(hlirType)
            else:
                type = LLVMHeaderType(hlirType)
        else:
            raise CompilationException(True, "Unexpected type {0}", hlirType)
        self.registerType(name, type)
        return type

    def registerType(self, name, llvmType):
        self.type_map[name] = llvmType
