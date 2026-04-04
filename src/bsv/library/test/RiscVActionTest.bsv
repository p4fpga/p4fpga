// Copyright (c) 2025 P4FPGA Project
// MIT License (see RiscVActionCore.bsv for full text)

/*
  Test for VLIW RISC-V Action Processor

  Tests 8-wide VLIW execution with parallel metadata access.

  TestMetadata layout (packed MSB-first by Bluespec):
    dropFlag    : 1 bit   -> bitOffset = 128
    outputPort  : 32 bits -> bitOffset = 96
    field2      : 32 bits -> bitOffset = 64
    field1      : 32 bits -> bitOffset = 32
    pktLength   : 32 bits -> bitOffset = 0
*/

import RiscVActionCore::*;
import ClientServer::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import StmtFSM::*;
import Connectable::*;
import BuildVector::*;

// Test metadata (129 bits)
typedef struct {
    Bit#(32) pktLength;     // bitOffset = 0
    Bit#(32) field1;        // bitOffset = 32
    Bit#(32) field2;        // bitOffset = 64
    Bit#(32) outputPort;    // bitOffset = 96
    Bool     dropFlag;      // bitOffset = 128
} TestMetadata deriving(Bits, Eq, FShow);

typedef Bit#(8) TestParam deriving(Bits, Eq, FShow);

// Encoding helpers
function Bit#(32) enc_addi(Bit#(5) rd, Bit#(5) rs1, Bit#(12) imm);
    return {imm, rs1, 3'b000, rd, 7'b0010011};
endfunction

function Bit#(32) enc_rtype(Bit#(7) funct7, Bit#(5) rs2, Bit#(5) rs1, Bit#(3) funct3, Bit#(5) rd);
    return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
endfunction

