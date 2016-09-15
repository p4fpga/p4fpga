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
#include "codegeninspector.h"
#include "string_utils.h"
#include "vector_utils.h"

namespace FPGA {

using namespace Parser;

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
  LOG1("create parse step " << fields);
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
  append_line(bsv, "`ifdef PARSER_STRUCT");
  append_line(bsv, "typedef enum {");
  incr_indent(bsv);
  for (auto s : parseSteps) {
    if (s == parseSteps.back())
      append_format(bsv, "State%s", CamelCase(s->name));
    else
      append_format(bsv, "State%s,", CamelCase(s->name));
  }
  decr_indent(bsv);
  append_line(bsv, "} ParserState deriving (Bits, Eq);");
  append_line(bsv, "`endif");
}

void FPGAParser::emitStructs(BSVProgram & bsv) {
  // assume all headers are parsed_out
  // optimization opportunity ??
  auto htype = typeMap->getType(headers);
  if (htype == nullptr)
    return;

  for (auto f : *htype->to<IR::Type_Struct>()->fields) {
    auto ftype = typeMap->getType(f);
    if (ftype->is<IR::Type_Header>()) {
      StructCodeGen visitor(program, bsv);
      ftype->apply(visitor);
    } else if (ftype->is<IR::Type_Stack>()) {
      auto hstack = ftype->to<IR::Type_Stack>();
      auto header = hstack->elementType->to<IR::Type_Header>();
      StructCodeGen visitor(program, bsv);
      header->apply(visitor);
    }
  }
}

void FPGAParser::emitFunctions(BSVProgram & bsv) {
  append_line(bsv, "`ifdef PARSER_FUNCTION");
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
      append_format(bsv, "function Action compute_next_state_%s(%s);", name, join(params, ","));
    } else {
      append_format(bsv, "function Action compute_next_state_%s();", name);
    }
    incr_indent(bsv);
    append_line(bsv, "action");
    // bit vector from ListExpression
    if (match.size() != 0) {
      append_format(bsv, "let v = {%s};", join(match, ","));
    } else {
      append_line(bsv, "let v = 0;");
    }
    append_line(bsv, "case(v) matches");
    incr_indent(bsv);
    if (state->cases != nullptr) {
      for (auto c : *state->cases) {
        if (c->keyset->is<IR::Constant>()) {
          append_format(bsv, "%d: begin", c->keyset->toString());
          incr_indent(bsv);
          append_line(bsv, "w_%s_%s.send();", name, c->state->toString());
          decr_indent(bsv);
          append_line(bsv, "end");
        } else if (c->keyset->is<IR::DefaultExpression>()) {
          append_line(bsv, "default: begin");
          incr_indent(bsv);
          append_line(bsv, "w_%s_%s.send();", name, c->state->toString());
          decr_indent(bsv);
          append_line(bsv, "end");
        }
      }
    } else {
      // no case.
    }
    decr_indent(bsv);
    append_line(bsv, "endcase");
    append_line(bsv, "endaction");
    decr_indent(bsv);
    append_line(bsv, "endfunction");
  }

  auto initStep = parseStateMap[initState];
  append_line(bsv, "let initState = State%s;", CamelCase(initStep->name.toString()));

  append_line(bsv, "`endif");
}

void FPGAParser::emitBufferRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
    auto name = state->name.toString();
    // Rule: load data
    append_format(bsv, "rule rl_%s_load if ((parse_state_ff.first == State%s) && rg_buffered[0] < %d);", name, CamelCase(name), state->width_bits);
    incr_indent(bsv);
    append_line(bsv, "report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, rg_tmp[0]);");
    append_line(bsv, "if (isValid(data_ff.first)) begin");
    incr_indent(bsv);
    append_line(bsv, "data_ff.deq;");
    append_line(bsv, "let data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    append_line(bsv, "rg_tmp[0] <= zeroExtend(data);");
    append_line(bsv, "move_shift_amt(128);");
    decr_indent(bsv);
    append_line(bsv, "end");
    decr_indent(bsv);
    append_line(bsv, "endrule");
    append_line(bsv, "");
}

void FPGAParser::emitExtractionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
    auto name = state->name.toString();
    auto type = state->type->toString();
    append_format(bsv, "rule rl_%s_extract if ((parse_state_ff.first == State%s) && (rg_buffered[0] > %d));", name, CamelCase(name), state->width_bits);
    incr_indent(bsv);
    append_line(bsv, "let data = rg_tmp[0];");
    append_line(bsv, "if (isValid(data_ff.first)) begin");
    incr_indent(bsv);
    append_line(bsv, "data_ff.deq;");
    append_line(bsv, "data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    decr_indent(bsv);
    append_line(bsv, "end");
    append_line(bsv, "report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);");
    append_line(bsv, "let %s = extract_%s(truncate(data));", name, type);
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
    append_line(bsv, "compute_next_state_%s(%s);", name, params);
    append_format(bsv, "rg_tmp[0] <= zeroExtend(data >> %d);", state->width_bits);
    append_format(bsv, "succeed_and_next(%d);", 0);
    append_line(bsv, "parse_state_ff.deq;");
    append_format(bsv, "%s_out_ff.enq(tagged Valid %s);", name, name);
    decr_indent(bsv);
    append_line(bsv, "endrule");
    append_line(bsv, "");
}

