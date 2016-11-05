// Copyright (c) 2016 Cornell University.

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

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import ClientServer::*;
import StmtFSM::*;
import Vector::*;
import DefaultValue::*;
import BRAM::*;
import FShow::*;
import Pipe::*;
import StringUtils::*;
import List::*;
import PrintTrace::*;
import DMHC::*;
import SynthBuilder::*;
import Bcam::*;
import BcamTypes::*;

`include "SynthBuilder.defines"
`include "ConnectalProjectConfig.bsv"

`define HASH 1
`define BCAM 2
`define TCAM 3
`define SIMU 4

interface MatchTable#(numeric type tp,
                      numeric type uniq,
                      numeric type depth,
                      numeric type keySz,
                      numeric type actionSz);
   interface Server#(Bit#(keySz), Maybe#(Bit#(actionSz))) lookupPort;
   interface Put#(Tuple2#(Bit#(keySz), Bit#(actionSz))) add_entry;
   interface Put#(Bit#(TLog#(depth))) delete_entry;
   interface Put#(Tuple2#(Bit#(TLog#(depth)), Bit#(actionSz))) modify_entry;
endinterface

typeclass MatchTableSim#(numeric type uniq, numeric type ksz, numeric type vsz);
   function ActionValue#(Bit#(vsz)) matchtable_read(Bit#(uniq) v, Bit#(ksz) key);
   function Action matchtable_write(Bit#(uniq) v, Bit#(ksz) key, Bit#(vsz) data);
endtypeclass

typeclass MkMatchTable#(numeric type tp,
                        numeric type uniq,
                        numeric type depth,
                        numeric type keySz,
                        numeric type actionSz);
   module mkMatchTable#(String name)(MatchTable#(tp, uniq, depth, keySz, actionSz));
endtypeclass

/*
   Special case when match table uses empty key, i.e. no match table
 */
