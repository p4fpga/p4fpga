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

#include "fdeparser.h"
#include "ir/ir.h"
#include "vector_utils.h"

namespace FPGA {

class DeparserTranslationVisitor : public Inspector {

 public:
  DeparserTranslationVisitor(const FPGADeparser* deparser, BSVProgram& bsv) :
    bsv_(bsv) {}

    std::vector<cstring> saveAction;

    bool preorder(const IR::MethodCallStatement* stat) override
    { saveAction.push_back(nullptr); visit(stat->methodCall); saveAction.pop_back(); return false; }
    bool preorder(const IR::MethodCallExpression* expression) override;
    bool preorder(const IR::Method* method) override;
 private:
  const FPGAProgram* program;
  BSVProgram & bsv_;
};

bool DeparserTranslationVisitor::preorder(const IR::MethodCallExpression* expression) {
  return false;
}

bool DeparserTranslationVisitor::preorder(const IR::Method* method) {
  return false;
}

class DeparserBuilder : public Inspector {
 public:
  DeparserBuilder(FPGADeparser* deparser, const FPGAProgram* program) :
    deparser(deparser), program(program) {}
  bool preorder(const IR::MethodCallStatement* stat) override
  { visit(stat->methodCall); return false; }
  bool preorder(const IR::MethodCallExpression* expression) override;
  bool preorder(const IR::Method* method) override;
  bool preorder(const IR::PathExpression* expr) override;
  bool preorder(const IR::Member* member) override;
  bool preorder(const IR::Path* path) override;
 private:
  const FPGAProgram* program;
  FPGADeparser* deparser;
};

bool DeparserBuilder::preorder(const IR::MethodCallExpression* expression) {
  // packet.emit
  auto emit = expression->method;
  for (auto h : MakeZipRange(*expression->typeArguments, *expression->arguments)) {
    auto hdr_type = h.get<0>();
    auto hdr_inst = h.get<1>();
    auto type_name = program->typeMap->getType(hdr_type, true);
    LOG1(hdr_type << hdr_inst << type_name);
    // Header Width
    auto hdr_width = hdr_type->width_bits();
    // Header Fields
    if (type_name->is<IR::Type_StructLike>()) {
      auto t = type_name->to<IR::Type_StructLike>();
      LOG1("xxx " << t->name << t->fields);
      deparser->states.push_back(new IR::BSV::DeparseState("test", t->fields, hdr_width));
    }
  }
  return false;
}

bool DeparserBuilder::preorder(const IR::Member* member) {
  LOG1("member expr " << member->expr->node_type_name());
  if (member->expr->is<IR::PathExpression>()) {
    auto et = member->expr->to<IR::PathExpression>();
    LOG1(et->path->name);
  }
  LOG1("member " << member->member);
  return false;
}

#define VECTOR_VISIT(V)                         \
for (auto r : V) {                               \
  DeparserTranslationVisitor visitor(this, bsv);  \
  r->apply(visitor);                            \
}

// Convert emit() to IR::BSV::DeparseState
bool FPGADeparser::build() {
  //LOG1(program->typeMap);
  auto stat = controlBlock->container->body;
  DeparserBuilder visitor(this, program);
  stat->apply(visitor);
  return true;
}

void FPGADeparser::emitModule(BSVProgram & bsv) {
  bsv.getDeparserBuilder().appendLine("module mkDeparser (Deparser);");
  bsv.getDeparserBuilder().increaseIndent();
  bsv.getDeparserBuilder().emitIndent();
}

void FPGADeparser::emit(BSVProgram & bsv) {
  // emitHeaders();
  emitModule(bsv);
  // emitInterface();
}

}  // namespace FPGA