void FPGAParser::emitTransitionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state) {
    auto name = state->name.toString();
    auto type = state->type->toString();
    if (state->cases == nullptr) {
      // direct transition path
      ::warning("directly transit to next state", state->toString());
    } else {
      for (auto c : *state->cases) {
        auto rl_name = name + "_" + c->state->toString();
        append_line(bsv, "rule rl_%s if (w_%s);", rl_name, rl_name);
        auto type = typeMap->getType(c->state, true);
        auto decl = refMap->getDeclaration(c->state->path, true);
        incr_indent(bsv);
        if (c->state->toString() == IR::ParserState::accept) {
          append_line(bsv, "parse_done[0] <= True;");
          append_line(bsv, "w_parse_done.send();");
          append_line(bsv, "fetch_next_header0(0);");
        } else {
          // ParserState* -> BSV::ParseStep --> width_bits
          // LOG1("decl" << decl << " " << c->state << " " << decl->node_type_name());
          if (decl->is<IR::ParserState>()) {
            auto s = decl->to<IR::ParserState>();
            auto bsv_parse_state = parseStateMap[s];
            append_format(bsv, "parse_state_ff.enq(State%s);", CamelCase(bsv_parse_state->name.toString()));
            append_line(bsv, "fetch_next_header0(%d);", bsv_parse_state->width_bits);
          }
        }
        decr_indent(bsv);
        append_line(bsv, "endrule");
      }
    }
}

void FPGAParser::emitRules(BSVProgram & bsv) {
  append_line(bsv, "`ifdef PARSER_RULES");
  for (auto s : parseSteps) {
    emitBufferRule(bsv, s);
    emitExtractionRule(bsv, s);
    emitTransitionRule(bsv, s);
  }
  emitAcceptRule(bsv);
  append_line(bsv, "`endif");
}

void FPGAParser::emitStateElements(BSVProgram & bsv) {
  append_line(bsv, "`ifdef PARSER_STATE");
  // pulsewire to communicate between different parse parseSteps
  for (auto state : parseSteps) {
    if (state->cases == nullptr) continue;
    auto name = state->name.toString();
    for (auto c : *state->cases) {
      append_line(bsv, "PulseWire w_%s_%s <- mkPulseWire;", name, c->state->toString());
    }
  }
  // dfifo to output parsed header
  for (auto state : parseSteps) {
    auto name = state->name.toString();
    auto type = CamelCase(state->type->toString());
    append_line(bsv, "FIFOF#(Maybe#(%s)) %s_out_ff <- mkDFIFOF(tagged Invalid);", type, name);
  }
  append_line(bsv, "`endif");
}

// convert every field in struct headers to its origial header type
void FPGAParser::emitAcceptedHeaders(BSVProgram & bsv, const IR::Type_Struct* headers) {
  for (auto h : *headers->fields) {
    auto node = h->getNode();
    auto type = typeMap->getType(node, true);
    auto name = h->name.toString();
    if (type->is<IR::Type_Header>()) {
      append_format(bsv, "let %s <- toGet(%s_out_ff).get;", name, name);
      append_format(bsv, "if (isValid(%s)) begin", name);
      incr_indent(bsv);
      append_format(bsv, "meta.%s = tagged Forward;", name);
      decr_indent(bsv);
      append_line(bsv, "end");
      for (auto m : program->metadata) {
        auto member = m.second;
        auto ftype = program->typeMap->getType(member->expr, true);
        auto structT = ftype->to<IR::Type_StructLike>();
        auto field = structT->getField(member->member);
        cstring fname = field->name.toString();
        LOG1("### metadata " << m.second << ftype << structT);
        if (ftype == type) {
          append_format(bsv, "if (%s matches tagged Valid .d) begin", name);
          incr_indent(bsv);
          append_format(bsv, "meta.%s = tagged Valid d.%s;", fname, fname);
          decr_indent(bsv);
          append_line(bsv,"end");
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
        append_line(bsv, "meta.%s = tagged Invalid;", name);
      }
    }
  }
}

void FPGAParser::emitAcceptRule(BSVProgram & bsv) {
  append_line(bsv, "rule rl_accept if (delay_ff.notEmpty);");
  incr_indent(bsv);
  append_line(bsv, "delay_ff.deq;");
  append_line(bsv, "MetadataT meta = defaultValue;");
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
  append_line(bsv, "rg_tmp[0] <= 0;");
  append_line(bsv, "rg_shift_amt[0] <= 0;");
  append_line(bsv, "rg_buffered[0] <= 0;");
  append_line(bsv, "meta_in_ff.enq(meta);");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

// emit BSV_IR with BSV-specific CodeGenInspector
void FPGAParser::emit(BSVProgram & bsv) {
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
    LOG1("state " << state);
    ParserBuilder visitor(this);
    state->apply(visitor);
  }
  return true;
}

}  // namespace FPGA
