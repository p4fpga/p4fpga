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

function Stmt testSeq(AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256)) dut,
                      String dut_name);
    return seq
        noAction;
        action
            $display("%t === %s write addr=0x0 data=0x0badf00d",$time, dut_name);
            dut.write(0,256'h0badf00d);
        endaction
        action
            $display("%t === %s write addr=0x0 data=0xdeadbeef",$time, dut_name);
            dut.write(0,256'hdeadbeef);
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0);
        endaction
        action
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0);
        endaction
        action
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0);
        endaction
        action
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
            $display("%t === %s write addr=0x0 data=0xbabebabe",$time, dut_name);
            dut.write(0,256'hbabebabe);
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0);
        endaction
        action
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
            $display("%t === %s read addr=0x0",$time, dut_name);
            dut.read(0);
        endaction
        action
            $display("%t === %s getRead(0) = 0x%0x",$time, dut_name, dut.getRead());
        endaction
        action
            $display("%t === TEST %s finished",$time, dut_name);
        endaction
    endseq;
endfunction

(* synthesize *)
module mkTb1();

    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_ff <- mkAsymmetricBRAM(False, False);
    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_ft <- mkAsymmetricBRAM(False, True);
    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_tf <- mkAsymmetricBRAM(True, False);
    AsymmetricBRAM#(Bit#(4),Bit#(32),Bit#(1),Bit#(256))  bram_tt <- mkAsymmetricBRAM(True, True);

    BRAM_Configure cfg = defaultValue;
    cfg.memorySize = 8;
    BRAM2Port#(Bit#(3), Bit#(32)) bram_std <- mkBRAM2Server(cfg);

    Stmt test_bram_std = seq
        noAction;
        action
            $display("%t === bram_std write port a addr=0x0 data=0x0badf00d",$time);
            bram_std.portA.request.put(BRAMRequest{
                write: True,
                responseOnWrite: False,
                address: 0,
                datain: 32'h0badf00d
            });
        endaction
        action
            $display("%t === bram_std write port a addr=0x0 data=0xdeadbeef",$time);
            bram_std.portA.request.put(BRAMRequest{
                write: True,
                responseOnWrite: False,
                address: 0,
                datain: 32'hdeadbeef
            });
            $display("%t === bram_std read port b addr=0x0",$time);
            bram_std.portB.request.put(BRAMRequest{
                write: False,
                responseOnWrite: False,
                address: 0,
                datain: 0
            });
        endaction
        action
            let data <- bram_std.portB.response.get();
            $display("%t === bram_std addr 0 = 0x%0x",$time, data);
            $display("%t === bram_std read port b addr=0x0",$time);
            bram_std.portB.request.put(BRAMRequest{
                write: False,
                responseOnWrite: False,
                address: 0,
                datain: 0
            });
        endaction
        action
            let data <- bram_std.portB.response.get();
            $display("%t === bram_std addr 0 = 0x%0x",$time, data);
            $display("%t === bram_std read port b addr=0x0",$time);
            bram_std.portB.request.put(BRAMRequest{
                write: False,
                responseOnWrite: False,
                address: 0,
                datain: 0
            });
        endaction
        action
            let data <- bram_std.portB.response.get();
            $display("%t === bram_std addr 0 = 0x%0x",$time, data);
            $display("%t === bram_std write port a addr=0x0 data=0xbabebabe",$time);
            bram_std.portA.request.put(BRAMRequest{
                write: True,
                responseOnWrite: False,
                address: 0,
                datain: 32'hbabebabe
            });
            $display("%t === bram_std read port b addr=0x0",$time);
            bram_std.portB.request.put(BRAMRequest{
                write: False,
                responseOnWrite: False,
                address: 0,
                datain: 0
            });
        endaction
        action
            let data <- bram_std.portB.response.get();
            $display("%t === bram_std addr 0 = 0x%0x",$time, data);
            $display("%t === bram_std read port b addr=0x0",$time);
            bram_std.portB.request.put(BRAMRequest{
                write: False,
                responseOnWrite: False,
                address: 0,
                datain: 0
            });
        endaction
        action
            let data <- bram_std.portB.response.get();
            $display("%t === bram_std addr 0 = 0x%0x",$time, data);
        endaction
        action
            $display("%t === TEST bram_std finished",$time);
        endaction
    endseq;

    mkAutoFSM(testSeq(bram_ff, "bram_ff"));
    mkAutoFSM(testSeq(bram_ft, "bram_ft"));
    mkAutoFSM(testSeq(bram_tf, "bram_tf"));
    mkAutoFSM(testSeq(bram_tt, "bram_tt"));
    mkAutoFSM(test_bram_std);

endmodule
