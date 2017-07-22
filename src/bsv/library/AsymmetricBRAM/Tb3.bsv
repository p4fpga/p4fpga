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
import BRAMCore::*;

function Stmt testSeq(AsymmetricBRAM#(Bit#(4),Bit#(256),Bit#(16),Bit#(32)) dut,
                      String dut_name);
    return seq
        noAction;
        action
            $display("%t === %s write addr=0x0 data=0x0badf00d",$time, dut_name);
            dut.write(0x10,32'h0badf00d);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        endaction
        //repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        action
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0x10);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        endaction
        //repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        action
            $display("%t === %s write addr=0x0 data=0xbabebabe",$time, dut_name);
            dut.write(0x10,32'hbabebabe);
            $display("%t === %s read addr=0x0",$time, dut_name);
         endaction
         action
            dut.read(0x10);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        endaction
        //repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        $display("%t === TEST %s finished",$time, dut_name);
    endseq;
endfunction

function Stmt testSeqCore(BRAM_DUAL_PORT#(Bit#(4), Bit#(32)) dut, String dut_name);
    return seq
        noAction;
        action
            $display("%t === %s write addr=0x0 data=0x0badf00d",$time, dut_name);
            dut.a.put(True,0,32'h0badf00d);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        endaction
        repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        action
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.b.put(False,0,?);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        endaction
        repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        action
            $display("%t === %s write addr=0x0 data=0xbabebabe",$time, dut_name);
            dut.a.put(True,0,32'hbabebabe);
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.b.put(False,0,?);
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        endaction
        repeat (2) $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.b.read());
        $display("%t === TEST %s finished",$time, dut_name);
    endseq;
endfunction

(* synthesize *)
module mkTb3();

//    AsymmetricBRAM#(Bit#(1),Bit#(256),Bit#(4),Bit#(32))  bram_ff <- mkAsymmetricBRAM(False, False);
    AsymmetricBRAM#(Bit#(1),Bit#(256),Bit#(4),Bit#(32))  bram_ft <- mkAsymmetricBRAM(False, True);
//    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_tf <- mkAsymmetricBRAM(True, False);
//    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_tt <- mkAsymmetricBRAM(True, True);

//    BRAM_DUAL_PORT#(Bit#(4), Bit#(32)) bram_core_std_fx <- mkBRAMCore2(16, False);
//    BRAM_DUAL_PORT#(Bit#(4), Bit#(32)) bram_core_std_tx <- mkBRAMCore2(16, True);

//    mkAutoFSM(testSeq(bram_ff, "bram_ff"));
    mkAutoFSM(testSeq(bram_ft, "bram_ft"));
//    mkAutoFSM(testSeq(bram_tf, "bram_tf"));
//    mkAutoFSM(testSeq(bram_tt, "bram_tt"));
//    mkAutoFSM(testSeqCore(bram_core_std_fx, "std_bram_core_f"));
//    mkAutoFSM(testSeqCore(bram_core_std_tx, "std_bram_core_t"));

endmodule
