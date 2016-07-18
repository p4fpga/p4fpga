/*
Copyright 2015-2016 P4FPGA Project

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

#include "ir/ir.h"
#include "fparser.h"
#include "codegen.h"
#include "string_utils.h"

namespace FPGA {

namespace {
class StateTranslationVisitor : public CodeGenInspector {
    bool hasDefault;
    P4::P4CoreLibrary& p4lib;
    const FPGAParserState* state;
//    void compileExtractField(const IR::Expression* expr, cstring name,
//                             unsigned alignment, FPGAType* type);
//    void compileExtract(const IR::Vector<IR::Expression>* args);

 public:
    StateTranslationVisitor(const FPGAParserState* state, CodeBuilder* builder) :
            CodeGenInspector(builder, state->parser->program->typeMap),
            hasDefault(false), p4lib(P4::P4CoreLibrary::instance), state(state) {}
    using CodeGenInspector::preorder;
    bool preorder(const IR::ParserState* state) override;
//    bool preorder(const IR::SelectCase* selectCase) override;
    bool preorder(const IR::SelectExpression* expression) override;
//    bool preorder(const IR::Member* expression) override;
//    bool preorder(const IR::MethodCallExpression* expression) override;
//    bool preorder(const IR::MethodCallStatement* stat) override
//    { visit(stat->methodCall); return false; }
};
}

namespace {
class ParserTranslationVisitor : public CodeGenInspector {
 public:
    ParserTranslationVisitor(const FPGAParser* parser, CodeBuilder* builder) :
            CodeGenInspector(builder, parser->program->typeMap) {}
    bool preorder(const IR::Type_Header* header) override;
};
}  // namespace

bool StateTranslationVisitor::preorder(const IR::ParserState* parserState) {
    if (parserState->isBuiltin()) return false;

    builder->append(parserState->name.name);
    for (auto f: *parserState->components) {
        LOG1(f);
    }
    visit(parserState->components);

    if (parserState->selectExpression == nullptr) {
        builder->append(IR::ParserState::reject.name);
    } else if (parserState->selectExpression->is<IR::SelectExpression>()) {
        visit(parserState->selectExpression);
    } else {
        // must be a PathExpression which is a state name
        if (!parserState->selectExpression->is<IR::PathExpression>())
            BUG("Expected a PathExpression, got a %1%", parserState->selectExpression);
        visit(parserState->selectExpression);
    }
    return false;
}

bool StateTranslationVisitor::preorder(const IR::SelectExpression* expression) {
    LOG1("expression" << expression);
    visit(expression->select);

    for (auto e: expression->selectCases) {
        if (e->keyset->is<IR::Expression>()) {
            // ExpressionTranlationVisitor
            LOG1("select case " << e->keyset);
        }
    }
    return false;
}

bool ParserTranslationVisitor::preorder(const IR::Type_Header* type) {
    auto hdr = type->to<IR::Type_Header>();
    builder->append("typedef struct {");
    builder->newline();
    builder->increaseIndent();
    for (auto f: *hdr->fields) {
        if (f->type->is<IR::Type_Bits>()) {
            auto width = f->type->to<IR::Type_Bits>()->size;
            auto name = f->name;
            builder->emitIndent();
            builder->appendFormat("Bit#(%d) %s;", width, name.toString());
            builder->newline();
        }
    }
    builder->decreaseIndent();
    auto name = hdr->name;
    builder->appendFormat("} %s deriving (Bits, Eq);", CamelCase(name.toString()));
    builder->newline();
    return false;
}

// RuleTranslationVisitor

// MethodTranslationVisitor

//////////////////////////////////////////////////////////////////

void FPGAParserState::emit(CodeBuilder* builder) {
    StateTranslationVisitor visitor(this, builder);
    state->apply(visitor);
}

FPGAParser::FPGAParser(const FPGAProgram* program,
                       const IR::ParserBlock* block, const P4::TypeMap* typeMap) :
        program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
        headers(nullptr), headerType(nullptr) {}

void FPGAParser::emitTypes(CodeBuilder* builder) {
    // assume all headers are parsed_out
    // optimization opportunity ??
    auto htype = typeMap->getType(headers);
    if (htype == nullptr)
        return;
    for (auto f : *htype->to<IR::Type_Struct>()->fields) {
        auto ftype = typeMap->getType(f);
        if (ftype->is<IR::Type_Header>()) {
            ParserTranslationVisitor visitor(this, builder);
            ftype->apply(visitor);
        } else if (ftype->is<IR::Type_Stack>()) {
            auto hstack = ftype->to<IR::Type_Stack>();
            auto header = hstack->baseType->to<IR::Type_Header>();
            ParserTranslationVisitor visitor(this, builder);
            header->apply(visitor);
        }
    }
}

void FPGAParser::emitParseState(CodeBuilder* builder) {
    builder->appendLine("typedef struct {");
    builder->increaseIndent();
    for (auto s : states) {
        builder->emitIndent();
        builder->appendFormat("State%s;", CamelCase(s->state->name.toString()));
        builder->newline();
    }
    builder->decreaseIndent();
    builder->appendLine("} ParserState deriving (Bits, Eq);");
}

void FPGAParser::emitInterface(CodeBuilder* builder) {
    builder->appendLine("interface Parser;");
    builder->increaseIndent();
    builder->emitIndent();
    builder->appendLine("interface Put#(EtherData) frameIn;");
    builder->emitIndent();
    builder->appendLine("interface Get#(MetadataT) metadata;");
    builder->emitIndent();
    builder->appendLine("interface Put#(int) verbosity;");
    builder->decreaseIndent();
    builder->appendLine("endinterface");
}

void FPGAParser::emitFunctVerbosity(CodeBuilder* builder) {
    builder->emitIndent();
    builder->appendLine("Reg#(int) cr_verbosity[2] <- mkCRegU(2);");
    builder->emitIndent();
    builder->appendLine("FIFOF#(int) cr_verbosity_ff <- mkFIFOF;");
    builder->emitIndent();
    builder->appendLine("rule set_verbosity;");
    builder->increaseIndent();
    builder->emitIndent();
    builder->appendLine("let x = cr_verbosity_ff.first;");
    builder->emitIndent();
    builder->appendLine("cr_verbosity_ff.deq;");
    builder->emitIndent();
    builder->appendLine("cr_verbosity[1] <= x;");
    builder->decreaseIndent();
    builder->emitIndent();
    builder->appendLine("endrule");
}

void FPGAParser::emitRegisters(CodeBuilder* builder) {
    // alternative impl:
    // vars.push_back(IR::BSVCReg("rg_next_header_len", 32, 3, 0));
    // vars.push_back(IR::BSVCReg("rg_buffered", 32, 3, 0));
    // vars.push_back(IR::BSVCReg("rg_shift_amt", 32, 3, 0));
    // vars.push_back(IR::BSVCReg("rg_tmp", 32, 2, 0));
    // for (auto v: vars) {
    //   BSVTranslationVisitor visitor(this, builder);
    //   v.apply(visitor);
    // }
    builder->emitIndent();
    builder->appendLine("Reg#(Bit#(32)) rg_next_header_len[3] <- mkCReg(3, 0);");
    builder->emitIndent();
    builder->appendLine("Reg#(Bit#(32)) rg_buffered[3] <- mkCReg(3, 0);");
    builder->emitIndent();
    builder->appendLine("Reg#(Bit#(32)) rg_shift_amt[3] <- mkCReg(3, 0);");
    builder->emitIndent();
    builder->appendLine("Reg#(Bit#(32)) rg_tmp[2] <- mkCReg(2, 0);");
}

void FPGAParser::emitModule(CodeBuilder* builder) {
    builder->appendLine("module mkParser (Parser);");
    builder->increaseIndent();
    emitFunctVerbosity(builder);
    emitRegisters(builder);
    builder->decreaseIndent();
    builder->append("}");
    for (auto f : creg) {
        //BSVTranslationVisitor visitor(this, builder);
        //f->apply(visitor);
        LOG1(f->toString());
    }
    for (auto r : reg) {
        LOG1(r->toString());
    }
    builder->newline();
    /* reg */
    /* rules */
    /* method */
}

