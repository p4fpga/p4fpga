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
`include "ConnectalProjectConfig.bsv"
import `PARSER::*;
import `DEPARSER::*;
import `TYPEDEF::*;

interface StreamOutChannel;
   interface PktWriteServer#(16) writeServer;
   interface Server#(MetadataRequest, MetadataResponse) prev;
   interface Get#(ByteStream#(8)) macTx;
   method Action set_verbosity (int verbosity);
endinterface

instance GetMacTx#(StreamOutChannel);
   function Get#(ByteStream#(8)) getMacTx(StreamOutChannel chan);
      return chan.macTx;
   endfunction
endinstance

instance GetWriteClient#(StreamInChannel);
   function Get#(ByteStream#(16)) getWriteClient(StreamInChannel chan);
      return chan.writeClient.writeData;
   endfunction
endinstance

instance GetWriteServer#(StreamOutChannel);
   function Put#(ByteStream#(16)) getWriteServer(StreamOutChannel chan);
      return chan.writeServer.writeData;
   endfunction
endinstance

// Streaming version of TxChannel
module mkStreamOutChannel#(Clock txClock, Reset txReset)(StreamOutChannel);
   FIFO#(PacketInstance) pkt_ff <- printTimedTraceM("pkt_ff", mkFIFO);
   Reg#(int) cf_verbosity <- mkConfigRegU;

   // RingBuffer Read Client
   FIFO#(ByteStream#(16)) readDataFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkFIFO;
   FIFO#(ByteStream#(16)) writeDataFifo <- mkFIFO;
   Reg#(Bool) readStarted <- mkReg(False);

   PacketBuffer#(16) pktBuff <- mkPacketBuffer();
   Deparser deparser <- mkDeparser();
   HeaderSerializer serializer <- mkHeaderSerializer();
   StoreAndFwdFromRingToMac ringToMac <- mkStoreAndFwdFromRingToMac(txClock, txReset);
   PacketBuffer#(16) pktBuffOut <- mkPacketBuffer();

   PktReadClient#(16) readClient = (interface PktReadClient;
      interface readData = toPut(readDataFifo);
      interface readLen = toPut(readLenFifo);
      interface readReq = toGet(readReqFifo);
   endinterface);

   PktWriteClient#(16) writeClient = (interface PktWriteClient;
      interface writeData = toGet(writeDataFifo);
   endinterface);

   function Action dbprint(Integer level, Fmt msg);
      action
      if (cf_verbosity > fromInteger(level)) begin
         $display("(%0d) ", $time, msg);
      end
      endaction
   endfunction

   rule packetReadStart if (!readStarted);
      pkt_ff.deq;
      let pktLen <- toGet(readLenFifo).get;
      readStarted <= True;
      readReqFifo.enq(pktLen);
      dbprint(3, $format("stream out read packet start len=%d ", pktLen));
   endrule

   rule packetReadInProgress if (readStarted);
      let v <- toGet(readDataFifo).get;
      if (v.eop) begin
         readStarted <= False;
      end
      writeDataFifo.enq(v);
   endrule

   mkConnection(readClient, pktBuff.readServer);
   mkConnection(writeClient, deparser.writeServer);
   mkConnection(deparser.writeClient, serializer.writeServer); 
   mkConnection(serializer.writeClient, pktBuffOut.writeServer);
   mkConnection(ringToMac.readClient, pktBuffOut.readServer);

   interface writeServer= pktBuff.writeServer;
   interface macTx = ringToMac.macTx;
   interface prev = (interface Server#(MetadataRequest, MetadataResponse);
      interface request = (interface Put;
         method Action put (MetadataRequest req);
            let meta = req.meta;
            let pkt = req.pkt;
            pkt_ff.enq(pkt);
            deparser.metadata.enq(meta);
            dbprint(3, $format("stream out metadata %d", pkt, fshow(meta)));
         endmethod
      endinterface);
   endinterface);
   method Action set_verbosity (int verbosity);
      cf_verbosity <= verbosity;
      deparser.set_verbosity(verbosity);
      serializer.set_verbosity(verbosity);
   endmethod
endmodule

// Streaming version of HostChannel
interface StreamInChannel;
   interface PktWriteServer#(16) writeServer;
   interface PktWriteClient#(16) writeClient;
   interface PipeOut#(MetadataRequest) next;
   method Action set_verbosity (int verbosity);
endinterface

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

   PacketBuffer#(16) pktBuff <- mkPacketBuffer();
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
      MetadataRequest nextReq = MetadataRequest {pkt: pktInst, meta: meta};
      outReqFifo.enq(nextReq);
      dbprint(3, $format("send packet ", fshow(meta)));
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

