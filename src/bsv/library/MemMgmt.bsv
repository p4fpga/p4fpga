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

// MemMgmt module handles memory allocation and memory translation

import BuildVector::*;
import Cntrs::*;
import GetPut::*;
import ClientServer::*;
import ConfigCounter::*;
import StmtFSM::*;
import FIFO::*;
import FIFOF::*;
import Pipe::*;
import Vector::*;
import BRAMFIFO::*;
import BRAM::*;
import ConnectalBram::*;
import ConnectalMemory::*;
import Ethernet::*;
import SharedBuffMMU::*;
import DbgDefs::*;

`include "ConnectalProjectConfig.bsv"
typedef enum {
   MemMgmtErrorNone,
   MemMgmtErrorInvalidPacketId,
   MemMgmtErrorOutOfSpace
} MemMgmtErrorType deriving (Bits);

typedef struct {
   MemMgmtErrorType errorType;
   Bit#(32) id;
} MemMgmtError deriving (Bits);

typedef struct {
   Bit#(EtherLen) req;
   Bit#(TLog#(TMax#(1, numClients))) clients;
} MemMgmtAllocReq#(numeric type numClients) deriving (Bits);

typedef struct {
   Maybe#(PktId) id;
   Bit#(TLog#(TMax#(1, numClients))) clients;
} MemMgmtAllocResp#(numeric type numClients) deriving (Bits);

typedef struct {
   PktId id;
   Bit#(TLog#(TMax#(1, numClients))) clients;
} MemMgmtFreeReq#(numeric type numClients) deriving (Bits);

interface MemMgmtIndication;
   method Action memory_allocated(Bit#(32) id);
   method Action packet_committed(Bit#(32) tag);
   method Action packet_freed(Bit#(32) tag);
   method Action error(Bit#(32) errorType, Bit#(32) id);
endinterface

typedef 8  PageAddrLen; // 2^8 = 256 byte page
typedef 16 MemoryAddrLen; // 2^16 = 65536 byte packet buffer
typedef TExp#(PageAddrLen) PageSize; // 256
typedef TSub#(MemoryAddrLen, PageAddrLen) PageIdx; // 8-bit index
typedef TExp#(PageIdx) FreeQueueDepth; // 256 pages

Integer pageIdx = valueOf(PageIdx);
Integer freeQueueDepth = valueOf(FreeQueueDepth);

/* Terminate MMUIndication.idResponse, because sending it to sw is slow*/
interface MMUIndicationProxy;
   interface MMUIndication mmuInd;
   interface Get#(Bit#(32)) idResponse;
endinterface
module mkMMUIndicationProxy
`ifdef DEBUG
                           #(MMUIndication mmuInd)
`endif
                           (MMUIndicationProxy);
   FIFO#(Bit#(32)) idresponse_fifo <- mkFIFO;
   interface MMUIndication mmuInd;
      method Action idResponse(Bit#(32) sglId);
         idresponse_fifo.enq(sglId);
      endmethod
`ifdef DEBUG
      method configResp = mmuInd.configResp;
      method error = mmuInd.error;
`endif
   endinterface
   interface Get idResponse = toGet(idresponse_fifo);
endmodule

typedef struct {
   Bit#(PageIdx) nPages;
   MemMgmtAllocReq#(numAllocClients) request;
   Bit#(EtherLen) mask;
   Bit#(32) id;
} Stage2Params#(numeric type numAllocClients) deriving (Bits);

interface MemMgmt#(numeric type addrWidth, numeric type numAllocClients, numeric type numReadClients);
   method Action init_mem();
   interface MMU#(addrWidth) mmu;
   interface Put#(MemMgmtAllocReq#(numAllocClients)) mallocReq;
   interface Get#(MemMgmtAllocResp#(numAllocClients)) mallocDone;
   interface Put#(MemMgmtFreeReq#(numReadClients)) freeReq;
   interface Get#(Bool) freeDone;
   method MemMgmtDbgRec dbg;
endinterface
module mkMemMgmt
`ifdef DEBUG
                #(MemMgmtIndication indication, MMUIndication mmuInd)
