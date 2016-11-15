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

// NOTE:
// Implement a store-and-forward mechanism between ring-buffer and 
// main packet memory. Packets are buffered completely in ring buffer
// before it is sent to main memory and vice versa.

import BuildVector::*;
import Connectable::*;
import Clocks::*;
import Cntrs::*;
import ConfigReg::*;
import ClientServer::*;
import DefaultValue::*;
import DbgDefs::*;
import Ethernet::*;
import EthMac::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Gearbox::*;
import MemTypes::*;
import MemServer::*;
import MemServerInternal::*;
import MemMgmt::*;
import PacketBuffer::*;
import SharedBuff::*;
import SharedBuffMMU::*;
import SpecialFIFOs::*;
import Stream::*;
import StreamGearbox::*;
import Vector::*;
import Pipe::*;
import PrintTrace::*;
import ConnectalConfig::*;
 `include "ConnectalProjectConfig.bsv"

interface StoreAndFwdFromRingToMem;
   interface PktReadClient#(16) readClient;
   interface MemAllocClient malloc;
   interface MemWriteClient#(DataBusWidth) writeClient;
   interface PipeOut#(PacketInstance) eventPktCommitted;
endinterface

module mkStoreAndFwdFromRingToMem(StoreAndFwdFromRingToMem)
   provisos (Div#(DataBusWidth, 8, bytesPerBeat)
            ,Log#(bytesPerBeat, beatShift));

   let verbose = False;

   // RingBuffer Read Client
   FIFO#(ByteStream#(16)) readDataFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkFIFO;

   // Memory Client
   FIFO#(MemRequest) writeReqFifo <- mkSizedFIFO(4);
   FIFO#(MemData#(DataBusWidth)) writeDataFifo <- mkSizedFIFO(16);
   FIFO#(Bit#(MemTagSize)) writeDoneFifo <- mkSizedFIFO(4);
   MemWriteClient#(DataBusWidth) dmaWriteClient = (interface MemWriteClient;
   interface Get writeReq = toGet(writeReqFifo);
   interface Get writeData = toGet(writeDataFifo);
   interface Put writeDone = toPut(writeDoneFifo);
   endinterface);

   FIFO#(Bit#(EtherLen)) mallocReqFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) pktLenFifo <- mkFIFO;
   FIFO#(Maybe#(PktId)) mallocDoneFifo <- mkFIFO;
   Reg#(Bool) readStarted <- mkReg(False);
   Reg#(Bool) mallocd <- mkReg(False);

   FIFOF#(PacketInstance) eventPktReceivedFifo <- mkFIFOF;
   FIFOF#(PacketInstance) eventPktCommittedFifo <- mkFIFOF;

   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule every1 if (verbose);
      cycle <= cycle + 1;
   endrule

   rule packetReadStart if (!readStarted);
      let pktLen <- toGet(readLenFifo).get;
      if (verbose) $display("StoreAndForward::packetReadStart %d: ReadLen %d", cycle, pktLen);
      mallocReqFifo.enq(pktLen);
      pktLenFifo.enq(pktLen);
      readStarted <= True;
   endrule

   rule allocMemory;
      let pktLen <- toGet(pktLenFifo).get;
      let allocId <- toGet(mallocDoneFifo).get;
      let bytesPerBeatMinusOne = fromInteger(valueOf(bytesPerBeat))-1;
      // roundup to 16 byte boundary
      let burstLen = ((pktLen + bytesPerBeatMinusOne) & ~(bytesPerBeatMinusOne));
      let mask = (1<< (pktLen % fromInteger(valueOf(bytesPerBeat))))-1;
      if (isValid(allocId)) begin
         mallocd <= True;
         readReqFifo.enq(truncate(pktLen));
         //FIXME use correct sglId
         writeReqFifo.enq(MemRequest {sglId: extend(fromMaybe(?, allocId)), offset: 0,
                                      burstLen: truncate(burstLen), tag:0
`ifdef BYTE_ENABLES
                                      , firstbe: 'hffff, lastbe: mask
