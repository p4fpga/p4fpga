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
#include "table.h"
#include "action.h"
#include "fstruct.h"
#include "funion.h"
#include "string_utils.h"
#include "vector_utils.h"

namespace FPGA {

class ExpressionConverter : public Inspector {
 public:
  cstring bsv = "";
  explicit ExpressionConverter () {}
  bool preorder(const IR::MethodCallExpression* expr){
    auto m = expr->method->to<IR::Member>();
    if (m->member == "isValid") {
      bsv += cstring("meta.") + m->expr->toString() + cstring(" matches tagged Valid .h");
    }
    return false;
  }
  bool preorder(const IR::Grt* expr) {
    //bsv += cstring("(");
    visit(expr->left);
    bsv += cstring(" > ");
    visit(expr->right);
    //bsv += cstring(")");
    return false;
  }
  bool preorder(const IR::LAnd* expr) {
    //bsv += cstring("(");
    visit(expr->left);
    bsv += cstring(" &&& ");
    visit(expr->right);
    //bsv += cstring(")");
    return false;
  }
  bool preorder(const IR::Constant* cst) {
    bsv += cstring(cst->toString());
    return false;
  }
  bool preorder(const IR::Member* expr) {
    bsv += cstring("h.hdr.") + expr->member.toString();
    return false;
  }
};

bool FPGAControl::build() {
  const IR::P4Control* cont = controlBlock->container;
  LOG1("Processing " << cont);
  cfg = new CFG();
  cfg->build(cont, program->refMap, program->typeMap);
  LOG1(cfg);

  if (cfg->entryPoint->successors.size() == 0) {
    LOG1("init table null");
  } else {
    BUG_CHECK(cfg->entryPoint->successors.size() == 1, "Expected 1 start node for %1%", cont);
    auto start = (*(cfg->entryPoint->successors.edges.begin()))->endpoint;
    LOG1("start node" << start);
  }

  // build map <cstring, IR::P4Action*>
  LOG1("Building action map");
  for (auto s : *controlBlock->container->getDeclarations()) {
    if (s->is<IR::P4Action>()) {
      auto action = s->to<IR::P4Action>();
      // Do not use annotated name, as P4Table will use original name
      cstring name = nameFromAnnotation(action->annotations, action->name);
      // auto name = action->name;
      actions.emplace(name, action);
      LOG1("add to action map " << name);
    }
  }

  // constantValue : compile-time allocated resource, such as table..
  // build map <cstring, IR::P4Table*>
  LOG1("Building table map");
  for (auto c : controlBlock->constantValue) {
    auto b = c.second;
    if (!b->is<IR::Block>()) continue;
    if (b->is<IR::TableBlock>()) {
      auto tblblk = b->to<IR::TableBlock>();
      auto table = tblblk->container;
      auto name = nameFromAnnotation(table->annotations, table->name);
      LOG1("add table " << name);
      tables.emplace(name.c_str(), table);

      // populate map <Action, Table> with annotated name
      for (auto a : *table->getActionList()->actionList) {
        auto path = a->getPath();
        auto decl = refMap->getDeclaration(path, true);
        if (decl->is<IR::P4Action>()) {
          auto action = decl->to<IR::P4Action>();
          cstring name = nameFromAnnotation(action->annotations, action->name);
          action_to_table[name] = table;
        }
      }

      // populate map <Metadata, Table>
      auto keys = table->getKey();
      if (keys == nullptr) {
        LOG4("Table has no key : " << name);
        continue;
      }

      for (auto key : *keys->keyElements) {
        auto element = key->to<IR::KeyElement>();
        if (element->expression->is<IR::Member>()) {
          auto m = element->expression->to<IR::Member>();

          program->metadata.insert(std::make_pair(m->toString(), m));

          auto type = program->typeMap->getType(m->expr, true);
          LOG1("meta type" << m);
          // from meta
          if (type->is<IR::Type_Struct>()) {
            auto t = type->to<IR::Type_StructLike>();
            auto f = t->getField(m->member);
            metadata_to_table[f].insert(table);
            // from hdr
          } else if (type->is<IR::Type_Header>()) {
            auto t = type->to<IR::Type_StructLike>();
            auto f = t->getField(m->member);
            metadata_to_table[f].insert(table);
          }
        }
      }
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

  return true;
}

void FPGAControl::emitEntryRule(BSVProgram & bsv, const CFG::Node* node) {
  builder->append_format("rule rl_entry if (entry_req_ff.notEmpty);");
  builder->incr_indent();
  builder->append_line("entry_req_ff.deq;");
  builder->append_line("let _req = entry_req_ff.first;");
  builder->append_line("let meta = _req.meta;");
  builder->append_line("let pkt = _req.pkt;");
  builder->append_line("MetadataRequest req = MetadataRequest {pkt: pkt, meta: meta};");
  if (tables.size() == 0) {
    builder->append_line("exit_req_ff.enq(req);");
    builder->append_format("dbprint(3, $format(\"exit\", fshow(meta)));");
  } else {
    BUG_CHECK(node->successors.size() == 1, "Expected 1 start node for %1%", node);
    auto start = (*(node->successors.edges.begin()))->endpoint;
    builder->append_format("%s_req_ff.enq(req);", start->name);
    builder->append_format("dbprint(3, $format(\"%s\", fshow(meta)));", start->name);
  }
  builder->decr_indent();
  builder->append_line("endrule");
}

void FPGAControl::emitTableRule(BSVProgram & bsv, const CFG::TableNode* node) {
  auto table = node->table->to<IR::P4Table>();
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  builder->append_format("rule rl_%s if (%s_rsp_ff.notEmpty);", name, name);
  builder->incr_indent();
  builder->append_format("%s_rsp_ff.deq;", name);
  builder->append_format("let _rsp = %s_rsp_ff.first;", name);
  // find next states
  builder->append_line("let meta = _rsp.meta;");
  builder->append_line("let pkt = _rsp.pkt;");
  builder->append_line("case (_rsp) matches");
  builder->incr_indent();
  for (auto s : node->successors.edges) {
    if (s->label == nullptr) {
      builder->append_line("default: begin");
      builder->incr_indent();
      builder->append_line("MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};");
      builder->append_line("%s_req_ff.enq(req);", s->endpoint->name);
      builder->append_format("dbprint(3, $format(\"default \", fshow(meta)));");
      builder->decr_indent();
      builder->append_line("end");
    } else {
      builder->append_line("%s: begin", s->label);
      builder->incr_indent();
      builder->append_line("MetadataRequest req = MetadataRequest { pkt : pkt, meta : meta};");
      builder->append_line("%s_req_ff.enq(req);", s->endpoint->name);
      builder->append_format("dbprint(3, $format(\"%s \", fshow(meta)));", s->label);
      builder->decr_indent();
      builder->append_line("end");
    }
  }
  builder->decr_indent();
  builder->append_line("endcase");
  builder->decr_indent();
  builder->append_line("endrule");
}

void FPGAControl::emitCondRule(BSVProgram & bsv, const CFG::IfNode* node) {
  //auto sig = cstring("w_") + node->name;
  auto name = node->name;
  builder->append_format("rule rl_%s if (%s_req_ff.notEmpty);", node->name, node->name);
  builder->incr_indent();
  auto stmt = node->statement->to<IR::IfStatement>();
  // LOG1(node << " succ " << node->successors.edges);
  builder->append_format("%s_req_ff.deq;", name);
  builder->append_format("let _req = %s_req_ff.first;", name);
  builder->append_line("let meta = _req.meta;");

  auto ifTrue = cstring("");
  auto ifFalse = cstring("");
  for (auto e : node->successors.edges) {
    if (e->isBool()) {
      if (e->getBool()) {
        ifTrue = e->getNode()->name + cstring("_req_ff.enq(_req);");
      } else {
        ifFalse = e->getNode()->name + cstring("_req_ff.enq(_req);");
      }
    }
  }
  ExpressionConverter visitor;
  stmt->condition->apply(visitor);
  if (ifTrue != "") {
    builder->append_format("if (%s) begin", visitor.bsv);
    builder->incr_indent();
    builder->append_format(ifTrue);
    builder->append_format("dbprint(3, $format(\"%s true\", fshow(meta)));", node->name);
    builder->decr_indent();
    builder->append_line("end");
  }
  if (ifFalse != "") {
    builder->append_line("else begin");
    builder->incr_indent();
    builder->append_format(ifFalse);
    builder->append_format("dbprint(3, $format(\"%s false\", fshow(meta)));", node->name);
    builder->decr_indent();
    builder->append_line("end");
  }
  builder->decr_indent();
  builder->append_line("endrule");
}

void FPGAControl::emitDeclaration(BSVProgram & bsv) {
  // basic block instances
  for (auto b : actions) {
    auto name = nameFromAnnotation(b.second->annotations, b.second->name);
    auto type = CamelCase(name);
    // ensure NoAction is translated to noAction
    builder->append_format("Control::%sAction %s_action <- mkEngine(toList(vec(step_1)));", type, camelCase(name));
  }
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    if (table == nullptr)
      continue;
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_line("%sMatchTable %s_table <- mkMatchTable_%s(\"%s\");", type, name, type, name);
    builder->append_line("Control::%sTable %s <- mkTable(table_request, table_execute, %s_table);", type, name, name);
    builder->append_line("messageM(printType(typeOf(%s_table)));", name);
    builder->append_line("messageM(printType(typeOf(%s)));", name);
  }
}

void FPGAControl::emitFifo(BSVProgram & bsv) {
  builder->append_line("FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;");
  builder->append_line("FIFOF#(MetadataRequest) entry_rsp_ff <- mkFIFOF;");
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_line("FIFOF#(MetadataRequest) %s_req_ff <- mkFIFOF;", name);
    builder->append_line("FIFOF#(MetadataRequest) %s_rsp_ff <- mkFIFOF;", name);
  }

  if (cfg != nullptr) {
    for (auto node : cfg->allNodes) {
      if (node->is<CFG::IfNode>()) {
        auto n = node->to<CFG::IfNode>();
        builder->append_line("FIFOF#(MetadataRequest) %s_req_ff <- mkFIFOF;", n->name);
        //builder->append_line("PulseWire w_%s <- mkPulseWire;", n->name);
      }
    }
  }
  builder->append_line("FIFOF#(MetadataRequest) exit_req_ff <- mkFIFOF;");
  builder->append_line("FIFOF#(MetadataRequest) exit_rsp_ff <- mkFIFOF;");
}

void FPGAControl::emitConnection(BSVProgram & bsv) {
  // table to fifo
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_line("mkConnection(toClient(%s_req_ff, %s_rsp_ff), %s.prev_control_state);", name, name, name);

    int idx = 0;
    for (auto a: *table->getActionList()->actionList) {
      auto path = a->getPath();
      auto decl = refMap->getDeclaration(path, true);
      if (decl->is<IR::P4Action>()) {
        auto action = decl->to<IR::P4Action>();
        auto action_name = nameFromAnnotation(action->annotations, action->name);
        builder->append_format("mkConnection(%s.next_control_state[%d], %s_action.prev_control_state);", name, idx, camelCase(action_name));
        idx ++ ;
      }
    }
  }
}

