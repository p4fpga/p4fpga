// Copyright (c) 2025 P4FPGA Project
// MIT License (see RiscVActionCore.bsv for full text)

/*
  Test for RISC-V Action Processor

  Verifies metadata read/write round-trip, arithmetic, branching,
  header state manipulation, and one's complement checksum.

  TestMetadata layout (packed MSB-first by Bluespec):
    dropFlag    : 1 bit   at bits [128]       -> bitOffset = 128
    outputPort  : 32 bits at bits [127:96]    -> bitOffset = 96
    field2      : 32 bits at bits [95:64]     -> bitOffset = 64
    field1      : 32 bits at bits [63:32]     -> bitOffset = 32
    pktLength   : 32 bits at bits [31:0]      -> bitOffset = 0
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

// Simple test metadata structure (129 bits total)
typedef struct {
    Bit#(32) pktLength;     // bitOffset = 0   (LSB)
    Bit#(32) field1;        // bitOffset = 32
    Bit#(32) field2;        // bitOffset = 64
    Bit#(32) outputPort;    // bitOffset = 96
    Bool     dropFlag;      // bitOffset = 128 (MSB)
} TestMetadata deriving(Bits, Eq, FShow);

typedef Bit#(8) TestParam deriving(Bits, Eq, FShow);

// Bit offsets for TestMetadata fields
Integer off_pktLength  = 0;
Integer off_field1     = 32;
Integer off_field2     = 64;
Integer off_outputPort = 96;
Integer off_dropFlag   = 128;

// Helper: encode ADDI rd, rs1, imm
function Bit#(32) enc_addi(Bit#(5) rd, Bit#(5) rs1, Bit#(12) imm);
    return {imm, rs1, 3'b000, rd, 7'b0010011};
endfunction

// Helper: encode R-type
function Bit#(32) enc_rtype(Bit#(7) funct7, Bit#(5) rs2, Bit#(5) rs1, Bit#(3) funct3, Bit#(5) rd);
    return {funct7, rs2, rs1, funct3, rd, 7'b0110011};
endfunction

// Helper: encode P4_EXT (custom instruction)
function Bit#(32) enc_p4ext(Bit#(7) funct7, Bit#(5) rs2, Bit#(5) rs1, Bit#(3) funct3, Bit#(5) rd);
    return {funct7, rs2, rs1, funct3, rd, 7'b1110011};
endfunction

// Helper: META_ACCESS read - rd = metaBits[regFile[rs1] +: 32]
function Bit#(32) meta_read(Bit#(5) rd, Bit#(5) offsetReg);
    return enc_p4ext(7'b0000000, 0, offsetReg, 3'b111, rd);
endfunction

// Helper: META_ACCESS write - metaBits[regFile[rs1] +: 32] = regFile[rs2]
function Bit#(32) meta_write(Bit#(5) offsetReg, Bit#(5) valueReg);
    return enc_p4ext(7'b0000001, valueReg, offsetReg, 3'b111, 0);
endfunction

// Helper: ADD_HEADER at offset in rs1
function Bit#(32) add_header(Bit#(5) rd, Bit#(5) offsetReg);
    return enc_p4ext(7'b0000000, 0, offsetReg, 3'b010, rd);
endfunction

// Helper: REM_HEADER at offset in rs1
function Bit#(32) rem_header(Bit#(5) rd, Bit#(5) offsetReg);
    return enc_p4ext(7'b0000000, 0, offsetReg, 3'b011, rd);
endfunction

// Helper: CHECKSUM rd = ones_complement_add(rs1, rs2)
function Bit#(32) p4_checksum(Bit#(5) rd, Bit#(5) rs1, Bit#(5) rs2);
    return enc_p4ext(7'b0000000, rs2, rs1, 3'b100, rd);
endfunction

// Helper: BEQ rs1, rs2, offset (offset in bytes, /2 for PC)
function Bit#(32) enc_beq(Bit#(5) rs1, Bit#(5) rs2, Bit#(13) imm);
    return {imm[12], imm[10:5], rs2, rs1, 3'b000, imm[4:1], imm[11], 7'b1100011};
endfunction

// Helper: JAL rd, offset (offset in bytes)
function Bit#(32) enc_jal(Bit#(5) rd, Bit#(21) imm);
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
endfunction

module mkRiscVActionTest(Empty);
    RiscVActionCore#(TestMetadata, TestParam) core <- mkRiscVActionCore();

    FIFO#(Tuple2#(TestMetadata, TestParam)) inputFIFO <- mkFIFO;
    FIFO#(TestMetadata) outputFIFO <- mkFIFO;
    FIFO#(TestMetadata) expectedFIFO <- mkFIFO;

    mkConnection(toGet(inputFIFO), core.action_server.request);
    mkConnection(core.action_server.response, toPut(outputFIFO));

    Reg#(Bit#(32)) testNum <- mkReg(0);
    Reg#(Bit#(32)) passCount <- mkReg(0);
    Reg#(Bit#(32)) failCount <- mkReg(0);

    // ---------------------------------------------------------------
    // Test 1: META_ACCESS read/write round-trip
    //   Read field1 (offset=32), add 5, write back
    // ---------------------------------------------------------------
    function Vector#(256, Bit#(32)) test1_program();
        Vector#(256, Bit#(32)) p = replicate(0);
        // r10 = 32 (bit offset of field1)
        p[0] = enc_addi(10, 0, 32);
        // r1 = metaBits[32 +: 32]  (read field1)
        p[1] = meta_read(1, 10);
        // r1 = r1 + 5
        p[2] = enc_addi(1, 1, 5);
        // metaBits[32 +: 32] = r1  (write field1)
        p[3] = meta_write(10, 1);
        // end
        p[4] = 0;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test 2: Conditional branch (if pktLength < 64, outputPort=1, else outputPort=2)
    // ---------------------------------------------------------------
    function Vector#(256, Bit#(32)) test2_program();
        Vector#(256, Bit#(32)) p = replicate(0);
        // r10 = 0 (offset of pktLength)
        p[0] = enc_addi(10, 0, 0);
        // r1 = metaBits[0 +: 32]  (pktLength)
        p[1] = meta_read(1, 10);
        // r2 = 64
        p[2] = enc_addi(2, 0, 64);
        // r3 = (r1 < r2) ? 1 : 0  (SLT)
        p[3] = enc_rtype(7'b0000000, 2, 1, 3'b010, 3);
        // if r3 == 0, skip 2 instructions (jump to p[6])
        p[4] = enc_beq(3, 0, 13'b0000000000110);  // offset = 6 bytes = 3 instrs * 2
        // outputPort = 1
        p[5] = enc_addi(4, 0, 1);
        // jump past else (skip 2 instrs)
        p[6] = enc_jal(0, 21'b000000000000000000110); // offset = 6 bytes = 3 instrs * 2
        // else: outputPort = 2
        p[7] = enc_addi(4, 0, 2);
        // (fall through to write)
        // r11 = 96 (offset of outputPort)
        p[8] = enc_addi(11, 0, 96);
        // metaBits[96 +: 32] = r4
        p[9] = meta_write(11, 4);
        // end
        p[10] = 0;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test 3: CHECKSUM - one's complement add of field1 and field2
    // ---------------------------------------------------------------
    function Vector#(256, Bit#(32)) test3_program();
        Vector#(256, Bit#(32)) p = replicate(0);
        // r10 = 32 (field1 offset), r11 = 64 (field2 offset), r12 = 96 (outputPort offset)
        p[0] = enc_addi(10, 0, 32);
        p[1] = enc_addi(11, 0, 64);
        p[2] = enc_addi(12, 0, 96);
        // r1 = field1, r2 = field2
        p[3] = meta_read(1, 10);
        p[4] = meta_read(2, 11);
        // r3 = checksum(r1, r2)
        p[5] = p4_checksum(3, 1, 2);
        // outputPort = r3
        p[6] = meta_write(12, 3);
        // end
        p[7] = 0;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test 4: LOAD/STORE - byte-addressed metadata access
    //   LOAD from byte address 4 (= field1 at bitOffset 32)
    //   Add 100, STORE back
    // ---------------------------------------------------------------
    function Vector#(256, Bit#(32)) test4_program();
        Vector#(256, Bit#(32)) p = replicate(0);
        // LOAD r1, 4(x0)  - load word at byte address 4 = bitOffset 32 = field1
        // I-type: imm=4, rs1=0, funct3=010 (LW), rd=1, opcode=0000011
        p[0] = {12'd4, 5'd0, 3'b010, 5'd1, 7'b0000011};
        // r1 = r1 + 100
        p[1] = enc_addi(1, 1, 100);
        // STORE r1, 4(x0)  - store word at byte address 4
        // S-type: imm[11:5]=0, rs2=1, rs1=0, funct3=010, imm[4:0]=4, opcode=0100011
        p[2] = {7'd0, 5'd1, 5'd0, 3'b010, 5'd4, 7'b0100011};
        // end
        p[3] = 0;
        return p;
    endfunction

    // ---------------------------------------------------------------
    // Test runner FSM
    // ---------------------------------------------------------------
    Stmt testSequence = seq
        core.setVerbosity(0);

        // --- Test 1: META_ACCESS round-trip ---
        action
            $display("=== Test 1: META_ACCESS read/write ===");
            testNum <= 1;
            core.loadProgram(test1_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.field1 = 15;  // 10 + 5
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: field1 = %d (expected %d)", result.field1, expected.field1);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Test 2: Conditional branch ---
        action
            $display("=== Test 2: Conditional branch (pktLength=32 < 64 -> port=1) ===");
            testNum <= 2;
            core.loadProgram(test2_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.outputPort = 1;  // 32 < 64, so port = 1
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: outputPort = %d", result.outputPort);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Test 3: Checksum ---
        action
            $display("=== Test 3: CHECKSUM (10 + 20 = 30) ===");
            testNum <= 3;
            core.loadProgram(test3_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.outputPort = 30;  // one's complement of 10+20 = 30 (no carry)
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: checksum result = %d", result.outputPort);
                passCount <= passCount + 1;
            end else begin
                $display("  FAIL: got ", fshow(result));
                $display("        exp ", fshow(expected));
                failCount <= failCount + 1;
            end
        endaction

        // --- Test 4: LOAD/STORE ---
        action
            $display("=== Test 4: LOAD/STORE (field1 + 100) ===");
            testNum <= 4;
            core.loadProgram(test4_program());
            TestMetadata meta = TestMetadata{pktLength:32, field1:10, field2:20, outputPort:0, dropFlag:False};
            TestMetadata expected = meta;
            expected.field1 = 110;  // 10 + 100
            inputFIFO.enq(tuple2(meta, 0));
            expectedFIFO.enq(expected);
        endaction
        action
            let result = outputFIFO.first; outputFIFO.deq;
            let expected = expectedFIFO.first; expectedFIFO.deq;
            if (pack(result) == pack(expected)) begin
                $display("  PASS: field1 = %d (expected %d)", result.field1, expected.field1);
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
            if (failCount == 0)
                $display("ALL TESTS PASSED");
            else
                $display("SOME TESTS FAILED");
            $finish(0);
        endaction
    endseq;

    FSM testFSM <- mkFSM(testSequence);

    rule startOnce (True);
        testFSM.start;
    endrule
endmodule

module mkRiscVActionTestSim(Empty);
    mkRiscVActionTest test <- mkRiscVActionTest;
endmodule
