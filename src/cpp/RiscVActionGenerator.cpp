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

static std::string instr_to_hex(uint32_t instr) {
    std::stringstream ss;
    ss << "32'h" << std::hex << std::setfill('0') << std::setw(8) << instr;
    return ss.str();
}

// --- VLIW Scheduler ---
// Packs tagged instructions into VLIW words by phase order:
//   SETUP words -> READ words -> COMPUTE words -> WRITE words -> CONTROL words
void RiscVActionGenerator::scheduleVLIW() {
    vliwProgram.clear();

    // Collect instructions by phase
    std::vector<uint32_t> phases[5];
    for (auto& ti : taggedInstrs) {
        phases[static_cast<int>(ti.phase)].push_back(ti.encoding);
    }

    // Pack each phase into VLIW words (8 slots each)
    InstrPhase order[] = {InstrPhase::SETUP, InstrPhase::READ,
                          InstrPhase::COMPUTE, InstrPhase::WRITE,
                          InstrPhase::CONTROL};
    for (auto phase : order) {
        auto& instrs = phases[static_cast<int>(phase)];
        for (size_t i = 0; i < instrs.size(); i += VLIW_SLOTS) {
            VLIWWord word;
            word.fill(RV_NOP);
            for (int j = 0; j < VLIW_SLOTS && (i + j) < instrs.size(); j++) {
                word[j] = instrs[i + j];
            }
            vliwProgram.push_back(word);
        }
    }

    // Add terminator word (all zeros)
    VLIWWord terminator;
    terminator.fill(0);
    vliwProgram.push_back(terminator);
}

// --- Field offset map ---

cstring RiscVActionGenerator::buildFieldPath(const IR::Member* member) {
    if (auto innerMember = member->expr->to<IR::Member>()) {
        return buildFieldPath(innerMember) + "." + member->member.toString();
    }
    return member->expr->toString() + "." + member->member.toString();
}

void RiscVActionGenerator::computeStructOffsets(
    const IR::Type_StructLike* type, cstring prefix, uint32_t baseOffset) {
    int totalWidth = type->width_bits();
    int currentBitFromMSB = 0;
    for (auto field : type->fields) {
        auto fieldType = control->program->typeMap->getType(field, true);
        cstring fieldPath = prefix + "." + field->name.toString();
        int fieldWidth = fieldType->width_bits();
        uint32_t bitOffset = baseOffset + (totalWidth - currentBitFromMSB - fieldWidth);

        if (fieldType->is<IR::Type_StructLike>()) {
            computeStructOffsets(fieldType->to<IR::Type_StructLike>(), fieldPath, bitOffset);
        } else {
            fieldOffsets[fieldPath] = FieldInfo{bitOffset, static_cast<uint32_t>(fieldWidth), fieldPath};
        }
        currentBitFromMSB += fieldWidth;
    }
}

void RiscVActionGenerator::buildFieldOffsetMap() {
    if (fieldMapBuilt) return;
    for (auto decl : *control->program->program->getDeclarations()) {
        if (auto typeStruct = decl->to<IR::Type_Struct>()) {
            computeStructOffsets(typeStruct, typeStruct->name.toString(), 0);
        }
    }
    fieldMapBuilt = true;
}

// --- Register allocation ---

uint8_t RiscVActionGenerator::getRegister(const IR::Expression* expr) {
    auto it = exprToReg.find(expr);
    if (it != exprToReg.end()) return it->second;
    uint8_t reg = allocateRegister();
    exprToReg[expr] = reg;
    return reg;
}

uint8_t RiscVActionGenerator::loadBitOffset(uint32_t bitOffset) {
    uint8_t reg = allocateRegister();
    if (bitOffset <= 2047) {
        emit(RiscVInstr::addi(reg, 0, static_cast<int16_t>(bitOffset)), InstrPhase::SETUP);
    } else {
        uint32_t upper = (bitOffset + 0x800) >> 12;
        int16_t lower = bitOffset & 0xFFF;
        if (lower & 0x800) lower -= 0x1000;
        emit(RiscVInstr::lui(reg, upper << 12), InstrPhase::SETUP);
        if (lower != 0)
            emit(RiscVInstr::addi(reg, reg, lower), InstrPhase::SETUP);
    }
    return reg;
}

