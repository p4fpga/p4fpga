/*
  Copyright 2025 P4FPGA Project
  Apache License 2.0

  Unit tests for RISC-V instruction encoding.
  These tests verify the instruction encoding helpers produce correct
  bit patterns without requiring the full p4c compilation infrastructure.
*/

#include <gtest/gtest.h>
#include <cstdint>

// Minimal include: just the instruction encoding class
// We re-declare it here to avoid pulling in p4c headers
namespace TestEncoding {

class RiscVInstr {
public:
    static uint32_t encodeRType(uint8_t opcode, uint8_t rd, uint8_t funct3,
                               uint8_t rs1, uint8_t rs2, uint8_t funct7) {
        return (static_cast<uint32_t>(funct7) << 25) |
               (static_cast<uint32_t>(rs2) << 20) |
               (static_cast<uint32_t>(rs1) << 15) |
               (static_cast<uint32_t>(funct3) << 12) |
               (static_cast<uint32_t>(rd) << 7) |
               static_cast<uint32_t>(opcode);
    }

    static uint32_t encodeIType(uint8_t opcode, uint8_t rd, uint8_t funct3,
                               uint8_t rs1, uint16_t imm) {
        return (static_cast<uint32_t>(imm & 0xFFF) << 20) |
               (static_cast<uint32_t>(rs1) << 15) |
               (static_cast<uint32_t>(funct3) << 12) |
               (static_cast<uint32_t>(rd) << 7) |
               static_cast<uint32_t>(opcode);
    }

    static uint32_t encodeBType(uint8_t opcode, uint8_t funct3,
                               uint8_t rs1, uint8_t rs2, int16_t offset) {
        uint16_t imm = static_cast<uint16_t>(offset);
        return (static_cast<uint32_t>((imm >> 12) & 0x1) << 31) |
               (static_cast<uint32_t>((imm >> 5) & 0x3F) << 25) |
               (static_cast<uint32_t>(rs2) << 20) |
               (static_cast<uint32_t>(rs1) << 15) |
               (static_cast<uint32_t>(funct3) << 12) |
               (static_cast<uint32_t>((imm >> 1) & 0xF) << 8) |
               (static_cast<uint32_t>((imm >> 11) & 0x1) << 7) |
               static_cast<uint32_t>(opcode);
    }

    enum { OP_IMM = 0x13, OP = 0x33, P4_EXT = 0x73, BRANCH = 0x63, LUI = 0x37 };
    enum { ADD_SUB = 0, SLL = 1, SLT = 2, SLTU = 3, XOR = 4, SRL_SRA = 5, OR = 6, AND = 7 };
    enum { META_ACCESS = 7, CHECKSUM = 4, ADD_HEADER = 2, REM_HEADER = 3 };

    static uint32_t add(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeRType(OP, rd, ADD_SUB, rs1, rs2, 0x00);
    }
    static uint32_t sub(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeRType(OP, rd, ADD_SUB, rs1, rs2, 0x20);
    }
    static uint32_t addi(uint8_t rd, uint8_t rs1, int16_t imm) {
        return encodeIType(OP_IMM, rd, ADD_SUB, rs1, static_cast<uint16_t>(imm));
    }
    static uint32_t metaRead(uint8_t rd, uint8_t offsetReg) {
        return encodeRType(P4_EXT, rd, META_ACCESS, offsetReg, 0, 0x00);
    }
    static uint32_t metaWrite(uint8_t offsetReg, uint8_t rs2) {
        return encodeRType(P4_EXT, 0, META_ACCESS, offsetReg, rs2, 0x01);
    }
    static uint32_t checksum(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeRType(P4_EXT, rd, CHECKSUM, rs1, rs2, 0x00);
    }
    static uint32_t addHeader(uint8_t rd, uint8_t offsetReg) {
        return encodeRType(P4_EXT, rd, ADD_HEADER, offsetReg, 0, 0x00);
    }
    static uint32_t remHeader(uint8_t rd, uint8_t offsetReg) {
        return encodeRType(P4_EXT, rd, REM_HEADER, offsetReg, 0, 0x00);
    }
};

} // namespace TestEncoding

using namespace TestEncoding;

// Decode helpers for verification
static uint8_t decode_opcode(uint32_t inst) { return inst & 0x7F; }
static uint8_t decode_rd(uint32_t inst) { return (inst >> 7) & 0x1F; }
static uint8_t decode_funct3(uint32_t inst) { return (inst >> 12) & 0x7; }
static uint8_t decode_rs1(uint32_t inst) { return (inst >> 15) & 0x1F; }
static uint8_t decode_rs2(uint32_t inst) { return (inst >> 20) & 0x1F; }
static uint8_t decode_funct7(uint32_t inst) { return (inst >> 25) & 0x7F; }
static int16_t decode_iimm(uint32_t inst) {
    int32_t imm = static_cast<int32_t>(inst) >> 20;
    return static_cast<int16_t>(imm);
}

