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
#include <algorithm>
#include "ir/ir.h"
#include "codegeninspector.h"
#include "string_utils.h"
#include "vector_utils.h"

namespace FPGA {

using namespace Parser;

class ParserBuilder : public Inspector {
  // variables to keep track of which state is being handled.
  cstring state;
  cstring header;
  std::map<cstring, int> ext_count;
  std::map<cstring, IR::BSV::ParseState*> smap;
 public:
  ParserBuilder(FPGAParser* parser, const FPGAProgram* program) :
    parser(parser), program(program) {}
  bool preorder(const IR::ParserState* state) override;
  bool preorder(const IR::SelectExpression* expression) override;
  bool preorder(const IR::MethodCallStatement* stmt) override
  { visit(stmt->methodCall); return false; };
  bool preorder(const IR::AssignmentStatement* stmt) override
  { LOG1(stmt); visit(stmt->right); visit(stmt->left); return false; };
  bool preorder(const IR::MethodCallExpression* expression) override;
 private:
  const FPGAProgram* program;
  FPGAParser* parser;
};

// A P4 parse state corresponds to one or more Bluespec parse state,
// depends on how many 'extract' method are used.
// There are two variants of 'extract' method:
// - one-argument variant for extracting fixed-size headers
// - two-argument variant for extracting variable-size headers
bool ParserBuilder::preorder(const IR::ParserState* ps) {

  // skip accept / reject states
  if (ps->isBuiltin()) return false;

  // take a note of current p4 parse state
  state = ps->name;
  ext_count[state] = 0;

  // process 'extract' method
  visit(ps->components);

  // process select expression
  if (ps->selectExpression->is<IR::SelectExpression>()) {
    // with more than one possible next state
    visit(ps->selectExpression);
  } else if (ps->selectExpression->is<IR::PathExpression>()){
    // with only one next state
    auto path = ps->selectExpression->to<IR::PathExpression>();
    auto nextState = new IR::SelectCase(new IR::DefaultExpression(), path);
    auto cases = new IR::IndexedVector<IR::SelectCase>();
    cases->push_back(nextState);
    auto s = smap[header];
    s->cases = cases;
  }
  return false;
}

bool ParserBuilder::preorder(const IR::SelectExpression* expression) {
  // get current parse state
  auto s = smap[header];

  // populate select keys
  auto keys = expression->select;
  if (s != nullptr && s->keys== nullptr) {
    s->keys = keys;
  }

  // populate select cases
  auto cases = new IR::IndexedVector<IR::SelectCase>();
  for (auto e : expression->selectCases) {
    if (e->is<IR::SelectCase>()) {
      cases->push_back(e->to<IR::SelectCase>());
    }
  }
  if (s != nullptr && s->cases == nullptr) {
    s->cases = cases;
  }
  return false;
}

bool ParserBuilder::preorder(const IR::MethodCallExpression* expression) {
  auto m = expression->method->to<IR::Expression>();
  if (m == nullptr) return false;

  auto e = m->to<IR::Member>();
  if (e == nullptr) return false;

  if (e->member == "extract") {
    if (ext_count[state] == 0) {
      ext_count[state] += 1;
    } else {
      ::warning("More than one 'extract' method");
      //BUG("ERROR: More than one 'extract' method in %s. TODO", state);
    }
    // implementing one-argument variant of 'extract' method
    for (auto h: MakeZipRange(*expression->typeArguments, *expression->arguments)) {
      auto typeName = h.get<0>();
      auto instName = h.get<1>();
      auto header_type = program->typeMap->getType(typeName, true);
      auto header_width = header_type->width_bits();
      if (instName->is<IR::ArrayIndex>()) {
        auto name = instName->to<IR::ArrayIndex>();
        // TODO: handle header stack
        ::warning("unhandle extract method %1%", name);
      } else if (instName->is<IR::Member>()) {
        auto name = instName->to<IR::Member>()->member;
        // keep track of current header
        header = name;

        if (header_type->is<IR::Type_StructLike>()) {
          auto header = header_type->to<IR::Type_StructLike>();
          // create parse state
          // leave fields related to next state selection empty
          auto s = new IR::BSV::ParseState(name, header->fields, header_width, nullptr, nullptr);
          parser->states.push_back(s);
          smap[name] = s;
        }
      }
    }
    // TODO: implement two-argument variant for extracting variable-size headers
  } else {
    // TODO: handle 'lookahead' method
    warning("unhandled method %1%.", e->member);
    //::error("%1%: unhandled method", e->member);
  }
  return false;
}

class ParserStateVisitor : public Inspector {
 public:
  ParserStateVisitor(const FPGAParser* parser, BSVProgram& bsv) :
    bsv_(bsv) {}
  bool preorder(const IR::Type_Header* header) override;
 private:
  BSVProgram & bsv_;
};

bool ParserStateVisitor::preorder(const IR::Type_Header* type) {
  auto hdr = type->to<IR::Type_Header>();
  bsv_.getStructBuilder().append("typedef struct {");
  bsv_.getStructBuilder().newline();
  bsv_.getStructBuilder().increaseIndent();
  for (auto f : *hdr->fields) {
    if (f->type->is<IR::Type_Bits>()) {
      auto width = f->type->to<IR::Type_Bits>()->size;
      auto name = f->name;
      bsv_.getStructBuilder().emitIndent();
      bsv_.getStructBuilder().appendFormat("Bit#(%d) %s;", width, name.toString());
      bsv_.getStructBuilder().newline();
    }
  }
  bsv_.getStructBuilder().decreaseIndent();
  auto name = hdr->name;
  bsv_.getStructBuilder().appendFormat("} %s deriving (Bits, Eq);", CamelCase(name.toString()));
  bsv_.getStructBuilder().newline();
  return false;
}

FPGAParser::FPGAParser(const FPGAProgram* program,
                       const IR::ParserBlock* block,
                       const P4::TypeMap* typeMap,
                       const P4::ReferenceMap* refMap) :
  program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
  refMap(refMap), headers(nullptr), headerType(nullptr) {
}

void FPGAParser::emitEnums(BSVProgram & bsv) {
  // assume all headers are parsed_out
  // optimization opportunity ??
  auto htype = typeMap->getType(headers);
  if (htype == nullptr)
    return;

  for (auto f : *htype->to<IR::Type_Struct>()->fields) {
    auto ftype = typeMap->getType(f);
    if (ftype->is<IR::Type_Header>()) {
      ParserStateVisitor visitor(this, bsv);
      ftype->apply(visitor);
    } else if (ftype->is<IR::Type_Stack>()) {
      auto hstack = ftype->to<IR::Type_Stack>();
      auto header = hstack->elementType->to<IR::Type_Header>();
      ParserStateVisitor visitor(this, bsv);
      header->apply(visitor);
    }
  }
}

void FPGAParser::emitFunctions(BSVProgram & bsv) {
  append_line(bsv, "`ifdef PARSER_FUNCTION");
  for (auto state : states) {
    // find out type and name of each field
    auto name = state->name.toString();
    std::vector<cstring> match;
    std::vector<cstring> params;
    if (state->keys != nullptr) {
      // get type for 'select' keys
      auto type = typeMap->getType(state->keys, true);
      auto tpl = type->to<IR::Type_Tuple>();
      auto keys = state->keys->to<IR::ListExpression>();
      for (auto h : MakeZipRange(*tpl->components, *keys->components)) {
        auto w = h.get<0>();
        auto k = h.get<1>();
        auto name = k->to<IR::Member>();
        auto width = w->width_bits();
        params.push_back("Bit#(" + std::to_string(width) + ") " + name->member);
        match.push_back(name->member);
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
    decr_indent(bsv);
    append_line(bsv, "endcase");
    append_line(bsv, "endaction");
    decr_indent(bsv);
    append_line(bsv, "endfunction");
  }
  append_line(bsv, "`endif");
}

void FPGAParser::emitStructs(BSVProgram & bsv) {
  append_line(bsv, "`ifdef PARSER_STRUCT");
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  for (auto s : states) {
    append_format(bsv, "State%s;", CamelCase(s->name));
  }
  decr_indent(bsv);
  append_line(bsv, "} ParserState deriving (Bits, Eq);");
  append_line(bsv, "`endif");
}

void FPGAParser::emitRules(BSVProgram & bsv) {
  for (auto s : states) {
    auto name = s->name.toString();
    // Rule: load data
    append_format(bsv, "rule rl_%s_load if ((parse_state_ff.first == State%s) && rg_buffered[0] < %d);", name, CamelCase(name), s->width_bits);
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

    // Rule: extract header
    append_format(bsv, "rule rl_%s_extract if ((parse_state_ff.first == State%s) && (rg_buffered[0] > %d));", name, CamelCase(name), s->width_bits);
    incr_indent(bsv);
    append_line(bsv, "let data = rg_tmp[0];");
    append_line(bsv, "if (isValid(data_ff.first)) begin");
    incr_indent(bsv);
    append_line(bsv, "data_ff.deq;");
    append_line(bsv, "data = zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
    decr_indent(bsv);
    append_line(bsv, "end");
    append_line(bsv, "report_parse_action(parse_state_ff.first, rg_buffered[0], data_this_cycle, data);");
    append_line(bsv, "let %s = extract_%s(truncate(data));", name, name);
    append_line(bsv, "compute_next_state_%s();", name);
    append_format(bsv, "rg_tmp[0] <= zeroExtend(data >> %d);", s->width_bits);
    append_format(bsv, "succeed_and_next(%d);", 0);
    append_line(bsv, "parse_state_ff.deq;");
    append_format(bsv, "%s_out_ff.enq(tagged Valid %s)", name, name);
    decr_indent(bsv);
    append_line(bsv, "endrule");
    append_line(bsv, "");

    // Rule: transition rules

  }
}

#define VECTOR_VISIT(V)                         \
for (auto r : V) {                               \
  ParserStateVisitor visitor(this, bsv);  \
  r->apply(visitor);                            \
}

void FPGAParser::emitStates(BSVProgram & bsv) {
  VECTOR_VISIT(rules);
}
#undef VECTOR_VISIT

// emit BSV_IR with BSV-specific CodeGenInspector
void FPGAParser::emit(BSVProgram & bsv) {
  emitEnums(bsv);
  emitStructs(bsv);
  emitFunctions(bsv);
  emitRules(bsv);
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
  ParserBuilder visitor(this, program);
  for (auto state : *states) {
    state->apply(visitor);
  }
  return true;
}

}  // namespace FPGA
