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
#include "string_utils.h"
#include "frontends/p4/methodInstance.h"

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

using namespace Control;

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

class TableTranslationVisitor : public Inspector {
 public:
  TableTranslationVisitor(FPGAControl* control) :
    control(control) {}
  bool preorder(const IR::TableBlock* table) override;
 private:
  FPGAControl* control;
};

bool TableTranslationVisitor::preorder(const IR::TableBlock* table) {
  // LOG1("Table " << table);
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
  ActionTranslationVisitor(FPGAControl* control, BSVProgram& bsv) : 
    control(control), bsv_(bsv) {}
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::Expression* expression) override;
  bool preorder(const IR::MethodCallExpression* expression) override;
 private:
  FPGAControl* control;
  BSVProgram & bsv_;
};

bool ActionTranslationVisitor::preorder(const IR::AssignmentStatement* stmt) {
  //LOG1("assignment " << stmt->left << stmt->right);
  visit(stmt->left);
  //FIXME: only take care of metadata write
  // visit(stmt->right);
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
    }
  }
  return false;
}

bool ActionTranslationVisitor::preorder(const IR::MethodCallExpression* expression) {
  auto mi = P4::MethodInstance::resolve(expression,
                                        control->program->refMap,
                                        control->program->typeMap);
  auto apply = mi->to<P4::ApplyMethod>();
  if (apply != nullptr) {
    LOG1("handle apply");
    return false;
  }

  auto ext = mi->to<P4::ExternMethod>();
  if (ext != nullptr) {
    LOG1("handle extern");
    return false;
  }

  auto actioncall = mi->to<P4::ActionCall>();
  if (actioncall != nullptr) {
    LOG1("action call");
    append_line(bsv_, expression->toString());
    return false;
  }

  auto extFunc = mi->to<P4::ExternFunction>();
  if (extFunc != nullptr) {
    if (extFunc->method->name == "mark_to_drop") {
      // drop packet
      //append_line(bsv_, "drop");
    }
    return false;
  }

  LOG1(mi->methodType);
  return false;
}

