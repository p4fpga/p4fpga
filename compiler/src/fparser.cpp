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

#include "fparser.h"
#include "fstruct.h"
#include <algorithm>
#include "ir/ir.h"
//#include "codegeninspector.h"
#include "string_utils.h"
#include "vector_utils.h"

namespace FPGA {

class ParserBuilder : public Inspector {
 public:
  ParserBuilder(FPGAParser* parser) : parser(parser) {
    statements = new IR::IndexedVector<IR::AssignmentStatement>();
    cases = new IR::IndexedVector<IR::SelectCase>();
    fields = new IR::IndexedVector<IR::StructField>();
    header_width = 0;
  }
  bool preorder(const IR::ParserState* state) override;
  bool preorder(const IR::SelectExpression* expression) override;
  bool preorder(const IR::MethodCallStatement* stmt) override
  { visit(stmt->methodCall); return false; };
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::MethodCallExpression* expression) override;
 private:
  IR::IndexedVector<IR::AssignmentStatement>* statements;
  IR::IndexedVector<IR::SelectCase>*          cases;
  const IR::ListExpression*                   select;
  const IR::IndexedVector<IR::StructField>*   fields;
  int                                         header_width;
  const IR::Type_Name*                        header_type_name;
  const IR::ID*                           header_name;

  const IR::ParserState* parser_state;
  FPGAParser* parser;
};

// A P4 parse state corresponds to one or more Bluespec parse state,
// depends on how many 'extract' method are used.
// There are two variants of 'extract' method:
// - one-argument variant for extracting fixed-size headers
// - two-argument variant for extracting variable-size headers
bool ParserBuilder::preorder(const IR::ParserState* state) {
  // skip accept / reject states
  if (state->isBuiltin()) {
    LOG1("skip built in state " << state);
  return false;
  }

  if (state->name.toString() == "start") {
    // NOTE: assume start state is actually called 'start'
    LOG1(state->components);
    if (state->components->size() == 0) {
      if (state->selectExpression->is<IR::PathExpression>()) {
        auto expr = state->selectExpression->to<IR::PathExpression>();
        auto inst = parser->refMap->getDeclaration(expr->path, true);
        if (inst->is<IR::ParserState>()) {
          auto pstate = inst->to<IR::ParserState>();
          parser->initState = pstate;
          LOG1("parse init state");
        }
      }
      return false;
    } else {
      parser->initState = state;
    }
  }

  // take a note of current p4 parse state
  parser_state = state;

  // process 'extract' or 'set_metadata'
  visit(state->components);

  // process 'select' statement
  if (state->selectExpression->is<IR::SelectExpression>()) {
    // multiple next step
    LOG1("select in state " << state);
    visit(state->selectExpression);
  } else if (state->selectExpression->is<IR::PathExpression>()){
    // only one next step
    LOG1("select only one " << state);
    auto path = state->selectExpression->to<IR::PathExpression>();
    auto nextState = new IR::SelectCase(new IR::DefaultExpression(), path);
    cases->push_back(nextState);
    select = nullptr;
  }

  // create one parse step
  //auto name = state->name.toString();
  // FIXME: set parseStep name to header_name because we assume each step extracts a header.
  auto name = header_name->toString();
  LOG1("create parse step " << fields << header_name << state);
  auto step = new IR::BSV::ParseStep(name, fields, header_width, header_type_name, select, cases, statements);
  parser->parseSteps.push_back(step);
  parser->parseStateMap[state] = step;
  return false;
}

bool ParserBuilder::preorder(const IR::SelectExpression* expression) {
  LOG1("select expression " << expression);
  select = expression->select;
  for (auto e : expression->selectCases) {
    if (e->is<IR::SelectCase>()) {
      cases->push_back(e->to<IR::SelectCase>());
    }
  }
  return false;
}

