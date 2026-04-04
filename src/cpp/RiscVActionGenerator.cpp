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

#include "RiscVActionGenerator.h"
#include "ir/ir.h"
#include "frontends/p4/methodInstance.h"
#include "string_utils.h"
#include <cstring>
#include <iomanip>
#include <sstream>
#include "lib/error_catalog.h"

namespace FPGA {

// Utility function to convert a uint32_t instruction to hex string
static std::string instr_to_hex(uint32_t instr) {
    std::stringstream ss;
    ss << "32'h" << std::hex << std::setfill('0') << std::setw(8) << instr;
    return ss.str();
}

// Build the field path for a Member expression chain
// e.g., hdr.ipv4.ttl -> "hdr.ipv4.ttl"
cstring RiscVActionGenerator::buildFieldPath(const IR::Member* member) {
    if (auto innerMember = member->expr->to<IR::Member>()) {
        return buildFieldPath(innerMember) + "." + member->member.toString();
    }
    // Base case: the outermost expression (e.g., "meta" parameter)
    return member->expr->toString() + "." + member->member.toString();
}

// Recursively compute bit offsets for all fields in a struct.
// Bluespec pack() is MSB-first, fields in declaration order from MSB.
// For our purposes, we compute offsets from LSB (bit 0).
void RiscVActionGenerator::computeStructOffsets(
    const IR::Type_StructLike* type, cstring prefix, uint32_t baseOffset) {

    // Calculate total width of this struct
    int totalWidth = type->width_bits();

    // Walk fields in declaration order. In Bluespec pack(), the first
    // field occupies the MSBs. We compute the bit offset from LSB.
    int currentBitFromMSB = 0;
    for (auto field : type->fields) {
        auto fieldType = control->program->typeMap->getType(field, true);
        cstring fieldPath = prefix + "." + field->name.toString();
        int fieldWidth = fieldType->width_bits();

        // Bit offset from LSB = totalWidth - currentBitFromMSB - fieldWidth
        uint32_t bitOffset = baseOffset + (totalWidth - currentBitFromMSB - fieldWidth);

        if (fieldType->is<IR::Type_StructLike>()) {
            computeStructOffsets(fieldType->to<IR::Type_StructLike>(),
                                fieldPath, bitOffset);
        } else {
            fieldOffsets[fieldPath] = FieldInfo{bitOffset,
                                                 static_cast<uint32_t>(fieldWidth),
                                                 fieldPath};
        }

        currentBitFromMSB += fieldWidth;
    }
}

void RiscVActionGenerator::buildFieldOffsetMap() {
    if (fieldMapBuilt) return;

    // Walk the MetadataT structure to compute offsets
    // MetadataT is defined as: struct { Headers hdr; Metadata meta; StandardMetadataT standard_metadata; }
    // We need to find it from the program's type declarations
    for (auto decl : *control->program->program->getDeclarations()) {
        if (auto typeStruct = decl->to<IR::Type_Struct>()) {
            cstring name = typeStruct->name.toString();
            // Compute offsets for all known struct types
            computeStructOffsets(typeStruct, name, 0);
        }
    }

    fieldMapBuilt = true;
}

uint8_t RiscVActionGenerator::getRegister(const IR::Expression* expr) {
    auto it = exprToReg.find(expr);
    if (it != exprToReg.end()) {
        return it->second;
    }

    uint8_t reg = allocateRegister();
    exprToReg[expr] = reg;
    return reg;
}

// Load a constant bit offset into a register
uint8_t RiscVActionGenerator::loadBitOffset(uint32_t bitOffset) {
    uint8_t reg = allocateRegister();
    if (bitOffset >= -2048U && bitOffset <= 2047) {
        instructions.push_back(RiscVInstr::addi(reg, 0, static_cast<int16_t>(bitOffset)));
    } else {
        // Large offset: use LUI + ADDI
        uint32_t upper = (bitOffset + 0x800) >> 12;
        int16_t lower = bitOffset & 0xFFF;
        if (lower & 0x800) lower -= 0x1000;
        instructions.push_back(RiscVInstr::lui(reg, upper << 12));
        if (lower != 0)
            instructions.push_back(RiscVInstr::addi(reg, reg, lower));
    }
    return reg;
}

void RiscVActionGenerator::generateFieldRead(const IR::Member* member) {
    buildFieldOffsetMap();

    cstring fieldPath = buildFieldPath(member);
    uint8_t destReg = getRegister(member);

    auto it = fieldOffsets.find(fieldPath);
    if (it != fieldOffsets.end()) {
        // Load bit offset, then META_ACCESS read
        uint8_t offsetReg = loadBitOffset(it->second.bitOffset);
        instructions.push_back(RiscVInstr::metaRead(destReg, offsetReg));
    } else {
        // Field not found in offset map - try partial match
        // This handles cases where the path prefix differs
        bool found = false;
        for (auto& entry : fieldOffsets) {
            if (entry.first.endsWith(fieldPath) ||
                fieldPath.endsWith(entry.first)) {
                uint8_t offsetReg = loadBitOffset(entry.second.bitOffset);
                instructions.push_back(RiscVInstr::metaRead(destReg, offsetReg));
                found = true;
                break;
            }
        }
        if (!found) {
            // Generate a read at offset 0 as fallback
            P4::warning(ErrorType::WARN_UNINITIALIZED,"RISC-V codegen: unknown field %s, using offset 0", fieldPath);
            uint8_t offsetReg = loadBitOffset(0);
            instructions.push_back(RiscVInstr::metaRead(destReg, offsetReg));
        }
    }
}

void RiscVActionGenerator::generateFieldWrite(const IR::Member* member, uint8_t valueReg) {
    buildFieldOffsetMap();

    cstring fieldPath = buildFieldPath(member);

    auto it = fieldOffsets.find(fieldPath);
    uint32_t bitOffset = 0;
    if (it != fieldOffsets.end()) {
        bitOffset = it->second.bitOffset;
    } else {
        // Try partial match
        for (auto& entry : fieldOffsets) {
            if (entry.first.endsWith(fieldPath) ||
                fieldPath.endsWith(entry.first)) {
                bitOffset = entry.second.bitOffset;
                break;
            }
        }
    }

    uint8_t offsetReg = loadBitOffset(bitOffset);
    instructions.push_back(RiscVInstr::metaWrite(offsetReg, valueReg));
}

bool RiscVActionGenerator::preorder(const IR::AssignmentStatement* stmt) {
    if (stmt->left->is<IR::Member>()) {
        auto member = stmt->left->to<IR::Member>();

        // Evaluate the right-hand side
        if (stmt->right->is<IR::Constant>()) {
            auto constant = stmt->right->to<IR::Constant>();
            uint8_t valReg = allocateRegister();
            generateConstant(constant, valReg);
            generateFieldWrite(member, valReg);
        } else if (stmt->right->is<IR::Operation_Binary>()) {
            auto binary = stmt->right->to<IR::Operation_Binary>();
            generateBinaryOperation(binary);
            uint8_t srcReg = getRegister(binary);
            generateFieldWrite(member, srcReg);
        } else if (stmt->right->is<IR::Member>()) {
            auto rightMember = stmt->right->to<IR::Member>();
            generateFieldRead(rightMember);
            uint8_t srcReg = getRegister(rightMember);
            generateFieldWrite(member, srcReg);
        } else if (stmt->right->is<IR::MethodCallExpression>()) {
            visit(stmt->right);
            uint8_t srcReg = getRegister(stmt->right);
            generateFieldWrite(member, srcReg);
        } else {
            visit(stmt->right);
            uint8_t srcReg = getRegister(stmt->right);
            generateFieldWrite(member, srcReg);
        }
    } else {
        // Non-member left side (local variable)
        uint8_t destReg = getRegister(stmt->left);

        if (stmt->right->is<IR::Constant>()) {
            generateConstant(stmt->right->to<IR::Constant>(), destReg);
        } else if (stmt->right->is<IR::Operation_Binary>()) {
            auto binary = stmt->right->to<IR::Operation_Binary>();
            generateBinaryOperation(binary);
            uint8_t srcReg = getRegister(binary);
            if (srcReg != destReg)
                instructions.push_back(RiscVInstr::addi(destReg, srcReg, 0));
        } else {
            visit(stmt->right);
            uint8_t srcReg = getRegister(stmt->right);
            if (srcReg != destReg)
                instructions.push_back(RiscVInstr::addi(destReg, srcReg, 0));
        }
    }

    return false;
}

bool RiscVActionGenerator::preorder(const IR::IfStatement* stmt) {
    // Evaluate condition into a register
    visit(stmt->condition);
    uint8_t condReg = getRegister(stmt->condition);

    // BEQ condReg, x0, else_label (branch over true body if condition is false)
    size_t branchIdx = instructions.size();
    instructions.push_back(0);  // placeholder for branch

    // Emit true body
    visit(stmt->ifTrue);

    if (stmt->ifFalse) {
        // Jump over else body
        size_t jumpIdx = instructions.size();
        instructions.push_back(0);  // placeholder for jump

        // Patch the conditional branch to jump here (else body start)
        // Offset in instruction count * 2 (to match our PC encoding)
        int16_t elseOffset = static_cast<int16_t>((instructions.size() - branchIdx) * 2);
        instructions[branchIdx] = RiscVInstr::beq(condReg, 0, elseOffset);

        // Emit else body
        visit(stmt->ifFalse);

        // Patch the unconditional jump to skip past else
        int32_t endOffset = static_cast<int32_t>((instructions.size() - jumpIdx) * 2);
        instructions[jumpIdx] = RiscVInstr::jal(0, endOffset);
    } else {
        // No else: just patch the branch
        int16_t skipOffset = static_cast<int16_t>((instructions.size() - branchIdx) * 2);
        instructions[branchIdx] = RiscVInstr::beq(condReg, 0, skipOffset);
    }

    return false;
}

bool RiscVActionGenerator::preorder(const IR::Expression* expression) {
    if (expression->is<IR::Member>()) {
        auto member = expression->to<IR::Member>();
        generateFieldRead(member);
    }
    return false;
}

bool RiscVActionGenerator::preorder(const IR::MethodCallExpression* expression) {
    auto mi = P4::MethodInstance::resolve(expression,
                                         control->program->refMap,
                                         control->program->typeMap);

    if (auto externMethod = mi->to<P4::ExternMethod>()) {
        generateExternMethod(externMethod);
        return false;
    }

    if (auto externFunction = mi->to<P4::ExternFunction>()) {
        generateExternFunction(externFunction);
        return false;
    }

    if (auto action = mi->to<P4::ActionCall>()) {
        // Nested action calls: visit the action body inline
        if (action->action && action->action->body) {
            visit(action->action->body);
        }
        return false;
    }

    return false;
}

void RiscVActionGenerator::generateBinaryOperation(const IR::Operation_Binary* binary) {
    visit(binary->left);
    visit(binary->right);

    uint8_t leftReg = getRegister(binary->left);
    uint8_t rightReg = getRegister(binary->right);
    uint8_t destReg = getRegister(binary);

    if (binary->is<IR::Add>()) {
        instructions.push_back(RiscVInstr::add(destReg, leftReg, rightReg));
    } else if (binary->is<IR::Sub>()) {
        instructions.push_back(RiscVInstr::sub(destReg, leftReg, rightReg));
    } else if (binary->is<IR::Shl>()) {
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SLL, leftReg, rightReg, 0));
    } else if (binary->is<IR::Shr>()) {
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SRL_SRA, leftReg, rightReg, 0));
    } else if (binary->is<IR::BAnd>()) {
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::AND, leftReg, rightReg, 0));
    } else if (binary->is<IR::BOr>()) {
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::OR, leftReg, rightReg, 0));
    } else if (binary->is<IR::BXor>()) {
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::XOR, leftReg, rightReg, 0));
    } else if (binary->is<IR::LAnd>()) {
        // Logical AND: both operands nonzero
        // SLTU t1, x0, left (t1 = left != 0)
        // SLTU t2, x0, right (t2 = right != 0)
        // AND dest, t1, t2
        uint8_t t1 = allocateRegister();
        uint8_t t2 = allocateRegister();
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, t1, RiscVInstr::SLTU, 0, leftReg, 0));
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, t2, RiscVInstr::SLTU, 0, rightReg, 0));
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::AND, t1, t2, 0));
    } else if (binary->is<IR::LOr>()) {
        // Logical OR: either operand nonzero
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::OR, leftReg, rightReg, 0));
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SLTU, 0, destReg, 0));
    } else if (binary->is<IR::Equ>()) {
        // Equal: XOR then SLTIU 1 (result is 1 if XOR==0)
        uint8_t tempReg = allocateRegister();
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, tempReg, RiscVInstr::XOR, leftReg, rightReg, 0));
        instructions.push_back(RiscVInstr::encodeIType(
            RiscVInstr::OP_IMM, destReg, RiscVInstr::SLTU, tempReg, 1));
    } else if (binary->is<IR::Neq>()) {
        // Not equal: XOR then SLTU(x0, temp) (result is 1 if XOR!=0)
        uint8_t tempReg = allocateRegister();
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, tempReg, RiscVInstr::XOR, leftReg, rightReg, 0));
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SLTU, 0, tempReg, 0));
    } else if (binary->is<IR::Lss>()) {
        // Less than (signed)
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SLT, leftReg, rightReg, 0));
    } else if (binary->is<IR::Grt>()) {
        // Greater than: SLT with swapped operands
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, destReg, RiscVInstr::SLT, rightReg, leftReg, 0));
    } else if (binary->is<IR::Leq>()) {
        // Less or equal: !(b < a)
        uint8_t tempReg = allocateRegister();
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, tempReg, RiscVInstr::SLT, rightReg, leftReg, 0));
        // NOT: XORI with 1
        instructions.push_back(RiscVInstr::xori(destReg, tempReg, 1));
    } else if (binary->is<IR::Geq>()) {
        // Greater or equal: !(a < b)
        uint8_t tempReg = allocateRegister();
        instructions.push_back(RiscVInstr::encodeRType(
            RiscVInstr::OP, tempReg, RiscVInstr::SLT, leftReg, rightReg, 0));
        instructions.push_back(RiscVInstr::xori(destReg, tempReg, 1));
    } else {
        // Fallback: treat as ADD
        instructions.push_back(RiscVInstr::add(destReg, leftReg, rightReg));
    }
}