// --- Field access ---

void RiscVActionGenerator::generateFieldRead(const IR::Member* member) {
    buildFieldOffsetMap();
    cstring fieldPath = buildFieldPath(member);
    uint8_t destReg = getRegister(member);

    uint32_t bitOffset = 0;
    auto it = fieldOffsets.find(fieldPath);
    if (it != fieldOffsets.end()) {
        bitOffset = it->second.bitOffset;
    } else {
        for (auto& entry : fieldOffsets) {
            if (entry.first.endsWith(fieldPath) || fieldPath.endsWith(entry.first)) {
                bitOffset = entry.second.bitOffset;
                break;
            }
        }
    }

    uint8_t offsetReg = loadBitOffset(bitOffset);
    emit(RiscVInstr::metaRead(destReg, offsetReg), InstrPhase::READ);
}

void RiscVActionGenerator::generateFieldWrite(const IR::Member* member, uint8_t valueReg) {
    buildFieldOffsetMap();
    cstring fieldPath = buildFieldPath(member);

    uint32_t bitOffset = 0;
    auto it = fieldOffsets.find(fieldPath);
    if (it != fieldOffsets.end()) {
        bitOffset = it->second.bitOffset;
    } else {
        for (auto& entry : fieldOffsets) {
            if (entry.first.endsWith(fieldPath) || fieldPath.endsWith(entry.first)) {
                bitOffset = entry.second.bitOffset;
                break;
            }
        }
    }

    uint8_t offsetReg = loadBitOffset(bitOffset);
    emit(RiscVInstr::metaWrite(offsetReg, valueReg), InstrPhase::WRITE);
}

// --- Statement visitors ---

bool RiscVActionGenerator::preorder(const IR::AssignmentStatement* stmt) {
    if (stmt->left->is<IR::Member>()) {
        auto member = stmt->left->to<IR::Member>();

        if (stmt->right->is<IR::Constant>()) {
            uint8_t valReg = allocateRegister();
            generateConstant(stmt->right->to<IR::Constant>(), valReg);
            generateFieldWrite(member, valReg);
        } else if (stmt->right->is<IR::Operation_Binary>()) {
            auto binary = stmt->right->to<IR::Operation_Binary>();
            generateBinaryOperation(binary);
            generateFieldWrite(member, getRegister(binary));
        } else if (stmt->right->is<IR::Member>()) {
            auto rightMember = stmt->right->to<IR::Member>();
            generateFieldRead(rightMember);
            generateFieldWrite(member, getRegister(rightMember));
        } else if (stmt->right->is<IR::MethodCallExpression>()) {
            visit(stmt->right);
            generateFieldWrite(member, getRegister(stmt->right));
        } else {
            visit(stmt->right);
            generateFieldWrite(member, getRegister(stmt->right));
        }
    } else {
        uint8_t destReg = getRegister(stmt->left);
        if (stmt->right->is<IR::Constant>()) {
            generateConstant(stmt->right->to<IR::Constant>(), destReg);
        } else if (stmt->right->is<IR::Operation_Binary>()) {
            auto binary = stmt->right->to<IR::Operation_Binary>();
            generateBinaryOperation(binary);
            uint8_t srcReg = getRegister(binary);
            if (srcReg != destReg)
                emit(RiscVInstr::addi(destReg, srcReg, 0), InstrPhase::COMPUTE);
        } else {
            visit(stmt->right);
            uint8_t srcReg = getRegister(stmt->right);
            if (srcReg != destReg)
                emit(RiscVInstr::addi(destReg, srcReg, 0), InstrPhase::COMPUTE);
        }
    }
    return false;
}

bool RiscVActionGenerator::preorder(const IR::IfStatement* stmt) {
    // For VLIW, branches go in CONTROL phase
    visit(stmt->condition);
    uint8_t condReg = getRegister(stmt->condition);

    // Emit as scalar branch sequence (occupies slot 0 of control words)
    // BEQ condReg, x0, skip_true_body
    // This is simplified: complex if/else in VLIW would need multiple passes
    // For now, we linearize: condition in compute phase, then branch
    emit(RiscVInstr::beq(condReg, 0, 4), InstrPhase::CONTROL);  // skip 2 VLIW words

    visit(stmt->ifTrue);

    if (stmt->ifFalse) {
        emit(RiscVInstr::jal(0, 4), InstrPhase::CONTROL);  // skip else
        visit(stmt->ifFalse);
    }

    return false;
}

