/*-
 * Copyright (c) 2013 Alexandre Joannou
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


import StmtFSM::*;
import AsymmetricBRAM::*;
import BRAM::*;
import Pipe::*;
import ClientServer::*;

(* synthesize *)
module mkTb2();
    AsymmetricBRAM#(Bit#(10),Bit#(32),Bit#(10),Bit#(32))   bram1 <- mkAsymmetricBRAM(False, False, "Test");
//    AsymmetricBRAM#(Bit#(2),Bit#(256),Bit#(5),Bit#(32))    bram2 <- mkAsymmetricBRAM(False, False);
//    AsymmetricBRAM#(Bit#(1),Bit#(32),Bit#(3),Bit#(8))    bram3 <- mkAsymmetricBRAM(False, False);
//    AsymmetricBRAM#(Bit#(2),Bit#(8),Bit#(2),Bit#(8))     bram4 <- mkAsymmetricBRAM(False, False);

   Reg#(Bit#(32)) cycle <- mkReg(0);
   rule every1;
      cycle <= cycle+1;
   endrule

    Stmt test_bram1 = seq
        noAction;
        action
        $display("bram1.writeServer.put(0x0,'h4)");
        bram1.writeServer.put(tuple2('h0,'h4));
        endaction
        action
        $display("bram1.writeServer.put(0x0,'h4)");
        bram1.writeServer.put(tuple2('h0,'h4));
        endaction
        action
        $display("bram1.readServer.request.put('h0)");
        bram1.readServer.request.put('h0);
        endaction
        action
        $display("bram1.readServer.response.get(), should be ");
        $display("addr 0x18 = 0x%0x", bram1.readServer.response.get());
        endaction
//        action
//        $display("bram1.writeServer.put(2,32'hfeedbabe)");
//        bram1.writeServer.put(tuple2(2,32'hfeedbabe));
//        endaction
//        action
//        $display("bram1.writeServer.put(2,32'hdeadbeef)");
//        bram1.writeServer.put(tuple2(3,32'hdeadbabe));
//        endaction
//        action
//        $display("%d: bram1.readServer.request.put(1)", cycle);
//        bram1.readServer.request.put(1);
//        endaction
//        action
//        $display("%d: bram1.readServer.response.get(), should be 0xdeadbeeffeedbabe", cycle);
//        $display("%d: addr 1 = 0x%0x", cycle, bram1.readServer.response.get());
//        endaction
        $display("TEST bram1 FINISHED");
    endseq;

//    Stmt test_bram2 = seq
//        noAction;
//        action
//        $display("bram2.write(0,32'h01234567)");
//        bram2.writeServer.put(tuple2(0,32'h01234567));
//        endaction
//        action
//        $display("bram2.read(0)");
//        bram2.readServer.request.put(0);
//        endaction
//        action
//        $display("bram2.getRead(), should be 0xdeadbabe");
//        $display("addr 0 = 0x%0x", bram2.readServer.response.get());
//        endaction
//        action
//        $display("bram2.read(2)");
//        bram2.readServer.request.put(2);
//        endaction
//        action
//        $display("bram2.getRead(), should be 0x89abcdef");
//        $display("addr 2 = 0x%0x", bram2.readServer.response.get());
//        endaction
//        action
//        $display("bram2.write(1,256'hfeedbabedeadbabe0123456789abcdef)");
//        bram2.writeServer.put(tuple2(1,32'hfeedbabe));
//        endaction
//        action
//        $display("bram2.read(1)");
//        bram2.readServer.request.put(0);
//        endaction
//        action
//        $display("bram2.getRead(), should be 0xfeedbabe");
//        $display("addr 1 = 0x%0x", bram2.readServer.response.get());
//        endaction
//        $display("TEST bram2 FINISHED");
//    endseq;

//    Stmt test_bram3 = seq
//        noAction;
//        action
//        $display("bram3.write(0,32'hdeadbabe)");
//        bram3.write(0,32'hdeadbabe);
//        endaction
//        action
//        $display("bram3.read(0)");
//        bram3.read(0);
//        endaction
//        action
//        $display("bram3.getRead(), should be 0xbe");
//        $display("addr 0 = 0x%0x", bram3.getRead());
//        endaction
//        action
//        $display("bram3.read(1)");
//        bram3.read(1);
//        endaction
//        action
//        $display("bram3.getRead(), should be 0xba");
//        $display("addr 1 = 0x%0x", bram3.getRead());
//        endaction
//        action
//        $display("bram3.write(1,32'hfeeddead)");
//        bram3.write(1,32'hfeeddead);
//        endaction
//        action
//        $display("bram3.read(5)");
//        bram3.read(5);
//        endaction
//        action
//        $display("bram3.getRead(), should be 0xde");
//        $display("addr 5 = 0x%0x", bram3.getRead());
//        endaction
//        $display("TEST bram3 FINISHED");
//    endseq;
//
//    Stmt test_bram4 = seq
//        noAction;
//        action
//        $display("bram4.write(0,8'hab)");
//        bram4.write(0,8'hab);
//        endaction
//        action
//        $display("bram4.read(0)");
//        bram4.read(0);
//        endaction
//        action
//        $display("bram4.getRead(), should be 0xab");
//        $display("addr 0 = 0x%0x", bram4.getRead());
//        endaction
//        action
//        $display("bram4.read(1)");
//        bram4.read(1);
//        endaction
//        action
//        $display("bram4.getRead(), should be ??");
//        $display("addr 1 = 0x%0x", bram4.getRead());
//        endaction
//        action
//        $display("bram4.write(2,8'hcd)");
//        bram4.write(2,8'hcd);
//        endaction
//        action
//        $display("bram4.read(2)");
//        bram4.read(2);
//        endaction
//        action
//        $display("bram4.getRead(), should be 0xcd");
//        $display("addr 2 = 0x%0x", bram4.getRead());
//        endaction
//        $display("TEST bram4 FINISHED");
//    endseq;
//
    mkAutoFSM(test_bram1);
    //mkAutoFSM(test_bram2);
//    mkAutoFSM(test_bram3);
//    mkAutoFSM(test_bram4);

endmodule