// handle 'extract' method call
// 
bool ParserBuilder::preorder(const IR::MethodCallExpression* expression) {
  auto m = expression->method->to<IR::Expression>();
  if (m == nullptr) return false;

  auto e = m->to<IR::Member>();
  if (e == nullptr) return false;

  if (e->member == "extract") {
    // argument types
    for (auto h: MakeZipRange(*expression->typeArguments, *expression->arguments)) {
      auto typeName = h.get<0>();
      auto instName = h.get<1>();
      auto header_type = parser->program->typeMap->getType(typeName, true);
      header_width += header_type->width_bits();
      if (header_type->is<IR::Type_StructLike>()) {
        auto header = header_type->to<IR::Type_StructLike>();
        fields = header->fields;
        LOG1("fields" << header->fields);
      }

      header_type_name = typeName->to<IR::Type_Name>();
      if (instName->is<IR::Member>()) {
        header_name = &instName->to<IR::Member>()->member;
      } else if (instName->is<IR::ArrayIndex>()) {
        //header_name = instName->to<IR::ArrayIndex>()->typeName;
        ::warning("extract expression, handle stack header");
      }
      LOG1("header_type " << header_type_name);
    }
    // TODO: implement two-argument variant for extracting variable-size headers
  } else {
    // TODO: handle 'lookahead' method
    warning("unhandled method %1%.", e->member);
  }
  return false;
}

bool ParserBuilder::preorder(const IR::AssignmentStatement* statement) {
  statements->push_back(statement);
  return false;
}

FPGAParser::FPGAParser(FPGAProgram* program,
                       const IR::ParserBlock* block,
                       const P4::TypeMap* typeMap,
                       const P4::ReferenceMap* refMap) :
  program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
  refMap(refMap), headers(nullptr), headerType(nullptr) {
}

void FPGAParser::emitEnums(BSVProgram & bsv) {
  builder->append_line("`ifdef PARSER_STRUCT");
  builder->append_line("typedef enum {");
  builder->incr_indent();
  for (auto s : parseSteps) {
    if (s == parseSteps.back())
      builder->append_format("State%s", CamelCase(s->name));
    else
      builder->append_format("State%s,", CamelCase(s->name));
  }
  builder->decr_indent();
  builder->append_line("} ParserState deriving (Bits, Eq);");
  builder->append_line("`endif");
}

void FPGAParser::emitStructs(BSVProgram & bsv) {
  // assume all headers are parsed_out
  // optimization opportunity ??
  auto type = typeMap->getType(headers);
  if (type == nullptr) {
    ::error("parameter 'headers' is null");
    return;
  }

  CodeBuilder* struct_builder = &bsv.getStructBuilder();
  StructCodeGen visitor(program, struct_builder);

  const IR::Type_Struct* ir_struct = type->to<IR::Type_Struct>();
  if (ir_struct == nullptr) {
    ::error("ir_struct is null");
    return;
  }

  for (auto f : *ir_struct->fields) {
    auto field_t = typeMap->getType(f);
    if (field_t->is<IR::Type_Header>()) {
      field_t->apply(visitor);
    } else if (field_t->is<IR::Type_Stack>()) {
      const IR::Type_Stack* stack_t = field_t->to<IR::Type_Stack>();
      const IR::Type_Header* header_t = stack_t->elementType->to<IR::Type_Header>();
      if (header_t == nullptr) {
        ::error("header_t is null");
        return;
      }
      header_t->apply(visitor);
    }
  }
}

