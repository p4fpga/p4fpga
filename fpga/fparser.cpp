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

class ParserTranslationVisitor : public CodeGenInspector {
 public:
    ParserTranslationVisitor(const FPGAParser* parser, CodeBuilder* builder) :
            CodeGenInspector(builder, parser->program->typeMap) {}
    bool preorder(const IR::Type_Header* header) override;
};

class BSVTranslationVisitor : public CodeGenInspector {
 public:
    BSVTranslationVisitor(const FPGAParser* parser, CodeBuilder* builder) :
        CodeGenInspector(builder, parser->program->typeMap) {}
    bool preorder(const IR::BSV::CReg* reg) override;
    bool preorder(const IR::BSV::Reg* reg) override;
    bool preorder(const IR::BSV::PulseWireOR* wire) override;
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

bool BSVTranslationVisitor::preorder(const IR::BSV::CReg* reg) {
    auto r = reg->to<IR::BSV::CReg>();
    builder->emitIndent();
    builder->appendFormat("CReg#(%s) %s <- mkCReg(%d, 0);", r->type, r->name, r->size);
    builder->newline();
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::Reg* reg) {
    auto r = reg->to<IR::BSV::Reg>();
    builder->emitIndent();
    builder->appendFormat("Reg#(%s) %s <- mkReg(%d, 0);", r->type, r->name, r->size);
    builder->newline();
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::PulseWireOR* wire) {
    auto r = wire->to<IR::BSV::PulseWireOR>();
    builder->emitIndent();
    builder->appendFormat("PulseWire %s <- mkPulseWireOR();", r->name);
    builder->newline();
    return false;
}

//////////////////////////////////////////////////////////////////

void FPGAParserState::emit(CodeBuilder* builder) {
    StateTranslationVisitor visitor(this, builder);
    state->apply(visitor);
}

FPGAParser::FPGAParser(const FPGAProgram* program,
                       const IR::ParserBlock* block, const P4::TypeMap* typeMap) :
        program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
        headers(nullptr), headerType(nullptr) {
}

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

void FPGAParser::emitRules(CodeBuilder* builder) {
    builder->emitIndent();
    builder->appendLine("");
}

#define VECTOR_VISIT(V)                               \
    for (auto r: V) {                                 \
        BSVTranslationVisitor visitor(this, builder); \
        r->apply(visitor);                            \
    }
void FPGAParser::emitModule(CodeBuilder* builder) {
    builder->appendLine("module mkParser (Parser);");
    builder->increaseIndent();
    VECTOR_VISIT(creg);
    VECTOR_VISIT(reg);

    emitFunctVerbosity(builder);

    VECTOR_VISIT(rules);
    builder->decreaseIndent();
    builder->append("}");
}
#undef VECTOR_VISIT

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

    //headerType = FPGATypeFactory::instance->create(headersType);
    creg.push_back(new IR::BSV::CReg("parse_done", "Bool", 2));
    creg.push_back(new IR::BSV::CReg("rg_next_header_len", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_buffered", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_shift_amt", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_tmp", "Bit#(512)", 3));

    wires.push_back(new IR::BSV::PulseWireOR("w_parse_header_done"));
    wires.push_back(new IR::BSV::PulseWireOR("w_load_header"));

    // build rules

    return true;
}

} // namespace FPGA
