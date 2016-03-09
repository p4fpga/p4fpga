# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import p4_match_type, p4_field, p4_table, p4_header_instance
from programSerializer import ProgramSerializer
from compilationException import *
from helper import *
import llvmProgram
import llvmInstance
import llvmCounter
import llvmStructType
import llvmAction

class LLVMTableKeyField(object):
    def __init__(self, fieldname, instance, field, mask):
        assert isinstance(instance, llvmInstance.LLVMInstanceBase)
        assert isinstance(field, llvmStructType.LLVMField)

        self.keyFieldName = fieldname
        self.instance = instance
        self.field = field
        self.mask = mask

    def serializeType(self, serializer):
        assert isinstance(serializer, ProgramSerializer)
        ftype = self.field.type
        ftype.declare(serializer, self.keyFieldName)

    def serializeConstruction(self, serializer, keyName, program):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(keyName, str)
        assert isinstance(program, llvmProgram.LLVMProgram)

        if self.mask is not None:
            maskExpression = " & {0}".format(self.mask)
        else:
            maskExpression = ""

        if isinstance(self.instance, llvmInstance.LLVMMetadata):
            base = program.metadataStructName
        else:
            base = program.headerStructName

        if isinstance(self.instance, llvmInstance.SimpleInstance):
            print "tll simple instance {0}.{1}.{2}".format(
                base, self.instance.name, self.field.name)
        else:
            assert isinstance(self.instance, llvmInstance.LLVMHeaderStack)
            print "tll header stack {0}.{1}[{2}].{3}".format(
                base, self.instance.name,
                self.instance.hlirInstance.index, self.field.name)
        size = self.field.widthInBits()
        serializer.emitIndent()
        serializer.appendLine("{0}.{1} width={2}".format(keyName, self.keyFieldName, size))

class LLVMTableKey(object):
    def __init__(self, match_fields, table, program):
        assert isinstance(program, llvmProgram.LLVMProgram)

        self.expressions = []
        self.fields = []
        self.masks = []
        self.fieldNamePrefix = "key_field_"
        self.program = program
        self.table = table

        fieldNumber = 0
        for f in match_fields:
            field = f[0]
            matchType = f[1]
            mask = f[2]

            if ((matchType is p4_match_type.P4_MATCH_TERNARY) or 
                (matchType is p4_match_type.P4_MATCH_LPM) or 
                (matchType is p4_match_type.P4_MATCH_RANGE)):
                raise NotSupportedException(
                    False, "Match type {0}", matchType)

            if matchType is p4_match_type.P4_MATCH_VALID:
                # we should be really checking the valid field;
                # p4_field is a header instance
                assert isinstance(field, p4_header_instance)
                instance = field
                fieldname = "valid"
            else:
                assert isinstance(field, p4_field)
                instance = field.instance
                fieldname = field.name

            if llvmProgram.LLVMProgram.isArrayElementInstance(instance):
                llvmStack = program.getStackInstance(instance.base_name)
                assert isinstance(llvmStack, llvmInstance.LLVMHeaderStack)
                basetype = llvmStack.basetype
                eInstance = program.getStackInstance(instance.base_name)
            else:
                llvmHeader = program.getInstance(instance.name)
                assert isinstance(llvmHeader, llvmInstance.SimpleInstance)
                basetype = llvmHeader.type
                eInstance = program.getInstance(instance.base_name)

            llvmField = basetype.getField(fieldname)
            assert isinstance(llvmField, llvmStructType.LLVMField)

            fieldName = self.fieldNamePrefix + str(fieldNumber)
            fieldNumber += 1
            keyField = LLVMTableKeyField(fieldName, eInstance, llvmField, mask)

            self.fields.append(keyField)
            self.masks.append(mask)

    @staticmethod
    def fieldRank(field):
        assert isinstance(field, LLVMTableKeyField)
        return field.field.type.alignment()

    def serializeType(self, serializer, keyTypeName):
        assert isinstance(serializer, ProgramSerializer)

        fieldOrder = sorted(
            self.fields, key=LLVMTableKey.fieldRank, reverse=True)

        serializer.appendLine("typedef struct {")
        serializer.blockStart()
        for f in fieldOrder:
            assert isinstance(f, LLVMTableKeyField)
            serializer.emitIndent()
            f.serializeType(serializer)
        serializer.appendLine("}} MatchField{table} deriving (Bits, Eq, FShow);".format(table=CamelCase(self.table)))
        serializer.blockEnd(False)
        serializer.newline()

    def serializeConstruction(self, serializer, keyName, program):
        for f in self.fields:
            f.serializeConstruction(serializer, keyName, program)

