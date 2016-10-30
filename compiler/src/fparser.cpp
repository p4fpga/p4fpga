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
#include "string_utils.h"
#include "vector_utils.h"

namespace FPGA {


class SelectStmtCodeGen : public Inspector {
 public:
  explicit SelectStmtCodeGen ( const IR::ParserState* state,
                               const P4::TypeMap* typeMap,
                               CodeBuilder* builder) :
    builder(builder), typeMap(typeMap), state(state) {}
  bool preorder(const IR::SelectExpression* expr) override;
  bool preorder(const IR::ListExpression* expr) override;
  bool preorder(const IR::PathExpression* path) override;
  bool preorder(const IR::SelectCase* cas) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
  std::vector<cstring> match;
  std::vector<cstring> params;
  void emitFunctionProlog();
  void emitFunctionEpilog();
};

bool SelectStmtCodeGen::preorder(const IR::ListExpression* expr) {
  // QUESTION: how does typeMap maps ListExpression to Tuple#(Type_Bits)??
  auto widthTuple = typeMap->getType(expr, true);
  CHECK_NULL(widthTuple);
  const IR::Type_Tuple* tpl = widthTuple->to<IR::Type_Tuple>();
  CHECK_NULL(tpl);
  // select -> (Bit#(n) key1, Bit#(n) key2) and list (key1, key2)
  for (auto h : MakeZipRange(*tpl->components, *expr->components)) {
    auto w = h.get<0>();
    auto k = h.get<1>();
    const IR::Member* member = k->to<IR::Member>();
    if (member != nullptr) {
      int width = w->width_bits();
      // LOG1(" >>> select key " << member);
      params.push_back("Bit#(" + std::to_string(width) + ") " + member->member);
      match.push_back(member->member);
    } else {
      ::error("lookahead not handled yet");
    }
  }
  // LOG1("param: " << params);
  // LOG1("match: " << match);
  return false;
}

void SelectStmtCodeGen::emitFunctionProlog() {
  cstring name = state->name.toString();
  if (params.size() != 0) {
    builder->append_format("function Action compute_next_state_%s(%s);", name, join(params, ","));
  } else {
    builder->append_format("function Action compute_next_state_%s();", name);
  }
  builder->incr_indent();
  builder->append_line("action");
  if (match.size() != 0) {
    builder->append_format("let v = {%s};", join(match, ","));
  } else {
    builder->append_line("let v = 0;");
  }
}

void SelectStmtCodeGen::emitFunctionEpilog() {
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
}

bool SelectStmtCodeGen::preorder(const IR::SelectCase* cas) {
  cstring name = state->name.toString();
  if (cas->keyset->is<IR::Constant>()) {
    builder->append_format("%d: begin", cas->keyset->toString());
    builder->incr_indent();
    builder->append_line("w_%s_%s.send();", name, cas->state->toString());
    builder->decr_indent();
    builder->append_line("end");
  } else if (cas->keyset->is<IR::DefaultExpression>()) {
    builder->append_line("default: begin");
    builder->incr_indent();
    builder->append_line("w_%s_%s.send();", name, cas->state->toString());
    builder->decr_indent();
    builder->append_line("end");
  }
  return false;
}

bool SelectStmtCodeGen::preorder(const IR::SelectExpression* expr) {
  // class SelectExpression : Expression
  //   ListExpression            select;
  //   inline Vector<SelectCase> selectCases;
  CHECK_NULL(typeMap);
  builder->append_line("`ifdef PARSER_FUNCTION");
  visit(expr->select);
  emitFunctionProlog();
  builder->append_line("case(v) matches");
  builder->incr_indent();
  for (auto c: expr->selectCases) {
    visit(c);
  }
  builder->decr_indent();
  builder->append_line("endcase");
  emitFunctionEpilog();
  builder->append_line("`endif");
  return false;
}

bool SelectStmtCodeGen::preorder(const IR::PathExpression* path) {
  builder->append_line("`ifdef PARSER_FUNCTION");
  builder->append_line("function Action compute_next_state_%s();", state->toString());
  builder->incr_indent();
  builder->append_line("action");
  builder->append_line("w_%s_%s.send();", state->toString(), path->toString());
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->append_line("`endif");
  return false;
}

class ExtractStmtCodeGen : public Inspector {
 public:
  explicit ExtractStmtCodeGen( const IR::ParserState* state,
                               const P4::TypeMap* typeMap,
                               CodeBuilder* builder,
                               int& num_rules) :
    builder(builder), typeMap(typeMap), state(state), num_rules(num_rules) {}
  bool preorder(const IR::MethodCallExpression* expr) override;
  bool preorder(const IR::SelectCase* cas) override;
  bool preorder(const IR::SelectExpression* expr) override;
  bool preorder(const IR::PathExpression* expr) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
  int& num_rules;
  std::set<cstring> visited;
};

bool ExtractStmtCodeGen::preorder (const IR::SelectCase* cas) {
  cstring this_state = state->name.toString();
  if (cas->keyset->is<IR::Constant>()) {
    cstring next_state = cas->state->toString();
    if (visited.find(this_state + next_state) != visited.end()) {
      return false;
    }
    if (next_state == "accept") {
      builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_%s_%s))));", this_state, next_state);
    } else {
      builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_%s_%s, State%s, valueOf(%sSz)))));", this_state, next_state, CamelCase(next_state), CamelCase(next_state));
    }
    visited.insert(this_state + next_state);
    num_rules++;
  } else if (cas->keyset->is<IR::DefaultExpression>()) {
    cstring next_state = cas->state->toString();

    if (visited.find(this_state + next_state) != visited.end()) {
      return false;
    }

    if (next_state == "accept") {
      builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_%s_%s))));", this_state, next_state);
    } else {
      builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genContRule(w_%s_%s, State%s, valueOf(%sSz)))));", this_state, next_state, CamelCase(next_state), CamelCase(next_state));
    }

    visited.insert(this_state + next_state);
    num_rules++;
  }
  return false;
}

