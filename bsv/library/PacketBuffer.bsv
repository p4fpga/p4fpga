// Copyright (c) 2015 Cornell University.

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

/**
   Simple Packet Buffer
   TODO: handle error cases
      - buffer filled
*/

package PacketBuffer;

import BRAM::*;
import Clocks::*;
import Connectable::*;
import ConfigReg::*;
import Channel::*;
import DbgDefs::*;
import Ethernet::*;
import FShow::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Pipe::*;
import PrintTrace::*;
import SpecialFIFOs::*;
import Stream::*;
import TieOff::*;
import Vector::*;
`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"

typedef struct {
   Bit#(PktAddrWidth) addr;
   ByteStream#(n)     data;
} ReqT#(numeric type n) deriving (Eq, Bits);
instance FShow#(ReqT#(n));
   function Fmt fshow (ReqT#(n) req);
      return ($format(" addr=0x%x ", req.addr)
              + $format(" data=0x%x ", req.data.data)
              + $format(" user=0x%x ", req.data.user)
              + $format(" sop= %d ", req.data.sop)
              + $format(" eop= %d ", req.data.eop));
   endfunction
endinstance

interface PktWriteClient#(numeric type n);
   interface Get#(ByteStream#(n)) writeData;
endinterface

interface PktReadClient#(numeric type n);
   interface Put#(ByteStream#(n)) readData;
   interface Put#(Bit#(EtherLen)) readLen;
   interface Get#(Bit#(EtherLen)) readReq;
endinterface

interface PktWriteServer#(numeric type n);
   interface Put#(ByteStream#(n)) writeData;
endinterface

interface PktReadServer#(numeric type n);
   interface Get#(ByteStream#(n)) readData;
   interface Get#(Bit#(EtherLen)) readLen;
   interface Put#(Bit#(EtherLen)) readReq;
endinterface

interface PacketBuffer#(numeric type n);
   interface PktWriteServer#(n) writeServer;
   interface PktReadServer#(n) readServer;
   method PktBuffDbgRec dbg;
   method Action set_verbosity (int verbosity);
endinterface

instance SetVerbosity#(PacketBuffer#(n));
   function Action set_verbosity(PacketBuffer#(n) t, int verbosity);
      action
         t.set_verbosity(verbosity);
      endaction
   endfunction
endinstance

instance Connectable#(PktWriteClient#(n), PktWriteServer#(n));
   module mkConnection#(PktWriteClient#(n) client, PktWriteServer#(n) server)(Empty);
      mkConnection(client.writeData, server.writeData);
   endmodule
endinstance

instance Connectable#(PktReadClient#(n), PktReadServer#(n));
   module mkConnection#(PktReadClient#(n) client, PktReadServer#(n) server)(Empty);
      mkConnection(client.readReq, server.readReq);
      mkConnection(server.readData, client.readData);
      mkConnection(server.readLen, client.readLen);
   endmodule
endinstance

typeclass ReadServer#(numeric type n);
   function Get#(Bit#(EtherLen)) getReadLen(PacketBuffer#(n) buff);
   function Put#(Bit#(EtherLen)) getReadReq(PacketBuffer#(n) buff);
   function Get#(ByteStream#(n)) getReadData(PacketBuffer#(n) buff);
endtypeclass

instance ReadServer#(n);
   function Get#(Bit#(EtherLen)) getReadLen(PacketBuffer#(n) buff);
      return buff.readServer.readLen;
   endfunction
   function Put#(Bit#(EtherLen)) getReadReq(PacketBuffer#(n) buff);
      return buff.readServer.readReq;
   endfunction
   function Get#(ByteStream#(n)) getReadData(PacketBuffer#(n) buff);
      return buff.readServer.readData;
   endfunction
endinstance

typeclass WriteServer#(numeric type n);
   function Put#(ByteStream#(n)) getWriteData(PacketBuffer#(n) buff);
endtypeclass

instance WriteServer#(n);
   function Put#(ByteStream#(n)) getWriteData(PacketBuffer#(n) buff);
      return buff.writeServer.writeData;
   endfunction
endinstance

module mkPacketBuffer#(String msg)(PacketBuffer#(n))
   provisos (Add#(1, a__, TLog#(TAdd#(1, n)))
            ,Add#(b__, TLog#(TAdd#(1, n)), 16));
   `PRINT_DEBUG_MSG
   Clock current_clock <- exposeCurrentClock;
   Reset current_reset <- exposeCurrentReset;
   // Mac
   Wire#(Bit#(64))              data        <- mkWire;
   Wire#(Bool)                  valid       <- mkWire;
   Wire#(Bool)                  sop         <- mkWire;
   Wire#(Bool)                  eop         <- mkWire;
   Wire#(Bool)                  goodFrame   <- mkWire;
   Wire#(Bool)                  badFrame    <- mkWire;

   Reg#(Bit#(PktAddrWidth))     wrCurrPtr   <- mkReg(0);
   Reg#(Bit#(EtherLen))         packetLen   <- mkReg(0);
   Reg#(Bool)                   inPacket    <- mkReg(False);

   // status registers
   Reg#(Bit#(64)) sopEnq <- mkReg(0);
   Reg#(Bit#(64)) eopEnq <- mkReg(0);
   Reg#(Bit#(64)) sopDeq <- mkReg(0);
   Reg#(Bit#(64)) eopDeq <- mkReg(0);

   // Memory
   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency = 1;
   BRAM2Port#(Bit#(PktAddrWidth), ByteStream#(n)) memBuffer <- mkBRAM2Server(bramConfig);

   FIFO#(ByteStream#(n)) fifoWriteData <- mkFIFO;
   FIFOF#(Bit#(EtherLen)) fifoEop <- mkFIFOF;
   FIFO#(ReqT#(n)) incomingReqs     <- mkFIFO;

   // Client
   Reg#(Bit#(PktAddrWidth))     rdCurrPtr   <- mkReg(0);
   Reg#(Bool)                   outPacket   <- mkReg(False);

   FIFOF#(Bit#(EtherLen))    fifoLen     <- mkSizedFIFOF(16);
   FIFOF#(Bit#(EtherLen))    fifoReadReq <- mkSizedFIFOF(4);
   FIFOF#(ByteStream#(n))    fifoReadData <- mkBypassFIFOF();

   rule enq_stage1;
      ByteStream#(n) d <- toGet(fifoWriteData).get;
      incomingReqs.enq(ReqT{addr: wrCurrPtr, data:d});
      wrCurrPtr <= wrCurrPtr + 1;
      let newPacketLen = packetLen + zeroExtend(pack(countOnes(d.mask)));
      dbprint(3, $format("%s enq_stage1 ", msg, fshow(d)));
      inPacket <= True;
      if (d.eop) begin
         fifoEop.enq(newPacketLen);
         packetLen <= 0;
      end
      else begin
         packetLen <= newPacketLen;
      end
   endrule

   rule enqueue_first_beat(!fifoEop.notEmpty && !inPacket);
      ReqT#(n) req <- toGet(incomingReqs).get;
      dbprint(3, $format("%s enqueue_first_beat ", msg, fshow(req)));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
      sopEnq <= sopEnq + 1;
   endrule

   rule enqueue_next_beat(!fifoEop.notEmpty && inPacket);
      ReqT#(n) req <- toGet(incomingReqs).get;
      dbprint(3, $format("%s enqueue_next_beat ", msg, fshow(req)));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
   endrule

   rule commit_packet(fifoEop.notEmpty && inPacket);
      ReqT#(n) req <- toGet(incomingReqs).get;
      dbprint(3, $format("%s commit_packet ", msg, fshow(req)));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
      let v <- toGet(fifoEop).get;
      fifoLen.enq(v);
      inPacket <= False;
      eopEnq <= eopEnq + 1;
   endrule

   rule dequeue_first_beat(!outPacket);
      let v <- toGet(fifoReadReq).get;
      dbprint(3, $format("%s dequeue_first_beat : %x %x", msg, rdCurrPtr, v));
      memBuffer.portB.request.put(BRAMRequest{write:False, responseOnWrite:False,
         address:truncate(rdCurrPtr), datain:?});
      outPacket <= True;
      rdCurrPtr <= rdCurrPtr + 1;
      sopDeq <= sopDeq + 1;
   endrule

   rule dequeue_next_beat(outPacket);
      let d <- memBuffer.portB.response.get;
      fifoReadData.enq(d);
      if (d.eop) begin
         outPacket <= False;
         eopDeq <= eopDeq + 1;
      end
      else begin
         memBuffer.portB.request.put(BRAMRequest{write:False, responseOnWrite:False,
            address:truncate(rdCurrPtr), datain:?});
         rdCurrPtr <= rdCurrPtr + 1;
      end
      dbprint(3, $format("%s dequeue_next_beat : %x %x", msg, rdCurrPtr, d));
   endrule

   // Big-endianess
   interface PktWriteServer writeServer;
      interface Put writeData;
         method Action put(ByteStream#(n) d);
            dbprint(3, $format("%s writeData : Packet data ", msg, fshow(d)));
            fifoWriteData.enq(d);
         endmethod
      endinterface
   endinterface
   interface PktReadServer readServer;
      interface Get readData;
         method ActionValue#(ByteStream#(n)) get if (fifoReadData.notEmpty);
            let v = fifoReadData.first;
            fifoReadData.deq;
            return v;
         endmethod
      endinterface
      interface Get readLen;
         method ActionValue#(Bit#(EtherLen)) get if (fifoLen.notEmpty);
            let v = fifoLen.first;
            fifoLen.deq;
            return v;
         endmethod
      endinterface
      interface Put readReq = toPut(fifoReadReq);
   endinterface
   method PktBuffDbgRec dbg();
      return PktBuffDbgRec { sopEnq: sopEnq
                            ,eopEnq: eopEnq
                            ,sopDeq: sopDeq
                            ,eopDeq: eopDeq };
   endmethod
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule
endpackage: PacketBuffer