void FPGAParser::emitFunctions(BSVProgram & bsv) {
  builder->append_line("`ifdef PARSER_FUNCTION");
  for (auto state : parseSteps) {
    // find out type and name of each field
    auto name = state->name.toString();
    std::vector<cstring> match;
    std::vector<cstring> params;
    if (state->keys != nullptr) {
      // get type for 'select' keys
      auto type = typeMap->getType(state->keys, true);
      if (type->is<IR::Type_Tuple>()) {
        auto tpl = type->to<IR::Type_Tuple>();
        if (state->keys->is<IR::ListExpression>()) {
          auto keys = state->keys->to<IR::ListExpression>();
          for (auto h : MakeZipRange(*tpl->components, *keys->components)) {
            auto w = h.get<0>();
            auto k = h.get<1>();
            if (k->is<IR::Member>()) {
              auto name = k->to<IR::Member>();
              auto width = w->width_bits();
              params.push_back("Bit#(" + std::to_string(width) + ") " + name->member);
              match.push_back(name->member);
            }
          }
        }
      }
    }
    if (params.size() != 0) {
      builder->append_format("function Action compute_next_state_%s(%s);", name, join(params, ","));
    } else {
      builder->append_format("function Action compute_next_state_%s();", name);
    }
    builder->incr_indent();
    builder->append_line("action");
    // bit vector from ListExpression
    if (match.size() != 0) {
      builder->append_format("let v = {%s};", join(match, ","));
    } else {
      builder->append_line("let v = 0;");
    }
    builder->append_line("case(v) matches");
    builder->incr_indent();
    if (state->cases != nullptr) {
      for (auto c : *state->cases) {
        if (c->keyset->is<IR::Constant>()) {
          builder->append_format("%d: begin", c->keyset->toString());
          builder->incr_indent();
          builder->append_line("w_%s_%s.send();", name, c->state->toString());
          builder->decr_indent();
          builder->append_line("end");
        } else if (c->keyset->is<IR::DefaultExpression>()) {
          builder->append_line("default: begin");
          builder->incr_indent();
          builder->append_line("w_%s_%s.send();", name, c->state->toString());
          builder->decr_indent();
          builder->append_line("end");
        }
      }
    } else {
      // no case.
    }
    builder->decr_indent();
    builder->append_line("endcase");
    builder->append_line("endaction");
    builder->decr_indent();
    builder->append_line("endfunction");
  }

  auto initStep = parseStateMap[initState];
  builder->append_line("let initState = State%s;", CamelCase(initStep->name.toString()));

  builder->append_line("`endif");
}

void FPGAParser::emitBufferRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
    auto name = state->name.toString();
    // Rule: load data
    builder->append_format("rule rl_%s_load if ((parse_state_ff.first == State%s) && rg_buffered[0] < %d);", name, CamelCase(name), state->width_bits);
    builder->incr_indent();
    builder->append_line("report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);");
    builder->append_line("if (isValid(data_ff.first)) begin");
    builder->incr_indent();
    builder->append_line("data_ff.deq;");
    builder->append_line("let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    builder->append_line("rg_tmp[0] <= zeroExtend(data);");
    builder->append_line("move_shift_amt(128);");
    builder->decr_indent();
    builder->append_line("end");
    builder->decr_indent();
    builder->append_line("endrule");
    builder->append_line("");
}

void FPGAParser::emitExtractionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
    auto name = state->name.toString();
    auto type = state->type->toString();
    builder->append_format("rule rl_%s_extract if ((parse_state_ff.first == State%s) && (rg_buffered[0] > %d));", name, CamelCase(name), state->width_bits);
    builder->incr_indent();
    builder->append_line("let data = rg_tmp[0];");
    builder->append_line("if (isValid(data_ff.first)) begin");
    builder->incr_indent();
    builder->append_line("data_ff.deq;");
    builder->append_line("data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    builder->decr_indent();
    builder->append_line("end");
    builder->append_line("report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);");
    builder->append_line("let %s = extract_%s(truncate(data));", name, type);
    auto params = cstring("");
    if (state->keys != nullptr) {
      auto lk = state->keys->to<IR::ListExpression>();
      if (lk != nullptr) {
        for (auto key : *lk->components) {
          if (key->is<IR::Member>()) {
            auto field = key->to<IR::Member>();
            if (field->expr->is<IR::Member>()) {
              auto header = field->expr->to<IR::Member>();
              // NOTE: what if header has a nested struture, i.e. header inside header?
              params += header->member.toString() + "." + field->member.toString();
            } else if (field->expr->is<IR::ArrayIndex>()) {
              ::warning("handle stack header");
            }
          }
        }
      }
    }
    builder->append_line("compute_next_state_%s(%s);", name, params);
    builder->append_format("rg_tmp[0] <= zeroExtend(data >> %d);", state->width_bits);
    builder->append_format("succeed_and_next(%d);", state->width_bits);
    builder->append_line("parse_state_ff.deq;");
    builder->append_format("%s_out_ff.enq(tagged Valid %s);", name, name);
    builder->decr_indent();
    builder->append_line("endrule");
    builder->append_line("");
}