bool ExtractStmtCodeGen::preorder (const IR::SelectExpression* expr) {
  for (auto c: expr->selectCases) {
    visit(c);
  }
  return false;
}

bool ExtractStmtCodeGen::preorder (const IR::PathExpression* expr) {
  cstring this_state = state->name.toString();
  //builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genAcceptRule(w_%s_%s))));", this_state, expr->toString());
  //num_rules++;
  return false;
}

bool ExtractStmtCodeGen::preorder (const IR::MethodCallExpression* expr) {
  cstring this_state = state->name.toString();
  for (auto h: MakeZipRange(*expr->typeArguments, *expr->arguments)) {
    auto typeName = h.get<0>();
    auto instName = h.get<1>();
    //FIXME: must fix for stack
    // const IR::Member* member = instName->to<IR::Member>();
    // if (member->member == "next") {
    //   ::error("must not print next as state");
    // }
    builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genLoadRule(State%s, valueOf(%sSz)))));", CamelCase(this_state), CamelCase(this_state));
    num_rules++;
    builder->append_line("`COLLECT_RULE(parse_fsm, joinRules(vec(genExtractRule(State%s, valueOf(%sSz)))));", CamelCase(this_state), CamelCase(this_state));
    num_rules++;
  }
  return false;
}

class ExtractLenCodeGen : public Inspector {
 public:
  explicit ExtractLenCodeGen ( const IR::ParserState* state,
                               const P4::TypeMap* typeMap,
                               CodeBuilder* builder) :
    builder(builder), typeMap(typeMap), state(state) {}
  bool preorder(const IR::MethodCallExpression* expr) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
};

bool ExtractLenCodeGen::preorder (const IR::MethodCallExpression* expr) {
  LOG1("<<<" << expr->method->toString());
  if (expr->method->toString() == "packet.extract") {
    for (auto h: MakeZipRange(*expr->typeArguments, *expr->arguments)) {
      auto typeName = h.get<0>();
      auto instName = h.get<1>();
      auto header_type = typeMap->getType(typeName, true);
      CHECK_NULL(header_type);
      int header_width = header_type->width_bits();
      builder->append_line("typedef %d %sSz;", header_width, CamelCase(state->toString()));
    }
  } else if (expr->method->toString() == "packet.lookahead") {
    ::warning("look ahead not handled");
  }
  return false;
}

class ExtractFuncCodeGen : public Inspector {
 public:
  explicit ExtractFuncCodeGen ( const IR::ParserState* state,
                                const P4::TypeMap* typeMap,
                                CodeBuilder* builder) :
    builder(builder), typeMap(typeMap), state(state) {
      printPath = false;
    }
  bool preorder(const IR::MethodCallExpression* expr) override;
  bool preorder(const IR::ListExpression* expr) override;
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::Member* member) override;
  bool preorder(const IR::Constant* constant) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
  std::vector<cstring> match;
  bool printPath;
  int index = 0;
};

