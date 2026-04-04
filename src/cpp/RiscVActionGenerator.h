/*
  Copyright 2025 P4FPGA Project

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0


  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_RISCV_ACTION_GENERATOR_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_RISCV_ACTION_GENERATOR_H_

#include <vector>
#include <map>
#include <string>
#include <cstdint>
#include "ir/ir.h"
#include "frontends/p4/methodInstance.h"
#include "control.h"

namespace FPGA {

// Metadata field layout information
struct FieldInfo {
    uint32_t bitOffset;
    uint32_t bitWidth;
    cstring fullPath;  // e.g., "hdr.ethernet.dstAddr"
};

/**
 * RISC-V instruction encoding
 */
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

    static uint32_t encodeSType(uint8_t opcode, uint8_t funct3,
                               uint8_t rs1, uint8_t rs2, uint16_t imm) {
        return (static_cast<uint32_t>((imm >> 5) & 0x7F) << 25) |
               (static_cast<uint32_t>(rs2) << 20) |
               (static_cast<uint32_t>(rs1) << 15) |
               (static_cast<uint32_t>(funct3) << 12) |
               (static_cast<uint32_t>(imm & 0x1F) << 7) |
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

    static uint32_t encodeUType(uint8_t opcode, uint8_t rd, uint32_t imm) {
        return (imm & 0xFFFFF000) |
               (static_cast<uint32_t>(rd) << 7) |
               static_cast<uint32_t>(opcode);
    }

    static uint32_t encodeJType(uint8_t opcode, uint8_t rd, int32_t offset) {
        uint32_t imm = static_cast<uint32_t>(offset);
        return (static_cast<uint32_t>((imm >> 20) & 0x1) << 31) |
               (static_cast<uint32_t>((imm >> 1) & 0x3FF) << 21) |
               (static_cast<uint32_t>((imm >> 11) & 0x1) << 20) |
               (static_cast<uint32_t>((imm >> 12) & 0xFF) << 12) |
               (static_cast<uint32_t>(rd) << 7) |
               static_cast<uint32_t>(opcode);
    }

    // P4 custom extension format (similar to R-type)
    static uint32_t encodeP4Ext(uint8_t rd, uint8_t funct3,
                               uint8_t rs1, uint8_t rs2, uint8_t funct7) {
        return encodeRType(P4_EXT, rd, funct3, rs1, rs2, funct7);
    }

    // Standard RISC-V opcodes
    enum Opcode {
        OP_IMM     = 0x13, // I-type ALU operations with immediate
        OP         = 0x33, // R-type ALU operations
        LOAD       = 0x03, // Load operations
        STORE      = 0x23, // Store operations
        BRANCH     = 0x63, // Branch operations
        LUI        = 0x37, // Load upper immediate
        AUIPC      = 0x17, // Add upper immediate to PC
        JAL        = 0x6F, // Jump and link
        JALR       = 0x67, // Jump and link register
        P4_EXT     = 0x73  // Custom P4 extensions
    };

    // RISC-V R-type function codes (funct3)
    enum Funct3 {
        ADD_SUB = 0x0, // ADD or SUB based on funct7
        SLL     = 0x1, // Shift left logical
        SLT     = 0x2, // Set less than
        SLTU    = 0x3, // Set less than unsigned
        XOR     = 0x4, // Bitwise XOR
        SRL_SRA = 0x5, // Shift right logical or arithmetic based on funct7
        OR      = 0x6, // Bitwise OR
        AND     = 0x7  // Bitwise AND
    };

    // Custom P4 extension operations (using funct3 field)
    enum P4ExtFunct3 {
        EXT_FIELD   = 0x0, // Extract bit field
        INS_FIELD   = 0x1, // Insert bit field
        ADD_HEADER  = 0x2, // Add header
        REM_HEADER  = 0x3, // Remove header
        CHECKSUM    = 0x4, // Calculate checksum
        TBL_LOOKUP  = 0x5, // Table lookup
        PKT_MODIFY  = 0x6, // Packet modification
        META_ACCESS = 0x7  // Metadata access
    };

    // Helper functions to generate common instructions
    static uint32_t add(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeRType(OP, rd, ADD_SUB, rs1, rs2, 0x00);
    }

    static uint32_t sub(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeRType(OP, rd, ADD_SUB, rs1, rs2, 0x20);
    }

    static uint32_t addi(uint8_t rd, uint8_t rs1, int16_t imm) {
        return encodeIType(OP_IMM, rd, ADD_SUB, rs1, static_cast<uint16_t>(imm));
    }

    static uint32_t andi(uint8_t rd, uint8_t rs1, int16_t imm) {
        return encodeIType(OP_IMM, rd, AND, rs1, static_cast<uint16_t>(imm));
    }

    static uint32_t ori(uint8_t rd, uint8_t rs1, int16_t imm) {
        return encodeIType(OP_IMM, rd, OR, rs1, static_cast<uint16_t>(imm));
    }

    static uint32_t xori(uint8_t rd, uint8_t rs1, int16_t imm) {
        return encodeIType(OP_IMM, rd, XOR, rs1, static_cast<uint16_t>(imm));
    }

    static uint32_t slli(uint8_t rd, uint8_t rs1, uint8_t shamt) {
        return encodeIType(OP_IMM, rd, SLL, rs1, shamt & 0x1F);
    }

    static uint32_t srli(uint8_t rd, uint8_t rs1, uint8_t shamt) {
        return encodeIType(OP_IMM, rd, SRL_SRA, rs1, shamt & 0x1F);
    }

    static uint32_t beq(uint8_t rs1, uint8_t rs2, int16_t offset) {
        return encodeBType(BRANCH, 0x0, rs1, rs2, offset);
    }

    static uint32_t bne(uint8_t rs1, uint8_t rs2, int16_t offset) {
        return encodeBType(BRANCH, 0x1, rs1, rs2, offset);
    }

    static uint32_t blt(uint8_t rs1, uint8_t rs2, int16_t offset) {
        return encodeBType(BRANCH, 0x4, rs1, rs2, offset);
    }

    static uint32_t bge(uint8_t rs1, uint8_t rs2, int16_t offset) {
        return encodeBType(BRANCH, 0x5, rs1, rs2, offset);
    }

    static uint32_t jal(uint8_t rd, int32_t offset) {
        return encodeJType(JAL, rd, offset);
    }

    static uint32_t jalr(uint8_t rd, uint8_t rs1, int16_t offset) {
        return encodeIType(JALR, rd, 0x0, rs1, static_cast<uint16_t>(offset));
    }

    static uint32_t lui(uint8_t rd, uint32_t imm) {
        return encodeUType(LUI, rd, imm);
    }

    // P4 custom instructions

    // META_ACCESS read: rd = metaBits[offsetReg +: 32]
    // funct7[0] = 0 for read
    static uint32_t metaRead(uint8_t rd, uint8_t offsetReg) {
        return encodeP4Ext(rd, META_ACCESS, offsetReg, 0, 0x00);
    }

    // META_ACCESS write: metaBits[offsetReg +: 32] = rs2
    // funct7[0] = 1 for write
    static uint32_t metaWrite(uint8_t offsetReg, uint8_t rs2) {
        return encodeP4Ext(0, META_ACCESS, offsetReg, rs2, 0x01);
    }

    // ADD_HEADER: set header state to Forward at bit offset in rs1
    static uint32_t addHeader(uint8_t rd, uint8_t offsetReg) {
        return encodeP4Ext(rd, ADD_HEADER, offsetReg, 0, 0x00);
    }

    // REM_HEADER: set header state to NotPresent at bit offset in rs1
    static uint32_t remHeader(uint8_t rd, uint8_t offsetReg) {
        return encodeP4Ext(rd, REM_HEADER, offsetReg, 0, 0x00);
    }

    // CHECKSUM: one's complement add
    static uint32_t checksum(uint8_t rd, uint8_t rs1, uint8_t rs2) {
        return encodeP4Ext(rd, CHECKSUM, rs1, rs2, 0x00);
    }
};