void FPGAParser::emitTransitionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
  auto name = state->name.toString();
  auto type = state->type->toString();
  std::set<cstring> rule_set;
  if (state->cases == nullptr) {
    // direct transition path
    ::warning("directly transit to next state", state->toString());
  } else {
    for (auto c : *state->cases) {
      auto rl_name = name + "_" + c->state->toString();
      if (rule_set.find(rl_name) != rule_set.end()) {
        // already generated.
        continue;
      } else {
        rule_set.insert(rl_name);
      }
      builder->append_line("rule rl_%s if (w_%s);", rl_name, rl_name);
      auto type = typeMap->getType(c->state, true);
      auto decl = refMap->getDeclaration(c->state->path, true);
      builder->incr_indent();
      if (c->state->toString() == IR::ParserState::accept) {
        builder->append_line("parse_done[0] <= True;");
        builder->append_line("w_parse_done.send();");
        builder->append_line("fetch_next_header0(0);");
      } else {
        // ParserState* -> BSV::ParseStep --> width_bits
        // LOG1("decl" << decl << " " << c->state << " " << decl->node_type_name());
        if (decl->is<IR::ParserState>()) {
          auto s = decl->to<IR::ParserState>();
          auto bsv_parse_state = parseStateMap[s];
          builder->append_format("parse_state_ff.enq(State%s);", CamelCase(bsv_parse_state->name.toString()));
          builder->append_line("fetch_next_header0(%d);", bsv_parse_state->width_bits);
        }
      }
      builder->decr_indent();
      builder->append_line("endrule");
    }
  }
}

void FPGAParser::emitRules(BSVProgram & bsv) {
  builder->append_line("`ifdef PARSER_RULES");
  // deparse rules are mutually exclusive
  std::vector<cstring> exclusive_rules;
  std::set<cstring> rule_set;
  for (auto r : parseSteps) {
    for (auto c : *r->cases) {
      cstring name = r->name.toString();
      cstring rl_name = "rl_" + name + "_" + c->state->toString();
      if (rule_set.find(rl_name) != rule_set.end()) {
        // already generated.
        continue;
      } else {
        rule_set.insert(rl_name);
        exclusive_rules.push_back(rl_name);
      }
    }
  }
  auto exclusive_annotation = cstring("(* mutually_exclusive=\"");
  for (auto r : exclusive_rules) {
    exclusive_annotation += r;
    if (r != exclusive_rules.back()) {
      exclusive_annotation += cstring(",");
    }
  }
  exclusive_annotation += cstring("\" *)");
  builder->append_line(exclusive_annotation);

  for (auto s : parseSteps) {
    emitBufferRule(bsv, s);
    emitExtractionRule(bsv, s);
    emitTransitionRule(bsv, s);
  }
  emitAcceptRule(bsv);
  builder->append_line("`endif");
}

void FPGAParser::emitStateElements(BSVProgram & bsv) {
  builder->append_line("`ifdef PARSER_STATE");
  // pulsewire to communicate between different parse parseSteps
  for (auto state : parseSteps) {
    if (state->cases == nullptr) continue;
    cstring name = state->name.toString();
    for (auto c : *state->cases) {
      cstring wire_name = "w_" + name + "_" + c->state->toString();
      pulse_wire_set.insert(wire_name);
    }
  }
  for (auto n : pulse_wire_set) {
    builder->append_line("PulseWire %s <- mkPulseWire;", n);
  }
  // dfifo to output parsed header
  for (auto state : parseSteps) {
    auto name = state->name.toString();
    auto type = CamelCase(state->type->toString());
    builder->append_line("FIFOF#(Maybe#(%s)) %s_out_ff <- mkDFIFOF(tagged Invalid);", type, name);
  }
  builder->append_line("`endif");
}