void FPGAControl::emitTables() {
  CHECK_NULL(cpp_builder);
  cpp_builder->append_line("#include <iostream>");
  cpp_builder->append_line("#include <unordered_map>");
  cpp_builder->append_line("#ifdef __cplusplus");
  cpp_builder->append_line("extern \"C\" {");
  cpp_builder->append_line("#endif");
  cpp_builder->append_line("#include <stdio.h>");
  cpp_builder->append_line("#include <stdlib.h>");
  cpp_builder->append_line("#include <string.h>");
  cpp_builder->append_line("#include <stdint.h>");
  for (auto t : tables) {
    TableCodeGen visitor(this, builder, cpp_builder, type_builder);
    t.second->apply(visitor);
  }
  cpp_builder->append_line("#ifdef __cplusplus");
  cpp_builder->append_line("}");
  cpp_builder->append_line("#endif");
}

void FPGAControl::emitActions(BSVProgram & bsv) {
  for (auto b : actions) {
    ActionCodeGen visitor(this, bsv, builder);
    b.second->apply(visitor);
 //   auto stmt = b.second->body->to<IR::BlockStatement>();
 //   if (stmt == nullptr) continue;
 //   // encode to cpu instruction
 //   for (auto path : *stmt->components) {
 //   //  path->apply(visitor);
 //   }
  }
}

