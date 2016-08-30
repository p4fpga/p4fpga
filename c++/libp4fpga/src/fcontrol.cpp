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

#include "fcontrol.h"
#include "codegeninspector.h"
#include "ir/ir.h"

/*
 * info associated with a pipeline stage, such as Ingress or Egress
 * - table/control flow nodes
 * - action engines
 *
 * parent: FPGAProgram, stored as individual members
 *
 */

namespace FPGA {

namespace {
class ControlTranslationVisitor : public CodeGenInspector {

 public:
  ControlTranslationVisitor(const FPGAControl* control, BSVProgram& bsv) :
    CodeGenInspector(bsv, control->program->typeMap), bsv_(bsv) {}

    std::vector<cstring> saveAction;

    using CodeGenInspector::preorder;
    bool preorder(const IR::MethodCallStatement* stat) override
    { saveAction.push_back(nullptr); visit(stat->methodCall); saveAction.pop_back(); return false; }
    bool preorder(const IR::MethodCallExpression* expression) override;
    bool preorder(const IR::Method* method) override;
 private:
  BSVProgram & bsv_;
};

bool ControlTranslationVisitor::preorder(const IR::MethodCallExpression* expression) {
  LOG1("Context " << getContext()->parent);
  LOG1("CodeGen: " << expression);
  LOG1("IR::MethodCallExpression: " << expression->method);
  for (auto s: *expression->typeArguments) {
    LOG1("ArgType: " << s);
  }
  for (auto s : *expression->arguments) {
    LOG1("Arg: " << s);
  }
  return false;
}

bool ControlTranslationVisitor::preorder(const IR::Method* method) {
  LOG1("IR::Method: " << method);
  return false;
}
}  // namespace

bool FPGAControl::build() {
  LOG1("control build");
  for (auto c : controlBlock->constantValue) {
    LOG1("constantValue" << c.first);
    auto b = c.second;
    if (!b->is<IR::Block>()) continue;
    if (b->is<IR::TableBlock>()) {
      auto tblblk = b->to<IR::TableBlock>();
      LOG1("tbl " << tblblk);
    } else if (b->is<IR::ExternBlock>()) {
      auto ctrblk = b->to<IR::ExternBlock>();
      LOG1("extern " << ctrblk);
    } else {
      ::error("Unexpected block %s nested within control", b->toString());
    }
  }
  return true;
}

#define VECTOR_VISIT(V)                         \
for (auto r : V) {                               \
  ControlTranslationVisitor visitor(this, bsv);  \
  r->apply(visitor);                            \
}

void FPGAControl::emit(BSVProgram & bsv) {
  // container: P4Control
  // P4Control could be table or deparse state
  // if container contains table

  LOG1("Control Type: " << controlBlock->container->type);
  // container->body has BlockStatement
  auto cbody = controlBlock->container->body;
  // BlockStatement.components has IndexedVector<StatOrDecl> components
  // We can getDeclarations()
  VECTOR_VISIT(*cbody->components);
  for (auto s : *controlBlock->container->getDeclarations()) {
    LOG1("decla: " << s);
  }

  LOG1("getTypeParameters " << controlBlock->container->getTypeParameters());
  LOG1("getDeclarations " << controlBlock->container->getDeclarations());
  LOG1("getApplyMethodType " << controlBlock->container->getApplyMethodType());
  LOG1("getConstructorMethodType " << controlBlock->container->getConstructorMethodType());
  LOG1("getConstructorParameters " << controlBlock->container->getConstructorParameters());
}
#undef VECTOR_VISIT

}  // namespace FPGA
