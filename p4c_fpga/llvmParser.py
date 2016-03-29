# Copyright (c) Barefoot Networks, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")

from p4_hlir.hlir import parse_call, p4_field, p4_parse_value_set, \
    P4_DEFAULT, p4_parse_state, p4_table, \
    p4_conditional_node, p4_parser_exception, \
    p4_header_instance, P4_NEXT
import p4_hlir.hlir.p4 as p4
import llvmProgram
import llvmStructType
import llvmInstance
import programSerializer
from compilationException import *
from helper import *
import collections
from pprint import pprint

class LLVMParser(object):

    total_bitcount = 0
    unparsed_bitcount = 0
    field_width = collections.OrderedDict()
    unparsedIn = collections.OrderedDict()
    unparsedOut = collections.OrderedDict()
    parseSteps = collections.OrderedDict()

    preamble="""typedef enum {{{states}}} ParserState deriving (Bits, Eq);
instance FShow#(ParserState);
    function Fmt fshow (ParserState state);
        return $format(" State %x", state);
    endfunction
endinstance
    """

    # templates
    library=["Connectable", "DefaultValue", "FIFO", "FIFOF", "FShow", "GetPut", "List", "StmtFSM", "SpecialFIFOs", "Vector", "Pipe", "Ethernet", "P4Types"]

    moduleTopInterface="""\
interface Parser;
    interface Put#(EtherData) frameIn;
endinterface
"""

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
    mkConnection({pipeout}, {pipein});"""

    moduleTopStartStatePre="""\
    rule start if (start_fsm);
        if (!started) begin"""

    moduleTopStartStatePost="""\
            started <= True;
        end
    endrule"""

    moduleTopStopStatePre="""\
    rule clear if (!start_fsm && curr_state == {initState});
        if (started) begin"""

    moduleTopStopStatePost="""\
            started <= False;
        end
    endrule"""

    moduleTopInterfaceEnd="""\
    interface frameIn = toPut(data_in_fifo);"""

    def __init__(self, hlirParser):  # hlirParser is a P4 parser
        self.parser = hlirParser
        self.name = hlirParser.name #get_camel_case(hlirParser.name.capitalize())
        self.numNextState = 1
        for e in self.parser.branch_to.values():
            if isinstance(e, p4_parse_state):
                self.numNextState += 1

        self.moduleSignature="""module mk{state}#(Reg#(ParserState) state, FIFOF#(EtherData) datain{extraParam})({interface});"""

        self.unparsedOutFifo="""FIFOF#({lastType}) unparsed_{lastState}_fifo <- mkSizedFIFOF({lastSize});"""
        self.unparsedInFifo="""FIFOF#({lastType}) unparsed_{lastState}_fifo <- mkBypassFIFOF;"""
        self.internalFifo="""FIFOF#({lastType}) internal_fifo <- mkSizedFIFOF(1);"""

        self.preamble="""Wire#(Bit#(128)) packet_in_wire <- mkDWire(0);
    Vector#({numNextState}, Wire#(Maybe#(ParserState))) next_state_wire <- replicateM(mkDWire(tagged Invalid));
    PulseWire start_wire <- mkPulseWire();
    PulseWire clear_wire <- mkPulseWire();"""

        self.postamble="""\
    rule start_fsm if (start_wire);
        fsm_{fsm}.start;
    endrule
    rule clear_fsm if (clear_wire);
        fsm_{fsm}.abort;
    endrule
    method Action start();
        start_wire.send();
    endmethod
    method Action clear();
        clear_wire.send();
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
        case (byteSwap({matchfield})) matches"""

        self.loadPacket="""\
    rule load_packet if (state == {state});
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
    seq"""

        self.stmtBeginAction="""\
    action"""

        self.stmtGetData="""\
        let {name} = packet_in_wire;"""

        self.stmtConcatData="""\
        Bit#({length}) data = {{data_current, {unparsed}}};"""

        self.stmtUnpackData="""\
        Vector#({length}, Bit#(1)) dataVec = unpack(data);"""

        self.stmtDelayFifo="""\
        {fifo}.enq(data);"""

        self.stmtGetFromFifo="""\
        let {data} <- toGet({fifo}).get;"""

        self.stmtExtract="""\
        let {field} = extract_{field}(pack(takeAt({index}, dataVec)));
        $display(fshow({field}));"""

        self.stmtUnparsed="""\
        Vector#({unparsed_len}, Bit#(1)) unparsed = takeAt({unparsed_index}, dataVec);"""

        self.stmtComputeNextState="""\
        let nextState = compute_next_state({field});
        $display("Goto state %h", nextState);"""

        self.stmtUnparsedData="""\
        if (nextState == {name}) begin
            unparsed_{nextState}_fifo.enq(pack(unparsed));
        end"""

        self.stmtAssignNextState="""\
        next_state_wire[{index}] <= tagged Valid {nextState};"""

        self.stmtEndAction="""\
    endaction"""

        self.stmtPostamble="""\
    endseq;"""

        self.stmtInterfaceGet="""\
    interface {name} = toGet({fifo});"""

        self.stmtInterfacePut="""\
    interface {name} = toPut({fifo});"""

    @classmethod
    def serialize_preamble(self, serializer, states):
        for l in LLVMParser.library:
            serializer.appendLine("import {}::*".format(l))
        s = map(lambda x: toState(x), states)
        serializer.appendLine(LLVMParser.preamble.format(states=",".join(s)))

    @classmethod
    def serialize_parser_top(self, serializer, states):
        serializer.emitIndent()
        serializer.appendLine(LLVMParser.moduleTopInterface)
        serializer.appendLine(LLVMParser.moduleTopSignature)
        serializer.moduleStart()
        serializer.appendLine(self.moduleTopPreamble.format(initState=toState(states[0])));
        for state in states:
            if (state == states[0]):
                continue
            serializer.appendLine(self.moduleTopInstantiateState.format(interface=CamelCase(state), name=convert(state), state=toState(state)))

        for k, v in LLVMParser.unparsedOut.items():
            for elem, width in v.items():
                if width == 0:
                    continue
                pair = [k, elem]
                print 'gg', pair, pair.reverse()
                serializer.appendLine(self.moduleTopMkConnection.format(pipeout=pair[0]+'.'+pair[1], pipein=pair[1]+'.'+pair[0]))

        serializer.appendLine(self.moduleTopStartStatePre)
        for state in states:
            if (state == states[0]):
                continue
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.appendLine("{}.start;".format(convert(state)))
        serializer.appendLine(self.moduleTopStartStatePost)

        serializer.appendLine(self.moduleTopStopStatePre.format(initState=toState(states[0])))
        for state in states:
            if (state == states[0]):
                continue
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.emitIndent()
            serializer.appendLine("{}.clear;".format(convert(state)))
        serializer.appendLine(self.moduleTopStopStatePost)
        serializer.appendLine(self.moduleTopInterfaceEnd)
        serializer.moduleEnd()

    def serialize_interfaces(self, serializer):
        if self.name == "start":
            return
        preamble="""interface {name};"""
        interfaceGet="""\
    interface Get#(Bit#({width})) {name};"""
        interfacePut="""\
    interface Put#(Bit#({width})) {name};"""
        postamble="""\
    method Action start;
    method Action clear;
endinterface"""
        serializer.appendLine(preamble.format(name=CamelCase(self.name)))
        for elem, width in LLVMParser.unparsedIn[self.name].items():
            if (width == 0):
                continue
            serializer.appendLine(interfacePut.format(width=width, name=elem))
        print 'pppp', LLVMParser.unparsedOut[self.name]
        for elem, width in LLVMParser.unparsedOut[self.name].items():
            serializer.appendLine(interfaceGet.format(width=width, name=elem))
        serializer.appendLine(postamble)

    def serialize_start(self, serializer, nextState):
        serializer.emitIndent()
        serializer.appendLine(self.moduleSignature.format(state=toState(self.name), interface="Empty", extraParam=", Wire#(Bool) start_fsm"))
        serializer.moduleStart()
        serializer.appendLine(self.alignByteStream.format(state=toState(self.name), nextState=toState(nextState.name)));
        serializer.moduleEnd()

    def serialize_common(self, serializer, program):
        assert isinstance(serializer, programSerializer.ProgramSerializer)
        assert isinstance(program, llvmProgram.LLVMProgram)
        # module
        serializer.emitIndent()
        serializer.append(self.moduleSignature.format(state=toState(self.name), interface=CamelCase(self.name), extraParam=""))
        serializer.moduleStart()
        # input interface
        for width in LLVMParser.parseSteps[self.name][1:]:
            serializer.emitIndent()
            serializer.appendLine(self.internalFifo.format(lastType="Bit#({})".format(width-128)))
        for state, width in LLVMParser.unparsedIn[self.name].items():
            if (width==0):
                continue
            serializer.emitIndent()
            serializer.appendLine(self.unparsedInFifo.format(lastType="Bit#({})".format(width), lastState=state))
        for state, width in LLVMParser.unparsedOut[self.name].items():
            if (width==0):
                continue
            serializer.emitIndent()
            serializer.appendLine(self.unparsedOutFifo.format(lastType="Bit#({})".format(width), lastState=state, lastSize=1))
        # preamble
        serializer.emitIndent()
        serializer.appendLine(self.preamble.format(numNextState=self.numNextState))
        # fsm
        serializer.appendLine(self.nextStateArbiter.format(state=toState(self.name), numNextState=self.numNextState))
        # branches
        self.serializeBranch(serializer, self.parser.branch_on, self.parser.branch_to, program)
        # load input data
        serializer.appendLine(self.loadPacket.format(state=toState(self.name), fifo="datain"))

        #FIXME: simplify this part
        # Stmt
        serializer.appendLine(self.stmtPreamble.format(name=self.name))
        serializer.appendLine(self.stmtBeginAction)
        #print 'ff', LLVMParser.parseSteps[self.name]

        # first parse cycle
        if (len(LLVMParser.parseSteps[self.name]) == 1):
            serializer.appendLine(self.stmtGetData.format(name="data"))
            serializer.appendLine(self.stmtUnpackData.format(length=128))
            for action, item in self.parser.call_sequence:
                _, length = LLVMParser.unparsedOut[self.name].items()[0]
                serializer.appendLine(self.stmtExtract.format(field=item.name, index="0", unparsed_len=length, unparsed_index=128-length))
            currWidth = LLVMParser.parseSteps[self.name][0]
            for action, item in self.parser.call_sequence:
                _, length = LLVMParser.unparsedOut[self.name].items()[0]
                serializer.appendLine(self.stmtUnparsed.format(unparsed_len=length, unparsed_index=currWidth-length))
            for elem in self.parser.branch_on:
                serializer.appendLine(self.stmtComputeNextState.format(field=elem))
            for target, length in LLVMParser.unparsedOut[self.name].items():
                serializer.appendLine(self.stmtUnparsedData.format(name=toState(target), nextState=target))
            serializer.appendLine(self.stmtAssignNextState.format(index=0, nextState="nextState"))
            serializer.appendLine(self.stmtEndAction)
        else:
            serializer.appendLine(self.stmtGetData.format(name="data_current"))
            length = LLVMParser.parseSteps[self.name][0]
            serializer.appendLine(self.stmtGetFromFifo.format(data='unparsed', fifo='unparsed_parse_ethernet_fifo')) #FIXME
            serializer.appendLine(self.stmtConcatData.format(length=length, unparsed='unparsed'))
            serializer.appendLine(self.stmtUnpackData.format(length=length))
            serializer.appendLine(self.stmtDelayFifo.format(fifo="internal_fifo"))
            serializer.appendLine(self.stmtEndAction)

            # every cycle but first and last
            for currWidth in LLVMParser.parseSteps[self.name][1:-1]:
                serializer.appendLine(self.stmtBeginAction)
                serializer.appendLine(self.stmtGetData.format(name="data_current"))
                for state, unparsedWidth in LLVMParser.unparsedIn[self.name].items():
                    if unparsedWidth== 0:
                        continue
                    serializer.appendLine(self.stmtGetFromFifo.format(data='data_delayed', fifo="internal_fifo"))

                serializer.appendLine(self.stmtConcatData.format(length=currWidth, unparsed='data_delayed'))
                serializer.appendLine(self.stmtUnpackData.format(length=currWidth))

                serializer.appendLine(self.stmtEndAction)

            # last parse cycle
            currWidth = LLVMParser.parseSteps[self.name][-1]
            serializer.appendLine(self.stmtBeginAction)
            serializer.appendLine(self.stmtGetData.format(name="data_current"))
            for state, unparsedWidth in LLVMParser.unparsedIn[self.name].items():
                if unparsedWidth== 0:
                    continue
                serializer.appendLine(self.stmtGetFromFifo.format(data='data_delayed', fifo="internal_fifo"))

            serializer.appendLine(self.stmtConcatData.format(length=currWidth, unparsed='data_delayed'))
            serializer.appendLine(self.stmtUnpackData.format(length=currWidth))

            for action, item in self.parser.call_sequence:
                for target, length in LLVMParser.unparsedOut[self.name].items():
                    print 'mmmmmtt', self.name, target, length
                    serializer.appendLine("%%%%%")
                    serializer.appendLine(self.stmtUnparsed.format(unparsed_len=length, unparsed_index=currWidth-length))
            serializer.appendLine(self.stmtExtract.format(field=item, index=0))
            for elem in self.parser.branch_on:
                serializer.appendLine(self.stmtComputeNextState.format(field=elem))
            for target, length in LLVMParser.unparsedOut[self.name].items():
                serializer.appendLine(self.stmtUnparsedData.format(name=toState(target), nextState=target))
            serializer.appendLine(self.stmtAssignNextState.format(index=0, nextState="nextState"))
            serializer.appendLine(self.stmtEndAction)

        serializer.appendLine(self.stmtPostamble)

        serializer.appendLine(self.fsm.format(fsm=self.name))
        # postamble
        serializer.appendLine(self.postamble.format(fsm=self.name))
        # output interface

        for elem, width in LLVMParser.unparsedIn[self.name].items():
            if (width == 0):
                continue
            serializer.appendLine(self.stmtInterfacePut.format(name=elem, fifo="unparsed_"+elem+"_fifo"))
        for elem, width in LLVMParser.unparsedOut[self.name].items():
            serializer.appendLine(self.stmtInterfaceGet.format(name=elem, fifo="unparsed_"+elem+"_fifo"))
        serializer.moduleEnd()

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

                serializer.appendLine(self.computeParseStateSelect.format(matchfield=llvmField.name, matchtype="Bit#({})".format(totalWidth), defaultState="StateStart"))
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
            print 'ee', value
            if isinstance(e, int):
                serializer.append("""
            'h{field}: begin
                nextState={state};
            end""".format(field=format(e,'x'), state=toState(value.name)))
            elif isinstance(e, tuple):
                raise CompilationException(True, "Not yet implemented")
            elif isinstance(e, p4_parse_value_set):
                raise NotSupportedException("{0}: Parser value sets", e)
            elif e is P4_DEFAULT:
                seenDefault = True
                serializer.append("""
            default: begin
                nextState={defaultState};
            end""".format(defaultState="StateStart"))
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
                print ("Conditional node Not yet implemented")
                #raise CompilationException(True, "Conditional node Not yet implemented")
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

    @classmethod
    def process_parser(self, node, stack, prev_bits, visited=None):
        if not visited:
            visited = set()
        visited.add(node.name)
        stack.append(node.name)
        # curr_bits: local_var, sum in current stage
        # prev_bits: local_var, unparsed from last stage
        curr_bits = prev_bits

        if (node.name != "start"):
            curr_bits += 128

        while (curr_bits < LLVMParser.field_width[node.name]):
            LLVMParser.parseSteps[node.name].append(curr_bits)
            curr_bits += 128

        LLVMParser.parseSteps[node.name].append(curr_bits)

        for case, target in node.branch_to.items():
            # next_bits: unparsed bits to next stage
            next_bits = curr_bits - LLVMParser.field_width[node.name]
            if type(case) is not list:
                case = [case]
            dst_name = target.name
            if type(target) is not p4.p4_table:
                print 'mmmmm', stack[-1], dst_name, next_bits
                LLVMParser.unparsedOut[stack[-1]][dst_name] = next_bits 

            for _, target in node.branch_to.items():
                if type(target) is p4.p4_parse_state and target.name not in visited:
                    self.process_parser(target, stack, next_bits, visited)
        stack.pop()

    def preprocess_parser(self, hlir):
        LLVMParser.field_width[self.parser.name] = 0
        extracted_bit_width = 0
        for k, v in self.parser.call_sequence:
            for field in hlir.p4_header_instances[v.name].fields:
                extracted_bit_width += field.width
        LLVMParser.field_width[self.parser.name] = extracted_bit_width

        for k in hlir.p4_parse_states:
            LLVMParser.unparsedIn[k] = collections.OrderedDict()
            LLVMParser.unparsedOut[k] = collections.OrderedDict()
            LLVMParser.parseSteps[k] = []

        for k, v in self.parser.branch_to.items():
            if type(v) is p4_parse_state:
                LLVMParser.unparsedIn[v.name][self.parser.name] = 0
                LLVMParser.unparsedOut[self.parser.name][v.name] = 0

    def postprocess_parser(self, hlir):
        for k, v in self.parser.branch_to.items():
            if type(v) is p4_parse_state:
                LLVMParser.unparsedIn[v.name][self.parser.name] = \
                        LLVMParser.unparsedOut[self.parser.name][v.name]