void RiscVActionGenerator::generateUnaryOperation(const IR::Operation_Unary* unary) {
    visit(unary->expr);

    uint8_t srcReg = getRegister(unary->expr);
    uint8_t destReg = getRegister(unary);

    if (unary->is<IR::Neg>()) {
        instructions.push_back(RiscVInstr::sub(destReg, 0, srcReg));
    } else if (unary->is<IR::Cmpl>()) {
        instructions.push_back(RiscVInstr::xori(destReg, srcReg, -1));
    } else if (unary->is<IR::LNot>()) {
        // Logical NOT: SLTIU srcReg, 1
        instructions.push_back(RiscVInstr::encodeIType(
            RiscVInstr::OP_IMM, destReg, RiscVInstr::SLTU, srcReg, 1));
    } else {
        if (srcReg != destReg)
            instructions.push_back(RiscVInstr::addi(destReg, srcReg, 0));
    }
}

void RiscVActionGenerator::generateConstant(const IR::Constant* constant, uint8_t destReg) {
    int64_t value = constant->asInt();

    if (value >= -2048 && value <= 2047) {
        instructions.push_back(RiscVInstr::addi(destReg, 0, static_cast<int16_t>(value)));
    } else {
        // LUI + ADDI for larger values
        uint32_t upper = (static_cast<uint32_t>(value) + 0x800) >> 12;
        int16_t lower = value & 0xFFF;
        if (lower & 0x800) lower -= 0x1000;
        instructions.push_back(RiscVInstr::lui(destReg, upper << 12));
        if (lower != 0)
            instructions.push_back(RiscVInstr::addi(destReg, destReg, lower));
    }
}