void FPGAControl::emitActionTypes(BSVProgram & bsv) {
  CodeBuilder* builder = &bsv.getUnionBuilder();
  UnionCodeGen visitor(this, builder);
  visitor.emit();
  for (auto b : tables) {
    UnionCodeGen visitor(this, builder);
    b.second->apply(visitor);
  }
}

void FPGAControl::emitAPI(BSVProgram & bsv, cstring cbname) {
  for (auto t : tables) {
    const IR::Key* key = t.second->getKey();
    if (key == nullptr) continue;

    const IR::P4Table* tbl = t.second;
    cstring name = nameFromAnnotation(tbl->annotations, tbl->name);
    cstring type = CamelCase(name);
    api_def->appendFormat("method Action %s_add_entry(", name);
    api_def->appendFormat("%sReqT key, ", type);
    api_def->appendFormat("%sRspT val", type);
    api_def->appendLine(");");
  }
  for (auto t : tables) {
    const IR::Key* key = t.second->getKey();
    if (key == nullptr) continue;

    const IR::P4Table* tbl = t.second;
    cstring name = nameFromAnnotation(tbl->annotations, tbl->name);
    prog_decl->appendFormat("method %s_add_entry", name);
    prog_decl->appendFormat("=%s", cbname);
    prog_decl->appendFormat(".%s_add_entry;", name);
    prog_decl->newline();

    api_decl->appendFormat("method %s_add_entry = prog", name);
    api_decl->appendFormat(".%s_add_entry;", name);
    api_decl->newline();
  }
}

