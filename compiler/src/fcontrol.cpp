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

class MetadataExtractor : public Inspector {
 public:
  std::vector<cstring> bsv;
  explicit MetadataExtractor () {}

  bool preorder(const IR::Member* expr) {
    if (expr->member == "isValid") return false;
    bsv.push_back(cstring("let ") + expr->member.toString() +
           cstring("_isValid = meta.") + expr->member.toString() +
           cstring(" matches tagged Valid .d") +
           cstring(" ? True : False;"));
    bsv.push_back(cstring("let ") + expr->member.toString() +
           cstring(" = fromMaybe(?, meta.") + expr->member.toString() +
           cstring(");"));
    return false;
  }
};

class ExpressionConverter : public Inspector {
 public:
  cstring bsv = "";
  explicit ExpressionConverter () {}
  bool preorder(const IR::MethodCallExpression* expr){
    auto m = expr->method->to<IR::Member>();
    if (m->member == "isValid") {
      bsv += cstring("isValid(") + m->expr->toString() + cstring(")");
    }
    return false;
  }
  bool preorder(const IR::Grt* expr) {
    bsv += cstring("(");
    visit(expr->left);
    bsv += cstring(" > ");
    visit(expr->right);
    bsv += cstring(")");
    return false;
  }
  bool preorder(const IR::LAnd* expr) {
    bsv += cstring("(");
    visit(expr->left);
    bsv += cstring(" && ");
    visit(expr->right);
    bsv += cstring(")");
    return false;
  }
  bool preorder(const IR::Constant* cst) {
    bsv += cstring(cst->toString());
    return false;
  }
  bool preorder(const IR::Member* expr) {
    // FIXME: use header$field format to avoid naming conflict
    bsv += expr->member.toString() +
           cstring("_isValid") +
           cstring(" && ") +
           expr->member.toString();
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
      auto name = action->name;
      basicBlock.emplace(name, action);
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

      // populate map <Action, Table>
      for (auto act : *table->getActionList()->actionList) {
        auto element = act->to<IR::ActionListElement>();
        if (element->expression->is<IR::PathExpression>()) {
          //LOG1("Path " << element->expression->to<IR::PathExpression>());
        } else if (element->expression->is<IR::MethodCallExpression>()) {
          auto expression = element->expression->to<IR::MethodCallExpression>();
          auto type = program->typeMap->getType(expression->method, true);
          auto action = expression->method->toString();
          action_to_table[action] = table;
          LOG1("action yyy " << action);
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

  MetadataExtractor metadataVisitor;
  stmt->condition->apply(metadataVisitor);
  for (auto str : metadataVisitor.bsv) {
    builder->append_line(str);
  }

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
  for (auto b : basicBlock) {
    auto name = nameFromAnnotation(b.second->annotations, b.second->name);
    auto type = CamelCase(name);
    // ensure NoAction is translated to noAction
    builder->append_format("Control::%s %s <- mk%s();", type, camelCase(name), type);
  }
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    if (table == nullptr)
      continue;
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_format("Control::%s %s <- mk%s();", type, name, type);
  }
}

void FPGAControl::emitFifo(BSVProgram & bsv) {
  builder->append_line("FIFOF#(MetadataRequest) entry_req_ff <- mkFIFOF;");
  builder->append_line("FIFOF#(MetadataResponse) entry_rsp_ff <- mkFIFOF;");
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_line("FIFOF#(MetadataRequest) %s_req_ff <- mkFIFOF;", name);
    builder->append_line("FIFOF#(MetadataResponse) %s_rsp_ff <- mkFIFOF;", name);
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
  builder->append_line("FIFOF#(MetadataResponse) exit_rsp_ff <- mkFIFOF;");
}

void FPGAControl::emitConnection(BSVProgram & bsv) {
  // table to fifo
  for (auto t : tables) {
    auto table = t.second->to<IR::P4Table>();
    auto name = nameFromAnnotation(table->annotations, table->name);
    auto type = CamelCase(name);
    builder->append_line("mkConnection(toClient(%s_req_ff, %s_rsp_ff), %s.prev_control_state);", name, name, name);

    auto actionList = table->getActionList()->actionList;
    int idx = 0;
    for (auto action : *actionList) {
      auto elem = action->to<IR::ActionListElement>();
      if (elem->expression->is<IR::MethodCallExpression>()) {
        auto e = elem->expression->to<IR::MethodCallExpression>();
        auto t = program->typeMap->getType(e->method, true);
        auto n = e->method->toString();
        auto action = basicBlock[n];
        auto annotatedName = nameFromAnnotation(action->annotations, action->name);
        builder->append_format("mkChan(mkFIFOF, mkFIFOF, %s.next_control_state_%d, %s.prev_control_state);", name, idx, camelCase(annotatedName));
        idx ++ ;
      }
    }
  }
}

void FPGAControl::emitDebugPrint(BSVProgram & bsv) {
  builder->append_line("Reg#(int) cf_verbosity <- mkConfigRegU;");
  builder->append_line("function Action dbprint(Integer level, Fmt msg);");
  builder->incr_indent();
  builder->append_line("action");
  builder->append_line("if (cf_verbosity > fromInteger(level)) begin");
  builder->incr_indent();
  builder->append_line("$display(\"(%%0d) \" , $time, msg);");
  builder->decr_indent();
  builder->append_line("end");
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
}

void FPGAControl::emitTables() {
  CHECK_NULL(cbuilder);
  cbuilder->append_line("#include <iostream>");
  cbuilder->append_line("#include <unordered_map>");
  cbuilder->append_line("#ifdef __cplusplus");
  cbuilder->append_line("extern \"C\" {");
  cbuilder->append_line("#endif");
  cbuilder->append_line("#include <stdio.h>");
  cbuilder->append_line("#include <stdlib.h>");
  cbuilder->append_line("#include <string.h>");
  cbuilder->append_line("#include <stdint.h>");
  for (auto t : tables) {
    TableCodeGen visitor(this, builder, cbuilder, type_builder);
    t.second->apply(visitor);
  }
  cbuilder->append_line("#ifdef __cplusplus");
  cbuilder->append_line("}");
  cbuilder->append_line("#endif");
}

void FPGAControl::emitActions(BSVProgram & bsv) {
  for (auto b : basicBlock) {
    ActionCodeGen visitor(this, bsv, builder);
    LOG1(b.second);
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
    LOG1("emit Action Types");
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
    api_def->append_format("method Action %s_add_entry(", name);
    api_def->append_format("%sReqT key, ", type);
    api_def->append_format("%sRspT val", type);
    api_def->append_format(");");
  }
  for (auto t : tables) {
    const IR::Key* key = t.second->getKey();
    if (key == nullptr) continue;

    const IR::P4Table* tbl = t.second;
    cstring name = nameFromAnnotation(tbl->annotations, tbl->name);
    api_decl->append_format("method %s_add_entry", name);
    api_decl->append_format("=%s", cbname);
    api_decl->append_format(".%s_add_entry;", name);
  }
}

void FPGAControl::emitImports() {
  builder->append_line("import Library::*;");
  builder->append_line("import StructDefines::*;");
  builder->append_line("import UnionDefines::*;");
  builder->append_line("import ConnectalTypes::*;");
  builder->append_line("import CPU::*;");
  builder->append_line("import IMem::*;");
}

// control block module
void FPGAControl::emit(BSVProgram & bsv, CppProgram & cpp) {
  auto cbname = controlBlock->container->name.toString();
  auto cbtype = CamelCase(cbname);
  builder = &bsv.getControlBuilder();
  cbuilder = &cpp.getSimBuilder();
  api_def = &bsv.getAPIIntfDefBuilder();
  api_decl = &bsv.getAPIIntfDeclBuilder();
  type_builder = &bsv.getConnectalTypeBuilder();
  emitImports();
  emitTables();
  emitActions(bsv);
  emitActionTypes(bsv);

  // TODO: synthesize boundary
  builder->append_format("// =============== control %s ==============", cbname);
  builder->append_line("interface %s;", cbtype);
  builder->incr_indent();
  builder->append_line("interface Client#(MetadataRequest, MetadataResponse) next;");
  for (auto t : tables) {
    auto tname = t.first;
    auto type = CamelCase(tname);
    builder->append_line("method Action %s_add_entry(ConnectalTypes::%sReqT key, ConnectalTypes::%sRspT value);", tname, type, type);
  }
  builder->append_line("method Action set_verbosity(int verbosity);");
  builder->decr_indent();
  builder->append_line("endinterface");
  builder->append_line("module mk%s #(Vector#(numClients, Client#(MetadataRequest, MetadataResponse)) mdc) (%s);", cbtype, cbtype);
  builder->incr_indent();
  emitDebugPrint(bsv);
  emitDeclaration(bsv);
  emitFifo(bsv);
  builder->append_line("Vector#(numClients, Server#(MetadataRequest, MetadataResponse)) mds = replicate(toServer(entry_req_ff, entry_rsp_ff));");
  builder->append_line("mkConnection(mds, mdc);");
  emitConnection(bsv);

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
    // if (cfg->exitPoint != nullptr) {
    //   emitExitRule(bsv, cfg->exitPoint);
    // }
  }
  builder->decr_indent();
  builder->append_line("interface next = (interface Client#(MetadataRequest, MetadataResponse);");
  builder->incr_indent();
  builder->append_line("interface request = toGet(exit_req_ff);");
  builder->append_line("interface response = toPut(exit_rsp_ff);");
  builder->decr_indent();
  builder->append_line("endinterface);");
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
  builder->append_line("endmodule");

  emitAPI(bsv, cbname);
}

}  // namespace FPGA