void RiscVActionGenerator::generateExternMethod(const P4::ExternMethod* externMethod) {
    cstring methodName = externMethod->method->name.toString();
    uint8_t destReg = getRegister(externMethod->expr);

    if (methodName == "read") {
        // Register/counter read: use META_ACCESS to read from extern storage area
        // The actual extern ID and index would come from the method arguments
        uint8_t offsetReg = loadBitOffset(0);  // placeholder offset
        instructions.push_back(RiscVInstr::metaRead(destReg, offsetReg));
    } else if (methodName == "write") {
        // Register/counter write
        uint8_t offsetReg = loadBitOffset(0);  // placeholder offset
        uint8_t valueReg = allocateRegister();
        instructions.push_back(RiscVInstr::addi(valueReg, 0, 0));  // placeholder value
        instructions.push_back(RiscVInstr::metaWrite(offsetReg, valueReg));
    }
}

void RiscVActionGenerator::generateExternFunction(const P4::ExternFunction* externFunction) {
    cstring functionName = externFunction->method->name.toString();

    if (functionName == "mark_to_drop") {
        // Set drop flag in standard_metadata
        // Look up the egress_spec field offset and set to DROP_PORT (511)
        buildFieldOffsetMap();

        // Find standard_metadata.egress_spec and set to 511 (drop)
        uint8_t dropValReg = allocateRegister();
        instructions.push_back(RiscVInstr::addi(dropValReg, 0, 511));

        // Try to find the egress_spec field
        for (auto& entry : fieldOffsets) {
            if (entry.first.find("egress_spec") != nullptr) {
                uint8_t offsetReg = loadBitOffset(entry.second.bitOffset);
                instructions.push_back(RiscVInstr::metaWrite(offsetReg, dropValReg));
                return;
            }
        }

        // Fallback: write to offset 0
        uint8_t offsetReg = loadBitOffset(0);
        instructions.push_back(RiscVInstr::metaWrite(offsetReg, dropValReg));
    }
}