`endif
                (MemMgmt#(addrWidth, numAllocClients, numReadClients))
   provisos(Add#(a__, addrWidth, 40));
   let verbose = False;

   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule cycleRule if (verbose);
      cycle <= cycle + 1;
   endrule

   Reg#(Bit#(64)) allocCnt <- mkReg(0);
   Reg#(Bit#(64)) allocCompleted <- mkReg(0);
   Reg#(Bit#(64)) freeCnt <- mkReg(0);
   Reg#(Bit#(64)) freeCompleted <- mkReg(0);
   Reg#(Bit#(64)) errorCode <- mkReg(0);
   Reg#(Bit#(64)) lastIdFreed <- mkReg(0);
   Reg#(Bit#(64)) lastIdAllocated <- mkReg(0);
   Reg#(Bit#(64)) firstSegment <- mkReg(0);
   Reg#(Bool) invalidSegment <- mkReg(False);

   Reg#(Bool) inited <- mkReg(False);
   FIFOF#(MemMgmtAllocReq#(numAllocClients)) mallcRequestFifo <- mkSizedFIFOF(16);
   FIFO#(MemMgmtAllocReq#(numAllocClients)) currRequestFIfo <- mkFIFO;
   FIFO#(MemMgmtAllocResp#(numAllocClients)) mallocDoneFifo <- mkFIFO;
   FIFOF#(PktId) freeRequestFifo <- mkFIFOF;

   FIFOF#(Bit#(PageIdx)) freePageList <- mkSizedFIFOF(freeQueueDepth);

   BRAM_Configure bramConfig = defaultValue;
   bramConfig.latency        = 2;
   // Store mapping from packetId to first page in linked list
   // PortA
   BRAM2Port#(PktId, Maybe#(Bit#(PageIdx))) idmap <- mkBRAM2Server(bramConfig);
   // Pack linked list of pages into BRAM for free operation
   // BRAM is indiced with pageIdx, and each entry in BRAM stores
   // a Maybe#(pageIdx) for next entry in the same list.
   // Entry is Invalid for last entry in a list
   BRAM2Port#(Bit#(PageIdx), Maybe#(Bit#(PageIdx))) pagemap <- mkBRAM2Server(bramConfig);

   Reg#(Bit#(PageIdx)) reqBurstLen <- mkReg(0);
   Reg#(Bit#(PageIdx)) reqSglIndex<- mkReg(0);
   ConfigCounter#(PageIdx) freePageCount <- mkConfigCounter(0);
   Reg#(Bool) free_started <- mkReg(False);
   Reg#(Maybe#(Bit#(PageIdx))) lastSegment <- mkReg(tagged Invalid);
   Reg#(PktId) idToFree <- mkReg(0);
   Reg#(Bit#(PageIdx)) currSegment <- mkReg(0);

   Reg#(PktId) packetId <- mkReg(0);
   Reg#(Bit#(64)) barr0 <- mkReg(0);

   FIFO#(Bool) freeDoneFifo <- mkFIFO;
   FIFO#(MemMgmtError) memMgmtErrorFifo <- mkFIFO;
   FIFO#(Bit#(PageIdx)) pagePointerFifo <- mkFIFO;

   FIFOF#(Stage2Params#(numAllocClients)) stage2Params <- mkFIFOF;

   MMUIndicationProxy proxy <- mkMMUIndicationProxy(
`ifdef DEBUG
                                                    mmuInd