/**
 * RISC-V action program generator
 *
 * Translates P4 action bodies into RISC-V instruction sequences.
 * Metadata fields are accessed via META_ACCESS custom instructions
 * using bit offsets computed from the P4 type layout.
 */
class RiscVActionGenerator : public Inspector {
public:
    RiscVActionGenerator(FPGAControl* control, BSVProgram& bsv) :
        control(control), bsv(bsv), currentReg(1) {}

    bool preorder(const IR::AssignmentStatement* stmt) override;
    bool preorder(const IR::IfStatement* stmt) override;
    bool preorder(const IR::Expression* expression) override;
    bool preorder(const IR::MethodCallExpression* expression) override;
    void postorder(const IR::P4Action* action) override;

    // Generate RISC-V assembly for an action
    void generateRiscVAction(const IR::P4Action* action);

    // Build the field offset map from the program's type information
    void buildFieldOffsetMap();

private:
    FPGAControl* control;
    BSVProgram& bsv;
    std::vector<uint32_t> instructions;
    std::map<const IR::Expression*, uint8_t> exprToReg;
    uint8_t currentReg;

    // Field offset map: field path -> bit offset and width
    std::map<cstring, FieldInfo> fieldOffsets;
    bool fieldMapBuilt = false;

    // Get a register for an expression, allocating a new one if needed
    uint8_t getRegister(const IR::Expression* expr);

    // Get next available register
    uint8_t allocateRegister() {
        if (currentReg >= 31) {
            currentReg = 1;  // wrap around (basic strategy)
        }
        return currentReg++;
    }

    // Reset register allocation for new action
    void resetRegisters() {
        exprToReg.clear();
        currentReg = 1;
    }

    // Build the path string for a Member expression (e.g., "hdr.ipv4.ttl")
    cstring buildFieldPath(const IR::Member* member);

    // Recursively compute field offsets for a struct type
    void computeStructOffsets(const IR::Type_StructLike* type,
                              cstring prefix, uint32_t baseOffset);

    // Emit instructions to load a bit offset into a register
    uint8_t loadBitOffset(uint32_t bitOffset);

    // Generate code for different expression types
    void generateBinaryOperation(const IR::Operation_Binary* binary);
    void generateUnaryOperation(const IR::Operation_Unary* unary);
    void generateConstant(const IR::Constant* constant, uint8_t destReg);
    void generateFieldRead(const IR::Member* member);
    void generateFieldWrite(const IR::Member* member, uint8_t valueReg);
    void generateExternMethod(const P4::ExternMethod* externMethod);
    void generateExternFunction(const P4::ExternFunction* externFunction);

    // Generate Bluespec code to instantiate the RISC-V action engine
    void emitRiscVActionEngine(const IR::P4Action* action);
};

} // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_RISCV_ACTION_GENERATOR_H_ */