`endif
                                     });
         if (verbose) $display("StoreAndForward::allocMemory %d: alloc done", cycle);
         eventPktReceivedFifo.enq(PacketInstance {id: fromMaybe(?, allocId), size: pktLen});
      end
   endrule

   rule packetReadInProgress if (readStarted && mallocd);
      let v <- toGet(readDataFifo).get;
      if (v.eop) begin
         readStarted <= False;
         mallocd <= False;
         if (verbose) $display("StoreAndForward:: %d: packet finished", cycle);
      end
      if (verbose) $display("StoreAndForward::writeData: %d: data:%h, tag:%h, last:%h", cycle, v.data, 0, v.eop);
      writeDataFifo.enq(MemData {data: v.data, tag: 0, last: v.eop});
   endrule

   rule packetReadDone;
      let v <- toGet(writeDoneFifo).get;
      let recvd <- toGet(eventPktReceivedFifo).get;
      eventPktCommittedFifo.enq(recvd);
      if (verbose) $display("StoreAndForward::packetReadDone %d: packet written to memory %h", cycle, v);
   endrule

   interface PktReadClient readClient;
      interface readData = toPut(readDataFifo);
      interface readLen = toPut(readLenFifo);
      interface readReq = toGet(readReqFifo);
   endinterface

   interface malloc = (interface MemAllocClient;
      interface Get mallocReq = toGet(mallocReqFifo);
      interface Put mallocDone = toPut(mallocDoneFifo);
   endinterface);
   interface writeClient = dmaWriteClient;
   interface PipeOut eventPktCommitted = toPipeOut(eventPktCommittedFifo);
endmodule

interface StoreAndFwdFromMemToRing;
   interface PktWriteClient#(16) writeClient;
   interface MemReadClient#(DataBusWidth) readClient;
   interface PipeIn#(PacketInstance) eventPktSend;
   interface MemFreeClient free;
endinterface

module mkStoreAndFwdFromMemToRing(StoreAndFwdFromMemToRing)
   provisos (Div#(DataBusWidth, 8, bytesPerBeat)
            ,Log#(bytesPerBeat, beatShift));

   Reg#(int) cf_verbosity <- mkConfigReg(4);
   function Action dbprint(Integer level, Fmt msg);
      action
      if (cf_verbosity > fromInteger(level)) begin
        $display("(%0d) ", $time, msg);
      end
      endaction
   endfunction

   // Ring Buffer Write Client
   FIFO#(ByteStream#(16)) writeDataFifo <- mkFIFO;

   // read client interface
   FIFO#(MemRequest) readReqFifo <-mkSizedFIFO(4);
   FIFO#(MemData#(DataBusWidth)) readDataFifo <- mkSizedFIFO(32);
   MemReadClient#(DataBusWidth) dmaReadClient = (interface MemReadClient;
   interface Get readReq = toGet(readReqFifo);
   interface Put readData = toPut(readDataFifo);
   endinterface);

   FIFOF#(PacketInstance) eventPktSendFifo <- mkSizedFIFOF(16);
   FIFOF#(Bit#(EtherLen)) readBurstLenFifo <- mkSizedFIFOF(16);
   FIFOF#(PktId) currPacketIdFifo <- mkSizedFIFOF(16);
   FIFO#(PktId) freeReqFifo <- mkSizedFIFO(4);

   Reg#(Bool)                 outPacket <- mkReg(False);
   Reg#(Bit#(EtherLen))   readBurstCount <- mkReg(maxBound);
   Reg#(Bool)                 started <- mkReg(False);

   rule packetReadStart;
      let pkt <- toGet(eventPktSendFifo).get;
      let bytesPerBeatMinusOne = fromInteger(valueOf(bytesPerBeat))-1;
      // roundup to 16 byte boundary
      let burstLen = ((pkt.size + bytesPerBeatMinusOne) & ~(bytesPerBeatMinusOne));
      dbprint(3, $format("StoreAndForward:packetReadStart %h, burstLen = %h", pkt.size, burstLen));
      let mask = (1<< (pkt.size % fromInteger(valueOf(bytesPerBeat))))-1;
      readReqFifo.enq(MemRequest{sglId: extend(pkt.id), offset: 0,
                                 burstLen: truncate(burstLen), tag: 0
`ifdef BYTE_ENABLES
                                 , firstbe: 'hffff, lastbe: mask