// convert every field in struct headers to its origial header type
void FPGAParser::emitAcceptedHeaders(BSVProgram & bsv, const IR::Type_Struct* headers) {
  for (auto h : *headers->fields) {
    auto node = h->getNode();
    auto type = typeMap->getType(node, true);
    auto name = h->name.toString();
    if (type->is<IR::Type_Header>()) {
      builder->append_format("let %s <- toGet(%s_out_ff).get;", name, name);
      builder->append_format("if (isValid(%s)) begin", name);
      builder->incr_indent();
      builder->append_format("meta.%s = tagged Forward;", name);
      builder->decr_indent();
      builder->append_line("end");
      builder->append_format("meta.hdr.%s = %s;", name, name);
      for (auto m : program->metadata) {
        auto member = m.second;
        auto ftype = program->typeMap->getType(member->expr, true);
        auto structT = ftype->to<IR::Type_StructLike>();
        auto field = structT->getField(member->member);
        cstring fname = field->name.toString();
        if (ftype == type) {
          builder->append_format("if (%s matches tagged Valid .d) begin", name);
          builder->incr_indent();
          builder->append_format("meta.%s = tagged Valid d.%s;", fname, fname);
          builder->decr_indent();
          builder->append_line("end");
        }
      }
    } else if (type->is<IR::Type_Stack>()) {
      ::warning("TODO: generate out_ff for header stack;");
    } else {
      ::error("Unknown header type ", type);
    }
  }
}

void FPGAParser::emitUserMetadata(BSVProgram & bsv, const IR::Type_Struct* metadata) {
  for (auto h : *metadata->fields) {
    auto node = h->getNode();
    auto type = typeMap->getType(node, true);
    if (type->is<IR::Type_Struct>()) {
      auto hh = type->to<IR::Type_Struct>();
      for (auto f : *hh->fields) {
        auto name = f->toString();
        builder->append_line("meta.%s = tagged Invalid;", name);
      }
    }
  }
}

void FPGAParser::emitAcceptRule(BSVProgram & bsv) {
  builder->append_line("rule rl_accept if (delay_ff.notEmpty);");
  builder->incr_indent();
  builder->append_line("delay_ff.deq;");
  builder->append_line("MetadataT meta = defaultValue;");
  for (auto h : *program->program->getDeclarations()) {
    // In V1 model, metadata comes from three sources:
    // - standard_metadata, metadata, header
    if (h->is<IR::Type_Struct>()) {
      auto h_struct = h->to<IR::Type_Struct>();
      auto name = h_struct->name.toString();
      // only handle one of the three above
      if (name == "standard_metadata") {
        // TODO: emitStandardMetadata();
      } else if (name == "metadata") {
        // this struct contains all extracted metadata
        LOG1("metadata" << h_struct);
        emitUserMetadata(bsv, h_struct);
      } else if (name == "headers") {
        LOG1("headers " << h_struct);
        emitAcceptedHeaders(bsv, h_struct);
      } else {
        // - struct used by externs, such as checksum
      }
    }
  }
  builder->append_line("rg_tmp[0] <= 0;");
  builder->append_line("rg_shift_amt[0] <= 0;");
  builder->append_line("rg_buffered[0] <= 0;");
  builder->append_line("meta_in_ff.enq(meta);");
  builder->decr_indent();
  builder->append_line("endrule");
}

// emit BSV_IR with BSV-specific CodeGenInspector
void FPGAParser::emit(BSVProgram & bsv) {
  builder = &bsv.getParserBuilder();
  emitEnums(bsv);
  emitStructs(bsv);
  emitFunctions(bsv);
  emitRules(bsv);
  emitStateElements(bsv);
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

  auto states = parserBlock->container->states;
  for (auto state : *states) {
    ParserBuilder visitor(this);
    state->apply(visitor);
  }

  return true;
}

}  // namespace FPGA