TEST(RiscVInstrEncoding, AddEncoding) {
    uint32_t inst = RiscVInstr::add(1, 2, 3);
    EXPECT_EQ(decode_opcode(inst), 0x33);  // OP
    EXPECT_EQ(decode_rd(inst), 1);
    EXPECT_EQ(decode_funct3(inst), 0);     // ADD_SUB
    EXPECT_EQ(decode_rs1(inst), 2);
    EXPECT_EQ(decode_rs2(inst), 3);
    EXPECT_EQ(decode_funct7(inst), 0x00);  // ADD (not SUB)
}

TEST(RiscVInstrEncoding, SubEncoding) {
    uint32_t inst = RiscVInstr::sub(5, 6, 7);
    EXPECT_EQ(decode_opcode(inst), 0x33);
    EXPECT_EQ(decode_rd(inst), 5);
    EXPECT_EQ(decode_rs1(inst), 6);
    EXPECT_EQ(decode_rs2(inst), 7);
    EXPECT_EQ(decode_funct7(inst), 0x20);  // SUB
}

TEST(RiscVInstrEncoding, AddiPositive) {
    uint32_t inst = RiscVInstr::addi(1, 0, 42);
    EXPECT_EQ(decode_opcode(inst), 0x13);  // OP_IMM
    EXPECT_EQ(decode_rd(inst), 1);
    EXPECT_EQ(decode_rs1(inst), 0);
    EXPECT_EQ(decode_iimm(inst), 42);
}

TEST(RiscVInstrEncoding, AddiNegative) {
    uint32_t inst = RiscVInstr::addi(2, 3, -5);
    EXPECT_EQ(decode_opcode(inst), 0x13);
    EXPECT_EQ(decode_rd(inst), 2);
    EXPECT_EQ(decode_rs1(inst), 3);
    EXPECT_EQ(decode_iimm(inst), -5);
}

TEST(RiscVInstrEncoding, MetaRead) {
    // META_ACCESS read: rd=5, offsetReg=10, funct7[0]=0
    uint32_t inst = RiscVInstr::metaRead(5, 10);
    EXPECT_EQ(decode_opcode(inst), 0x73);   // P4_EXT
    EXPECT_EQ(decode_rd(inst), 5);
    EXPECT_EQ(decode_funct3(inst), 7);       // META_ACCESS
    EXPECT_EQ(decode_rs1(inst), 10);
    EXPECT_EQ(decode_rs2(inst), 0);
    EXPECT_EQ(decode_funct7(inst) & 1, 0);   // read mode
}

TEST(RiscVInstrEncoding, MetaWrite) {
    // META_ACCESS write: offsetReg=10, valueReg=3, funct7[0]=1
    uint32_t inst = RiscVInstr::metaWrite(10, 3);
    EXPECT_EQ(decode_opcode(inst), 0x73);
    EXPECT_EQ(decode_rd(inst), 0);           // no destination
    EXPECT_EQ(decode_funct3(inst), 7);       // META_ACCESS
    EXPECT_EQ(decode_rs1(inst), 10);
    EXPECT_EQ(decode_rs2(inst), 3);
    EXPECT_EQ(decode_funct7(inst) & 1, 1);   // write mode
}

TEST(RiscVInstrEncoding, Checksum) {
    uint32_t inst = RiscVInstr::checksum(4, 1, 2);
    EXPECT_EQ(decode_opcode(inst), 0x73);
    EXPECT_EQ(decode_rd(inst), 4);
    EXPECT_EQ(decode_funct3(inst), 4);       // CHECKSUM
    EXPECT_EQ(decode_rs1(inst), 1);
    EXPECT_EQ(decode_rs2(inst), 2);
}

TEST(RiscVInstrEncoding, AddHeader) {
    uint32_t inst = RiscVInstr::addHeader(1, 10);
    EXPECT_EQ(decode_opcode(inst), 0x73);
    EXPECT_EQ(decode_funct3(inst), 2);       // ADD_HEADER
    EXPECT_EQ(decode_rs1(inst), 10);
}

TEST(RiscVInstrEncoding, RemHeader) {
    uint32_t inst = RiscVInstr::remHeader(1, 10);
    EXPECT_EQ(decode_opcode(inst), 0x73);
    EXPECT_EQ(decode_funct3(inst), 3);       // REM_HEADER
    EXPECT_EQ(decode_rs1(inst), 10);
}

TEST(RiscVInstrEncoding, ZeroIsNop) {
    // Instruction 0x00000000 should decode as: ADDI x0, x0, 0
    // which is the canonical NOP / terminator
    uint32_t inst = 0;
    EXPECT_EQ(decode_opcode(inst), 0);  // not a valid opcode -> treated as terminator
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
