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

#include "vector_utils.h"

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

class TableTranslationVisitor : public Inspector {
 public:
  TableTranslationVisitor(FPGAControl* control) :
    control(control) {}
  bool preorder(const IR::TableBlock* table) override;
 private:
  FPGAControl* control;
};

bool TableTranslationVisitor::preorder(const IR::TableBlock* table) {
  //LOG1("Table " << table);
  for (auto act : *table->container->getActionList()->actionList) {
    auto element = act->to<IR::ActionListElement>();
    if (element->expression->is<IR::PathExpression>()) {
      //LOG1("Path " << element->expression->to<IR::PathExpression>());
    } else if (element->expression->is<IR::MethodCallExpression>()) {
      auto expression = element->expression->to<IR::MethodCallExpression>();
      auto type = control->program->typeMap->getType(expression->method, true);
      auto action = expression->method->toString();
      control->action_to_table[action] = table->container;
    }
  }

  // visit keys
  auto keys = table->container->getKey();
  if (keys == nullptr) return false;

  for (auto key : *keys->keyElements) {
    auto element = key->to<IR::KeyElement>();
    if (element->expression->is<IR::Member>()) {
      auto m = element->expression->to<IR::Member>();
      auto type = control->program->typeMap->getType(m->expr, true);
      if (type->is<IR::Type_Struct>()) {
        auto t = type->to<IR::Type_StructLike>();
        //LOG1("header meta " << t->getField(m->member) << " " << table);
        auto f = t->getField(m->member);
        control->metadata_to_table[f].insert(table->container);
      }
    }
  }
  return false;
}

class ActionTranslationVisitor : public Inspector {
 public:
  ActionTranslationVisitor(FPGAControl* control, cstring name) : 
    control(control), name(name) {}
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::Expression* expression) override;
 private:
  FPGAControl* control;
  cstring name;
};

bool ActionTranslationVisitor::preorder(const IR::AssignmentStatement* stmt) {
  //LOG1("assignment " << stmt->left << stmt->right);
  visit(stmt->left);
  //FIXME: only take care of metadata write
  //visit(stmt->right);
  return false;
}

bool ActionTranslationVisitor::preorder(const IR::Expression* expression) {
  // accessing part of metadata struct, thus member type
  if (expression->is<IR::Member>()) {
    auto m = expression->to<IR::Member>();
    auto type = control->program->typeMap->getType(m->expr, true);
    if (type->is<IR::Type_Struct>()) {
      auto t = type->to<IR::Type_StructLike>();
      auto f = t->getField(m->member);
      control->metadata_to_action[f] = name;
    }
  }
  return false;
}

bool FPGAControl::build() {
  LOG1("Build " << controlBlock->container->toString());
  for (auto s : *controlBlock->container->getDeclarations()) {
    if (s->is<IR::P4Action>()) {
      auto act = s->to<IR::P4Action>();
      // LOG1("declare: " << act->name);
      // build map from metadata to table
      auto stmt = act->body->to<IR::BlockStatement>();
      if (stmt == nullptr) continue;

      ActionTranslationVisitor visitor(this, act->name);
      for (auto path : *stmt->components) {
        path->apply(visitor);
      }
    }
  }

  // constainValue : compile-time allocated resource, such as table..
  for (auto c : controlBlock->constantValue) {
    auto b = c.second;
    if (!b->is<IR::Block>()) continue;
    if (b->is<IR::TableBlock>()) {
      auto tblblk = b->to<IR::TableBlock>();
      TableTranslationVisitor visitor(this);
      tblblk->apply(visitor);
      LOG1("table: " << tblblk);
    } else if (b->is<IR::ExternBlock>()) {
      auto ctrblk = b->to<IR::ExternBlock>();
      LOG1("extern " << ctrblk);
    } else {
      ::error("Unexpected block %s nested within control", b->toString());
    }
  }

  for (auto n : metadata_to_action) {
    // LOG1("action " << n.first << action_to_table[n.second]);
    metadata_to_table[n.first].insert(action_to_table[n.second]);
  }

  for (auto n : metadata_to_table) {
    LOG1("metadata " << n.first << n.second);
    for (auto n1 : n.second) {
      for (auto n2 : n.second) {
        if (n1 == n2) continue;
        std::pair<const IR::StructField*, const IR::P4Table*> p (n.first, n2);
        adj_list[n1].insert(p);
      }
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
  if (controlBlock->container->body != nullptr) {
    auto cbody = controlBlock->container->body;
    VECTOR_VISIT(*cbody->components);
  }
}
#undef VECTOR_VISIT

// table as vertex, metadata as edge
void FPGAControl::plot_v_table_e_meta(Graph & graph) {
  Dot::append_line(graph, "graph g {");
  Dot::append_line(graph, "concentrate=true;");
  Dot::incr_indent(graph);
  for (auto n : adj_list) {
    for (auto m : n.second) {
      Dot::append_format(graph, "%s -- %s [ label = \"%s\"];", n.first->name.toString(), m.second->name.toString(), m.first);
      //Dot::append_format(graph, "%s -- %s;", n.first->name.toString(), m.second->name.toString());
    }
  }
  Dot::decr_indent(graph);
  Dot::append_line(graph, "}");
}

// metadata as vertex, table as edge
void FPGAControl::plot_v_meta_e_table(Graph & graph) {
  std::map<const IR::StructField*, int> weight;
  int metadata_total_width = 0;
  Dot::append_line(graph, "graph g {");
  Dot::append_line(graph, "concentrate=true;");
  Dot::incr_indent(graph);
  for (auto n : metadata_to_table) {
    if (n.first->type->is<IR::Type_Bits>()) {
      auto width = n.first->type->to<IR::Type_Bits>()->size;
      // LOG1(n.first << " " << width);
      metadata_total_width += width;
    }
    for (auto m : metadata_to_table) {
      if (m == n) continue;
      for (auto t : n.second) {
        std::set<const IR::P4Table*>::iterator it;
        it = m.second.find(t);
        if (it != m.second.end()) {
          //Dot::append_format(graph, "%s -- %s [ label = \"%s\"];", n.first->name.toString(), m.first->name.toString(), t->name.toString());
          weight[n.first]++;
        }
      }
    }
  }
  LOG1("Total metadata width " << metadata_total_width);
  Dot::decr_indent(graph);
  Dot::append_line(graph, "}");
}

}  // namespace FPGA
