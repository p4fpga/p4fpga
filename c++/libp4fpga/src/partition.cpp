#include "partition.h"

namespace P4 {

const IR::Node* DoPartition::preorder(IR::IfStatement* statement) {
  if (start_partition) {
    if (statement->ifTrue != nullptr) {
      visit(statement->ifTrue);
    }
    if (statement->ifFalse != nullptr) {
      visit(statement->ifFalse);
    }
  }
  return statement;
}

const IR::Node* DoPartition::postorder(IR::IfStatement* statement) {
  if (start_partition) {
    // clean up if statement if both true and false statement are nullptr;
    if (statement->ifTrue->is<IR::EmptyStatement>()) {
      if (statement->ifFalse == nullptr) {
        return new IR::EmptyStatement(statement->srcInfo);
      } else if(statement->ifFalse->is<IR::EmptyStatement>()) {
        return new IR::EmptyStatement(statement->srcInfo);
      } else {
        return statement;
      }
    } else {
      return statement;
    }
  }
  return statement;
}

const IR::Node* DoPartition::preorder(IR::BlockStatement* statement) {
  auto parent = getContext()->node;
  if (parent->is<IR::P4Control>()) {
    auto p = parent->to<IR::P4Control>();
    // only partition ingress and egress
    if (p->name == "ingress" || p->name == "egress") {
      start_partition = true;
      n_table = 0;
      for (auto s : *statement->components) {
        visit(s);
      }
      start_partition = false;
    }
  } else {
    if (start_partition) {
      for (auto s : *statement->components) {
        visit(s);
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
  if (parent->is<IR::BlockStatement>()) {
    // calling from another control block, do not increment table count;
    auto mi = P4::MethodInstance::resolve(statement, refMap, typeMap);
    if (start_partition) {
      // MethodCall on P4Table
      if (mi->object->is<IR::P4Table>()) {
        n_table ++;
      } else {
        // Do not increment table count on call to control blocks
      }
    }
  } else {
    if (start_partition) {
      n_table ++ ;
    }
  }
  return statement;
}

const IR::Node* DoPartition::postorder(IR::MethodCallStatement* statement) {
  if (start_partition) {
    if (n_table > tbegin && n_table <= tend) {
      return statement;
    } else {
      return new IR::EmptyStatement(statement->srcInfo);
    }
  }
  return statement;
}

}  // namespace P4
