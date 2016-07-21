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
    bool preorder(const IR::BSV::RuleParserShift* rule) override;
    bool preorder(const IR::BSV::RuleParserExtract* rule) override;
    bool preorder(const IR::BSV::RuleParserTransition* rule) override;
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

#define APPEND_FORMAT(fmt, ...) \
    builder->emitIndent(); \
    builder->appendFormat(fmt, ##__VA_ARGS__); \
    builder->newline();

#define APPEND_LINE(fmt, ...) \
    builder->emitIndent(); \
    builder->appendLine(fmt, ##__VA_ARGS__); \

#define INCR_INDENT \
    builder->increaseIndent();

#define DECR_INDENT \
    builder->decreaseIndent();

bool BSVTranslationVisitor::preorder(const IR::BSV::CReg* reg) {
    auto r = reg->to<IR::BSV::CReg>();
    APPEND_FORMAT("CReg#(%s) %s <- mkCReg(%d, 0);", r->type, r->name, r->size);
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::Reg* reg) {
    auto r = reg->to<IR::BSV::Reg>();
    APPEND_FORMAT("Reg#(%s) %s <- mkReg(%d, 0);", r->type, r->name, r->size);
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::PulseWireOR* wire) {
    auto r = wire->to<IR::BSV::PulseWireOR>();
    APPEND_FORMAT("PulseWire %s <- mkPulseWireOR();", r->name);
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserShift* rule) {
    auto r = rule->to<IR::BSV::RuleParserShift>();
    auto name = r->state->name;
    APPEND_LINE("(* fire_when_enabled *)");
    APPEND_FORMAT("rule rl_%s_shift if ((parse_state_ff.first == %s) && rg_buffered[0]< %d);", name.toString(), CamelCase(name.toString()), r->len);
    APPEND_LINE("endrule");
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserExtract* rule) {
    auto r = rule->to<IR::BSV::RuleParserExtract>();
    auto name = r->state->name.toString();
    auto len = r->len;
    APPEND_LINE("(* fire_when_enabled *)");
    APPEND_FORMAT("rule rl_%s_extract if ((parse_state_ff.first == %s) && rg_buffered[0] > %d);", name, CamelCase(name), len);
    INCR_INDENT;
    APPEND_LINE("let data = rg_tmp[0];");
    APPEND_LINE("if (isValid(data_ff.first)) begin");
    APPEND_LINE("  data_ff.deq;");
    APPEND_LINE("  data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    APPEND_LINE("end");
    APPEND_LINE("report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);");
    for (auto c : *r->state->components) {
        APPEND_FORMAT("let %s = extract_%s(truncate(data));", name, name);
        APPEND_FORMAT("compute_next_state_%s(%s.%s);", name, "header", "field");
    }
    APPEND_FORMAT("rg_tmp[0] <= zeroExtend(data >> %d);", len);
    APPEND_FORMAT("succeed_and_next(%d);", len);
    APPEND_LINE("parse_state_ff.deq;");
    DECR_INDENT;
    APPEND_LINE("endrule");
    return false;
}

bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserTransition* rule) {
    auto r = rule->to<IR::BSV::RuleParserTransition>();
    auto this_state_name = r->this_state->name.toString();
    auto next_state_name = r->next_state->name.toString();
    APPEND_FORMAT("rule rl_%s_%s if (w_%s_%s);", this_state_name,
            next_state_name, this_state_name, next_state_name);
    INCR_INDENT;
    APPEND_FORMAT("parse_state_ff.enq(State%s);", CamelCase(this_state_name));
    APPEND_FORMAT("dbg3($format(\"%%s -> %%s\", \"%s\", \"%s\"));",
            this_state_name, next_state_name);
    APPEND_FORMAT("fetch_next_headers(%d);", r->next_len);
    DECR_INDENT;
    APPEND_LINE("endrule");
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
    APPEND_LINE("typedef struct {");
    INCR_INDENT;
    for (auto s : states) {
        APPEND_FORMAT("State%s;", CamelCase(s->state->name.toString()));
    }
    DECR_INDENT;
    APPEND_LINE("} ParserState deriving (Bits, Eq);");
}

void FPGAParser::emitInterface(CodeBuilder* builder) {
    APPEND_LINE("interface Parser;");
    INCR_INDENT;
    APPEND_LINE("interface Put#(EtherData) frameIn;");
    APPEND_LINE("interface Get#(MetadataT) metadata;");
    APPEND_LINE("interface Put#(int) verbosity;");
    DECR_INDENT;
    APPEND_LINE("endinterface");
}

void FPGAParser::emitFunctVerbosity(CodeBuilder* builder) {
    APPEND_LINE("Reg#(int) cr_verbosity[2] <- mkCRegU(2);");
    APPEND_LINE("FIFOF#(int) cr_verbosity_ff <- mkFIFOF;");
    APPEND_LINE("rule set_verbosity;");
    INCR_INDENT;
    APPEND_LINE("let x = cr_verbosity_ff.first;");
    APPEND_LINE("cr_verbosity_ff.deq;");
    APPEND_LINE("cr_verbosity[1] <= x;");
    DECR_INDENT;
    APPEND_LINE("endrule");
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
        auto ps = new FPGAParserState(state, this);
        states.push_back(ps);
        rules.push_back(new IR::BSV::RuleParserShift(state, 0));
        rules.push_back(new IR::BSV::RuleParserExtract(state, 0));
        if (state->selectExpression != nullptr) {
            if (state->selectExpression->is<IR::SelectExpression>()) {
                auto se = state->selectExpression->to<IR::SelectExpression>();
                for (auto sc: se->selectCases) {
                    LOG1(sc->state->path);
                    LOG1(sc->state);
                    rules.push_back(new IR::BSV::RuleParserTransition(state, sc->state->path, 0));
                }
            }
        }
    }

    //headerType = FPGATypeFactory::instance->create(headersType);
    creg.push_back(new IR::BSV::CReg("parse_done", "Bool", 2));
    creg.push_back(new IR::BSV::CReg("rg_next_header_len", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_buffered", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_shift_amt", "Bit#(32)", 3));
    creg.push_back(new IR::BSV::CReg("rg_tmp", "Bit#(512)", 3));

    wires.push_back(new IR::BSV::PulseWireOR("w_parse_header_done"));
    wires.push_back(new IR::BSV::PulseWireOR("w_load_header"));


    return true;
}

} // namespace FPGA