bool ExtractFuncCodeGen::preorder(const IR::ListExpression* expr) {
  // select -> list (key1, key2)
  for (auto h : *expr->components) {
    const IR::Member* member = h->to<IR::Member>();
    // header->member corresponding IR.
    // <Vector<Expression>>(1558), size=1
    //   <Member>(1557)ethernet
    //     <PathExpression>(1537)
    //       <Path>(1538):hdr */
    if (member != nullptr) {
      auto header = member->expr->to<IR::Member>();
      cstring name = header->member.toString() + "." + member->member.toString();
      match.push_back(name);
    } else {
      ::error("lookahead not handled yet");
    }
  }
  return false;
}

bool ExtractFuncCodeGen::preorder (const IR::AssignmentStatement* stmt) {
  if (stmt->right->is<IR::Member>()) {
    const IR::Member* expr = stmt->right->to<IR::Member>();
    const IR::Member* header = expr->expr->to<IR::Member>();
    cstring src_name = header->member.toString() + "." + expr->member.toString();

    if (stmt->left->is<IR::Member>()) {
      const IR::Member* left = stmt->left->to<IR::Member>();
      auto type = typeMap->getType(left->expr);
      const IR::Member* dst_hdr = left->expr->to<IR::Member>();
      CHECK_NULL(dst_hdr);
      cstring dst_name = dst_hdr->member.toString();
      cstring tmp_var = left->member.toString();

      builder->append_line("let %s = %s;", tmp_var, src_name);

      builder->emitIndent();
      builder->appendFormat("%s ", CamelCase(type->getP4Type()->toString()));
      builder->appendFormat("%s ", dst_name);
      builder->appendLine("= defaultValue;");

      builder->emitIndent();
      builder->appendFormat("%s.%s", dst_name, tmp_var);
      builder->appendFormat("= %s;", tmp_var);
      builder->newline();

      builder->emitIndent();
      builder->appendFormat("rg_%s", dst_name);
      builder->appendFormat("<= tagged Valid %s;", dst_name);
      builder->newline();
    }
  } else if (stmt->right->is<IR::Operation_Binary>()) {
    auto expr = stmt->right->to<IR::Operation_Binary>();
    if (stmt->left->is<IR::Member>()) {
      const IR::Member* left = stmt->left->to<IR::Member>();
      auto type = typeMap->getType(left->expr);
      const IR::Member* dst_hdr = left->expr->to<IR::Member>();
      CHECK_NULL(dst_hdr);
      cstring dst_name = dst_hdr->member.toString();
      cstring tmp_var = left->member.toString();

      builder->emitIndent();
      builder->appendFormat("%s ", CamelCase(type->getP4Type()->toString()));
      builder->appendFormat("%s ", dst_name);
      builder->appendFormat("= fromMaybe(?, rg_%s);", dst_name);
      builder->newline();

      // build expression tree properly
      builder->emitIndent();
      builder->appendFormat("let %s = ", tmp_var);
      printPath=true;
      visit(expr->left);
      builder->appendFormat(stmt->right->toString());
      visit(expr->right);
      printPath=false;
      builder->appendLine(";");

      builder->emitIndent();
      builder->appendFormat("%s.%s", dst_name, tmp_var);
      builder->appendFormat("= %s;", tmp_var);
      builder->newline();

      builder->emitIndent();
      builder->appendFormat("rg_%s", dst_name);
      builder->appendFormat("<= tagged Valid %s;", dst_name);
      builder->newline();
    }
  }
  return false;
}

bool ExtractFuncCodeGen::preorder (const IR::Member* member) {
  if (!printPath) return false;
  const IR::Member* dst_hdr = member->expr->to<IR::Member>();
  CHECK_NULL(dst_hdr);
  cstring dst_name = dst_hdr->member.toString();
  cstring dst_field = member->member.toString();
  cstring dst_path = dst_name + "." + dst_field;
  builder->appendFormat("%s", dst_path);
  return false;
}

bool ExtractFuncCodeGen::preorder (const IR::Constant* constant) {
  if (!printPath) return false;
  builder->appendFormat(constant->toString());
  return false;
}

