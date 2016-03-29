# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import p4_conditional_node, p4_expression
from p4_hlir.hlir import p4_header_instance, p4_field
from programSerializer import ProgramSerializer
from compilationException import CompilationException
import llvmProgram
import llvmInstance


class LLVMConditional(object):
    @staticmethod
    def translate(op):
        if op == "not":
            return "!"
        elif op == "or":
            return "||"
        elif op == "and":
            return "&&"
        return op

    def __init__(self, p4conditional, program):
        assert isinstance(p4conditional, p4_conditional_node)
        assert isinstance(program, llvmProgram.LLVMProgram)
        self.hlirconditional = p4conditional
        self.name = p4conditional.name

    def emitNode(self, node, serializer, program):
        if isinstance(node, p4_expression):
            self.emitExpression(node, serializer, program, False)
            pass
        elif node is None:
            pass
        elif isinstance(node, int):
            pass
        elif isinstance(node, p4_header_instance):
            header = program.getInstance(node.name)
            assert isinstance(header, llvmInstance.LLVMHeader)
            # TODO: stacks?
            pass
        elif isinstance(node, p4_field):
            instance = node.instance
            einstance = program.getInstance(instance.name)
            if isinstance(einstance, llvmInstance.LLVMHeader):
                base = program.headerStructName
            else:
                base = program.metadataStructName
            pass
        else:
            raise CompilationException(True, "{0} Unexpected expression ", node)

    def emitExpression(self, expression, serializer, program, toplevel):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(expression, p4_expression)
        assert isinstance(toplevel, bool)
        left = expression.left
        op = expression.op
        right = expression.right

        assert isinstance(op, str)

        op = LLVMConditional.translate(op)

    def generateCode(self, serializer, program, nextNode):
        assert isinstance(serializer, ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)

        trueBranch = self.hlirconditional.next_[True]
        if trueBranch is None:
            trueBranch = nextNode
        falseBranch = self.hlirconditional.next_[False]
        if falseBranch is None:
            falseBranch = nextNode

        self.emitExpression(
            self.hlirconditional.condition, serializer, program, True)

        label = program.getLabel(trueBranch)

        label = program.getLabel(falseBranch)