`endif
                                });
      dbprint(3, $format("StoreAndForward:packetReadStart send a new packet with size %h %h", burstLen, pack(mask)));
      currPacketIdFifo.enq(pkt.id);
      readBurstLenFifo.enq(pkt.size);
   endrule

   rule packetReadInProgress if (readBurstLenFifo.notEmpty);
      let d <- toGet(readDataFifo).get;
      let _bytesPerBeat= fromInteger(valueOf(bytesPerBeat));

      let readBurstLen = readBurstLenFifo.first;
      let currPacketId = currPacketIdFifo.first;

      let sop = False;
      let eop = False;
      if (!started) begin
         readBurstCount <= readBurstLen - _bytesPerBeat;
         started <= True;
         sop = True;
      end
      else if (readBurstCount <= _bytesPerBeat && started) begin
         readBurstLenFifo.deq;
         currPacketIdFifo.deq;
         readBurstCount <= maxBound;
         started <= False;
         eop = True;
         freeReqFifo.enq(currPacketId);
      end
      else if (readBurstCount > _bytesPerBeat && started) begin
         readBurstCount <= readBurstCount - _bytesPerBeat;
      end

      Bit#(bytesPerBeat) mask;
      if (readBurstCount <= _bytesPerBeat)
         mask = (1<<readBurstCount)-1;
      else
         mask = (1<<_bytesPerBeat)-1;

      ByteStream#(16) v = defaultValue;
      v.data = d.data;
      v.mask = mask;
      v.sop = sop;
      v.eop = eop;
      writeDataFifo.enq(v);

      dbprint(3, $format("StoreAndForward:readdata  %h %h %h %h %h", readBurstCount, d.data, pack(mask), sop, eop));
   endrule

   interface PktWriteClient writeClient;
      interface writeData = toGet(writeDataFifo);
   endinterface
   interface readClient = dmaReadClient;
   interface PipeIn eventPktSend = toPipeIn(eventPktSendFifo);
   interface free = (interface MemFreeClient;
      interface Get freeReq = toGet(freeReqFifo);
   endinterface);
endmodule

interface StoreAndFwdFromRingToMac;
   interface PktReadClient#(16) readClient;
   interface Get#(ByteStream#(8)) macTx;
   method TxThruDbgRec dbg; 
   method ThruDbgRec sdbg; 
endinterface

// store data from ring buffer to network
// big-endianess -> little-endianess
module mkStoreAndFwdFromRingToMac#(Clock txClock, Reset txReset)(StoreAndFwdFromRingToMac);
   let verbose = False;
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   Reg#(Bit#(64)) cycle_cnt <- mkReg(0);
   Reg#(Bit#(64)) last_startofpacket <- mkReg(0);
   Reg#(Bit#(64)) last_endofpacket <- mkReg(0);
   Reg#(Bit#(64)) goodputCount <- mkReg(0);
   Reg#(Bit#(64)) idleCount <- mkReg(0);

   // stats
   Reg#(Bit#(64)) total_cycles <- mkReg(0, clocked_by txClock, reset_by txReset);
   Reg#(Bit#(64)) idle_cycles <- mkReg(0, clocked_by txClock, reset_by txReset);
   Reg#(Bit#(64)) sopCount <- mkReg(0, clocked_by txClock, reset_by txReset);
   Reg#(Bit#(64)) eopCount <- mkReg(0, clocked_by txClock, reset_by txReset);
   Reg#(Bit#(64)) data_bytes <- mkReg(0, clocked_by txClock, reset_by txReset);

   // RingBuffer Read Client
   FIFO#(ByteStream#(16)) readDataFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readLenFifo <- mkFIFO;
   FIFO#(Bit#(EtherLen)) readReqFifo <- mkFIFO;

   // Mac Facing Fifo
   FIFOF#(ByteStream#(8)) writeMacFifo <- mkFIFOF(clocked_by txClock, reset_by txReset);
   Gearbox#(2, 1, ByteStream#(8)) fifoTxData <- mkNto1Gearbox(txClock, txReset, txClock, txReset);
   SyncFIFOIfc#(ByteStream#(16)) tx_fifo <- mkSyncFIFO(5, defaultClock, defaultReset, txClock);

   rule cycle;
      cycle_cnt <= cycle_cnt + 1;
   endrule

   rule total_cycle;
      total_cycles <= total_cycles + 1;
   endrule

   rule readDataStart;
      let pktLen <- toGet(readLenFifo).get;
      if (verbose) $display(fshow(" read packt ") + fshow(pktLen));
      readReqFifo.enq(pktLen);
   endrule

   function Vector#(2, ByteStream#(8)) split(ByteStream#(16) in);
      Vector#(2, ByteStream#(8)) v = defaultValue;
      Vector#(8, Bit#(8)) v0_data = unpack(in.data[63:0]);
      Vector#(8, Bit#(8)) v1_data = unpack(in.data[127:64]);
      v[0].sop = in.sop;
`ifdef ALTERA
      v[0].data = pack(reverse(v0_data));