bool ExtractFuncCodeGen::preorder (const IR::MethodCallExpression* expr) {
  cstring this_state = state->name.toString();
  visit(state->selectExpression);
  for (auto h: MakeZipRange(*expr->typeArguments, *expr->arguments)) {
    auto typeName = h.get<0>();
    auto instName = h.get<1>();
    auto header_type = typeMap->getType(typeName, true);
    int header_width = header_type->width_bits();
    const IR::Member* member = instName->to<IR::Member>();
    cstring header = member->member.toString();
    builder->append_line("let %s = extract_%s(truncate(data));", header, typeName->toString());
    for (auto stmt : *state->components) {
      if (stmt->is<IR::AssignmentStatement>()) {
        visit(stmt);
      }
    }

    builder->append_line("Header#(%s) header%d = defaultValue;", CamelCase(typeName->toString()), index);
    builder->append_line("header%d.hdr = %s;", index, header);
    builder->append_line("header%d.state = tagged Forward;", index);
    builder->append_format("%s_out_ff.enq(tagged Valid header%d);", header, index);
    index++;
  }
  if (match.size() != 0) {
    builder->append_format("compute_next_state_%s(%s);", this_state, join(match, ","));
  } else {
    builder->append_format("compute_next_state_%s();", this_state);
  }
  return false;
}

class PulseWireCodeGen : public Inspector {
 public:
  explicit PulseWireCodeGen ( const IR::ParserState* state,
                              const P4::TypeMap* typeMap,
                              CodeBuilder* builder) :
    builder(builder), typeMap(typeMap), state(state) {}
  bool preorder(const IR::SelectCase* cas) override;
  bool preorder (const IR::SelectExpression* expr) override;
  bool preorder (const IR::PathExpression* expr) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
  std::set<cstring> visited;
};

bool PulseWireCodeGen::preorder(const IR::SelectCase* cas) {
  cstring this_state = state->name.toString();
  cstring next_state = cas->state->toString();
  if (visited.find(next_state) != visited.end()) {
    return false;
  }
  if (cas->keyset->is<IR::Constant>()) {
    builder->append_line("PulseWire w_%s_%s <- mkPulseWire();", this_state, next_state);
    visited.insert(next_state);
  } else if (cas->keyset->is<IR::DefaultExpression>()) {
    builder->append_line("PulseWire w_%s_%s <- mkPulseWire();", this_state, next_state);
    visited.insert(next_state);
  }
  return false;
}

bool PulseWireCodeGen::preorder(const IR::PathExpression* expr) {
  cstring this_state = state->name.toString();
  cstring next_state = expr->toString();
  if (visited.find(next_state) != visited.end()) {
    return false;
  }
  builder->append_line("PulseWire w_%s_%s <- mkPulseWire();", this_state, next_state);
  visited.insert(next_state);
  return false;
}

bool PulseWireCodeGen::preorder (const IR::SelectExpression* expr) {
  for (auto c: expr->selectCases) {
    visit(c);
  }
  return false;
}

class DfifoCodeGen : public Inspector {
 public:
  explicit DfifoCodeGen (const IR::ParserState* state,
                         const P4::TypeMap* typeMap,
                         CodeBuilder* builder) :
    builder(builder), typeMap(typeMap), state(state) {}
  bool preorder(const IR::MethodCallExpression* expr) override;

 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::TypeMap* typeMap;
  std::set<cstring> visited;
};

bool DfifoCodeGen::preorder(const IR::MethodCallExpression* expr) {
  if (expr->method->toString() == "packet.extract") {
    for (auto h: MakeZipRange(*expr->typeArguments, *expr->arguments)) {
      auto typeName = h.get<0>();
      auto instName = h.get<1>();
      cstring type = CamelCase(typeName->toString());
      const IR::Member* member = instName->to<IR::Member>();
      cstring name = member->member;
      if (visited.find(name) != visited.end()) {
        return false;
      }
      builder->append_line("FIFOF#(Maybe#(Header#(%s))) %s_out_ff <- mkDFIFOF(tagged Invalid);", type, name);
      visited.insert(name);
    }
  } else if (expr->method->toString() == "packet.lookahead") {
    ::warning("look ahead not handled");
  }
  return false;
}

class RegCodeGen : public Inspector {
 public:
  explicit RegCodeGen (const P4::TypeMap* typeMap,
                       CodeBuilder* builder) :
    builder(builder), typeMap(typeMap) {}
  bool preorder(const IR::Type_Struct* strt);
 private:
  CodeBuilder* builder;
  const P4::TypeMap* typeMap;
};

