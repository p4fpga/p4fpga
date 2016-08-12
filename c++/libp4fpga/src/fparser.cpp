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
#include "codegeninspector.h"
#include "string_utils.h"
#include <algorithm>

namespace FPGA {

  namespace {
    class StateTranslationVisitor : public CodeGenInspector {
      BSVProgram & bsv_;
      bool hasDefault;
      P4::P4CoreLibrary& p4lib;
      const FPGAParserState* state;

      //    void compileExtractField(const IR::Expression* expr, cstring name,
      //                             unsigned alignment, FPGAType* type);
      //    void compileExtract(const IR::Vector<IR::Expression>* args);

    public:
      StateTranslationVisitor(const FPGAParserState* state, BSVProgram& bsv) :
	CodeGenInspector(bsv, state->parser->program->typeMap),
	bsv_(bsv),
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
      using CodeGenInspector::preorder;

    public:
      ParserTranslationVisitor(const FPGAParser* parser, BSVProgram& bsv) :
	CodeGenInspector(bsv, parser->program->typeMap), bsv_(bsv) {}
      bool preorder(const IR::Type_Header* header) override;
    private:
      BSVProgram & bsv_;
    };

    class BSVTranslationVisitor : public CodeGenInspector {
      using CodeGenInspector::preorder;
    public:
      BSVTranslationVisitor(const FPGAParser* parser, BSVProgram& bsv, int x) :
        CodeGenInspector(bsv, parser->program->typeMap), bsv_(bsv) {}
      bool preorder(const IR::BSV::CReg* reg) override;
      bool preorder(const IR::BSV::Reg* reg) override;
      bool preorder(const IR::BSV::PulseWireOR* wire) override;
      bool preorder(const IR::BSV::RuleParserShift* rule) override;
      bool preorder(const IR::BSV::RuleParserExtract* rule) override;
      bool preorder(const IR::BSV::RuleParserTransition* rule) override;
    private:
      BSVProgram & bsv_;
    };

  }  // namespace