// emit BSV_IR with BSV-specific CodeGenInspector
void FPGAParser::emit(CodeBuilder *builder) {
    builder->newline();
    builder->appendLine("// ==============Parser==============");
    builder->newline();
    emitTypes(builder);
    emitParseState(builder);
    emitInterface(builder);
    emitModule(builder);
}

// build IR::BSV from mid-end IR
bool FPGAParser::build() {
    // ParameterList
    auto pl = parserBlock->container->type->applyParams;
    // as defined in v1model.h
    if (pl->size() != 4) {
        ::error("Expected parser to have exactly 4 parameters");
        return false;
    }
    auto model = program->v1model;
    packet = pl->getParameter(model.parser.packetParam.index);
    headers = pl->getParameter(model.parser.headersParam.index);
    userMetadata = pl->getParameter(model.parser.metadataParam.index);
    stdMetadata = pl->getParameter(model.parser.standardMetadataParam.index);

    for (auto state : *parserBlock->container->states) {
        LOG1("id " << state->id);
        auto ps = new FPGAParserState(state, this);
        states.push_back(ps);
    }

    LOG1(parserBlock->instanceType);
    for (auto s : parserBlock->constantValue) {
        auto b = s.second;
        LOG1("s " << s.second);
    }

    //headerType = FPGATypeFactory::instance->create(headersType);
    creg.push_back(new IR::PMICReg("parse_done", "Bool", 2));

    return true;
}

} // namespace FPGA
