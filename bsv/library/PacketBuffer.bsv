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
import FShow::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Pipe::*;
import SpecialFIFOs::*;
import Stream::*;
import Vector::*;
import DbgDefs::*;
import Ethernet::*;
import TieOff::*;

interface PktWriteClient;
   interface Get#(ByteStream#(16)) writeData;
endinterface

interface PktReadClient;
   interface Put#(ByteStream#(16)) readData;
   interface Put#(Bit#(EtherLen)) readLen;
   interface Get#(EtherReq) readReq;
endinterface

interface PktWriteServer;
   interface Put#(ByteStream#(16)) writeData;
endinterface

interface PktReadServer;
   interface Get#(ByteStream#(16)) readData;
   interface Get#(Bit#(EtherLen)) readLen;
   interface Put#(EtherReq) readReq;
endinterface

interface PacketBuffer;
   interface PktWriteServer writeServer;
   interface PktReadServer readServer;
   method PktBuffDbgRec dbg;
endinterface

instance Connectable#(PktWriteClient, PktWriteServer);
   module mkConnection#(PktWriteClient client, PktWriteServer server)(Empty);
      mkConnection(client.writeData, server.writeData);
   endmodule
endinstance

instance Connectable#(PktReadClient, PktReadServer);
   module mkConnection#(PktReadClient client, PktReadServer server)(Empty);
      mkConnection(client.readReq, server.readReq);
      mkConnection(server.readData, client.readData);
      mkConnection(server.readLen, client.readLen);
   endmodule
endinstance

module mkPacketBuffer(PacketBuffer);
   Clock current_clock <- exposeCurrentClock;
   Reset current_reset <- exposeCurrentReset;

   let verbose = False;

   Reg#(Bit#(32))  cycle <- mkReg(0);
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
   BRAM2Port#(Bit#(PktAddrWidth), ByteStream#(16)) memBuffer <- mkBRAM2Server(bramConfig);

   FIFO#(ByteStream#(16)) fifoWriteData <- mkFIFO;
   FIFOF#(Bit#(EtherLen)) fifoEop <- mkFIFOF;
   FIFO#(AddrTransRequest) incomingReqs     <- mkFIFO;

   // Client
   Reg#(Bit#(PktAddrWidth))     rdCurrPtr   <- mkReg(0);
   Reg#(Bool)                   outPacket   <- mkReg(False);

   FIFOF#(Bit#(EtherLen))    fifoLen     <- mkSizedFIFOF(16);
   FIFOF#(Bit#(EtherLen))    fifoReadReq <- mkSizedFIFOF(4);
   FIFOF#(ByteStream#(16))         fifoReadData <- mkBypassFIFOF();

   rule every1 if (verbose);
      cycle <= cycle + 1;
   endrule

   rule enq_stage1;
      ByteStream#(16) d <- toGet(fifoWriteData).get;
      incomingReqs.enq(AddrTransRequest{addr: wrCurrPtr, data:d});
      wrCurrPtr <= wrCurrPtr + 1;
      let newPacketLen = packetLen + zeroExtend(pack(countOnes(d.mask)));
      if (d.eop) begin
         fifoEop.enq(newPacketLen);
         packetLen <= 0;
      end
      else begin
         packetLen <= newPacketLen;
      end
   endrule

   rule enqueue_first_beat(!inPacket);
      AddrTransRequest req <- toGet(incomingReqs).get;
      if (verbose) $display("PacketBuffer::enqueue_first_beat %d", cycle, fshow(req));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
      inPacket <= True;
      sopEnq <= sopEnq + 1;
   endrule

   rule enqueue_next_beat(!fifoEop.notEmpty && inPacket);
      AddrTransRequest req <- toGet(incomingReqs).get;
      if (verbose) $display("PacketBuffer::enqueue_next_beat %d", cycle, fshow(req));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
   endrule

   rule commit_packet(fifoEop.notEmpty && inPacket);
      AddrTransRequest req <- toGet(incomingReqs).get;
      if (verbose) $display("PacketBuffer::commit_packet %d", cycle, fshow(req));
      memBuffer.portA.request.put(BRAMRequest{write:True, responseOnWrite:False,
         address:req.addr, datain:req.data});
      let v <- toGet(fifoEop).get;
      fifoLen.enq(v);
      inPacket <= False;
      eopEnq <= eopEnq + 1;
   endrule

   rule dequeue_first_beat(!outPacket);
      let v <- toGet(fifoReadReq).get;
      if (verbose) $display("PacketBuffer::dequeue_first_beat %d: %x %x", cycle, rdCurrPtr, v);
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
      if (verbose) $display("PacketBuffer::dequeue_next_beat %d: %x %x", cycle, rdCurrPtr, d);
   endrule

   // Big-endianess
   interface PktWriteServer writeServer;
      interface Put writeData;
         method Action put(ByteStream#(16) d);
            if (verbose) $display("PacketBuffer::writeData %d: Packet data %x", cycle, d.data);
            fifoWriteData.enq(d);
         endmethod
      endinterface
   endinterface
   interface PktReadServer readServer;
      interface Get readData;
         method ActionValue#(ByteStream#(16)) get if (fifoReadData.notEmpty);
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
      interface Put readReq;
         method Action put(EtherReq r);
            fifoReadReq.enq(r.len);
         endmethod
      endinterface
   endinterface
   method PktBuffDbgRec dbg();
      return PktBuffDbgRec { sopEnq: sopEnq
                            ,eopEnq: eopEnq
                            ,sopDeq: sopDeq
                            ,eopDeq: eopDeq };
   endmethod
endmodule

endpackage: PacketBuffer