bool FPGAControl::build() {
  const IR::P4Control* cont = controlBlock->container;
  LOG1("Processing " << cont);
  cfg = new CFG();
  LOG1("before build");
  cfg->build(cont, program->refMap, program->typeMap);
  LOG1("after build");

  if (cfg->entryPoint->successors.size() == 0) {
    LOG1("init table null");
  } else {
    BUG_CHECK(cfg->entryPoint->successors.size() == 1, "Expected 1 start node for %1%", cont);
    auto start = (*(cfg->entryPoint->successors.edges.begin()))->endpoint;
    LOG1(start);
  }

  for (auto s : *controlBlock->container->getDeclarations()) {
    if (s->is<IR::P4Action>()) {
      auto act = s->to<IR::P4Action>();
      basicBlock.push_back(act);
    }
  }

  // constantValue : compile-time allocated resource, such as table..
  for (auto c : controlBlock->constantValue) {
    auto b = c.second;
    if (!b->is<IR::Block>()) continue;
    if (b->is<IR::TableBlock>()) {
      auto tblblk = b->to<IR::TableBlock>();
      tables.push_back(tblblk);
      LOG1("table: " << tblblk);
      // TableTranslationVisitor visitor(this);
      // tblblk->apply(visitor);
    } else if (b->is<IR::ExternBlock>()) {
      auto ctrblk = b->to<IR::ExternBlock>();
      LOG1("extern " << ctrblk);
    } else {
      ::error("Unexpected block %s nested within control", b->toString());
    }
  }

  // control flow
  if (controlBlock->container->body->is<IR::BlockStatement>()) {
    auto stmt = controlBlock->container->body->to<IR::BlockStatement>();
    LOG1("block statement size " << stmt->components->size());
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
for (auto r : V) {                              \
  ControlTranslationVisitor visitor(this, bsv); \
  r->apply(visitor);                            \
}

void FPGAControl::emitEntryRule(BSVProgram & bsv, const CFG::Node* node) {
  append_format(bsv, "rule rl_entry if (entry_req_ff.notEmpty);");
  incr_indent(bsv);
  append_line(bsv, "entry_req_ff.deq;");
  append_line(bsv, "let _req = entry_req_ff.first;");
  append_line(bsv, "let meta = _req.meta;");
  append_line(bsv, "let pkt = _req.pkt;");
  append_line(bsv, "MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};");
  if (tables.size() == 0) {
    append_line(bsv, "next_req_ff.enq(req);");
  } else {
    auto t = tables[0]->container->to<IR::P4Table>();
    append_format(bsv, "%s_req_ff.enq(req);", t->name.toString());
  }
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void FPGAControl::emitExitRule(BSVProgram & bsv, const CFG::Node* node) {
  append_format(bsv, "rule rl_exit if (exit_req_ff.notEmpty);");
  incr_indent(bsv);

  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void FPGAControl::emitTableRule(BSVProgram & bsv, const IR::P4Table* table) {
  auto name = table->name.toString();
  auto type = CamelCase(name);
  append_format(bsv, "rule rl_%s if (%s_rsp_ff.notEmpty);", name, name);
  incr_indent(bsv);
  append_format(bsv, "%s_rsp_ff.deq;", name);
  append_format(bsv, "let _rsp = %s_rsp_ff.first;", name);
  // find next states
  append_line(bsv, "let meta = _req.meta;");
  append_line(bsv, "let pkt = _req.pkt;");
  append_format(bsv, "let %s = fromMaybe(?, meta.);", "xxx");
  append_format(bsv, "tagged %s {}", "xxx");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void FPGAControl::emitCondRule(BSVProgram & bsv, const CFG::IfNode* node) {
  auto sig = cstring("w_") + node->name;
  LOG1(sig);
  append_format(bsv, "rule rl_%s if (%s);", node->name, sig);
  incr_indent(bsv);
  auto stmt = node->statement->to<IR::IfStatement>();
  LOG1(node << " succ " << node->successors);
  LOG1(node << " pred " << node->predecessors);
  if (stmt != nullptr) {
    LOG1(stmt->condition);
    append_line(bsv, "%s", stmt->condition);
    if (stmt->ifTrue != nullptr) {
      LOG1(stmt->ifTrue);
    }
    if (stmt->ifFalse != nullptr) {
      LOG1(stmt->ifFalse);
    }
  }
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void FPGAControl::emitBasicBlocks(BSVProgram & bsv) {
  for (auto b : basicBlock) {
    // implementation for basic block
    auto stmt = b->body->to<IR::BlockStatement>();
    if (stmt == nullptr) continue;
    ActionTranslationVisitor visitor(this, bsv);
    for (auto path : *stmt->components) {
      path->apply(visitor);
    }
  }
}

void FPGAControl::emitDeclaration(BSVProgram & bsv) {
  // basic block instances
  for (auto b : basicBlock) {
    LOG1("basic block" << b);
    auto name = b->name.toString();
    auto type = CamelCase(name);
    append_format(bsv, "%s %s <- mk%s();", type, name, type);
  }
  for (auto t : tables) {
    auto table = t->container->to<IR::P4Table>();
    if (table == nullptr)
      continue;
    auto name = table->name.toString();
    auto type = CamelCase(name);
    append_format(bsv, "%s %s <- mk%s();", type, name, type);
  }
}

void FPGAControl::emitFifo(BSVProgram & bsv) {
  append_line(bsv, "FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;");
  append_line(bsv, "FIFOF#(MetadataResponse) entry_rsp_ff <- mkFIFOF;");
  for (auto t : tables) {
    auto table = t->container->to<IR::P4Table>();
    auto name = table->name.toString();
    auto type = CamelCase(name);
    append_line(bsv, "FIFOF#(MetadataRequest) %s_req_ff <- mkFIFOF;", name);
    append_line(bsv, "FIFOF#(%sResponse) %s_rsp_ff <- mkFIFOF;", type, name);
  }
  append_line(bsv, "FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;");
  append_line(bsv, "FIFOF#(MetadataResponse) exit_rsp_ff <- mkFIFOF;");
}

void FPGAControl::emitConnection(BSVProgram & bsv) {
  // table to fifo
  for (auto t : tables) {
    auto table = t->container->to<IR::P4Table>();
    auto name = table->name.toString();
    auto type = CamelCase(name);
    append_format(bsv, "mkConnection(toClient(%s_req_ff, %s_rsp_ff), %s.prev_control_state);", name, name, name);
  }
  // table to action
}

void FPGAControl::emitDebugPrint(BSVProgram & bsv) {
  append_line(bsv, "Reg#(int) cf_verbosity <- mkConfigRegU;");
  append_line(bsv, "function Action dbprint(Integer level, Fmt msg);");
  incr_indent(bsv);
  append_line(bsv, "action");
  append_line(bsv, "if (cf_verbosity > fromInteger(level)) begin");
  incr_indent(bsv);
  append_line(bsv, "$display(\"(%%0d) \" , $time, msg);");
  decr_indent(bsv);
  append_line(bsv, "end");
  append_line(bsv, "endaction");
  decr_indent(bsv);
  append_line(bsv, "endfunction");
}

// control block module
void FPGAControl::emit(BSVProgram & bsv) {
  auto cbname = controlBlock->container->name.toString();
  auto cbtype = CamelCase(cbname);
  // TODO: synthesize boundary
  append_line(bsv, "module mk%s #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (%s);", cbtype, cbtype);
  incr_indent(bsv);
  emitBasicBlocks(bsv);
  emitDebugPrint(bsv);
  emitDeclaration(bsv);
  emitFifo(bsv);
  append_line(bsv, "Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(default_req_ff, default_rsp_ff));");
  append_line(bsv, "mkConnection(mds, mdc);");
  emitConnection(bsv);

  if (cfg != nullptr) {
    if (cfg->entryPoint != nullptr) {
      emitEntryRule(bsv, cfg->entryPoint);
    }
    for (auto node : cfg->allNodes) {
      if (node->is<CFG::TableNode>()) {
        auto t = node->to<CFG::TableNode>();
        emitTableRule(bsv, t->table);
      } else if (node->is<CFG::IfNode>()) {
        auto n = node->to<CFG::IfNode>();
        //for (auto e : node->successors.edges) {
        //  LOG1(n->statement << " " << e->getBool() << ":" << e->endpoint);
        //}
        emitCondRule(bsv, n);
      }
    }
    if (cfg->exitPoint != nullptr) {
      emitExitRule(bsv, cfg->exitPoint);
    }
  }
  decr_indent(bsv);
  append_line(bsv, "endmodule");
}
#undef VECTOR_VISIT
}  // namespace FPGA
