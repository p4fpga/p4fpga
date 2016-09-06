#include "partition.h"

namespace P4 {

const IR::Node* DoPartition::postorder(IR::IfStatement* statement) {
  //auto parent = getContext()->node;
  //LOG1(parent);
  if (start_partition) {
    if (table > 40) {
      return new IR::EmptyStatement(statement->srcInfo);
    }
  }
  return statement;
}

const IR::Node* DoPartition::preorder(IR::IfStatement* statement) {
  if (start_partition) {
    LOG1("if" << statement);
    if (statement->ifTrue != nullptr) {
      visit(statement->ifTrue);
    }
    if (statement->ifFalse != nullptr) {
      visit(statement->ifFalse);
    }
  }
  return statement;
}

const IR::Node* DoPartition::preorder(IR::BlockStatement* statement) {
  auto parent = getContext()->node;
  if (parent->is<IR::P4Control>()) {
    auto p = parent->to<IR::P4Control>();
    LOG1("start partition " << p->name);
    // only partition ingress and egress
    if (p->name == "ingress" || p->name == "egress") {
      start_partition = true;
      table = 0;
      for (auto s : *statement->components) {
        LOG1("Visiting " << s);
        visit(s);
        if (s->is<IR::MethodCallStatement>()) {
          LOG1(table);
        }
      }
      start_partition = false;
    }
  } else {
    if (start_partition) {
      for (auto s : *statement->components) {
        LOG1("visiting " << s);
        visit(s);
        if (s->is<IR::MethodCallStatement>()) {
          LOG1(table);
        }
      }
    }
  }
  return statement;
}

const IR::Node* DoPartition::postorder(IR::BlockStatement* statement) {
  auto parent = getContext()->node;
  return statement;
}

const IR::Node* DoPartition::preorder(IR::MethodCallStatement* statement) {
  auto parent = getContext()->node;
  if (start_partition) {
    table++;
  }
  return statement;
}

const IR::Node* DoPartition::postorder(IR::MethodCallStatement* statement) {
  if (start_partition) {
    if (table > 40) {
      return new IR::EmptyStatement(statement->srcInfo);
    }
  }
  return statement;
}

}  // namespace P4