void RiscVActionGenerator::generateRiscVAction(const IR::P4Action* action) {
    instructions.clear();
    resetRegisters();
    buildFieldOffsetMap();

    // Process the action body
    if (action->body) {
        if (auto block = action->body->to<IR::BlockStatement>()) {
            for (auto s : block->components) {
                visit(s);
            }
        }
    }

    // Terminator instruction (all zeros)
    instructions.push_back(0);

    emitRiscVActionEngine(action);
}

void RiscVActionGenerator::emitRiscVActionEngine(const IR::P4Action* action) {
    cstring name = nameFromAnnotation(action, action->name);
    cstring type = CamelCase(name);

    const IR::P4Table* table = control->action_to_table[name];
    if (table == nullptr) {
        P4::error(ErrorType::ERR_UNEXPECTED,"unable to find table from action %1%", name);
        return;
    }

    cstring table_name = nameFromAnnotation(table, table->name);
    cstring table_type = CamelCase(table_name);

    CodeBuilder* builder = &bsv.getControlBuilder();

    // Generate program vector
    builder->append_line("// RISC-V program for action %s (%d instructions)", name,
                         static_cast<int>(instructions.size()));
    builder->append_line("Vector#(256, Bit#(32)) %s_program = replicate(0);", name);

    // Only emit non-zero instructions
    for (size_t i = 0; i < instructions.size(); i++) {
        if (instructions[i] != 0) {
            builder->append_line("%s_program[%d] = %s;", name,
                                static_cast<int>(i), instr_to_hex(instructions[i]).c_str());
        }
    }
    builder->newline();

    // Create the RISC-V action engine instance
    builder->append_line("typedef Engine#(1, MetadataRequest, %sParam) %sAction;", table_type, type);
    builder->append_line("module mk%sAction(Server#(Tuple2#(MetadataRequest, %sParam), MetadataRequest));",
                         type, table_type);
    builder->incr_indent();
    builder->append_line("let rv_engine <- mkRiscVActionEngine(%s_program);", name);
    builder->append_line("return rv_engine.prev_control_state;");
    builder->decr_indent();
    builder->append_line("endmodule");
    builder->newline();
}

void RiscVActionGenerator::postorder(const IR::P4Action* action) {
    generateRiscVAction(action);
}

} // namespace FPGA