class LLVMTable(object):
    # noinspection PyUnresolvedReferences
    def __init__(self, hlirtable, program):
        assert isinstance(hlirtable, p4_table)
        assert isinstance(program, llvmProgram.LLVMProgram)

        self.name = hlirtable.name
        self.hlirtable = hlirtable
        #self.config = config

        self.defaultActionMapName = (program.reservedPrefix +
                                     self.name + "_miss")
        self.key = LLVMTableKey(hlirtable.match_fields, self.name, program)
        self.size = hlirtable.max_size
        if self.size is None:
            program.emitWarning(
                "{0} does not specify a max_size; using 1024", hlirtable)
            self.size = 1024
        self.isHash = True  # TODO: try to guess arrays when possible
        self.dataMapName = self.name
        self.actionEnumName = program.generateNewName(self.name + "_actions")
        self.keyTypeName = program.generateNewName(self.name + "_key")
        self.valueTypeName = program.generateNewName(self.name + "_value")
        self.actions = []

        if hlirtable.action_profile is not None:
            raise NotSupportedException("{0}: action_profile tables",
                                        hlirtable)
        if hlirtable.support_timeout:
            program.emitWarning("{0}: table timeout {1}; ignoring",
                                hlirtable, NotSupportedException.archError)

        self.counters = []
        print ('gt attached_counters', hlirtable.attached_counters)
        if (hlirtable.attached_counters is not None):
            for c in hlirtable.attached_counters:
                print ('gt counter', c)
                ctr = program.getCounter(c.name)
                assert isinstance(ctr, llvmCounter.LLVMCounter)
                self.counters.append(ctr)

        if (len(hlirtable.attached_meters) > 0 or 
            len(hlirtable.attached_registers) > 0):
            program.emitWarning("{0}: meters/registers {1}; ignored",
                                hlirtable, NotSupportedException.archError)

        for a in hlirtable.actions:
            action = program.getAction(a)
            self.actions.append(action)

    def serializeKeyType(self, serializer):
        assert isinstance(serializer, ProgramSerializer)
        self.key.serializeType(serializer, self.keyTypeName)

    def serializeActionArguments(self, serializer, action):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(action, llvmAction.LLVMActionBase)
        action.serializeArgumentsAsStruct(serializer)

    def serializeValueType(self, serializer):
        assert isinstance(serializer, ProgramSerializer)

        serializer.appendLine("typedef enum {")
        serializer.blockStart()
        for a in self.actions:
            serializer.emitIndent()
            separator = "," if (a != self.actions[-1]) else ""
            serializer.appendLine("{name} = {value}{sep}".format(name=CamelCase(a.name), value=self.actions.index(a) + 1, sep=separator))
        serializer.appendLine("""}} Action{} deriving (Bits, Eq);""".format(CamelCase(self.valueTypeName)))
        serializer.blockEnd(False)
        serializer.newline()

        for a in self.actions:
            self.serializeActionArguments(serializer, a)

    def serializeTableDeclaration(self, serializer):
        assert isinstance(serializer, ProgramSerializer)
        serializer.emitIndent()
        serializer.appendLine("MatchTable_{name};".format(name=self.name))
        pass

    def serialize(self, serializer, program):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)

        self.serializeKeyType(serializer)
        self.serializeValueType(serializer)

    def serializeCode(self, serializer, program, nextNode):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)

        hitVarName = program.reservedPrefix + "hit"
        keyname = "key"
        valueName = "value"

        serializer.appendLine("/* generate control flow */")
        self.serializeTableDeclaration(serializer)
        self.key.serializeConstruction(serializer, keyname, program)

        print "mm datamap", self.dataMapName
        print "mm actionmap", self.defaultActionMapName

        if len(self.counters) > 0:
            for c in self.counters:
                assert isinstance(c, llvmCounter.LLVMCounter)
                if c.autoIncrement:
                    c.serializeCode(keyname, serializer, program)

        self.runAction(serializer, self.name, valueName, program, nextNode)

        # Purpose??
        nextNode = self.hlirtable.next_
        if "hit" in nextNode:
            # check if hit
            node = nextNode["hit"]
            if node is None:
                node = nextNode
            label = program.getLabel(node)

            # check if miss
            node = nextNode["miss"]
            if node is None:
                node = nextNode
            label = program.getLabel(node)

        if not "hit" in nextNode:
            print 'catch all'

    def runAction(self, serializer, tableName, valueName, program, nextNode):
        # Loop all actions
        for a in self.actions:
            assert isinstance(a, llvmAction.LLVMActionBase)
            a.serializeBody(serializer, valueName, program)
            nextNodes = self.hlirtable.next_
            if a.hliraction in nextNodes:
                # table
                node = nextNodes[a.hliraction]
                if node is None:
                    node = nextNode
                label = program.getLabel(node)
            else:
                # default
                pass
