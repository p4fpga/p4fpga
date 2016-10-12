/*-
 * Copyright (c) 2013, 2014 Alexandre Joannou
 * Copyright (c) 2015 Han Wang
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249
 * ("MRC2"), as part of the DARPA MRC research programme.
 *
 * @BERI_LICENSE_HEADER_START@
 *
 * Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  BERI licenses this
 * file to you under the BERI Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.beri-open-systems.org/legal/license-1-0.txt
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @BERI_LICENSE_HEADER_END@
 */

package AsymmetricBRAM;

import Connectable::*;
import ClientServer::*;
import FIFO :: *;
import FIFOF :: *;
import GetPut::*;
import SpecialFIFOs :: *;
import ConfigReg :: * ;
import Vector :: * ;
import Pipe::*;
import ConnectalConfig::*;

 `include "ConnectalProjectConfig.bsv"

// Interface to the asymmetric ram
interface AsymmetricBRAM#(  type rAddrT, type rDataT,
                            type wAddrT, type wDataT);
   interface Put#(Tuple2#(wAddrT, wDataT)) writeServer;
   interface Server#(rAddrT, rDataT) readServer;
endinterface

// Interface to the verilog module (using an altsyncram component)
interface VAsymBRAMIfc#(    type rAddrT,type rDataT,
                            type wAddrT, type wDataT);
    method Action read(rAddrT read_addr);
    method rDataT getRead();
    method Action write(wAddrT write_addr, wDataT write_data);
endinterface

// Assume narrower write port
// Wrapper for the verilog
`ifndef SIMULATION
`ifdef ALTERA
import "BVI" AsymmetricBRAM_Altera =
`endif
`ifdef XILINX
import "BVI" AsymmetricBRAM_Xilinx =
`endif
module vAsymBRAM#(Bool hasOutputRegister)
                 (VAsymBRAMIfc#(raddr_t, rdata_t, waddr_t, wdata_t))
    provisos(
        Bits#(raddr_t, raddr_sz),
        Bits#(rdata_t, rdata_sz),
        Bits#(waddr_t, waddr_sz),
        Bits#(wdata_t, wdata_sz)
    );

    default_clock (CLK);
    default_reset no_reset;

    parameter   PIPELINED   = Bit#(1)'(pack(hasOutputRegister));
    parameter   WADDR_WIDTH = valueOf(waddr_sz);
    parameter   WDATA_WIDTH = valueOf(wdata_sz);
    parameter   RADDR_WIDTH = valueOf(raddr_sz);
    parameter   RDATA_WIDTH = valueOf(rdata_sz);
    parameter   MEMSIZE     = valueOf(TExp#(waddr_sz));

    method read(RADDR) enable(REN);
    method RDATA getRead();
    method write(WADDR,WDATA) enable(WEN);

    schedule (getRead) SBR (read, write);
    schedule (read)  C (read);
    schedule (write) C (write);
    schedule (getRead) CF (getRead);
    schedule (write) CF (read);

endmodule
`endif

module mkAsymmetricBRAM#(Bool hasOutputRegister, Bool hasForwarding, String name)
                               (AsymmetricBRAM#(raddr_t, rdata_t, waddr_t, wdata_t))
    provisos(
        Bits#(raddr_t, raddr_sz),
        Bits#(rdata_t, rdata_sz),
        Bits#(waddr_t, waddr_sz),
        Bits#(wdata_t, wdata_sz),
        Div#(rdata_sz,wdata_sz,ratio),
        Log#(ratio,offset_sz),
        Add#(raddr_sz,offset_sz,waddr_sz),
        Bits#(Vector#(ratio, wdata_t), rdata_sz)
    );
    AsymmetricBRAM#(raddr_t, rdata_t, waddr_t, wdata_t) ret_ifc;
    `ifndef SIMULATION
        ret_ifc <- mkAsymmetricBRAMVerilog(hasOutputRegister, hasForwarding);
    `else
        ret_ifc <- mkAsymmetricBRAMBluesim(hasOutputRegister, hasForwarding, name);
    `endif
    return ret_ifc;
endmodule

`ifndef SIMULATION
module mkAsymmetricBRAMVerilog#(Bool hasOutputRegister, Bool hasForwarding)
                               (AsymmetricBRAM#(raddr_t, rdata_t, waddr_t, wdata_t))
    provisos(
        Bits#(raddr_t, raddr_sz),
        Bits#(rdata_t, rdata_sz),
        Bits#(waddr_t, waddr_sz),
        Bits#(wdata_t, wdata_sz),
        Div#(rdata_sz,wdata_sz,ratio),
        Log#(ratio,offset_sz),
        Add#(raddr_sz,offset_sz,waddr_sz),
        Bits#(Vector#(ratio, wdata_t), rdata_sz)
    );
    FIFO#(Tuple2#(waddr_t, wdata_t)) writeReqFifo <- mkFIFO;
    FIFO#(raddr_t) readReqFifo <- mkFIFO;
    FIFO#(rdata_t) readDataFifo <- mkFIFO;
    FIFO#(void) readCtrlFifo <- mkFIFO;

    VAsymBRAMIfc#(raddr_t, rdata_t, waddr_t, wdata_t) bram <- vAsymBRAM(hasOutputRegister);

    rule do_read;
       let v <- toGet(readReqFifo).get;
       bram.read(v);
       readCtrlFifo.enq(?);
    endrule

    rule do_reponse;
       let v <- toGet(readCtrlFifo).get;
       let addr = bram.getRead;
       readDataFifo.enq(addr);
    endrule

    rule do_write;
       let v <- toGet(writeReqFifo).get;
       let addr = tpl_1(v);
       let data = tpl_2(v);
       bram.write(addr, data);
    endrule

    interface Put writeServer = toPut(writeReqFifo);
    interface readServer = (interface Server;
      interface Put request;
         method Action put(raddr_t addr);
            readReqFifo.enq(addr);
         endmethod
      endinterface
      interface Get response = toGet(readDataFifo);
   endinterface);

endmodule
`endif

import "BDPI" mem_create    = function ActionValue#(Bit#(64)) mem_create(msize_t size, rsize_t rsize, wsize_t wsize)
                              provisos (Bits#(msize_t, msize_sz),
                                        Bits#(rsize_t, rsize_sz),
                                        Bits#(wsize_t, wsize_sz));
import "BDPI" mem_clean     = function Action mem_clean(Bit#(64) mem_ptr);
import "BDPI" mem_read      = function ActionValue#(rdata_t) mem_read(Bit#(64) mem_ptr, raddr_t raddr)
                              provisos (Bits#(raddr_t, raddr_sz),
                                        Bits#(rdata_t, rdata_sz));
import "BDPI" mem_write     = function Action mem_write(Bit#(64) mem_ptr, waddr_t waddr, wdata_t wdata)
                              provisos (Bits#(waddr_t, waddr_sz),
                                        Bits#(wdata_t, wdata_sz));

module mkAsymmetricBRAMBluesim#(Bool hasOutputRegister, Bool hasForwarding, String name)
                               (AsymmetricBRAM#(raddr_t, rdata_t, waddr_t, wdata_t))
    provisos(
        Bits#(raddr_t, raddr_sz),
        Bits#(rdata_t, rdata_sz),
        Bits#(waddr_t, waddr_sz),
        Bits#(wdata_t, wdata_sz),
        Div#(rdata_sz,wdata_sz,ratio),
        Log#(ratio,offset_sz),
        Add#(raddr_sz,offset_sz,waddr_sz),
        Bits#(Vector#(ratio, wdata_t), rdata_sz)
    );
    let verbose = False;
    FIFO#(Tuple2#(waddr_t, wdata_t)) writeReqFifo <- mkFIFO;
    FIFO#(raddr_t) readReqFifo <- mkFIFO;
    FIFO#(rdata_t) readDataFifo <- mkFIFO;

    Reg#(Bit#(64))  mem_ptr         <- mkRegU();
    Reg#(Bool)      isInitialized   <- mkReg(False);

    Reg#(Bit#(32)) cntr <- mkReg(0);
    rule every1 if (verbose);
      cntr <= cntr + 1;
    endrule

    (* execution_order = "do_read, do_write" *)
    rule do_read (isInitialized);
       let v <- toGet(readReqFifo).get;
       rdata_t rdata  <- mem_read(mem_ptr, v);
       readDataFifo.enq(rdata);
       if (verbose) $display("%s %d: read data from %x with index %x = %x", name, cntr, mem_ptr, v, rdata);
    endrule

    rule do_write (isInitialized);
       let v <- toGet(writeReqFifo).get;
       let writeAddr = tpl_1(v);
       let writeData = tpl_2(v);
       mem_write(mem_ptr, writeAddr, writeData);
       if (verbose) $display("%s %d: write data to %x with index %x = %x", name, cntr, mem_ptr, writeAddr, writeData);
    endrule

    rule do_init (!isInitialized);
       let tmp <- mem_create(fromInteger(valueOf(TExp#(waddr_sz))),
                             fromInteger(valueOf(rdata_sz)),
                             fromInteger(valueOf(wdata_sz)));
       mem_ptr <= tmp;
       isInitialized <= True;

       if (valueOf(raddr_sz) > 64) begin
          $display("raddr_sz larger than 64 is not supported");
       end
    endrule

   interface Put writeServer = toPut(writeReqFifo);
   interface readServer = (interface Server;
      interface Put request;
         method Action put(raddr_t addr);
            readReqFifo.enq(addr);
         endmethod
      endinterface
      interface Get response = toGet(readDataFifo);
   endinterface);
endmodule

endpackage