instance MkMatchTable#(`SIMU, uniq, depth, 0, actionSz)
   provisos (MatchTable::MatchTableSim#(uniq, 0, actionSz));
   module mkMatchTable#(String name)(MatchTable#(`SIMU, uniq, depth, 0, actionSz))
   provisos (MatchTable::MatchTableSim#(uniq, 0, actionSz));
      // This is intentionally empty
      messageM("empty match table");
   endmodule
endinstance
instance MkMatchTable#(`HASH, uniq, depth, 0, actionSz);
   module mkMatchTable#(String name)(MatchTable#(`HASH, uniq, depth, 0, actionSz));
      // This is intentionally empty
      messageM("empty match table");
   endmodule
endinstance
instance MkMatchTable#(`BCAM, uniq, depth, 0, actionSz);
   module mkMatchTable#(String name)(MatchTable#(`BCAM, uniq, depth, 0, actionSz));
      // This is intentionally empty
      messageM("empty match table");
   endmodule
endinstance

/*
   Bcam-based match table
 */
instance MkMatchTable#(`BCAM, uniq, depth, keySz, actionSz)
   provisos(Mul#(c__, 256, d__),
            Add#(c__, 7, TLog#(depth)),
            Log#(d__, TLog#(depth)),
            Mul#(e__, 9, keySz),
            Add#(TAdd#(TLog#(c__), 4), 2, TLog#(TDiv#(depth, 4))),
            Log#(TDiv#(depth, 16), TAdd#(TLog#(c__), 4)),
            Add#(9, f__, keySz),
            PriorityEncoder::PEncoder#(d__),
            Add#(2, g__, TLog#(depth)),
            Add#(4, h__, TLog#(depth)),
            Add#(TAdd#(TLog#(c__), 4), i__, TLog#(depth)));

   module mkMatchTable#(String name)(MatchTable#(`BCAM, uniq, depth, keySz, actionSz))
      provisos(Mul#(c__, 256, d__),
               Add#(c__, 7, TLog#(depth)),
               Log#(d__, TLog#(depth)),
               Mul#(e__, 9, keySz),
               Add#(TAdd#(TLog#(c__), 4), 2, TLog#(TDiv#(depth, 4))),
               Log#(TDiv#(depth, 16), TAdd#(TLog#(c__), 4)),
               Add#(9, f__, keySz),
               PriorityEncoder::PEncoder#(d__),
               Add#(2, g__, TLog#(depth)),
               Add#(4, h__, TLog#(depth)),
               Add#(TAdd#(TLog#(c__), 4), i__, TLog#(depth)));

      MatchTable#(`BCAM, uniq, depth, keySz, actionSz) ret_ifc;
      ret_ifc <- mkMatchTableSynth();
      return ret_ifc;
   endmodule
endinstance

// SIMULATION instance
`ifdef SIMULATION
instance MkMatchTable#(`SIMU, uniq, depth, keySz, actionSz) 
   provisos (MatchTableSim#(uniq, keySz, actionSz));
   module mkMatchTable#(String name)(MatchTable#(`SIMU, uniq, depth, keySz, actionSz))
      provisos (MatchTableSim#(uniq, keySz, actionSz));
      MatchTable#(`SIMU, uniq, depth, keySz, actionSz) ret_ifc;
      ret_ifc <- mkMatchTableBluesim(name);
      return ret_ifc;
   endmodule
endinstance
`endif

// Hash-based match table
instance MkMatchTable#(`HASH, uniq, depth, keySz, actionSz)
   provisos(Add#(a__, TLog#(TMul#(2, depth)), keySz));
   module mkMatchTable#(String name)(MatchTable#(`HASH, uniq, depth, keySz, actionSz))
      provisos(Add#(a__, TLog#(TMul#(2, depth)), keySz));
      MatchTable#(`HASH, uniq, depth, keySz, actionSz) ret_ifc;
      ret_ifc <- mkMatchTableDMHC(name);
      messageM("Generate hash-based match table: " + printType(typeOf(ret_ifc)));
      return ret_ifc;
   endmodule
endinstance

//`ifndef SIMULATION
module mkMatchTableSynth(MatchTable#(`BCAM, uniq, depth, keySz, actionSz))
   provisos (NumAlias#(depthSz, TLog#(depth)),
             Mul#(a__, 256, b__),
             Add#(a__, 7, depthSz),
             Log#(b__, depthSz),
             Mul#(c__, 9, keySz),
             Add#(TAdd#(TLog#(a__), 4), 2, TLog#(TDiv#(depth, 4))),
             Log#(TDiv#(depth, 16), TAdd#(TLog#(a__), 4)),
             Add#(9, d__, keySz),
             PriorityEncoder::PEncoder#(b__),
             Add#(2, e__, TLog#(depth)),
             Add#(4, f__, TLog#(depth)),
             Add#(TAdd#(TLog#(a__), 4), g__, TLog#(depth))
            );
   let verbose = True;
   Reg#(Bit#(32)) cycle <- mkReg(0);

   rule every1 (verbose);
      cycle <= cycle + 1;
   endrule

   BinaryCam#(depth, keySz) bcam <- mkBinaryCam();
   FIFO#(Bool) bcamMatchFifo <- mkFIFO();

   BRAM_Configure cfg = defaultValue;
   cfg.latency = 2;
   BRAM2Port#(Bit#(depthSz), Bit#(actionSz)) ram <- mkBRAM2Server(cfg);

   Reg#(Bit#(depthSz)) addrIdx <- mkReg(0);

   rule handle_bcam_response;
      let v <- bcam.readServer.response.get;
      if (verbose) $display("(%0d) MatchTable:handle_bcam_response ", $time, fshow(v));
      if (isValid(v)) begin // if match
         let address = fromMaybe(?, v);
         ram.portA.request.put(BRAMRequest{write:False, responseOnWrite: False, address: address, datain:?});
         bcamMatchFifo.enq(True);
      end
      else begin // if miss
         ram.portA.request.put(BRAMRequest{write:False, responseOnWrite: False, address: 0, datain: ?});
         bcamMatchFifo.enq(False);
      end
   endrule

   // Interface for lookup from data-plane modules
   interface Server lookupPort;
      interface Put request;
         method Action put (Bit#(keySz) v);
            BcamReadReq#(Bit#(keySz)) req_bcam = BcamReadReq{data: v};
            bcam.readServer.request.put(pack(req_bcam));
            //if (verbose) $display("matchTable %d: lookup ", cycle, fshow(req_bcam));
         endmethod
      endinterface
      interface Get response;
         method ActionValue#(Maybe#(Bit#(actionSz))) get();
            let m <- toGet(bcamMatchFifo).get;
            let act <- ram.portA.response.get;
            if (verbose) $display("(%0d) MatchTable:response ", $time, fshow(act));
            case (m) matches
               True: return tagged Valid act;
               False: return tagged Invalid;
            endcase
         endmethod
      endinterface
   endinterface

   // Interface for write from control-plane
   interface Put add_entry;
      method Action put (Tuple2#(Bit#(keySz), Bit#(actionSz)) v);
         BcamWriteReq#(Bit#(depthSz), Bit#(keySz)) req_bcam = BcamWriteReq{addr: addrIdx, data: pack(tpl_1(v))};
         BRAMRequest#(Bit#(depthSz), Bit#(actionSz)) req_ram = BRAMRequest{write: True, responseOnWrite: False, address: addrIdx, datain: pack(tpl_2(v))};
         bcam.writeServer.put(req_bcam);
         ram.portA.request.put(req_ram);
         $display("(%0d) Matchtable:add_entry %x %x %x", $time, addrIdx, tpl_1(v), tpl_2(v));
         addrIdx <= addrIdx + 1; //FIXME: currently no reuse of address.
      endmethod
   endinterface
   interface Put delete_entry;
      method Action put (Bit#(depthSz) id);
         BcamWriteReq#(Bit#(depthSz), Bit#(keySz)) req_bcam = BcamWriteReq{addr: id, data: 0};
         BRAMRequest#(Bit#(depthSz), Bit#(actionSz)) req_ram = BRAMRequest{write: True, responseOnWrite: False, address: id, datain: 0};
         bcam.writeServer.put(req_bcam);
         ram.portA.request.put(req_ram);
         $display("(%0d) Matchtable:delete_entry %x", $time, id);
      endmethod
   endinterface
   interface Put modify_entry;
      method Action put (Tuple2#(Bit#(depthSz), Bit#(actionSz)) v);
         match { .flowid, .act} = v;
         BRAMRequest#(Bit#(depthSz), Bit#(actionSz)) req_ram = BRAMRequest{write: True, responseOnWrite: False, address: flowid, datain: pack(act)};
         ram.portA.request.put(req_ram);
      endmethod
   endinterface
endmodule
//`endif

`ifdef SIMULATION
module mkMatchTableBluesim#(String name)(MatchTable#(`SIMU, uniq, depth, keySz, actionSz))
   provisos (MatchTable::MatchTableSim#(uniq, keySz, actionSz));
   let verbose = True;

   Integer idv = valueOf(uniq);
   Integer dpv = valueOf(depth);
   FIFO#(Tuple2#(Bit#(keySz), Bit#(actionSz))) writeReqFifo <- mkFIFO;
   FIFO#(Bit#(keySz)) readReqFifo <- mkFIFO;
   FIFO#(Maybe#(Bit#(actionSz))) readDataFifo <- printTimedTraceM(name, mkFIFO);

   Reg#(Bool)      isInitialized   <- mkReg(True);

   rule do_read (isInitialized);
      let v <- toGet(readReqFifo).get;
      $display("(%0d) MatchTable:do_read %s key: %h", $time, name, v);
      Bit#(uniq) tid = 0;
      let ret <- matchtable_read(tid, pack(v));
      $display("(%0d) MatchTable:do_read %s value: %h", $time, name, ret);
      if (ret != 0)
         readDataFifo.enq(tagged Valid ret);
      else
         readDataFifo.enq(tagged Invalid);
   endrule

   interface Server lookupPort;
      interface Put request = toPut(readReqFifo);
      interface Get response = toGet(readDataFifo);
   endinterface
   interface Put add_entry;
      method Action put (Tuple2#(Bit#(keySz), Bit#(actionSz)) v);
         $display("(%0d) MatchTable:add_entry %h %h", $time, tpl_1(v), tpl_2(v));
         Bit#(uniq) tid = 0;
         matchtable_write(tid, tpl_1(v), tpl_2(v));
      endmethod
   endinterface
   interface Put delete_entry;
      method Action put (Bit#(depthSz) id);
      endmethod
   endinterface
   interface Put modify_entry;
      method Action put (Tuple2#(Bit#(depthSz), Bit#(actionSz)) v);
      endmethod
   endinterface
endmodule
`endif

module mkMatchTableDMHC#(String name)(MatchTable#(`HASH, uniq, depth, keySz, actionSz))
   provisos(Add#(a__, TLog#(TMul#(2, depth)), keySz));
   DMHCIfc#(depth, 4, 2, keySz, actionSz) dmhc <- mkDMHC();
   FIFO#(Bit#(keySz)) readReqFifo <- mkFIFO;
   FIFO#(Maybe#(Bit#(actionSz))) readDataFifo <- printTimedTraceM(name, mkFIFO);
   FIFO#(Bit#(keySz)) delay_ff <- mkFIFO;
   FIFO#(Bit#(keySz)) delay2_ff <- mkFIFO;

   rule do_read (dmhc.is_enabled);
      let v <- toGet(readReqFifo).get;
      $display("(%0d) MatchTable:do_read %s key: %h", $time, name, v);
      dmhc.lookup_key(v);
      delay_ff.enq(v);
   endrule

   // pipeline delay for dmhc read, assume read latency of 2
   rule do_delay;
      let v <- toGet(delay_ff).get;
      delay2_ff.enq(v);
      $display("(%0d) dmhc %d", $time, dmhc.is_hit);
   endrule

   rule do_resp;
      let v <- toGet(delay2_ff).get;
      $display("(%0d) MatchTable:do_resp %s key: %h, ishit: %d", $time, name, v, dmhc.is_hit);
      if (dmhc.is_hit) begin
         let val = dmhc.get_value;
         readDataFifo.enq(tagged Valid val);
      end
      else begin
         readDataFifo.enq(tagged Invalid);
      end
   endrule

   interface Server lookupPort;
      interface Put request = toPut(readReqFifo);
      interface Get response = toGet(readDataFifo);
   endinterface
   interface Put add_entry;
      method Action put (Tuple2#(Bit#(keySz), Bit#(actionSz)) v);
         $display("(%0d) add entry %h %h", $time, tpl_1(v), tpl_2(v));
         dmhc.new_key_value(tpl_1(v), tpl_2(v));
      endmethod
   endinterface
   interface Put delete_entry;
      method Action put (Bit#(depthSz) id);

      endmethod
   endinterface
   interface Put modify_entry;
      method Action put (Tuple2#(Bit#(depthSz), Bit#(actionSz)) v);

      endmethod
   endinterface
endmodule
`SynthBuildModule(mkDMHC, DMHCIfc#(1024, 4, 2, 64, 64), mkDMHC_64)
