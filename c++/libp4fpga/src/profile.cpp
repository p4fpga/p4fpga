#include "profile.h"

namespace P4 {

bool DoResourceEstimation::preorder(const IR::P4Control* control) {
  if (control->name == "ingress" || control->name == "egress") {
    for (auto s : *control->controlLocals) {
      visit(s);
    }
  }
  return false;
}

bool DoResourceEstimation::preorder(const IR::P4Table* table) {
  int size_ = 0;
  for (auto p : *table->properties->properties) {
    if (p->is<IR::TableProperty>()) {
      auto pp = p->to<IR::TableProperty>();
      if (pp->name == "size") {
        auto expr = pp->value->to<IR::ExpressionValue>();
        if (expr->expression->is<IR::Constant>()) {
          auto cst = expr->expression->to<IR::Constant>();
          size_ = cst->asInt();
        }
      } else if (pp->name == "default_action") {
      } else {
        visit(pp->value);
      }
    }
  }
  // pretty print to file
  profgen->getTableProfiler().appendFormat("%d %d %s %s", size_, width_bit, table_type, table->name.toString());
  profgen->getTableProfiler().newline();

  // reset temporary variables
  width_bit = 0;
  table_type = "exact";
  return false;
}

bool DoResourceEstimation::preorder(const IR::ActionList* action) {
  width_bit += std::ceil(log2f(action->actionList->size()));
  return false;
}

bool DoResourceEstimation::preorder(const IR::Key* key) {
  int width_ = 0;
  cstring type_ = "exact";
  for (auto k : *key->keyElements) {
    auto e = k->to<IR::KeyElement>();
    if (e == nullptr) continue;

    auto t = typeMap->getType(e->expression, true);
    if (t->is<IR::Type_Bits>()) {
      auto tb = t->to<IR::Type_Bits>();
      width_ += tb->width_bits();
      if (e->matchType->is<IR::PathExpression>()) {
        auto type = e->matchType->to<IR::PathExpression>();
        if (type->path->name == "ternary") {
          type_ = "ternary";
        } else if (type->path->name == "lpm") {
          type_ = "lpm";
        }
      }
    }
  }

  table_type = type_;
  width_bit += width_;
  return false;
}

}  // namespace P4