bool RegCodeGen::preorder(const IR::Type_Struct* strt) {
  for (auto f : *strt->fields) {
    auto type = typeMap->getType(f);
    auto type_name = CamelCase(type->getP4Type()->toString());
    auto name = f->toString();
    builder->append_line("Reg#(Maybe#(%s)) rg_%s <- mkReg(tagged Invalid);", type_name, name);
  }
  return false;
}

class InitStateCodeGen : public Inspector {
 public:
  explicit InitStateCodeGen (const IR::ParserState* state,
                             const P4::ReferenceMap* refMap,
                             CodeBuilder* builder) :
    builder(builder), state(state), refMap(refMap) {}
  bool preorder(const IR::ParserState* state) override;
 private:
  CodeBuilder* builder;
  const IR::ParserState* state;
  const P4::ReferenceMap* refMap;
};

bool InitStateCodeGen::preorder(const IR::ParserState* state) {
  if (state->name.toString() == "start") {
    // NOTE: assume start state is actually called 'start'
    if (state->components->size() == 0) {
      if (state->selectExpression->is<IR::PathExpression>()) {
        auto expr = state->selectExpression->to<IR::PathExpression>();
        auto inst = refMap->getDeclaration(expr->path, true);
        if (inst->is<IR::ParserState>()) {
          auto pstate = inst->to<IR::ParserState>();
          builder->append_line("let initState = State%s;", CamelCase(pstate->name.toString()));
        }
      }
    } else {
      builder->append_line("let initState = State%s;", CamelCase(state->name.toString()));
    }
  }
  return false;
}

FPGAParser::FPGAParser(FPGAProgram* program,
                       const IR::ParserBlock* block,
                       const P4::TypeMap* typeMap,
                       const P4::ReferenceMap* refMap) :
  program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
  refMap(refMap), headers(nullptr), headerType(nullptr) {
}

// FIXME: stack is not handled
void FPGAParser::emitEnums(BSVProgram & bsv) {
  builder->append_line("`ifdef PARSER_STRUCT");
  builder->append_line("typedef enum {");
  builder->incr_indent();
  std::vector<cstring> state_vec;
  for (auto state: *parserBlock->container->states) {
    state_vec.push_back(state->name.toString());
  }
  for (auto s : state_vec) {
    if (s == state_vec.back())
      builder->append_format("State%s", CamelCase(s));
    else
      builder->append_format("State%s,", CamelCase(s));
  }
  builder->decr_indent();
  builder->append_line("} ParserState deriving (Bits, Eq);");
  builder->append_line("`endif");
}

void FPGAParser::emitStructs(BSVProgram & bsv) {
  // assume all headers are parsed_out
  // optimization opportunity ??
  auto type = typeMap->getType(headers);
  CHECK_NULL(type);

  CodeBuilder* struct_builder = &bsv.getStructBuilder();
  StructCodeGen visitor(program, struct_builder);

  const IR::Type_Struct* ir_struct = type->to<IR::Type_Struct>();
  CHECK_NULL(ir_struct);

  for (auto f : *ir_struct->fields) {
    auto field_t = typeMap->getType(f);
    if (field_t->is<IR::Type_Header>()) {
      field_t->apply(visitor);
    } else if (field_t->is<IR::Type_Stack>()) {
      const IR::Type_Stack* stack_t = field_t->to<IR::Type_Stack>();
      const IR::Type_Header* header_t = stack_t->elementType->to<IR::Type_Header>();
      CHECK_NULL(header_t);
      header_t->apply(visitor);
    }
  }

  auto meta = typeMap->getType(userMetadata);
  CHECK_NULL(meta);

  const IR::Type_Struct* meta_struct = meta->to<IR::Type_Struct>();
  CHECK_NULL(meta_struct);

  for (auto f : *meta_struct->fields) {
    auto field_t = typeMap->getType(f);
    if (field_t->is<IR::Type_Struct>()) {
      field_t->apply(visitor);
    }
  }
}

