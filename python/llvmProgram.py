# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import p4_header_instance, p4_table, \
     p4_conditional_node, p4_action, p4_parse_state
from p4_hlir.main import HLIR
import p4_hlir.hlir.p4 as p4
import llvmlite.ir as ll
import llvmlite.binding as llvmBinding
import llvmCounter
import llvmInstance
import llvmTable
import llvmParser
import llvmDeparser
import typeFactory
import programSerializer
from compilationException import *
from pprint import pprint

class LLVMProgram(object):
    def __init__(self, name, hlir):
        assert isinstance(hlir, HLIR)

        self.hlir = hlir
        self.name = name
        self.uniqueNameCounter = 0
        self.reservedPrefix = "llvm_"

        self.packetName = self.reservedPrefix + "packet"
        self.dropBit = self.reservedPrefix + "drop"
        self.license = "MIT"
        self.offsetVariableName = self.reservedPrefix + "packetOffsetInBits"
        self.zeroKeyName = self.reservedPrefix + "zero"
        # all array tables must be indexed with u32 values

        self.errorName = self.reservedPrefix + "error"
        self.functionName = self.reservedPrefix + "filter"
        self.egressPortName = "egress_port" # Hardwired in P4 definition

        self.typeFactory = typeFactory.LLVMTypeFactory()
        self.errorCodes = [
            "p4_pe_no_error",
            "p4_pe_index_out_of_bounds",
            "p4_pe_out_of_packet",
            "p4_pe_header_too_long",
            "p4_pe_header_too_short",
            "p4_pe_unhandled_select",
            "p4_pe_checksum"]

        self.actions = []
        self.conditionals = []
        self.tables = []
        self.headers = []   # header instances
        self.metadata = []  # metadata instances
        self.stacks = []    # header stack instances LLVMHeaderStack
        self.parsers = []   # all parsers
        self.deparser = None
        self.entryPoints = []  # control-flow entry points from parser
        self.counters = []
        self.entryPointLabels = {}  # maps p4_node from entryPoints
                                    # to labels in the C program
        self.egressEntry = None

        self.construct()

        self.headersStructTypeName = self.reservedPrefix + "headers_t"
        self.headerStructName = self.reservedPrefix + "headers"
        self.metadataStructTypeName = self.reservedPrefix + "metadata_t"
        self.metadataStructName = self.reservedPrefix + "metadata"

        self.context = ll.Context()
        self.module = ll.Module(context=self.context) # each P4 program is a compilation unit
        self.builder = ll.IRBuilder()

    def construct(self):
        if len(self.hlir.p4_field_list_calculations) > 0:
            raise NotSupportedException(
                "{0} calculated field",
                self.hlir.p4_field_list_calculations.values()[0].name)

        # header_instance sort to (stack, header, metadata)
        for h in self.hlir.p4_header_instances.values():
            print 'header instances', h, h.max_index, h.metadata
            if h.max_index is not None:
                assert isinstance(h, p4_header_instance)
                if h.index == 0:
                    # header stack; allocate only for zero-th index
                    indexVarName = self.generateNewName(h.base_name + "_index")
                    stack = llvmInstance.LLVMHeaderStack(
                        h, indexVarName, self.typeFactory)
                    self.stacks.append(stack)
            elif h.metadata:
                metadata = llvmInstance.LLVMMetadata(h, self.typeFactory)
                self.metadata.append(metadata)
            else:
                header = llvmInstance.LLVMHeader(h, self.typeFactory)
                self.headers.append(header)

        stack = []
        # parse_state -> parser objects
        for p in self.hlir.p4_parse_states.values():
            parser = llvmParser.LLVMParser(p)
            parser.preprocess_parser(self.hlir)
            self.parsers.append(parser)

        llvmParser.LLVMParser.process_parser(self.hlir.p4_parse_states["start"], stack)

        for p in self.hlir.p4_parse_states.values():
            parser = llvmParser.LLVMParser(p)
            parser.postprocess_parser(self.hlir)

        for t in self.hlir.p4_tables.values():
            table = llvmTable.LLVMTable(t, self)
            self.tables.append(table)

        # ingress pipeline -> entry point
        for n in self.hlir.p4_ingress_ptr.keys():
            self.entryPoints.append(n)

        # conditional -> conditional object
        for n in self.hlir.p4_conditional_nodes.values():
            conditional = llvmConditional.LLVMConditional(n, self)
            self.conditionals.append(conditional)

        # egress -> entry point
        self.egressEntry = self.hlir.p4_egress_ptr

        # deparser object
        self.deparser = llvmDeparser.LLVMDeparser(self.hlir)

    @staticmethod
    def isArrayElementInstance(headerInstance):
        assert isinstance(headerInstance, p4_header_instance)
        return headerInstance.max_index is not None

    def emitWarning(self, formatString, *message):
        assert isinstance(formatString, str)
        print("WARNING: ", formatString.format(*message))

    def tollvm(self, serializer):
        self.generateTypes()
        self.generateTables()
        self.generateHeaderInstance()
        self.generateMetadataInstance()
        self.generateParser(serializer)
        self.generatePipeline()

    def getLabel(self, p4node):
        # C label that corresponds to this point in the control-flow
        if p4node is None:
            return "end"
        elif isinstance(p4node, p4_parse_state):
            label = p4node.name
            self.entryPointLabels[p4node.name] = label
        if p4node.name not in self.entryPointLabels:
            label = self.generateNewName(p4node.name)
            self.entryPointLabels[p4node.name] = label
        return self.entryPointLabels[p4node.name]

    def generateNewName(self, base):  # base is a string
        """Generates a fresh name based on the specified base name"""
        # TODO: this should be made "safer"
        assert isinstance(base, str)
        base += "_" + str(self.uniqueNameCounter)
        self.uniqueNameCounter += 1
        return base

    def generateTypes(self):
        for t in self.typeFactory.type_map.values():
            print t
        print 'headerStruct', self.headersStructTypeName
        for h in self.headers:
            print 'headers', h

        for h in self.stacks:
            print 'stacks', h

        # metadata
        for h in self.metadata:
            print 'metadata', h


    def generateTables(self):
        for t in self.tables:
            print 'gt generateTable', t

        for c in self.counters:
            print 'gc generate counters', c

    def generateHeaderInstance(self):
        print self.headersStructTypeName, self.headerStructName

        mytype = self.context.get_identified_type("header_t")
        mytype.set_body(ll.IntType(32), ll.IntType(32))

    def generateInitializeHeaders(self, serializer):
        assert isinstance(serializer, programSerializer.ProgramSerializer)

        serializer.blockStart()
        for h in self.headers:
            serializer.emitIndent()
            serializer.appendFormat(".{0} = ", h.name)
            h.type.emitInitializer(serializer)
            serializer.appendLine(",")
        serializer.blockEnd(False)

    def generateMetadataInstance(self):
        print (self.metadataStructTypeName, self.metadataStructName)
        for m in self.metadata:
            print m

    def generateDeparser(self, serializer):
        self.deparser.serialize(serializer, self)

    def generateInitializeMetadata(self, serializer):
        assert isinstance(serializer, programSerializer.ProgramSerializer)

        serializer.blockStart()
        for h in self.metadata:
            serializer.emitIndent()
            serializer.appendFormat(".{0} = ", h.name)
            h.emitInitializer(serializer)
            serializer.appendLine(",")
        serializer.blockEnd(False)

    def getStackInstance(self, name):
        assert isinstance(name, str)

        for h in self.stacks:
            if h.name == name:
                assert isinstance(h, llvmInstance.LLVMHeaderStack)
                return h
        raise CompilationException(
            True, "Could not locate header stack named {0}", name)

    def getHeaderInstance(self, name):
        assert isinstance(name, str)

        for h in self.headers:
            if h.name == name:
                assert isinstance(h, llvmInstance.LLVMHeader)
                return h
        raise CompilationException(
            True, "Could not locate header instance named {0}", name)

    def getInstance(self, name):
        assert isinstance(name, str)

        for h in self.headers:
            if h.name == name:
                return h
        for h in self.metadata:
            if h.name == name:
                return h
        raise CompilationException(
            True, "Could not locate instance named {0}", name)

    def getTable(self, name):
        assert isinstance(name, str)
        for t in self.tables:
            if t.name == name:
                return t
        raise CompilationException(
            True, "Could not locate table named {0}", name)

    def getConditional(self, name):
        assert isinstance(name, str)
        for c in self.conditionals:
            if c.name == name:
                return c
        raise CompilationException(
            True, "Could not locate conditional named {0}", name)

    def generateParser(self, serializer):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        states = map(lambda x: x.name, self.parsers)
        llvmParser.LLVMParser.serialize_preamble(serializer, states)
        for p in self.parsers:
            if (p.name == self.parsers[0].name):
                p.serialize_interfaces(serializer)
                p.serialize_start(serializer, self.parsers[1])
            else:
                p.serialize_interfaces(serializer)
                p.serialize_common(serializer, self)

        llvmParser.LLVMParser.serialize_parser_top(serializer, states)

    def generateIngressPipeline(self, serializer):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        print "mm generateIngressPipeline"
        # Generate Tables

    def generateControlFlowNode(self, node, nextEntryPoint):
        print "xx generateControlFlowNode"
        # generate control flow

    def generatePipelineInternal(self, nodestoadd, nextEntryPoint):
        assert isinstance(nodestoadd, set)

        done = set()
        while len(nodestoadd) > 0:
            todo = nodestoadd.pop()
            if todo in done:
                continue
            if todo is None:
                continue

            print("Generating ", todo.name)

            done.add(todo)
            self.generateControlFlowNode(todo, nextEntryPoint)

            for n in todo.next_.values():
                nodestoadd.add(n)

    def generatePipeline(self):
        todo = set()
        for e in self.entryPoints:
            todo.add(e)
        print "zz generate Pipeline", todo
        self.generatePipelineInternal(todo, self.egressEntry)
        todo = set()
        todo.add(self.egressEntry)
        self.generatePipelineInternal(todo, None)