function Bit#(32) enc_p4ext(Bit#(7) funct7, Bit#(5) rs2, Bit#(5) rs1, Bit#(3) funct3, Bit#(5) rd);
    return {funct7, rs2, rs1, funct3, rd, 7'b1110011};
endfunction

function Bit#(32) meta_read(Bit#(5) rd, Bit#(5) offsetReg);
    return enc_p4ext(7'b0000000, 0, offsetReg, 3'b111, rd);
endfunction

function Bit#(32) meta_write(Bit#(5) offsetReg, Bit#(5) valueReg);
    return enc_p4ext(7'b0000001, valueReg, offsetReg, 3'b111, 0);
endfunction

function Bit#(32) p4_checksum(Bit#(5) rd, Bit#(5) rs1, Bit#(5) rs2);
    return enc_p4ext(7'b0000000, rs2, rs1, 3'b100, rd);
endfunction

Bit#(32) rvNOP = 32'h00000013;

// Helper to create a VLIW word from up to 8 instructions
function VLIWWord mkVLIW(Bit#(32) s0, Bit#(32) s1, Bit#(32) s2, Bit#(32) s3,
                         Bit#(32) s4, Bit#(32) s5, Bit#(32) s6, Bit#(32) s7);
    Vector#(8, Bit#(32)) w = newVector;
    w[0]=s0; w[1]=s1; w[2]=s2; w[3]=s3; w[4]=s4; w[5]=s5; w[6]=s6; w[7]=s7;
    return w;
endfunction

VLIWWord vliwTerminator = replicate(0);
VLIWWord vliwNOP = replicate(rvNOP);

module mkRiscVActionTest(Empty);
    RiscVActionCore#(TestMetadata, TestParam) core <- mkRiscVActionCore();

    FIFO#(Tuple2#(TestMetadata, TestParam)) inputFIFO <- mkFIFO;
    FIFO#(TestMetadata) outputFIFO <- mkFIFO;
    FIFO#(TestMetadata) expectedFIFO <- mkFIFO;

    mkConnection(toGet(inputFIFO), core.action_server.request);
    mkConnection(core.action_server.response, toPut(outputFIFO));

    Reg#(Bit#(32)) passCount <- mkReg(0);
    Reg#(Bit#(32)) failCount <- mkReg(0);

    // ---------------------------------------------------------------
    // Test 1: Parallel field read + increment + write (3 VLIW cycles)
    //   Read field1 and field2 in parallel, add 5 and 10, write back in parallel
    // ---------------------------------------------------------------
    function Vector#(64, VLIWWord) test1_program();
        Vector#(64, VLIWWord) p = replicate(replicate(0));

        // Word 0 (SETUP): load bit offsets into registers
        // r10=32 (field1), r11=64 (field2) — 2 slots used, 6 NOP
        p[0] = mkVLIW(enc_addi(10,0,32), enc_addi(11,0,64),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 1 (READ): parallel metadata reads
        // r1 = meta[32], r2 = meta[64]
        p[1] = mkVLIW(meta_read(1,10), meta_read(2,11),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 2 (COMPUTE): parallel adds
        // r1 = r1 + 5, r2 = r2 + 10
        p[2] = mkVLIW(enc_addi(1,1,5), enc_addi(2,2,10),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 3 (WRITE): parallel metadata writes
        p[3] = mkVLIW(meta_write(10,1), meta_write(11,2),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 4: terminator
        p[4] = vliwTerminator;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test 2: All 8 slots active — load 8 values, compute, write
    // ---------------------------------------------------------------
    function Vector#(64, VLIWWord) test2_program();
        Vector#(64, VLIWWord) p = replicate(replicate(0));

        // Word 0 (SETUP): load offset for outputPort (96) and constants
        p[0] = mkVLIW(enc_addi(10,0,96),  // r10 = offset of outputPort
                       enc_addi(1,0,1), enc_addi(2,0,2), enc_addi(3,0,3),
                       enc_addi(4,0,4), enc_addi(5,0,5), enc_addi(6,0,6),
                       enc_addi(7,0,7));

        // Word 1 (COMPUTE): sum them: r1=1+2=3, r3=3+4=7, r5=5+6=11, r7=7+r5
        // Build partial sums in parallel
        p[1] = mkVLIW(enc_rtype(0,2,1,3'b000,1),   // r1 = r1+r2 = 3
                       enc_rtype(0,4,3,3'b000,3),   // r3 = r3+r4 = 7
                       enc_rtype(0,6,5,3'b000,5),   // r5 = r5+r6 = 11
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 2: reduce: r1 = r1+r3, r5 = r5+r7
        p[2] = mkVLIW(enc_rtype(0,3,1,3'b000,1),   // r1 = 3+7 = 10
                       enc_rtype(0,7,5,3'b000,5),   // r5 = 11+7 = 18
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 3: final reduce + write
        p[3] = mkVLIW(enc_rtype(0,5,1,3'b000,1),   // r1 = 10+18 = 28
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        // Word 4 (WRITE): outputPort = r1 = 28
        p[4] = mkVLIW(meta_write(10,1),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);

        p[5] = vliwTerminator;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test 3: CHECKSUM — parallel checksum of field1 and field2
    // ---------------------------------------------------------------
    function Vector#(64, VLIWWord) test3_program();
        Vector#(64, VLIWWord) p = replicate(replicate(0));

        // SETUP: offsets
        p[0] = mkVLIW(enc_addi(10,0,32), enc_addi(11,0,64), enc_addi(12,0,96),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);
        // READ: field1 and field2 in parallel
        p[1] = mkVLIW(meta_read(1,10), meta_read(2,11),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);
        // COMPUTE: checksum
        p[2] = mkVLIW(p4_checksum(3,1,2),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);
        // WRITE: outputPort = checksum result
        p[3] = mkVLIW(meta_write(12,3),
                       rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP, rvNOP);
        p[4] = vliwTerminator;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test runner
    // ---------------------------------------------------------------
    Stmt testSequence = seq
        core.setVerbosity(0);

        // --- Test 1: Parallel read/compute/write ---
        action
            $display("=== Test 1: Parallel field1+=5, field2+=10 (3 VLIW cycles) ===");
            core.loadProgram(test1_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.field1 = 15;
            expected.field2 = 30;
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: field1=%d, field2=%d", result.field1, result.field2);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Test 2: 8-slot parallel sum ---
        action
            $display("=== Test 2: 8-slot parallel reduction (1+2+...+7 = 28) ===");
            core.loadProgram(test2_program());
            TestMetadata meta = TestMetadata{pktLength:0, field1:0, field2:0, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.outputPort = 28;
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: outputPort=%d", result.outputPort);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Test 3: Checksum ---
        action
            $display("=== Test 3: CHECKSUM(10, 20) = 30 ===");
            core.loadProgram(test3_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.outputPort = 30;
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: outputPort=%d", result.outputPort);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Summary ---
        action
            $display("========================================");
            $display("Results: %d passed, %d failed", passCount, failCount);
            if (failCount == 0) $display("ALL TESTS PASSED");
            else $display("SOME TESTS FAILED");
            $finish(0);
        endaction
    endseq;

    FSM testFSM <- mkFSM(testSequence);
    rule startOnce; testFSM.start; endrule
endmodule

module mkRiscVActionTestSim(Empty);
    mkRiscVActionTest test <- mkRiscVActionTest;
endmodule