`endif
                                                   );
   MMU#(addrWidth) iommu <- mkSharedBuffMMU(0, proxy.mmuInd);

   function BRAMServer#(a,b) portsel(BRAM2Port#(a,b) x, Integer i);
      if(i==0) return x.portA;
      else return x.portB;
   endfunction

   rule initialization if (!inited);
      freePageList.enq(pack(freePageCount.read));
      if (freePageCount.read == fromInteger(freeQueueDepth-1)) begin
         inited <= True;
         if (verbose) $display("(%0d) Init: freePageCount %h", $time, freePageCount.read);
      end
      else begin
         // NOTE: maximum freeQueueDepth-1
         freePageCount.increment(1);
      end
   endrule

   // assign available pages to packet id.
   rule handle_alloc_req;
      let v <- toGet(mallcRequestFifo).get;
      let id <- proxy.idResponse.get;
      if (verbose) $display("(%0d) MemMgmt:: %d Allocating pages for packet id %d packet size %d", $time, cycle, id, v.req);
      // Corner case when v is close to 4kb.
      let mask = (1 << valueOf(PageAddrLen)) - 1;
      Bit#(PageIdx) nPages = truncate(((v.req + mask) & (~mask)) >> valueOf(PageAddrLen));
      if (verbose) $display("(%0d) MemMgmt:: %d handle_malloc allocate nPage=%d", $time, cycle, nPages);
      let hasSpace <- freePageCount.maybeDecrement(unpack(nPages));
      if (hasSpace) begin
         stage2Params.enq(Stage2Params{
            nPages : nPages,
            request : v,
            mask : mask,
            id : id });
      end
   endrule

   rule handle_alloc_req2;
      let params <- toGet(stage2Params).get;
      reqBurstLen <= params.nPages;
      reqSglIndex <= 0;
      lastSegment <= tagged Invalid;
      barr0 <= extend(((params.request.req + params.mask) & (~params.mask)) >> valueOf(PageAddrLen));
      packetId <= truncate(params.id); // MaxNumPkts defined in SharedBuffMMU;
      currRequestFIfo.enq(params.request);
   endrule

   rule generate_sglist if (reqBurstLen > 0);
      let segment <- toGet(freePageList).get;
      // assume fixed page size of 256 bytes
      // extend packetId to 32 bit, only lower TLog#(MaxNumPkts) bits are used
      iommu.request.sglist(extend(packetId), extend(reqSglIndex), extend(segment), 256);
      // add current page(segment) to the front of a linked list
      portsel(pagemap, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:segment, datain: lastSegment});
      reqBurstLen <= reqBurstLen - 1;
      reqSglIndex <= reqSglIndex + 1;
      lastSegment <= tagged Valid segment;
      if (reqBurstLen == 1) begin
         iommu.request.region(extend(packetId), 0, 0, 0, 0, 0, 0, barr0, 0);
         // map id to linked-list of pages
         portsel(idmap, 0).request.put(BRAMRequest{write:True, responseOnWrite:False, address:packetId, datain:tagged Valid segment});
         mallocDoneFifo.enq(MemMgmtAllocResp{id: tagged Valid packetId, clients: currRequestFIfo.first.clients});
         currRequestFIfo.deq;
         allocCompleted <= allocCompleted + 1;
         lastIdAllocated <= extend(packetId);
`ifdef DEBUG
         indication.memory_allocated(extend(packetId));
`endif
      end
      if (verbose) $display("(%0d) MemMgmt:: %d id=%d, segmentIdx=%x %h", $time, cycle, packetId, segment, lastSegment);
   endrule

   rule handle_free_req if (!free_started);
      let sglId <- toGet(freeRequestFifo).get;
      free_started <= True;
      portsel(idmap, 1).request.put(BRAMRequest{write:False, responseOnWrite:False, address:sglId, datain:?});
      idToFree <= sglId;
      if (verbose) $display("(%0d) MemMgmt:: %d start_free_sglist %h", $time, cycle, sglId);
      lastIdFreed <= extend(sglId);
   endrule

   rule report_error;
      let v <- toGet(memMgmtErrorFifo).get;
`ifdef DEBUG
      indication.error(extend(pack(v.errorType)), v.id);