`else
      v[0].data = pack(v0_data);
`endif
      v[0].eop = (in.mask[15:8] == 0) ? in.eop : False;
      v[0].mask = in.mask[7:0];
      v[1].sop = False;
`ifdef ALTERA
      v[1].data = pack(reverse(v1_data));
`else
      v[1].data = pack(v1_data);
`endif
      v[1].eop = in.eop;
      v[1].mask = in.mask[15:8];
      return v;
   endfunction

   rule cross_clocking;
      let v <- toGet(readDataFifo).get;
      tx_fifo.enq(v);

      // performance analysis
      if (v.sop) begin
         last_startofpacket <= cycle_cnt;
         idleCount <= (last_endofpacket != 0) ? (idleCount + (cycle_cnt - last_endofpacket)) : 0;
      end
      if (v.eop) begin
         last_endofpacket <= cycle_cnt;
         goodputCount <= (last_startofpacket != 0) ? (goodputCount + (cycle_cnt - last_startofpacket)) : 0;
      end
   endrule

   rule process_incoming_packet;
      let v <- toGet(tx_fifo).get;
      fifoTxData.enq(split(v));
   endrule

   rule process_outgoing_packet;
      let data = fifoTxData.first; fifoTxData.deq;
      let temp = head(data);
      let bytes = zeroExtend(pack(countOnes(temp.mask)));
      if (temp.sop) sopCount <= sopCount + 1;
      data_bytes <= data_bytes + bytes;
      if (temp.mask != 0) begin
         if (verbose) $display("ringToMac:: tx data %h", temp.data);
         if (temp.eop) eopCount <= eopCount + 1;
         writeMacFifo.enq(temp);
      end
      else begin
         idle_cycles <= idle_cycles + 1;
      end
   endrule

   rule count_idle_cycles (!fifoTxData.notEmpty);
      idle_cycles <= idle_cycles + 1;
   endrule

   interface PktReadClient readClient;
      interface readData = toPut(readDataFifo);
      interface readLen = toPut(readLenFifo);
      interface readReq = toGet(readReqFifo);
   endinterface
   interface Get macTx = toGet(writeMacFifo);
   method TxThruDbgRec dbg;
      return TxThruDbgRec {goodputCount: goodputCount, idleCount: idleCount};
   endmethod
   method ThruDbgRec sdbg;
      return ThruDbgRec {data_bytes: data_bytes, sops: sopCount, eops: eopCount, idle_cycles: idle_cycles, total_cycles: total_cycles};
   endmethod
endmodule

interface StoreAndFwdFromMacToRing;
   interface PipeOut#(ByteStream#(16)) writeClient;
   interface Put#(ByteStream#(8)) macRx;
   method ThruDbgRec sdbg;
endinterface

// store data from network to ring buffer
// little-endianess -> big-endianess
module mkStoreAndFwdFromMacToRing#(Clock rxClock, Reset rxReset)(StoreAndFwdFromMacToRing);
   let verbose = True;
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   // stats
   Reg#(Bit#(64)) total_cycles <- mkReg(0, clocked_by rxClock, reset_by rxReset);
   Reg#(Bit#(64)) data_bytes <- mkReg(0, clocked_by rxClock, reset_by rxReset);

   rule total_cycle;
      total_cycles <= total_cycles + 1;
   endrule

   StreamGearbox#(8, 16) gearbox <- mkStreamGearboxUp(clocked_by rxClock, reset_by rxReset);
   SyncFIFOIfc#(ByteStream#(16)) writeDataFifo <- mkSyncFIFO(5, rxClock, rxReset, defaultClock);

   rule writeData;
      let v <- gearbox.dataout.get;
      writeDataFifo.enq(v);
      if (verbose) begin
         if (v.sop) begin
            $display("(%0d) packet_in: Rx MAC", $time);
         end
      end
   endrule

   interface writeClient = toPipeOut(writeDataFifo);
   interface macRx = gearbox.datain;
   method ThruDbgRec sdbg;
      return ThruDbgRec {data_bytes: gearbox.getDataCount(),
                         sops: gearbox.getSopCount(),
                         eops: gearbox.getEopCount(),
                         idle_cycles: gearbox.getIdleCount(),
                         total_cycles: total_cycles};
   endmethod
endmodule
