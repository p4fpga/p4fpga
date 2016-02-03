# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import parse_call, p4_field, p4_parse_value_set, \
    P4_DEFAULT, p4_parse_state, p4_table, \
    p4_conditional_node, p4_parser_exception, \
    p4_header_instance, P4_NEXT
import llvmProgram
import llvmStructType
import llvmInstance
import programSerializer
from compilationException import *
from helper import *

class LLVMParser(object):
    preamble="""typedef enum {{{states}}} ParserState deriving (Bits, Eq)
instance FShow#(ParserState);
    function Fmt show (ParserState state);
        return $format(" State %x", state);
    endfunction
endinstance
    """
    imports="""
import DefaultValues::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import List::*;
import StmtFSM::*;
import SpecialFIFOs::*;
import Vector::*;

import Pipe::*;
import Ethernet::*;
import P4Types::*;
"""

    def __init__(self, hlirParser):  # hlirParser is a P4 parser
        self.parser = hlirParser
        self.name = get_camel_case(hlirParser.name.capitalize())
        self.moduleSignature="""module mk{state}#(Reg#(ParserState) state, FIFO#(EtherData) datain)({interface});"""
        self.unparsedFifo="""FIFO#({lastType}) unparsed_{lastState}_fifo <- mkSizedFIFO({lastSize});"""
        self.preamble="""Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
    Vector#({numNextState}, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
    PulseWire start_wire <- mkPulseWire();
    PulseWire stop_wire <- mkPulseWire();"""
        self.postamble="""\
    rule start_fsm if (start_wire);
        {fsm}.start;
    endrule
    rule stop_fsm if (stop_wire);
        {fsm}.abort;
    endrule
    method Action start();
        start_wire.send();
    endmethod
    method Action stop();
        stop_wire.send();
    endmethod"""
        self.fsm="""\
    FSM fsm_{fsm} <- mkFSM({fsm})"""
        self.nextStateArbiter="""\
    (* fire_when_enabled *)
    rule arbitrate_outgoing_state if (state={state});
        Vector#({numNextState}, Bool) next_state_valid = replicate(False);
        Bool stateSet = False;
        for (Integer port=0; port<{numNextState}; port=port+1) begin
            next_state_valid[port] = isValid(next_state_wire[port]);
            if (!stateSet && next_state_valid[port]) begin
                stateSet = True;
                ParserState next_state = fromMaybe(?, next_state_wire[port]);
                state <= next_state;
            end
        end
    endrule"""
        self.computeParseStateSelect="""\
    function ParserState compute_next_state({matchtype} {matchfield});
        ParserState nextState = {defaultState};
        case ({matchfield}) matches"""
        self.loadPacket="""\
    rule load_packet_{id} if (state == {state});
        let data_current <- toGet({FIXME}).get
        packet_in_wire <= data_current.data;
    endrule"""
        self.loadDelayedPacket="""\
    rule load_packet_{id} if (state == {state});
        let data_delayed <- toGet({FIXME}).get;
        {unparsed_fifo}.enq(data_delayed);
    endrule"""
        self.stmtPreamble="""\
    Stmt {name} =
    seq
    action"""
        self.stmtGetData="""\
        let data = packet_in_wire;
        Vector#(128, Bit#(1)) dataVec = unpack(data);"""
        self.stmtExtract="""\
        let {field} = extract_{field}(pack(takeAt({index}, dataVec)));
        Vector#({unparsed_len}, Bit#(1)) unparsed = takeAt({unparsed_index}, dataVec);"""
        self.stmtComputeNextState="""\
        let nextState = compute_next_state({field});"""
        self.stmtUnparsedData="""\
        if (nextState={nextState}) begin
            unparsed_fifo_{nextState}.enq(pack(unparsed));
        end"""
        self.stmtAssignNextState="""\
        next_state_wire[{index}] = tagged Valid nextState;"""
        self.stmtPostamble="""\
    endaction
    endseq"""

    @classmethod
    def serialize_parse_states(self, serializer, states):
        serializer.appendLine(LLVMParser.imports)
        serializer.appendLine(LLVMParser.preamble.format(states=",".join(states)))

    def serialize(self, serializer, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        # module
        serializer.emitIndent()
        serializer.append(self.moduleSignature.format(state=self.name, interface=self.name))
        serializer.moduleStart()
        # input interface
        serializer.emitIndent()
        serializer.appendLine(self.unparsedFifo.format(lastType="FIXME", lastState="FIXME", lastSize=1))
        # preamble
        serializer.emitIndent()
        serializer.appendLine(self.preamble.format(numNextState="FIXME"))
        # fsm
        serializer.appendLine(self.nextStateArbiter.format(state="FIXME", numNextState="FIXME"))
        # branches
        self.serializeBranch(serializer, self.parser.branch_on, self.parser.branch_to, program)
        # load input data
        serializer.appendLine(self.loadPacket)

        # Stmt
        serializer.appendLine(self.stmtPreamble)
        serializer.appendLine(self.stmtGetData)
        serializer.appendLine(self.stmtExtract)
        serializer.appendLine(self.stmtComputeNextState)
        serializer.appendLine(self.stmtUnparsedData)
        serializer.appendLine(self.stmtAssignNextState)
        serializer.appendLine(self.stmtPostamble)

        serializer.emitIndent()
        serializer.appendLine(self.fsm.format(fsm=self.name))
        # postamble
        serializer.emitIndent()
        serializer.appendLine(self.postamble.format(fsm=self.name))
        # output interface
        serializer.moduleEnd()
        #for op in self.parser.call_sequence:
        #    self.serializeOperation(serializer, op, program)

    def serializeSelect(self, serializer, branch_on, program):
        totalWidth = 0
        for e in branch_on:
            #FIXME: what is the case that has multiple branch_on?
            if isinstance(e, p4_field):
                instance = e.instance
                assert isinstance(instance, p4_header_instance)

                llvmHeader = program.getInstance(instance.name)
                assert isinstance(llvmHeader, llvmInstance.LLVMHeader)
                basetype = llvmHeader.type

                llvmField = basetype.getField(e.name)
                assert isinstance(llvmField, llvmStructType.LLVMField)
                totalWidth += llvmField.widthInBits()

                serializer.appendLine(self.computeParseStateSelect.format(matchfield=llvmField.name, matchtype="Bit#({})".format(totalWidth), defaultState="FIXME"))
            elif isinstance(e, tuple):
                raise CompilationException(
                    True, "Unexpected element in match tuple {0}", e)
            else:
                raise CompilationException(
                    True, "Unexpected element in match {0}", e)

    def serializeCases(self, selectVarName, serializer, branch_to, program):
        assert isinstance(selectVarName, str)
        assert isinstance(program, llvmProgram.LLVMProgram)

        branches = 0
        seenDefault = False
        for e in branch_to.keys():
            value = branch_to[e]
            if isinstance(e, int):
                serializer.append("""
            'h{field}: begin
                nextState={state}
            end""".format(field=format(e,'x'), state="FIXME"))
            elif isinstance(e, tuple):
                raise CompilationException(True, "Not yet implemented")
            elif isinstance(e, p4_parse_value_set):
                raise NotSupportedException("{0}: Parser value sets", e)
            elif e is P4_DEFAULT:
                seenDefault = True
                serializer.append("""
            default: begin
                nextState={defaultState}
            end""".format(defaultState="FIXME"))
            else:
                raise CompilationException(
                    True, "Unexpected element in match case {0}", e)

            branches += 1

            label = program.getLabel(value)

            if isinstance(value, p4_parse_state):
                print 'sc', value 
            elif isinstance(value, p4_table):
                print 'sc', value
            elif isinstance(value, p4_conditional_node):
                raise CompilationException(True, "Conditional node Not yet implemented")
            elif isinstance(value, p4_parser_exception):
                raise CompilationException(True, "Exception Not yet implemented")
            else:
                raise CompilationException(
                    True, "Unexpected element in match case {0}", value)

        # Must create default if it is missing
        if not seenDefault:
            serializer.append("""
        default: begin
            nextState={defaultState}
        end""")

        serializer.append("""
        endcase
        return nextState;
    endfunction
""")

    def serializeBranch(self, serializer, branch_on, branch_to, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)

        if branch_on == []:
            dest = branch_to.values()[0]
            serializer.emitIndent()
            serializer.newline()
        elif isinstance(branch_on, list):
            selectVar = self.serializeSelect(serializer, branch_on, program)
            self.serializeCases("", serializer, branch_to, program)
        else:
            raise CompilationException(
                True, "Unexpected branch_on {0}", branch_on)

    def serializeOperation(self, serializer, op, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)

        operation = op[0]
        if operation is parse_call.extract:
            self.serializeExtract(serializer, op[1], program)
        elif operation is parse_call.set:
            self.serializeMetadataSet(serializer, op[1], op[2], program)
        else:
            raise CompilationException(
                True, "Unexpected operation in parser {0}", op)

    def serializeFieldExtract(self, serializer, headerInstanceName,
                              index, field, alignment, program):
        assert isinstance(index, str)
        assert isinstance(headerInstanceName, str)
        assert isinstance(field, llvmStructType.LLVMField)
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(alignment, int)
        assert isinstance(program, llvmProgram.LLVMProgram)

        fieldToExtractTo = headerInstanceName + index + "." + field.name

        serializer.emitIndent()
        width = field.widthInBits()
        if field.name == "valid":
            serializer.appendFormat(
                "{0}.{1} = 1;", program.headerStructName, fieldToExtractTo)
            serializer.newline()
            return

        if width <= 32:
            serializer.emitIndent()
            #load = self.generatePacketLoad(0, width, alignment, program)

            #serializer.appendFormat("{0}.{1} = {2};",
            #                        program.headerStructName,
            #                        fieldToExtractTo, load)
            #serializer.newline()
        else:
            # Destination is bigger than 4 bytes and
            # represented as a byte array.
            if alignment == 0:
                shift = 0
            else:
                shift = 8 - alignment

            assert shift >= 0
            if shift == 0:
                method = "load_byte"
            else:
                method = "load_half"
            b = (width + 7) / 8

    def serializeExtract(self, serializer, headerInstance, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(headerInstance, p4_header_instance)
        assert isinstance(program, llvmProgram.LLVMProgram)

        if llvmProgram.LLVMProgram.isArrayElementInstance(headerInstance):
            llvmStack = program.getStackInstance(headerInstance.base_name)
            assert isinstance(llvmStack, llvmInstance.LLVMHeaderStack)

            if isinstance(headerInstance.index, int):
                index = "[" + str(headerInstance.index) + "]"
            elif headerInstance.index is P4_NEXT:
                index = "[" + llvmStack.indexVar + "]"
            else:
                raise CompilationException(
                    True, "Unexpected index for array {0}",
                    headerInstance.index)
            basetype = llvmStack.basetype
        else:
            llvmHeader = program.getHeaderInstance(headerInstance.name)
            basetype = llvmHeader.type
            index = ""

        # extract all fields
        alignment = 0
        for field in basetype.fields:
            assert isinstance(field, llvmStructType.LLVMField)

            self.serializeFieldExtract(serializer, headerInstance.base_name,
                                       index, field, alignment, program)
            alignment += field.widthInBits()
            alignment = alignment % 8

        if llvmProgram.LLVMProgram.isArrayElementInstance(headerInstance):
            # increment stack index
            llvmStack = program.getStackInstance(headerInstance.base_name)
            assert isinstance(llvmStack, llvmInstance.LLVMHeaderStack)

    def serializeMetadataSet(self, serializer, field, value, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        assert isinstance(field, p4_field)

        dest = program.getInstance(field.instance.name)
        assert isinstance(dest, llvmInstance.SimpleInstance)
        destType = dest.type
        assert isinstance(destType, llvmStructType.LLVMStructType)
        destField = destType.getField(field.name)

        if destField.widthInBits() > 32:
            useMemcpy = True
            bytesToCopy = destField.widthInBits() / 8
            if destField.widthInBits() % 8 != 0:
                raise CompilationException(
                    True,
                    "{0}: Not implemented: wide field w. sz not multiple of 8",
                    field)
        else:
            useMemcpy = False
            bytesToCopy = None # not needed, but compiler is confused

        serializer.emitIndent()
        destination = "{0}.{1}.{2}".format(
            program.metadataStructName, dest.name, destField.name)
        if isinstance(value, int):
            source = str(value)
            if useMemcpy:
                raise CompilationException(
                    True,
                    "{0}: Not implemented: copying from wide constant",
                    value)
        elif isinstance(value, tuple):
            source = self.currentReferenceAsString(value, program)
        elif isinstance(value, p4_field):
            source = program.getInstance(value.instance.name)
            if isinstance(source, llvmInstance.LLVMMetadata):
                sourceStruct = program.metadataStructName
            else:
                sourceStruct = program.headerStructName
            source = "{0}.{1}.{2}".format(sourceStruct, source.name, value.name)
        else:
            raise CompilationException(
                True, "Unexpected type for parse_call.set {0}", value)