`endif
      if (verbose) $display("(%0d) MemMgmt:: %d free_error: memMgmt error", $time, cycle);
   endrule

   (* descending_urgency="initialization, del_id_metadata, del_page_metadata, read_next_page_metadata" *)
   rule del_id_metadata if (free_started);
      Maybe#(Bit#(PageIdx)) segment <- portsel(idmap, 1).response.get;
      case (segment) matches
         tagged Valid .page: begin
            portsel(idmap, 1).request.put(BRAMRequest{write:True, responseOnWrite:False, address: idToFree, datain: tagged Invalid});
            portsel(pagemap, 1).request.put(BRAMRequest{write:False, responseOnWrite:False, address: page, datain:?});
            if (verbose) $display("(%0d) MemMgmt:: %d free_idmap ", $time, cycle, fshow(page));
            currSegment <= page;
         end
         tagged Invalid: begin
            memMgmtErrorFifo.enq(MemMgmtError{errorType: MemMgmtErrorInvalidPacketId, id: extend(idToFree)});
            invalidSegment <= True;
         end
      endcase
      firstSegment <= extend(pack(segment));
   endrule

   rule del_page_metadata if (free_started);
      Maybe#(Bit#(PageIdx)) segment <- portsel(pagemap, 1).response.get;
      case (segment) matches
         tagged Valid .page: begin
            currSegment <= page;
            pagePointerFifo.enq(page);
         end
         tagged Invalid: begin
            free_started <= False;
            freeCompleted <= freeCompleted + 1;
`ifdef DEBUG
            indication.packet_freed(extend(idToFree));
`endif
         end
      endcase
      // return current page to free page list
      portsel(pagemap, 1).request.put(BRAMRequest{write:True, responseOnWrite:False, address: currSegment, datain: tagged Invalid});
      freePageList.enq(currSegment);
      freePageCount.increment(1);
      if (verbose) $display("(%0d) MemMgmt:: %d segment ", $time, cycle, fshow(segment));
   endrule

   rule read_next_page_metadata if (free_started);
      let page <- toGet(pagePointerFifo).get;
      portsel(pagemap, 1).request.put(BRAMRequest{write:False, responseOnWrite:False, address:page, datain:?});
      if (verbose) $display("(%0d) MemMgmt:: %d read next page ", $time, cycle, fshow(page));
   endrule

   method Action init_mem();
      freePageList.clear;
      freePageCount.decrement(freePageCount.read);
      inited <= False;
   endmethod
   interface Put mallocReq;
      method Action put(MemMgmtAllocReq#(numAllocClients) req);
         mallcRequestFifo.enq(req);
         iommu.request.idRequest(0); //FIXME
         allocCnt <= allocCnt + 1;
      endmethod
   endinterface
   interface Get mallocDone = toGet(mallocDoneFifo);
   interface Put freeReq;
      method Action put(MemMgmtFreeReq#(numReadClients) req);
         iommu.request.idReturn(extend(req.id));
         freeRequestFifo.enq(req.id);
         freeCnt <= freeCnt + 1;
      endmethod
   endinterface
   interface Get freeDone = toGet(freeDoneFifo);
   interface MMU mmu = iommu;
   method MemMgmtDbgRec dbg;
      return MemMgmtDbgRec { allocCnt: allocCnt
                            ,freeCnt: freeCnt
                            ,allocCompleted: allocCompleted
                            ,freeCompleted: freeCompleted
                            ,errorCode: errorCode
                            ,lastIdFreed: lastIdFreed
                            ,lastIdAllocated: lastIdAllocated
                            ,freeStarted: extend(pack(free_started))
                            ,firstSegment: extend(firstSegment)
                            ,lastSegment: extend(pack(lastSegment))
                            ,currSegment: extend(currSegment)
                            ,invalidSegment: extend(pack(invalidSegment))};
   endmethod
endmodule

