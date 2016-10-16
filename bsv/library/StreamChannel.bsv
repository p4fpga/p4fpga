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

import Library::*;
import Channel::*;
import StoreAndForward::*;
import StreamGearbox::*;
import SharedBuff::*;
import HeaderSerializer::*;
import Printf::*;
import PrintTrace::*;
import PacketModifier::*;
`include "ConnectalProjectConfig.bsv"
import `PARSER::*;
import `DEPARSER::*;
import `TYPEDEF::*;
`include "Debug.defines"

function PktWriteClient#(16) toWriteClient(FIFO#(ByteStream#(16)) fifo);
   PktWriteClient#(16) writeClient = (interface PktWriteClient;
      interface writeData = toGet(fifo);
   endinterface);
   return writeClient;
endfunction

interface StoreAndFwdBuffer;
   interface PktWriteServer#(16) writeServer;
   interface PipeIn#(MetadataRequest) prev;
   interface PktWriteClient#(16) writeClient;
   method Action set_verbosity (int verbosity);
endinterface

module mkStoreAndFwdBuffer#(Integer id)(StoreAndFwdBuffer);
   `PRINT_DEBUG_MSG

   String msg = sprintf("store&fwd %d", id);
   FIFOF#(MetadataRequest) meta_ff <- mkFIFOF;

   PacketBuffer#(16) pktBuff <- mkPacketBuffer(msg);

   // RingBuffer Read Client
   FIFO#(ByteStream#(16)) readDataFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkFIFO;
   FIFO#(ByteStream#(16)) writeDataFifo <- printTraceM("OutChan", mkFIFO);
   Reg#(Bool) readStarted <- mkReg(False);

   PktReadClient#(16) readClient = (interface PktReadClient;
      interface readData = toPut(readDataFifo);
      interface readLen = toPut(readLenFifo);
      interface readReq = toGet(readReqFifo);
   endinterface);

   mkConnection(readClient, pktBuff.readServer);

   rule packetReadStart if (!readStarted);
      let req = meta_ff.first;
      meta_ff.deq;
      let pktLen <- toGet(readLenFifo).get;
      readReqFifo.enq(pktLen);
      readStarted <= True;
      dbprint(3, $format("stream out read packet start len=%d ", pktLen));
   endrule

   rule packetReadInProgress if (readStarted);
      let v <- toGet(readDataFifo).get;
      if (v.eop) begin
         readStarted <= False;
      end
      writeDataFifo.enq(v);
   endrule

   interface prev = toPipeIn(meta_ff);
   interface writeServer= pktBuff.writeServer;
   interface writeClient = toWriteClient(writeDataFifo);
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
   endmethod
endmodule

interface StreamOutChannel;
   interface PktWriteServer#(16) writeServer;
   interface PipeIn#(MetadataRequest) prev;
   interface PktWriteClient#(16) writeClient;
   method Action set_verbosity (int verbosity);
endinterface

instance GetWriteServer#(StreamOutChannel);
   function Put#(ByteStream#(16)) getWriteServer(StreamOutChannel chan);
      return chan.writeServer.writeData;
   endfunction
endinstance

instance GetWriteClient#(StreamOutChannel);
   function Get#(ByteStream#(16)) getWriteClient(StreamOutChannel chan);
      return chan.writeClient.writeData;
   endfunction
endinstance

instance GetMetaIn#(StreamOutChannel);
   function PipeIn#(MetadataRequest) getMetaIn(StreamOutChannel chan);
      return chan.prev;
   endfunction
endinstance

instance SetVerbosity#(StreamOutChannel);
   function Action set_verbosity(StreamOutChannel t, int verbosity);
      action
         t.set_verbosity(verbosity);
      endaction
   endfunction
endinstance