// control block module
void FPGAControl::emit(BSVProgram & bsv, CppProgram & cpp) {
  auto cbname = controlBlock->container->name.toString();
  auto cbtype = CamelCase(cbname);
  builder = &bsv.getControlBuilder();
  cpp_builder = &cpp.getSimBuilder();
  type_builder = &bsv.getConnectalTypeBuilder();
  api_def = &bsv.getAPIDefBuilder();
  api_decl = &bsv.getAPIDeclBuilder();
  prog_decl = &bsv.getProgDeclBuilder();

  emitTables();
  emitActions(bsv);
  emitActionTypes(bsv);

  // TODO: synthesize boundary
  builder->append_format("// =============== control %s ==============", cbname);
  builder->append_line("interface %s;", cbtype);
  builder->incr_indent();
  builder->append_line("interface PipeIn#(MetadataRequest) prev;");
  builder->append_line("interface PipeOut#(MetadataRequest) next;");
  for (auto t : tables) {
    auto tname = t.first;
    auto type = CamelCase(tname);
    builder->append_line("method Action %s_add_entry(ConnectalTypes::%sReqT key, ConnectalTypes::%sRspT value);", tname, type, type);
  }
  builder->append_line("method Action set_verbosity(int verbosity);");
  builder->decr_indent();
  builder->append_line("endinterface");
  builder->append_line("module mk%s (%s);", cbtype, cbtype);
  builder->incr_indent();
  builder->append_line("`PRINT_DEBUG_MSG");
  emitFifo(bsv);
  emitDeclaration(bsv);
  emitConnection(bsv);

  // emit control flow
  if (cfg != nullptr) {
    if (cfg->entryPoint != nullptr) {
      emitEntryRule(bsv, cfg->entryPoint);
    }
    for (auto node : cfg->allNodes) {
      if (node->is<CFG::TableNode>()) {
        auto t = node->to<CFG::TableNode>();
        emitTableRule(bsv, t);
      } else if (node->is<CFG::IfNode>()) {
        auto n = node->to<CFG::IfNode>();
        emitCondRule(bsv, n);
      }
    }
  }
  // emit interfaces
  builder->append_line("interface prev = toPipeIn(entry_req_ff);");
  builder->append_line("interface next = toPipeOut(exit_req_ff);");
  for (auto t : tables) {
    auto tname = t.first;
    builder->append_line("method %s_add_entry = %s.add_entry;", tname, tname);
  }
  builder->append_line("method Action set_verbosity (int verbosity);");
  builder->incr_indent();
  builder->append_line("cf_verbosity <= verbosity;");
  for (auto t : tables) {
    auto tname = t.first;
    builder->append_line("%s.set_verbosity(verbosity);", tname);
  }
  builder->decr_indent();
  builder->append_line("endmethod");
  builder->decr_indent();
  builder->append_line("endmodule");

  emitAPI(bsv, cbname);
}

cstring FPGAControl::toP4Action (cstring inst) {
  auto k = actions.find(inst);
  if (k != actions.end()) {
    auto params = k->second->parameters;
    cstring action_name = nameFromAnnotation(k->second->annotations, k->second->name);
    return action_name;
  } else {
    return nullptr;
  }
}

}  // namespace FPGA