bool RiscVActionGenerator::preorder(const IR::Expression* expression) {
    if (expression->is<IR::Member>()) {
        generateFieldRead(expression->to<IR::Member>());
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
        if (action->action && action->action->body)
            visit(action->action->body);
        return false;
    }
    return false;
}

// --- Code generation helpers ---

void RiscVActionGenerator::generateBinaryOperation(const IR::Operation_Binary* binary) {
    visit(binary->left);
    visit(binary->right);

    uint8_t leftReg = getRegister(binary->left);
    uint8_t rightReg = getRegister(binary->right);
    uint8_t destReg = getRegister(binary);

    if (binary->is<IR::Add>()) {
        emit(RiscVInstr::add(destReg, leftReg, rightReg), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Sub>()) {
        emit(RiscVInstr::sub(destReg, leftReg, rightReg), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Shl>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SLL, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Shr>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SRL_SRA, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::BAnd>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::AND, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::BOr>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::OR, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::BXor>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::XOR, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::LAnd>()) {
        uint8_t t1 = allocateRegister();
        uint8_t t2 = allocateRegister();
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t1, RiscVInstr::SLTU, 0, leftReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t2, RiscVInstr::SLTU, 0, rightReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::AND, t1, t2, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::LOr>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::OR, leftReg, rightReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SLTU, 0, destReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Equ>()) {
        uint8_t t = allocateRegister();
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t, RiscVInstr::XOR, leftReg, rightReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::encodeIType(RiscVInstr::OP_IMM, destReg, RiscVInstr::SLTU, t, 1), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Neq>()) {
        uint8_t t = allocateRegister();
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t, RiscVInstr::XOR, leftReg, rightReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SLTU, 0, t, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Lss>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SLT, leftReg, rightReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Grt>()) {
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, destReg, RiscVInstr::SLT, rightReg, leftReg, 0), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Leq>()) {
        uint8_t t = allocateRegister();
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t, RiscVInstr::SLT, rightReg, leftReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::xori(destReg, t, 1), InstrPhase::COMPUTE);
    } else if (binary->is<IR::Geq>()) {
        uint8_t t = allocateRegister();
        emit(RiscVInstr::encodeRType(RiscVInstr::OP, t, RiscVInstr::SLT, leftReg, rightReg, 0), InstrPhase::COMPUTE);
        emit(RiscVInstr::xori(destReg, t, 1), InstrPhase::COMPUTE);
    } else {
        emit(RiscVInstr::add(destReg, leftReg, rightReg), InstrPhase::COMPUTE);
    }
}

void RiscVActionGenerator::generateUnaryOperation(const IR::Operation_Unary* unary) {
    visit(unary->expr);
    uint8_t srcReg = getRegister(unary->expr);
    uint8_t destReg = getRegister(unary);

    if (unary->is<IR::Neg>()) {
        emit(RiscVInstr::sub(destReg, 0, srcReg), InstrPhase::COMPUTE);
    } else if (unary->is<IR::Cmpl>()) {
        emit(RiscVInstr::xori(destReg, srcReg, -1), InstrPhase::COMPUTE);
    } else if (unary->is<IR::LNot>()) {
        emit(RiscVInstr::encodeIType(RiscVInstr::OP_IMM, destReg, RiscVInstr::SLTU, srcReg, 1), InstrPhase::COMPUTE);
    } else {
        if (srcReg != destReg)
            emit(RiscVInstr::addi(destReg, srcReg, 0), InstrPhase::COMPUTE);
    }
}

void RiscVActionGenerator::generateConstant(const IR::Constant* constant, uint8_t destReg) {
    int64_t value = constant->asInt();
    if (value >= -2048 && value <= 2047) {
        emit(RiscVInstr::addi(destReg, 0, static_cast<int16_t>(value)), InstrPhase::SETUP);
    } else {
        uint32_t upper = (static_cast<uint32_t>(value) + 0x800) >> 12;
        int16_t lower = value & 0xFFF;
        if (lower & 0x800) lower -= 0x1000;
        emit(RiscVInstr::lui(destReg, upper << 12), InstrPhase::SETUP);
        if (lower != 0)
            emit(RiscVInstr::addi(destReg, destReg, lower), InstrPhase::SETUP);
    }
}