  bool StateTranslationVisitor::preorder(const IR::ParserState* parserState) {
    if (parserState->isBuiltin()) return false;

    bsv_.getParserBuilder().append(parserState->name.name);
    for (auto f: *parserState->components) {
      LOG1(f);
    }
    visit(parserState->components);

    if (parserState->selectExpression == nullptr) {
      bsv_.getParserBuilder().append(IR::ParserState::reject.name);
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
    bsv_.getParserBuilder().append("typedef struct {");
    bsv_.getParserBuilder().newline();
    bsv_.getParserBuilder().increaseIndent();
    for (auto f: *hdr->fields) {
      if (f->type->is<IR::Type_Bits>()) {
	auto width = f->type->to<IR::Type_Bits>()->size;
	auto name = f->name;
	bsv_.getParserBuilder().emitIndent();
	bsv_.getParserBuilder().appendFormat("Bit#(%d) %s;", width, name.toString());
	bsv_.getParserBuilder().newline();
      }
    }
    bsv_.getParserBuilder().decreaseIndent();
    auto name = hdr->name;
    bsv_.getParserBuilder().appendFormat("} %s deriving (Bits, Eq);", CamelCase(name.toString()));
    bsv_.getParserBuilder().newline();
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::CReg* reg) {
    auto r = reg->to<IR::BSV::CReg>();
    append_format(bsv_,"CReg#(%s) %s <- mkCReg(%d, 0);", r->type, r->name, r->size);
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::Reg* reg) {
    auto r = reg->to<IR::BSV::Reg>();
    append_format(bsv_,"Reg#(%s) %s <- mkReg(%d, 0);", r->type, r->name, r->size);
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::PulseWireOR* wire) {
    auto r = wire->to<IR::BSV::PulseWireOR>();
    append_format(bsv_,"PulseWire %s <- mkPulseWireOR();", r->name);
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserShift* rule) {
    auto r = rule->to<IR::BSV::RuleParserShift>();
    auto name = r->state->name;
    append_line(bsv_,"(* fire_when_enabled *)");
    append_format(bsv_,"rule rl_%s_shift if ((parse_state_ff.first == %s) && rg_buffered[0]< %d);", name.toString(), CamelCase(name.toString()), r->len);
    append_line(bsv_,"endrule");
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserExtract* rule) {
    auto r = rule->to<IR::BSV::RuleParserExtract>();
    auto name = r->state->name.toString();
    auto len = r->len;
    append_line(bsv_,"(* fire_when_enabled *)");
    append_format(bsv_,"rule rl_%s_extract if ((parse_state_ff.first == %s) && rg_buffered[0] > %d);", name, CamelCase(name), len);
    incr_indent(bsv_);
    append_line(bsv_,"let data = rg_tmp[0];");
    append_line(bsv_,"if (isValid(data_ff.first)) begin");
    append_line(bsv_,"  data_ff.deq;");
    append_line(bsv_,"  data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    append_line(bsv_,"end");
    append_line(bsv_,"report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);");
    for (auto c : *r->state->components) {
      append_format(bsv_,"let %s = extract_%s(truncate(data));", name, name);
      append_format(bsv_,"compute_next_state_%s(%s.%s);", name, "header", "field");
    }

    // std::for_each(std::begin(*r->state->components), std::end(*r->state->components), [](auto&& /* nothing */) { 
    //     //append_format(bsv_,"let %s = extract_%s(truncate(data));", name, name);
    //     //append_format(bsv_,"compute_next_state_%s(%s.%s);", name, "header", "field");
    //   });

    
    append_format(bsv_,"rg_tmp[0] <= zeroExtend(data >> %d);", len);
    append_format(bsv_,"succeed_and_next(%d);", len);
    append_line(bsv_,"parse_state_ff.deq;");
    decr_indent(bsv_);
    append_line(bsv_,"endrule");
    return false;
  }

  bool BSVTranslationVisitor::preorder(const IR::BSV::RuleParserTransition* rule) {
    auto r = rule->to<IR::BSV::RuleParserTransition>();
    auto this_state_name = r->this_state->name.toString();
    auto next_state_name = r->next_state->name.toString();
    append_format(bsv_,"rule rl_%s_%s if (w_%s_%s);", this_state_name,
		  next_state_name, this_state_name, next_state_name);
    incr_indent(bsv_);
    append_format(bsv_,"parse_state_ff.enq(State%s);", CamelCase(this_state_name));
    append_format(bsv_,"dbg3($format(\"%%s -> %%s\", \"%s\", \"%s\"));",
		  this_state_name, next_state_name);
    append_format(bsv_,"fetch_next_headers(%d);", r->next_len);
    decr_indent(bsv_);
    append_line(bsv_,"endrule");
    return false;
  }

  //////////////////////////////////////////////////////////////////

  void FPGAParserState::emit(BSVProgram& bsv) {

    // TODO(rjs): fixme
    BSVProgram& program = const_cast< BSVProgram&>(bsv);
    StateTranslationVisitor visitor(this, bsv);
    state->apply(visitor);
  }

  FPGAParser::FPGAParser(const FPGAProgram* program,
			 const IR::ParserBlock* block, const P4::TypeMap* typeMap) :
    program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
    headers(nullptr), headerType(nullptr) {
  }

  void FPGAParser::emitTypes(BSVProgram & bsv) {
    // assume all headers are parsed_out
    // optimization opportunity ??
    auto htype = typeMap->getType(headers);
    if (htype == nullptr)
      return;

    for (auto f : *htype->to<IR::Type_Struct>()->fields) {
      auto ftype = typeMap->getType(f);
      if (ftype->is<IR::Type_Header>()) {
	ParserTranslationVisitor visitor(this, bsv);
	ftype->apply(visitor);
      } else if (ftype->is<IR::Type_Stack>()) {
	auto hstack = ftype->to<IR::Type_Stack>();
	auto header = hstack->baseType->to<IR::Type_Header>();
	ParserTranslationVisitor visitor(this, bsv);
	header->apply(visitor);
      }
    }
  }

  void FPGAParser::emitParseState(BSVProgram & bsv) {
    append_line(bsv,"typedef struct {");
    incr_indent(bsv);
    for (auto s : states) {
      append_format(bsv,"State%s;", CamelCase(s->state->name.toString()));
    }
    decr_indent(bsv);
    append_line(bsv,"} ParserState deriving (Bits, Eq);");
  }

  void FPGAParser::emitInterface(BSVProgram & bsv) {
    append_line(bsv,"interface Parser;");
    incr_indent(bsv);
    append_line(bsv,"interface Put#(EtherData) frameIn;");
    append_line(bsv,"interface Get#(MetadataT) metadata;");
    append_line(bsv,"interface Put#(int) verbosity;");
    decr_indent(bsv);
    append_line(bsv,"endinterface");
  }

  void FPGAParser::emitFunctVerbosity(BSVProgram & bsv) {
    append_line(bsv,"Reg#(int) cr_verbosity[2] <- mkCRegU(2);");
    append_line(bsv,"FIFOF#(int) cr_verbosity_ff <- mkFIFOF;");
    append_line(bsv,"rule set_verbosity;");
    incr_indent(bsv);
    append_line(bsv,"let x = cr_verbosity_ff.first;");
    append_line(bsv,"cr_verbosity_ff.deq;");
    append_line(bsv,"cr_verbosity[1] <= x;");
    decr_indent(bsv);
    append_line(bsv,"endrule");
  }

#define VECTOR_VISIT(V)					\
  for (auto r: V) {					\
    BSVTranslationVisitor visitor(this, bsv, 1);	\
    r->apply(visitor);					\
  }
  void FPGAParser::emitModule(BSVProgram & bsv) {
    bsv.getParserBuilder().appendLine("module mkParser (Parser);");
    bsv.getParserBuilder().increaseIndent();
    VECTOR_VISIT(creg);
    VECTOR_VISIT(reg);

    emitFunctVerbosity(bsv);

    VECTOR_VISIT(rules);
    bsv.getParserBuilder().decreaseIndent();
    bsv.getParserBuilder().append("}");
  }
#undef VECTOR_VISIT

  // emit BSV_IR with BSV-specific CodeGenInspector
  void FPGAParser::emit(BSVProgram & bsv) {
    bsv.getParserBuilder().newline();
    bsv.getParserBuilder().appendLine("// ==============Parser==============");
    bsv.getParserBuilder().newline();
    emitTypes(bsv);
    emitParseState(bsv);
    emitInterface(bsv);
    emitModule(bsv);
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
