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
    preamble="""typedef enum {{{states}}} ParserState deriving (Bits, Eq);
instance FShow#(ParserState);
    function Fmt show (ParserState state);
        return $format(" State %x", state);
    endfunction
endinstance
    """

    # FIXME to list
    imports="""
import DefaultValue::*;
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
import P4Types::*;"""

    moduleTopSignature="""(* synthesize *)
module mkParser(Parser);"""

    moduleTopPreamble="""\
    Reg#(ParserState) curr_state <- mkReg({initState});
    Reg#(Bool) started <- mkReg(False);
    FIFOF#(EtherData) data_in_fifo <- mkFIFOF;
    Wire#(Bool) start_fsm <- mkDWire(False);

    Empty init_state <- mk{initState}(curr_state, data_in_fifo, start_fsm);"""

    moduleTopInstantiateState="""\
    {interface} {name} <- mk{state}(curr_state, data_in_fifo);"""

    moduleTopMkConnection="""\
    mkConnection({out}, {in});"""

    moduleTopStartStatePre="""\
    rule start if (start_fsm);
        if (!started) begin"""

    moduleTopStartStatePost="""\
            started <= True;
        end
    endrule"""

    moduleTopStopStatePre="""\
    rule stop if (!start_fsm && curr_state == {initState});
        if (started) begin"""

    moduleTopStopStatePost="""\
            started <= False;
        end
    endrule"""

    def __init__(self, hlirParser):  # hlirParser is a P4 parser
        self.parser = hlirParser
        self.name = get_camel_case(hlirParser.name.capitalize())
        self.moduleSignature="""module mk{state}#(Reg#(ParserState) state, FIFO#(EtherData) datain{extraParam})({interface});"""

        self.unparsedFifo="""FIFO#({lastType}) unparsed_{lastState}_fifo <- mkSizedFIFO({lastSize});"""

        self.preamble="""Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
    Vector#({numNextState}, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
    PulseWire start_wire <- mkPulseWire();
    PulseWire stop_wire <- mkPulseWire();"""

        self.postamble="""\
    rule start_fsm if (start_wire);
        fsm_{fsm}.start;
    endrule
    rule stop_fsm if (stop_wire);
        fsm_{fsm}.abort;
    endrule
    method Action start();
        start_wire.send();
    endmethod
    method Action stop();
        stop_wire.send();
    endmethod"""

        self.fsm="""\
    FSM fsm_{fsm} <- mkFSM({fsm});"""

        self.nextStateArbiter="""\
    (* fire_when_enabled *)
    rule arbitrate_outgoing_state if (state == {state});
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
        let data_current <- toGet({fifo}).get;
        packet_in_wire <= data_current.data;
    endrule"""

        self.loadDelayedPacket="""\
    rule load_packet_delayed_{id} if (state == {state});
        let data_delayed <- toGet({fifo}).get;
        {unparsed_fifo}.enq(data_delayed);
    endrule"""

        self.alignByteStream="""\
    rule load_packet if (state=={state});
        let v = datain.first;
        if (v.sop) begin
            state <= {nextState};
            start_fsm <= True;
        end
        else begin
            datain.deq;
            start_fsm <= False;
        end
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
        if (nextState == {nextState}) begin
            unparsed_fifo_{nextState}.enq(pack(unparsed));
        end"""

        self.stmtAssignNextState="""\
        next_state_wire[{index}] <= tagged Valid nextState;"""

        self.stmtPostamble="""\
    endaction
    endseq;"""

    @classmethod
    def serialize_preamble(self, serializer, states):
        serializer.appendLine(LLVMParser.imports)
        serializer.appendLine(LLVMParser.preamble.format(states=",".join(states)))

    @classmethod
    def serialize_parse_interfaces(self):
        pass

    @staticmethod
    def convert(name):
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

    @classmethod
    def serialize_parser_top(self, serializer, states):
        serializer.emitIndent()
        serializer.appendLine(LLVMParser.moduleTopSignature)
        serializer.moduleStart()
        serializer.appendLine(self.moduleTopPreamble.format(initState=states[0]));
        for state in states:
            if (state == states[0]):
                continue
            serializer.appendLine(self.moduleTopInstantiateState.format(interface=state, name=LLVMParser.convert(state), state=state))

        # FIXME
        serializer.appendLine(self.moduleTopMkConnection)

        serializer.appendLine(self.moduleTopStartStatePre)
        for state in states:
            if (state == states[0]):
                continue
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.appendLine("{}.start;".format(LLVMParser.convert(state)))
        serializer.appendLine(self.moduleTopStartStatePost)

        serializer.appendLine(self.moduleTopStopStatePre.format(initState=states[0]))
        for state in states:
            if (state == states[0]):
                continue
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.appendLine("{}.clear;".format(LLVMParser.convert(state)))
        serializer.appendLine(self.moduleTopStopStatePost)

        serializer.moduleEnd()

    def serialize_start(self, serializer, nextState):
        serializer.emitIndent()
        serializer.appendLine(self.moduleSignature.format(state=self.name, interface="Empty", extraParam=", Wire#(Bool) start_fsm"))
        serializer.moduleStart()
        serializer.appendLine(self.alignByteStream.format(state=self.name, nextState=nextState.name));
        serializer.moduleEnd()

    def serialize(self, serializer, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        # module
        serializer.emitIndent()
        serializer.append(self.moduleSignature.format(state=self.name, interface=self.name, extraParam=""))
        serializer.moduleStart()
        # input interface
        serializer.emitIndent()
        serializer.appendLine(self.unparsedFifo.format(lastType="FIXME", lastState="FIXME", lastSize=1))
        # preamble
        serializer.emitIndent()
        serializer.appendLine(self.preamble.format(numNextState="FIXME"))
        # fsm
        serializer.appendLine(self.nextStateArbiter.format(state="0", numNextState="FIXME"))
        # branches
        self.serializeBranch(serializer, self.parser.branch_on, self.parser.branch_to, program)
        # load input data
        serializer.appendLine(self.loadPacket.format(id="FIXME", state="FIXME", fifo="input_fifo"))

        # any delayed data?
        serializer.appendLine(self.loadDelayedPacket.format(state="FIXME", id="FIXME", fifo="FIXME", unparsed_fifo="unparsedFifo"))

        # Stmt
        serializer.appendLine(self.stmtPreamble.format(name="fixme"))
        serializer.appendLine(self.stmtGetData)
        serializer.appendLine(self.stmtExtract.format(field="fixme", index="FIXME", unparsed_len="16", unparsed_index="112"))
        serializer.appendLine(self.stmtComputeNextState.format(field="FIXME"))
        serializer.appendLine(self.stmtUnparsedData.format(nextState="FIXME"))
        serializer.appendLine(self.stmtAssignNextState.format(index="FIXME"))
        serializer.appendLine(self.stmtPostamble)

        serializer.appendLine(self.fsm.format(fsm=self.name))
        # postamble
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
                nextState={state};
            end""".format(field=format(e,'x'), state="FIXME"))
            elif isinstance(e, tuple):
                raise CompilationException(True, "Not yet implemented")
            elif isinstance(e, p4_parse_value_set):
                raise NotSupportedException("{0}: Parser value sets", e)
            elif e is P4_DEFAULT:
                seenDefault = True
                serializer.append("""
            default: begin
                nextState={defaultState};
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

