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
import Arith::*;
import BRAM::*;
import BRAMCore::*;
import Connectable::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import OInt::*;
import StmtFSM::*;
import Vector::*;
import Pipe::*;
import AsymmetricBRAM::*;

import BcamTypes::*;
import Ram9b::*;
import PriorityEncoder::*;

typedef struct {
   Vector#(4, Maybe#(Bit#(9))) rpatt;
} RPatt deriving (Bits, Eq);

typedef enum {S0, S1, S2} StateType
   deriving (Bits, Eq);

interface Bcam9b#(numeric type camDepth);
   interface Put#(BcamWriteReq#(Bit#(TLog#(camDepth)), Bit#(9))) writeServer;
   interface Put#(ReadRequest) mPatt;
   interface Get#(ReadResponse#(TSub#(TLog#(camDepth), 7))) mIndc;
endinterface
module mkBcam9b(Bcam9b#(camDepth))
   provisos(Add#(cdep, 7, camSz)
            ,Log#(camDepth, camSz)
            ,Mul#(cdep, 256, indcWidth)
            ,Add#(TLog#(cdep), 4, wAddrHWidth)
            ,Add#(writeSz, 0, 10)
            ,Add#(dataSz, 1, writeSz)
            ,Add#(readSz, 0, 40)
            ,Div#(readSz, writeSz, ratio)
            ,Log#(ratio, ratioSz)
            ,Div#(camDepth, 4, writeDepth)
            ,Log#(writeDepth, writeDepthSz)
            ,Add#(readDepthSz, ratioSz, writeDepthSz)
            ,Add#(readDepthSz, 0, wAddrHWidth)
            ,Add#(vacWriteSz, 0, 16)
            ,Add#(vacReadSz, 0, 16)
            ,Div#(camDepth, 16, vacWriteDepth)
            ,Div#(vacReadSz, vacWriteSz, vacRatio)
            ,Log#(vacRatio, vacRatioSz)
            ,Log#(vacWriteDepth, vacWriteDepthSz)
            ,Add#(vacReadDepthSz, vacRatioSz, vacWriteDepthSz)
            ,Add#(vacReadDepthSz, 0, wAddrHWidth)
            ,Add#(vacWriteDepthSz, 0, wAddrHWidth)
            ,Add#(idxWriteSz, 0, 4)
            ,Add#(idxReadSz, 0, 16)
            ,Div#(camDepth, 4, idxWriteDepth)
            ,Div#(idxReadSz, idxWriteSz, idxRatio)
            ,Log#(idxRatio, idxRatioSz)
            ,Log#(idxWriteDepth, idxWriteDepthSz)
            ,Add#(idxReadDepthSz, idxRatioSz, idxWriteDepthSz)
            ,Add#(idxReadDepthSz, 0, wAddrHWidth)
            ,Add#(2, a__, camSz)
            ,Add#(4, b__, camSz)
            ,Add#(wAddrHWidth, c__, camSz)
         );

   let verbose = False;
   let verbose_setram = verbose && True;
   let verbose_idxram = verbose && True;
   let verbose_vacram = verbose && True;

   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule every1 if (verbose);
      cycle <= cycle + 1;
   endrule

   // setram fifo, remove later.
   FIFO#(Bit#(16)) oldPattIndc_fifo <- mkFIFO;
   FIFO#(Bit#(16)) newPattIndc_fifo <- mkFIFO;
   FIFO#(void) setram_read <- mkFIFO;
   FIFO#(void) vacram_read <- mkFIFO;
   FIFO#(void) idxram_read <- mkFIFO;
   FIFO#(void) bcam_fsm_start <- mkFIFO;
   FIFO#(Bool) wEnb_setram_fifo <- mkFIFO;
   FIFO#(Bool) wEnb_vacram_fifo <- mkFIFO;
   FIFO#(Bool) wEnb_idxram_fifo <- mkFIFO;

   Reg#(Bool) oldNewbPattWrR <- mkReg(False);
   Reg#(Bit#(9)) oldPattR <- mkReg(0);
   Reg#(Bool) oldPattVR <- mkReg(False);
   Reg#(Bit#(9)) wPatt_bcam <- mkReg(0);
   Reg#(Bit#(camSz)) wAddr_bcam <- mkReg(0);
   Reg#(Bit#(4)) vacFLocR <- mkReg(0);
   Reg#(Bit#(16)) cVacR <- mkReg(maxBound);
   Reg#(Bool) oldPattMultiOccR <- mkReg(False);
   Reg#(Bool) newPattMultiOccR <- mkReg(False);
   Reg#(Bit#(4)) oldIdxR <- mkReg(0);
   Reg#(Bit#(4)) newIdxR <- mkReg(0);
   Reg#(Bool) oldEqNewPattR <- mkReg(False);
   Reg#(Bit#(wAddrHWidth)) wAddrHR <- mkReg(0);
   Reg#(Bit#(16)) wIndcR <- mkReg(0);
   Reg#(Bit#(4)) wIndxR <- mkReg(0);
   Reg#(Bit#(4)) wAddr_indcR <- mkReg(0);

   Wire#(Bit#(4)) newPattOccFLoc_wire <- mkDWire(0);

   Ram9b#(cdep) ram9b <- mkRam9b();

   `define SETRAM AsymmetricBRAM#(Bit#(readDepthSz), Bit#(readSz), Bit#(writeDepthSz), Bit#(writeSz))
   Vector#(4, `SETRAM) setRam <- replicateM(mkAsymmetricBRAM(True, False, "Setram"));

   `define VACRAM AsymmetricBRAM#(Bit#(vacReadDepthSz), Bit#(vacReadSz), Bit#(vacWriteDepthSz), Bit#(vacWriteSz))
   `VACRAM vacram <- mkAsymmetricBRAM(True, False, "Vacram");

   `define IDXRAM AsymmetricBRAM#(Bit#(idxReadDepthSz), Bit#(idxReadSz), Bit#(idxWriteDepthSz), Bit#(idxWriteSz))
   Vector#(4, `IDXRAM) idxRam <- replicateM(mkAsymmetricBRAM(True, False, "Idxram"));

   // Cam Control
   // first state, erase previous entry
   Reg#(StateType) curr_state <- mkReg(S0);

   rule state_S0 (curr_state == S0);
      let v <- toGet(bcam_fsm_start).get;
      let oldPattIndc <- toGet(oldPattIndc_fifo).get;
      let newPattIndc <- toGet(newPattIndc_fifo).get;
      Bit#(16) wIndc = oldNewbPattWrR ? oldPattIndc : newPattIndc;
      if(verbose) $display("cam9b %d: oldPattIndc=%x, newPattIndc=%x", cycle, oldPattIndc, newPattIndc);
      if(verbose) $display("cam9b %d: oldNewbPattwr=%x, wIndc=", cycle, oldNewbPattWrR, fshow(wIndc));
      Bit#(4) _oldIdx = oldPattMultiOccR ? oldIdxR : 0;
      Bit#(4) _newIdx = newPattMultiOccR ? newIdxR : vacFLocR;
      Bit#(4) wIndx = oldNewbPattWrR ? _oldIdx : _newIdx;
      if (verbose) $display("vacram %d: oldPattMultiOccR=%x, newPattMultiOcc=%x, oldNewbPattWrR=%x", cycle, oldPattMultiOccR, newPattMultiOccR, oldNewbPattWrR);
      if (verbose) $display("vacram %d: compute oldIdx_=%x, newIdx_=%x wIndx=%x", cycle, _oldIdx, _newIdx, wIndx);
      wIndxR <= wIndx;
      wAddr_indcR <= wIndx;
      wIndcR <= wIndc;
      if (verbose) $display("bcam %d: ram9b wAddr_indc=%x wIndx=%x", cycle, wIndx, wIndx);
      curr_state <= S1;
   endrule

   rule state_S1 (curr_state == S1);
      let oldEqNewPatt = oldEqNewPattR;
      Bool wEnb_indc = !(oldEqNewPatt && oldPattVR) && oldPattVR && oldPattMultiOccR;
      Bool wEnb_iVld = !(oldEqNewPatt && oldPattVR) && oldPattVR && !oldPattMultiOccR;
      Bit#(9) patt = oldPattVR ? oldPattR : wPatt_bcam;
      WriteRequest#(cdep) request;
      request = WriteRequest {
         wPatt: patt,
         wIndx: wIndxR,
         wIndc: wIndcR,
         wAddr_indx: wAddrHR,
         wAddr_indc: wAddr_indcR,
         wIVld: 0,
         wEnb_iVld: pack(wEnb_iVld),
         wEnb_indx: 0,
         wEnb_indc: pack(wEnb_indc)
      };
      ram9b.writeRequest.put(request);
      oldNewbPattWrR <= oldPattVR;
      curr_state <= S2;
      if (verbose) $display("camctrl\t %d: currStt=%d, patt=%x oldPattV=%x, oldPatt=%x, wPatt=%x", cycle, curr_state, patt, oldPattVR, oldPattR, wPatt_bcam);
      if (verbose) $display("camctrl\t %d: currStt=%d, oldPatt=%x, oldPattV=%x, oldMultiOcc=%x, newMultiOcc=%x", cycle, curr_state, oldPattR, oldPattVR, oldPattMultiOccR, newPattMultiOccR);
      if (verbose) $display("camctrl\t %d: Generate wEnb_indc=%x and wEnb_iVld=%x", cycle, wEnb_indc, wEnb_iVld);
   endrule

   // second state, write new entry
   rule state_S2 (curr_state == S2);
      let oldEqNewPatt = oldEqNewPattR;
      Bool wEnb_setram = !(oldEqNewPatt && oldPattVR);
      Bool wEnb_idxram = !(oldEqNewPatt && oldPattVR);
      Bool wEnb_vacram = !(oldEqNewPatt && oldPattVR) && (oldPattVR && !oldPattMultiOccR) || !newPattMultiOccR;
      Bool wEnb_indc = !(oldEqNewPatt && oldPattVR);
      Bool wEnb_indx = !(oldEqNewPatt && oldPattVR) && !newPattMultiOccR;
      Bool wEnb_iVld = !(oldEqNewPatt && oldPattVR) && !newPattMultiOccR;

      if (verbose) $display("camctrl %d: currStt=%d, wEnb_setram=%x, wEnb_idxram=%x, wEnb_vacram=%x, wEnb_indx=%x, wEnb_indc=%x", cycle, curr_state, wEnb_setram, wEnb_idxram, wEnb_vacram, wEnb_indx, wEnb_indc);

      wEnb_setram_fifo.enq(wEnb_setram);
      wEnb_vacram_fifo.enq(wEnb_vacram);
      wEnb_idxram_fifo.enq(wEnb_idxram);
      WriteRequest#(cdep) request;
      request = WriteRequest {
         wPatt: wPatt_bcam,
         wIndx: wIndxR,
         wIndc: wIndcR,
         wAddr_indx: wAddrHR,
         wAddr_indc: wAddr_indcR,
         wIVld: 1,
         wEnb_iVld: pack(wEnb_iVld),
         wEnb_indx: pack(wEnb_indx),
         wEnb_indc: pack(wEnb_indc)
      };
      ram9b.writeRequest.put(request);
      oldNewbPattWrR <= False;
      if (verbose) $display("camctrl %d: write new pattern to iitram", cycle);
      curr_state <= S0;
   endrule

   // vacram
   function Bit#(16) compute_cVac(Bit#(16) rVac, Bool oldPattMultiOcc, Bool oldPattV, Bit#(4) oldIdx);
      OInt#(16) oldIdxOH = toOInt(oldIdx);
      Bool oldVac = !oldPattMultiOcc && oldPattV;
      Vector#(16, Bit#(1)) maskOldVac = replicate(pack(oldVac));
      Bit#(16) cVac = (~rVac) | (pack(oldIdxOH) & pack(maskOldVac));
      return cVac;
   endfunction

   function Bit#(16) compute_wVac(Bit#(4) vacFLoc, Bool newPattMultiOcc, Bit#(16) cVac);
      OInt#(16) vacFLocOH = toOInt(vacFLoc);
      Vector#(16, Bit#(1)) maskNewVac = replicate(pack(newPattMultiOcc));
      Bit#(16) wVac = ~(cVac & ((~pack(vacFLocOH)) | pack(maskNewVac)));
      return wVac;
   endfunction

   rule vacram_read_response;
      let rVac <- vacram.readServer.response.get;
      let oldPattMultiOcc = oldPattMultiOccR;
      let oldPattV = oldPattVR;
      Bit#(16) cVac = compute_cVac(rVac, oldPattMultiOcc, oldPattV, oldIdxR);
      cVacR <= cVac;
      Maybe#(Bit#(4)) bin = mkPE16(cVac);
      vacFLocR <= fromMaybe(?, bin);
      bcam_fsm_start.enq(?);
      if (verbose) $display("vacram %d: bin=%x vld=%x vacFLoc=%x", cycle, fromMaybe(?, bin), isValid(bin), fromMaybe(?, bin));
      if (verbose) $display("vacram %d: response cVac=%x, rVac = %x, oldPattMultiOcc = %x, oldPattV = %x, oldIdx = %x", cycle, cVac, rVac, oldPattMultiOcc, oldPattV, oldIdxR);
   endrule

   rule vacram_write_request;
      let wEnb <- toGet(wEnb_vacram_fifo).get;
      Vector#(wAddrHWidth, Bit#(1)) wAddrH = takeAt(4, unpack(wAddr_bcam)); //FIXME
      Bit#(16) wVac = compute_wVac(vacFLocR, newPattMultiOccR, cVacR);
      if (verbose) $display("vacram %d: vacFLoc=%x, newPattMultiOcc=%x, cVac=%x", cycle, vacFLocR, newPattMultiOccR, cVacR);
      vacram.writeServer.put(tuple2(pack(wAddrH), wVac));
      if (verbose) $display("vacram %d: vacram write wAddrH=%x, wVac=%x", cycle, pack(wAddrH), wVac);
   endrule

   rule idxram_read_response;
      Vector#(4, Bit#(16)) data = newVector;
      for (Integer i=0; i<4; i=i+1) begin
         let v <- idxRam[i].readServer.response.get;
         data[i] = v;
      end
      Bit#(64) data_pack = pack(data);
      Vector#(4, Bit#(1)) wAddrL = take(unpack(wAddr_bcam));
      Bit#(4) oldIdx = data_pack[pack(wAddrL)*4+4 : pack(wAddrL)*4];
      oldIdxR <= oldIdx;
      if (verbose) $display("idxram %d: oldIdx=%x", cycle, oldIdx);

      let newPattOccFLoc = newPattOccFLoc_wire;
      Bit#(4) newIdx = data_pack[newPattOccFLoc*4+4: newPattOccFLoc*4];
      newIdxR <= newIdx;
      if (verbose) $display("idxram %d: newIdx=%x", cycle, newIdx);

      if (verbose) $display("idxram %d: response %x", cycle, data_pack);
   endrule

   rule idxram_write_request;
      let wEnb <- toGet(wEnb_idxram_fifo).get;
      Vector#(2, Bit#(1)) wAddrLH = takeAt(2, unpack(wAddr_bcam));
      Vector#(2, Bit#(1)) wAddrLL = take(unpack(wAddr_bcam));
      Vector#(wAddrHWidth, Bit#(1)) wAddrH = takeAt(4, unpack(wAddr_bcam));
      Bit#(idxWriteDepthSz) writeAddr = {pack(wAddrH), pack(wAddrLL)};
      if (verbose) $display("idxram %d: wAddrLH %x", cycle, pack(wAddrLH));
      if (verbose) $display("idxram %d: wAddrLL %x", cycle, pack(wAddrLL));
      if (verbose) $display("idxram %d: wAddrH %x", cycle, pack(wAddrH));
      for (Integer i=0; i<4; i=i+1) begin
         if (fromInteger(i) == pack(wAddrLH)) begin
            if (verbose) $display("idxram %d: write memory %x, addr=%x data=%x", cycle, i, writeAddr, vacFLocR);
            idxRam[i].writeServer.put(tuple2(writeAddr, vacFLocR));
         end
      end
   endrule

   rule setram_write_request;
      let v <- toGet(wEnb_setram_fifo).get;
      Vector#(2, Bit#(1)) wAddrLH = takeAt(2, unpack(wAddr_bcam));
      Vector#(2, Bit#(1)) wAddrLL = take(unpack(wAddr_bcam));
      Vector#(wAddrHWidth, Bit#(1)) wAddrH = takeAt(4, unpack(wAddr_bcam));
      Bit#(writeDepthSz) writeAddr = {pack(wAddrH), pack(wAddrLL)};
      Maybe#(Bit#(dataSz)) writeData = tagged Valid wPatt_bcam;
      if (verbose) $display("setram %d: writeReq wAddr=%x, wData=%x", cycle, wAddr_bcam, wPatt_bcam);
      for (Integer i=0; i<4; i=i+1) begin
         if (fromInteger(i) == pack(wAddrLH)) begin
            setRam[i].writeServer.put(tuple2(writeAddr, pack(writeData)));
         end
      end
      if (verbose) $display("Setram %d: write to setram addr=%x, data=%x", cycle, wAddr_bcam, wPatt_bcam);
   endrule

   function Maybe#(Bit#(9)) compute_oldPatt(Vector#(4, RPatt) data, Bit#(camSz) wAddr);
      Vector#(4, Bit#(1)) wAddrL = take(unpack(wAddr));
      Bit#(2) wAddrL_ram = pack(wAddrL)[3:2];
      Bit#(2) wAddrL_word = pack(wAddrL)[1:0];
      return (data[wAddrL_ram].rpatt[wAddrL_word]);
   endfunction

   function Bit#(16) compute_oldPattIndc(Vector#(4, RPatt) data, Bit#(camSz) wAddr, Maybe#(Bit#(9)) oldPatt);
      Vector#(4, Bit#(1)) wAddrL = take(unpack(wAddr));
      OInt#(16) wAddrLOH = toOInt(pack(wAddrL));
      Vector#(16, Bool) oldPattIndc;
      for (Integer i=0; i<4; i=i+1) begin
         for (Integer j=0; j<4; j=j+1) begin
            oldPattIndc[i*4+j] = (data[i].rpatt[j] == oldPatt) && !unpack(pack(wAddrLOH)[i*4+j]);
         end
      end
      return pack(oldPattIndc);
   endfunction

   function Bit#(16) compute_newPattIndc(Vector#(4, RPatt) data, Maybe#(Bit#(9)) wPatt);
      Vector#(16, Bool) newPattIndc;
      for (Integer i=0; i<4; i=i+1) begin
         for (Integer j=0; j<4; j=j+1) begin
            newPattIndc[i*4+j] = (data[i].rpatt[j] == wPatt);
         end
      end
      return pack(newPattIndc);
   endfunction

   // Compute Setram Outputs
   rule setram_read_response;
      Vector#(4, Bit#(1)) wAddrL = take(unpack(wAddr_bcam));
      OInt#(16) wAddrLOH = toOInt(pack(wAddrL));

      Vector#(4, RPatt) data = newVector;
      for (Integer i=0; i<4; i=i+1) begin
         let setram_data <- setRam[i].readServer.response.get;
         Vector#(4, Maybe#(Bit#(9))) m = unpack(setram_data);
         data[i] = unpack(setram_data);
      end
      let _oldPatt = compute_oldPatt(data, wAddr_bcam);
      let oldPattV = isValid(_oldPatt);
      let oldPatt = fromMaybe(?, _oldPatt);
      let oldPattIndc = compute_oldPattIndc(data, wAddr_bcam, _oldPatt);
      let oldPattMultiOcc = (oldPattIndc != 0);
      if (verbose) $display("setram %d: oldPattIndc=%x", cycle, oldPattIndc);

      // outputs
      oldPattIndc_fifo.enq(pack(oldPattIndc));
      oldPattVR <= oldPattV;
      oldPattR <= oldPatt;
      oldEqNewPattR <= (oldPatt==wPatt_bcam);
      oldPattMultiOccR <= oldPattMultiOcc;
      if (verbose) $display("setram %d: oldPattMultiOcc=%x", cycle, oldPattMultiOcc);

      // compute new pattern
      let newPattIndc_prev = compute_newPattIndc(data, tagged Valid wPatt_bcam);
      Maybe#(Bit#(4)) bin = mkPE16(pack(newPattIndc_prev));
      newPattOccFLoc_wire <= fromMaybe(0, bin); //FIXME: fly-wire
      newPattMultiOccR <= isValid(bin);

      // add currently written pattern into indicators
      Bit#(16) newPattIndc = pack(newPattIndc_prev) | pack(wAddrLOH);
      newPattIndc_fifo.enq(newPattIndc);
      if (verbose) $display("setram %d: newPattIndc=%h %h", cycle, newPattIndc, pack(newPattIndc_prev));
   endrule

   interface Put writeServer;
      // Cycle 0.
      method Action put(BcamWriteReq#(Bit#(camSz), Bit#(9)) req);
         Bit#(camSz) wAddr = req.addr;
         Bit#(9) wData = req.data;
         Vector#(wAddrHWidth, Bit#(1)) wAddrH = takeAt(4, unpack(wAddr));

         wAddr_bcam <= wAddr;
         wPatt_bcam <= wData;
         if(verbose) $display("bcam9b %d: wAddr=%x, wPatt=%x", cycle, wAddr, wData);

         if (verbose) $display("setram %d: setram read addr=%x", cycle, pack(wAddrH));
         for (Integer i=0; i<4; i=i+1) begin
            setRam[i].readServer.request.put(pack(wAddrH));
         end

         vacram.readServer.request.put(pack(wAddrH));
         if (verbose) $display("vacram %d: vacram read addr=%x", cycle, pack(wAddrH));

         Vector#(4, Bit#(1)) wAddrL = take(unpack(wAddr));
         for (Integer i=0; i<4; i=i+1) begin
            idxRam[i].readServer.request.put(pack(wAddrH));
         end
         if (verbose) $display("idxram %d: idxram read addr=%x", cycle, pack(wAddrH));

         wAddrHR <= pack(wAddrH);
      endmethod
   endinterface

   interface Put mPatt = ram9b.readRequest;
   interface Get mIndc = ram9b.readResponse;
endmodule

interface BinaryCam#(numeric type camDepth, numeric type pattWidth);
   //interface Put#(Tuple2#(Bit#(TLog#(camDepth)), Bit#(pattWidth))) writeServer;
   interface Put#(BcamWriteReq#(Bit#(TLog#(camDepth)), Bit#(pattWidth))) writeServer;
   interface Server#(Bit#(pattWidth), Maybe#(Bit#(TLog#(camDepth)))) readServer;
   interface Server#(Bit#(TLog#(camDepth)), Maybe#(Bit#(pattWidth))) printServer;
endinterface

//(* synthesize *)
module mkBinaryCam(BinaryCam#(camDepth, pattWidth))
   provisos(Add#(cdep, 7, camSz)
            ,Mul#(cdep, 256, indcWidth)
            ,Log#(camDepth, camSz)
            ,Log#(indcWidth, camSz)
            ,Mul#(pwid, 9, pattWidth)
            ,Add#(TAdd#(TLog#(cdep), 4), 2, TLog#(TDiv#(camDepth, 4)))
            ,Log#(TDiv#(camDepth, 16), TAdd#(TLog#(cdep), 4))
            ,Add#(9, h__, pattWidth)
            ,PEncoder#(indcWidth)
            ,Add#(2, a__, camSz)
            ,Add#(4, b__, camSz)
            ,Add#(TAdd#(TLog#(cdep), 4), c__, camSz)
         );
   Clock defaultClock <- exposeCurrentClock();
   Reset defaultReset <- exposeCurrentReset();

   let verbose = True;
   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule every1 if (verbose);
      cycle <= cycle + 1;
   endrule

   FIFO#(Maybe#(Bit#(camSz))) readFifo <- mkFIFO;
   FIFO#(Maybe#(Bit#(pattWidth))) printFifo <- mkFIFO;

   Vector#(pwid, Bcam9b#(camDepth)) cam9b <- replicateM(mkBcam9b());
   PE#(indcWidth) pe_bcam <- mkPEncoder();

   rule cam9b_fifo_out;
      Bit#(indcWidth) mIndc = maxBound;
      for (Integer i=0; i < valueOf(pwid); i=i+1) begin
         let v_mIndc <- toGet(cam9b[i].mIndc).get;
         mIndc = mIndc & pack(v_mIndc);
      end
      pe_bcam.oht.put(mIndc);
      if (verbose) $display("bcam %d: cascading mindc=%x", cycle, mIndc);
   endrule

   rule pe_bcam_out;
      let bin <- pe_bcam.bin.get;
      if (verbose) $display("indc pe_bcam %d: bin=", cycle, fshow(bin));
      readFifo.enq(bin);
   endrule

   interface Server printServer;
      interface Put request;
         method Action put(Bit#(camSz) addr);
         endmethod
      endinterface
      interface Get response = toGet(printFifo);
   endinterface
   interface Server readServer;
      interface Put request;
         method Action put(Bit#(pattWidth) v);
            for (Integer i=0; i<valueOf(pwid); i=i+1) begin
               Vector#(9, Bit#(1)) data = takeAt(fromInteger(i) * 9, unpack(v));
               cam9b[i].mPatt.put(ReadRequest{mPatt: pack(data)});
            end
         endmethod
      endinterface
      interface Get response = toGet(readFifo);
   endinterface
   interface Put writeServer;
      method Action put(BcamWriteReq#(Bit#(camSz), Bit#(pattWidth)) v);
         for (Integer i=0; i<valueOf(pwid); i=i+1) begin
            Vector#(9, Bit#(1)) data = takeAt(fromInteger(i) * 9, unpack(v.data));
            let req = BcamWriteReq{addr: v.addr, data: pack(data)};
            cam9b[i].writeServer.put(req);
         end
      endmethod
   endinterface
endmodule

// Generated by compiler
(* synthesize *)
module mkBinaryCamBSV(BinaryCam#(256, 9));
   BinaryCam#(256, 9) bcam <- mkBinaryCam();
   interface writeServer = bcam.writeServer;
   interface readServer = bcam.readServer;
endmodule