module mkStreamOutChannel#(Integer id)(StreamOutChannel);
   `PRINT_DEBUG_MSG
   FIFOF#(MetadataRequest) meta_ff <- mkFIFOF;
   StoreAndFwdBuffer pktBuff <- mkStoreAndFwdBuffer(id);
   PacketModifier modifier <- mkPacketModifier();

   mkConnection(pktBuff.writeClient, modifier.writeServer);

   rule rl_dispatch_metadata;
      let req <- toGet(meta_ff).get;
      pktBuff.prev.enq(req);
      modifier.prev.enq(req);
      dbprint(3, $format("initiate transmit packet id=%d", id));
   endrule

   interface prev = toPipeIn(meta_ff);
   interface writeServer= pktBuff.writeServer;
   interface writeClient = modifier.writeClient;
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
      pktBuff.set_verbosity(verbosity);
      modifier.set_verbosity(verbosity);
   endmethod
endmodule

// Streaming version of HostChannel
interface StreamInChannel;
   interface PktWriteServer#(16) writeServer;
   interface PktWriteClient#(16) writeClient;
   interface PipeOut#(MetadataRequest) next;
   method Action set_verbosity (int verbosity);
endinterface

instance GetWriteClient#(StreamInChannel);
   function Get#(ByteStream#(16)) getWriteClient(StreamInChannel chan);
      return chan.writeClient.writeData;
   endfunction
endinstance

instance SetVerbosity#(StreamInChannel);
   function Action set_verbosity(StreamInChannel t, int verbosity);
      action
         t.set_verbosity(verbosity);
      endaction
   endfunction
endinstance

module mkStreamInChannel#(Integer id)(StreamInChannel);
   Reg#(int) cf_verbosity <- mkConfigRegU;
   FIFOF#(MetadataRequest) outReqFifo <- mkFIFOF;

   // RingBuffer Read Client
   FIFO#(ByteStream#(16)) readDataFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkFIFO;
   FIFO#(ByteStream#(16)) writeDataFifo <- mkFIFO;
   Reg#(Bool) readStarted <- mkReg(False);
   FIFO#(Bit#(EtherLen)) pktLenFifo <- mkFIFO;

   PacketBuffer#(16) pktBuff <- mkPacketBuffer("streamIn channel");
   Parser parser <- mkParser(id);

   PktReadClient#(16) readClient = (interface PktReadClient;
      interface readData = toPut(readDataFifo);
      interface readLen = toPut(readLenFifo);
      interface readReq = toGet(readReqFifo);
   endinterface);

   mkConnection(readClient, pktBuff.readServer);

   function Action dbprint(Integer level, Fmt msg);
      action
      if (cf_verbosity > fromInteger(level)) begin
         $display("(%0d) ", $time, msg);
      end
      endaction
   endfunction

   rule packetReadStart if (!readStarted);
      let pktLen <- toGet(readLenFifo).get;
      pktLenFifo.enq(pktLen);
      readReqFifo.enq(pktLen);
      readStarted <= True;
      dbprint(3, $format("read packet start %d", pktLen));
   endrule

   rule packetReadInProgress if (readStarted);
      let v <- toGet(readDataFifo).get;
      if (v.eop) begin
         readStarted <= False;
      end
      writeDataFifo.enq(v);
      parser.frameIn.put(v);
      dbprint(3, $format("read packet start ", fshow(v)));
   endrule

   rule dispatch_packet;
      let pktLen <- toGet(pktLenFifo).get;
      let meta <- parser.meta.get;
      let pktInst = PacketInstance {id: 0, size: pktLen};
      // set ingress_port metadata
      meta.standard_metadata.ingress_port = tagged Valid fromInteger(id);
      MetadataRequest nextReq = MetadataRequest {pkt: pktInst, meta: meta};
      outReqFifo.enq(nextReq);
      dbprint(3, $format("send packet ingress %d ", id, fshow(meta)));
   endrule

   interface writeServer = pktBuff.writeServer;
   interface writeClient = (interface PktWriteClient;
      interface writeData = toGet(writeDataFifo);
   endinterface);
   interface next = toPipeOut(outReqFifo);
   method Action set_verbosity (int verbosity);
      parser.set_verbosity(verbosity);
      cf_verbosity <= verbosity;
      $display("set verbosity ", verbosity);
   endmethod
endmodule

// Streaming version of RxChannel

