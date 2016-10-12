// Copyright (c) 2016 P4FPGA Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/* table
   - receive metadata request
   - performance table lookup
   - dispatch action request
   - gather action response
   - forward metadata request

   This module must be fully pipelined to minimize impact on throughput.
 */
import BUtils::*;
import BuildVector::*;
import CBus::*;
import ClientServer::*;
import ConfigReg::*;
import Connectable::*;
import DefaultValue::*;
import Ethernet::*;
import FIFO::*;
import FIFOF::*;
import FShow::*;
import GetPut::*;
import MatchTable::*;
import PacketBuffer::*;
import Pipe::*;
import Printf::*;
import PrintTrace::*;
import Register::*;
import SpecialFIFOs::*;
import SharedBuff::*;
import StmtFSM::*;
import TxRx::*;
import Utils::*;
import Vector::*;
import StructDefines::*;
import UnionDefines::*;
import ConnectalTypes::*;

`include "Debug.defines"
`include "SynthBuilder.defines"
interface Table#(numeric type nActions, type metaI, type actI, type keyT, type valueT);
   interface Server#(metaI, metaI) prev_control_state;
   interface Vector#(nActions, Client#(Tuple2#(metaI, actI), metaI)) next_control_state;
   method Action add_entry(keyT key, valueT value);
   method Action set_verbosity(int verbosity);
endinterface

typeclass Table_request #(type reqT);
   function reqT table_request (MetadataRequest data);
endtypeclass

typeclass Table_execute #(type rspT, type paramT, numeric type num);
   function Action table_execute (rspT rsp, MetadataRequest meta, Vector#(num, FIFOF#(Tuple2#(MetadataRequest, paramT))) fifos);
endtypeclass

typeclass Action_execute #(type paramT);
   function ActionValue#(MetadataRequest) step_1 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_1");
   function ActionValue#(MetadataRequest) step_2 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_2");
   function ActionValue#(MetadataRequest) step_3 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_3");
   function ActionValue#(MetadataRequest) step_4 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_4");
   function ActionValue#(MetadataRequest) step_5 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_5");
   function ActionValue#(MetadataRequest) step_6 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_6");
   function ActionValue#(MetadataRequest) step_7 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_7");
   function ActionValue#(MetadataRequest) step_8 (MetadataRequest data, paramT param) = error("No default for typeclass Action_execute::step_8");
endtypeclass

/*
   alternative implementation is 
 */
module mkTable#(function keyT match_table_request(metaI data),
                function Action execute_action(valT data, metaI md,
                   Vector#(nact, FIFOF#(Tuple2#(metaI, actI))) fifo),
                MatchTable#(a, b, c, d) matchTable)
                (Table#(nact, metaI, actI, keyT, valT))
   provisos(Bits#(actI, b__)
           ,Bits#(metaI, d__)
           ,Bits#(keyT, c)
           ,Bits#(valT, d)
           ,FShow#(keyT));
   `PRINT_DEBUG_MSG
   RX #(metaI) meta_in <- mkRX;
   TX #(metaI) meta_out <- mkTX;
   Vector#(nact, FIFOF#(Tuple2#(metaI, actI))) bbReqFifo <- replicateM(mkSizedFIFOF(16));
   Vector#(nact, FIFOF#(metaI)) bbRspFifo <- replicateM(mkSizedFIFOF(16));

   FIFOF#(metaI) metadata_ff <- mkSizedFIFOF(16);

   Vector#(nact, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);
   Bool interruptStatus = False;
   Bit#(nact) readyChannel = -1;
   messageM("readyChannel " + integerToString(valueOf(nact)) + " " + sprintf("%0d", readyChannel));
   for (Integer i=valueOf(TSub#(nact, 1)); i>=0; i=i-1) begin
       if (readyBits[i]) begin
           interruptStatus = True;
           readyChannel = fromInteger(i);
       end
   end
   rule rl_handle_request;
       metaI data = meta_in.u.first;
       meta_in.u.deq;
       let req = match_table_request(data);
       matchTable.lookupPort.request.put(pack(req));
       dbprint(3, fshow(req));
       metadata_ff.enq(data);
   endrule
   rule rl_execute;
       let rsp <- matchTable.lookupPort.response.get;
       let md <- toGet(metadata_ff).get;
       dbprint(3, fshow(rsp));
       if (rsp matches tagged Valid .r) begin
         execute_action(unpack(r), md, bbReqFifo);
       end
   endrule
   rule rl_handle_response if (readyChannel != -1);
       let v <- toGet(bbRspFifo[readyChannel]).get;
       meta_out.u.enq(v);
       dbprint(3, $format("dequeue %d ", readyChannel));
   endrule
   interface prev_control_state = toServer(meta_in.e, meta_out.e);
   interface next_control_state = zipWith(toClient, bbReqFifo, bbRspFifo);
   method Action add_entry(keyT k, valT v);
      // function that takes care of padding
      // let key = ForwardReqT { padding: 0, nhop_ipv4: k.nhop_ipv4};
      // let value = ForwardRspT { _action: unpack(v._action), dmac: v.dmac};
      matchTable.add_entry.put(tuple2(pack(k), pack(v)));
   endmethod
   method Action set_verbosity(int verbosity);
       cf_verbosity <= verbosity;
   endmethod
endmodule