// convert every field in struct headers to its origial header type
void FPGAParser::emitAcceptedHeaders(BSVProgram & bsv, const IR::Type_Struct* headers) {
  for (auto h : *headers->fields) {
    auto node = h->getNode();
    auto type = typeMap->getType(node, true);
    auto name = h->name.toString();
    if (type->is<IR::Type_Header>()) {
      builder->append_format("let %s <- toGet(%s_out_ff).get;", name, name);
      builder->append_format("meta.hdr.%s = %s;", name, name);
      for (auto m : program->metadata) {
        auto member = m.second;
        auto ftype = program->typeMap->getType(member->expr, true);
        auto structT = ftype->to<IR::Type_StructLike>();
        auto field = structT->getField(member->member);
        cstring fname = field->name.toString();
      }
    } else if (type->is<IR::Type_Stack>()) {
      ::warning("TODO: generate out_ff for header stack;");
    } else {
      ::error("Unknown header type ", type);
    }
  }
}

// User declared metadata are used in two places:
// - parser
// - pipeline
// When used in parser, there is no need to create an out_ff.
//
void FPGAParser::emitUserMetadata(BSVProgram & bsv, const IR::Type_Struct* metadata) {
  for (auto h : *metadata->fields) {
    cstring header = h->toString();
    builder->append_line("meta.meta.%s = rg_%s;", header, header);
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
  //builder->append_line("rg_shift_amt[0] <= 0;");
  builder->append_line("rg_buffered[0] <= 0;");
  builder->append_line("meta_in_ff.enq(meta);");
  builder->decr_indent();
  builder->append_line("endrule");
}

// emit BSV_IR with BSV-specific CodeGenInspector
void FPGAParser::emit(BSVProgram & bsv) {
  CHECK_NULL(typeMap);

  builder = &bsv.getParserBuilder();

  // translate
  emitEnums(bsv);
  // translate
  emitStructs(bsv);

  // translate select statement to bluespec function
  for (auto state: *parserBlock->container->states) {
    SelectStmtCodeGen selectCodeGen(state, typeMap, builder);
    state->selectExpression->apply(selectCodeGen);
  }

  builder->append_line("`ifdef PARSER_FUNCTION");
  for (auto state: *parserBlock->container->states) {
    InitStateCodeGen initStateCodeGen(state, refMap, builder);
    state->apply(initStateCodeGen);
  }
  builder->append_line("`endif");

  builder->append_line("`ifdef PARSER_STRUCT");
  int num_rules = 0;
  for (auto state: *parserBlock->container->states) {
    ExtractLenCodeGen extractLenCodeGen(state, typeMap, builder);
    state->apply(extractLenCodeGen);
  }
  builder->append_line("`endif");

  builder->append_line("`ifdef PARSER_FUNCTION");
  builder->append_line("function Action extract_header(ParserState state, Bit#(512) data);");
  builder->incr_indent();
  builder->append_line("action");
  builder->append_line("case (state) matches");
  builder->incr_indent();
  for (auto state: *parserBlock->container->states) {
    cstring this_state = state->name.toString();
    builder->append_line("State%s : begin", CamelCase(this_state));
    builder->incr_indent();
    ExtractFuncCodeGen extractCodeGen(state, typeMap, builder);
    state->apply(extractCodeGen);
    builder->decr_indent();
    builder->append_line("end");
  }
  builder->decr_indent();
  builder->append_line("endcase");
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->append_line("`endif");

  builder->append_line("`ifdef PARSER_RULES");
  for (auto state: *parserBlock->container->states) {
    ExtractStmtCodeGen extractCodeGen(state, typeMap, builder, num_rules);
    state->apply(extractCodeGen);
  }
  builder->append_line("Vector#(%d, Rules) fsmRules = toVector(parse_fsm);", num_rules);
  builder->append_line("`endif");

  builder->append_line("`ifdef PARSER_RULES");
  emitAcceptRule(bsv);
  builder->append_line("`endif");

  // emit state variables
  // PulseWire for state transition
  builder->append_line("`ifdef PARSER_STATE");
  for (auto state: *parserBlock->container->states) {
    PulseWireCodeGen pulsewireCodeGen(state, typeMap, builder);
    state->selectExpression->apply(pulsewireCodeGen);
  }

  // DFIFOF for exporting extracted header
  for (auto state: *parserBlock->container->states) {
    DfifoCodeGen dfifoCodeGen(state, typeMap, builder);
    state->apply(dfifoCodeGen);
  }

  // Register for local metadata modified by set_metadata()
  auto usermeta = typeMap->getType(userMetadata);
  RegCodeGen visitor(typeMap, builder);
  usermeta->apply(visitor);

  builder->append_line("`endif");
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
  return true;
}

}  // namespace FPGA