void RiscVActionGenerator::generateExternMethod(const P4::ExternMethod* externMethod) {
    cstring methodName = externMethod->method->name.toString();
    uint8_t destReg = getRegister(externMethod->expr);

    if (methodName == "read") {
        uint8_t offsetReg = loadBitOffset(0);
        emit(RiscVInstr::metaRead(destReg, offsetReg), InstrPhase::READ);
    } else if (methodName == "write") {
        uint8_t offsetReg = loadBitOffset(0);
        uint8_t valueReg = allocateRegister();
        emit(RiscVInstr::addi(valueReg, 0, 0), InstrPhase::SETUP);
        emit(RiscVInstr::metaWrite(offsetReg, valueReg), InstrPhase::WRITE);
    }
}

void RiscVActionGenerator::generateExternFunction(const P4::ExternFunction* externFunction) {
    cstring functionName = externFunction->method->name.toString();

    if (functionName == "mark_to_drop") {
        buildFieldOffsetMap();
        uint8_t dropValReg = allocateRegister();
        emit(RiscVInstr::addi(dropValReg, 0, 511), InstrPhase::SETUP);

        for (auto& entry : fieldOffsets) {
            if (entry.first.find("egress_spec") != nullptr) {
                uint8_t offsetReg = loadBitOffset(entry.second.bitOffset);
                emit(RiscVInstr::metaWrite(offsetReg, dropValReg), InstrPhase::WRITE);
                return;
            }
        }
        uint8_t offsetReg = loadBitOffset(0);
        emit(RiscVInstr::metaWrite(offsetReg, dropValReg), InstrPhase::WRITE);
    }
}

// --- Top-level generation ---

void RiscVActionGenerator::generateRiscVAction(const IR::P4Action* action) {
    taggedInstrs.clear();
    vliwProgram.clear();
    resetRegisters();
    buildFieldOffsetMap();

    if (action->body) {
        if (auto block = action->body->to<IR::BlockStatement>()) {
            for (auto s : block->components)
                visit(s);
        }
    }

    scheduleVLIW();
    emitRiscVActionEngine(action);
}

void RiscVActionGenerator::emitRiscVActionEngine(const IR::P4Action* action) {
    cstring name = nameFromAnnotation(action, action->name);
    cstring type = CamelCase(name);

    const IR::P4Table* table = control->action_to_table[name];
    if (table == nullptr) {
        P4::error(ErrorType::ERR_UNEXPECTED, "unable to find table from action %1%", name);
        return;
    }

    cstring table_name = nameFromAnnotation(table, table->name);
    cstring table_type = CamelCase(table_name);
    CodeBuilder* builder = &bsv.getControlBuilder();

    // Emit VLIW program
    builder->append_line("// VLIW program for action %s (%d words, %d scalar ops)",
                         name, static_cast<int>(vliwProgram.size()),
                         static_cast<int>(taggedInstrs.size()));

    builder->append_line("Vector#(64, Vector#(8, Bit#(32))) %s_program = replicate(replicate(0));", name);

    for (size_t w = 0; w < vliwProgram.size() && w < 64; w++) {
        bool allNopOrZero = true;
        for (int s = 0; s < VLIW_SLOTS; s++) {
            if (vliwProgram[w][s] != 0 && vliwProgram[w][s] != RV_NOP)
                allNopOrZero = false;
        }
        if (allNopOrZero) continue;  // skip all-NOP words (terminator is all-zero)

        for (int s = 0; s < VLIW_SLOTS; s++) {
            if (vliwProgram[w][s] != 0 && vliwProgram[w][s] != RV_NOP) {
                builder->append_line("%s_program[%d][%d] = %s;", name,
                                    static_cast<int>(w), s,
                                    instr_to_hex(vliwProgram[w][s]).c_str());
            } else if (vliwProgram[w][s] == RV_NOP) {
                builder->append_line("%s_program[%d][%d] = %s; // NOP", name,
                                    static_cast<int>(w), s,
                                    instr_to_hex(RV_NOP).c_str());
            }
        }
    }
    builder->newline();

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
