# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import p4_action, p4_field, p4_field_list, p4_register
from p4_hlir.hlir import p4_signature_ref, p4_header_instance
import llvmProgram
from programSerializer import ProgramSerializer
from compilationException import *
import llvmScalarType
import llvmCounter
import llvmType
import llvmInstance


class LLVMActionData(object):
    def __init__(self, name, argtype):
        self.name = name
        self.argtype = argtype


class LLVMActionBase(object):
    def __init__(self, p4action):
        self.name = p4action.name
        self.hliraction = p4action
        self.builtin = False
        self.arguments = []

    def serializeArgumentsAsStruct(self, serializer):
        print ("gt arg base struct, no arguments", self.name)

    def serializeBody(self, serializer, valueName, program):
        print ("gt arg base struct body", self.name, valueName)

    def __str__(self):
        return "LLVMAction({0})".format(self.name)


class LLVMAction(LLVMActionBase):
    unsupported = [
        # The following cannot be done in llvm
        "execute_meter",
        "clone_egress_pkt_to_egress", "generate_digest", "resubmit",
        "modify_field_with_hash_based_offset", "truncate", "push", "pop",
        # The following could be done, but are not yet implemented
        # The situation with copy_header is complicated,
        # because we don't do checksums
        "copy_header", "count"]

    def __init__(self, p4action, program):
        super(LLVMAction, self).__init__(p4action)
        assert isinstance(p4action, p4_action)
        assert isinstance(program, llvmProgram.LLVMProgram)

        self.builtin = False
        self.invalid = False  # a leaf action which is never
                              # called from a table can be invalid.

        for i in range(0, len(p4action.signature)):
            param = p4action.signature[i]
            width = p4action.signature_widths[i]
            if width is None:
                self.invalid = True
                return
            argtype = llvmScalarType.LLVMScalarType(p4action, width, False)
            actionData = LLVMActionData(param, argtype)
            self.arguments.append(actionData)

    def serializeArgumentsAsStruct(self, serializer):
        if self.invalid:
            raise CompilationException(True,
                "{0} Attempting to generate code for an invalid action",
                                       self.hliraction)

        # Build a struct containing all action arguments.
        assert isinstance(serializer, ProgramSerializer)
        if len(self.arguments) != 0:
            serializer.appendLine("typedef struct {")
            serializer.blockStart()
        for arg in self.arguments:
            serializer.emitIndent()
            assert isinstance(arg, LLVMActionData)
            argtype = arg.argtype
            assert isinstance(argtype, llvmType.LLVMType)
            argtype.declare(serializer, arg.name)
        if len(self.arguments) != 0:
            serializer.appendLine("}} ActionArguments_{table};".format(table=self.name))
            serializer.blockEnd(False)
            serializer.newline()

    def serializeBody(self, serializer, dataContainer, program):
        if self.invalid:
            raise CompilationException(True,
                "{0} Attempting to generate code for an invalid action",
                                       self.hliraction)

        # TODO: generate PARALLEL implementation
        # dataContainer is a string containing the variable name
        # containing the action data
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(dataContainer, str)
        callee_list = self.hliraction.flat_call_sequence
        for e in callee_list:
            print "cf callee:", e
            action = e[0]
            assert isinstance(action, p4_action)
            arguments = e[1]
            assert isinstance(arguments, list)
            self.serializeCallee(self, action, arguments, serializer,
                                 dataContainer, program)

    def checkSize(self, call, args, program):
        size = None
        for a in args:
            if a is None:
                continue
            if size is None:
                size = a
            elif a != size:
                program.emitWarning(
                    "{0}: Arguments do not have the same size {1} and {2}",
                    call, size, a)
        return size

    @staticmethod
    def translateActionToOperator(actionName):
        if actionName == "add" or actionName == "add_to_field":
            return "+"
        elif actionName == "bit_and":
            return "&"
        elif actionName == "bit_or":
            return "|"
        elif actionName == "bit_xor":
            return "^"
        elif actionName == "subtract" or actionName == "subtract_from_field":
            return "-"
        else:
            raise CompilationException(True,
                                       "Unexpected primitive action {0}",
                                       actionName)

    def serializeCount(self, caller, arguments, serializer,
                       dataContainer, program):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(arguments, list)
        assert len(arguments) == 2

        counter = arguments[0]
        index = ArgInfo(arguments[1], caller, dataContainer, program)
        ctr = program.getCounter(counter.name)
        assert isinstance(ctr, llvmCounter.LLVMCounter)
        serializer.emitIndent()
        serializer.blockStart()

        # This is actually incorrect, since the key is not always an u32.
        # This code is currently disabled
        key = program.reservedPrefix + "index"
        serializer.emitIndent()
        serializer.appendFormat("u32 {0} = {1};", key, index.asString)
        serializer.newline()

        ctr.serializeCode(key, serializer, program)

        serializer.blockEnd(True)

    def serializeCallee(self, caller, callee, arguments,
                        serializer, dataContainer, program):
        if self.invalid:
            raise CompilationException(
                True,
                "{0} Attempting to generate code for an invalid action",
                self.hliraction)

        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(callee, p4_action)
        assert isinstance(arguments, list)

        if callee.name in LLVMAction.unsupported:
            raise NotSupportedException("{0}", callee)

        args = self.transformArguments(arguments, caller,
                                       dataContainer, program)
        if callee.name == "modify_field":
            dst = args[0]
            src = args[1]

            size = self.checkSize(callee,
                                  [a.widthInBits() for a in args],
                                  program)
            if size is None:
                raise CompilationException(
                    True, "Cannot infer width for arguments {0}",
                    callee)
            serializer.appendLine("""/* modify_field */""")

        elif (callee.name == "add" or 
             callee.name == "bit_and" or 
             callee.name == "bit_or" or 
             callee.name == "bit_xor" or 
             callee.name == "subtract"):
            size = self.checkSize(callee,
                                  [a.widthInBits() for a in args],
                                  program)
            if size is None:
                raise CompilationException(
                    True,
                    "Cannot infer width for arguments {0}",
                    callee)
            serializer.appendLine("""arithmetic""")
            op = LLVMAction.translateActionToOperator(callee.name)

        elif (callee.name == "add_to_field" or 
              callee.name == "subtract_from_field"):
            op = LLVMAction.translateActionToOperator(callee.name)
            serializer.appendLine("""/* add_to_field */""")
        elif callee.name == "no_op":
            serializer.append("/* noop */")
        elif callee.name == "drop":
            serializer.appendLine("/* drop */")
        elif callee.name == "push" or callee.name == "pop":
            raise CompilationException(
                True, "{0} push/pop not yet implemented", callee)
        elif callee.name == "clone_ingress_pkt_to_egress":
            serializer.appendLine("/* clone_ingress_pkt_to_egress */")
        elif callee.name == "register_read":
            serializer.appendLine("/* register_read */")
        elif callee.name == "register_write":
            serializer.appendLine("/* register_write */")
        elif callee.name == "remove_header":
            serializer.appendLine("/* remove_header */")
        elif callee.name == "add_header":
            serializer.appendLine("/* add_header */")
        else:
            raise CompilationException(
                True, "Unexpected primitive action {0}", callee)

    def transformArguments(self, arguments, caller, dataContainer, program):
        result = []
        for a in arguments:
            t = ArgInfo(a, caller, dataContainer, program)
            result.append(t)
        return result


class BuiltinAction(LLVMActionBase):
    def __init__(self, p4action):
        super(BuiltinAction, self).__init__(p4action)
        self.builtin = True

    def serializeBody(self, serializer, valueName, program):
        print 'tll body builtin', self.name, type(self), len(self.hliraction.flat_call_sequence)
        for call in self.hliraction.flat_call_sequence:
            # see if anything can be parallelized
            print 'tll actions {0} field={1} {2}'.format(call[0], call[1], call[2])

class ArgInfo(object):
    # noinspection PyUnresolvedReferences
    # Represents an argument passed to an action
    def __init__(self, argument, caller, dataContainer, program):
        self.width = None
        self.asString = None
        self.isLvalue = True
        self.caller = caller

        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(caller, LLVMAction)

        if isinstance(argument, int):
            self.asString = str(argument)
            self.isLvalue = False
            # size is unknown
        elif isinstance(argument, p4_field):
            if llvmProgram.LLVMProgram.isArrayElementInstance(
                    argument.instance):
                if isinstance(argument.instance.index, int):
                    index = "[" + str(argument.instance.index) + "]"
                else:
                    raise CompilationException(
                        True,
                        "Unexpected index for array {0}",
                        argument.instance.index)
                stackInstance = program.getStackInstance(
                    argument.instance.base_name)
                assert isinstance(stackInstance, llvmInstance.LLVMHeaderStack)
                fieldtype = stackInstance.basetype.getField(argument.name)
                self.width = fieldtype.widthInBits()
                self.asString = "{0}.{1}{3}.{2}".format(
                    program.headerStructName,
                    stackInstance.name, argument.name, index)
            else:
                instance = program.getInstance(argument.instance.base_name)
                if isinstance(instance, llvmInstance.LLVMHeader):
                    parent = program.headerStructName
                else:
                    parent = program.metadataStructName
                fieldtype = instance.type.getField(argument.name)
                self.width = fieldtype.widthInBits()
                self.asString = "{0}.{1}.{2}".format(
                    parent, instance.name, argument.name)
        elif isinstance(argument, p4_signature_ref):
            refarg = caller.arguments[argument.idx]
            self.asString = "{0}->u.{1}.{2}".format(
                dataContainer, caller.name, refarg.name)
            self.width = caller.arguments[argument.idx].argtype.widthInBits()
        elif isinstance(argument, p4_header_instance):
            # This could be a header array element
            # Unfortunately for push and pop, the user mean the whole array,
            # but the representation contains just the first element here.
            # This looks like a bug in the HLIR.
            if llvmProgram.LLVMProgram.isArrayElementInstance(argument):
                if isinstance(argument.index, int):
                    index = "[" + str(argument.index) + "]"
                else:
                    raise CompilationException(
                        True,
                        "Unexpected index for array {0}", argument.index)
                stackInstance = program.getStackInstance(argument.base_name)
                assert isinstance(stackInstance, llvmInstance.LLVMHeaderStack)
                fieldtype = stackInstance.basetype
                self.width = fieldtype.widthInBits()
                self.asString = "{0}.{1}{2}".format(
                    program.headerStructName, stackInstance.name, index)
            else:
                instance = program.getInstance(argument.name)
                instancetype = instance.type
                self.width = instancetype.widthInBits()
                self.asString = "{0}.{1}".format(
                    program.headerStructName, argument.name)
        elif isinstance(argument, p4_field_list):
            print "tll fieldlist", argument
        elif isinstance(argument, p4_register):
            print 'tll register', argument
        else:
            raise CompilationException(
                True, "Unexpected action argument {0}", argument)

    def widthInBits(self):
        return self.width
