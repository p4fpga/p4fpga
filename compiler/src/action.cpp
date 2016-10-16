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
#include "ir/ir.h"
#include "action.h"
#include "frontends/p4/methodInstance.h"
#include "string_utils.h"

namespace FPGA {

bool ActionCodeGen::preorder(const IR::AssignmentStatement* stmt) {
  auto type = control->program->typeMap->getType(stmt->left, true);
  if (type != nullptr) {
    if (type->is<IR::Type_Bits>()) {
      auto bits = type->to<IR::Type_Bits>();
      builder->append_line("// INST (%d) %s = %s", bits->width_bits(), stmt->left, stmt->right);
    } else {
      builder->append_line("// INST (%d) %s = %s", stmt->left, stmt->right);
    }
  }
  visit(stmt->left);
  visit(stmt->right);
  return false;
}

bool ActionCodeGen::preorder(const IR::Expression* expression) {
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

bool ActionCodeGen::preorder(const IR::MethodCallExpression* expression) {
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
    LOG1("MethodCall extern type");
    // ext->type : register
    // ext->expr : register name
    builder->append_line("// INST extern %s %s", ext->method->name.toString(), ext->expr->toString());
    return false;
  }

  auto actioncall = mi->to<P4::ActionCall>();
  if (actioncall != nullptr) {
    LOG1("action call");
    builder->append_line(expression->toString());
    return false;
  }

  auto extFunc = mi->to<P4::ExternFunction>();
  if (extFunc != nullptr) {
    if (extFunc->method->name == "mark_to_drop") {
      builder->append_line("// mark_to_drop ");
    } else {
      builder->append_line("// INST extern %s", extFunc->method->name.toString());
    }
    return false;
  }

  return false;
}

void ActionCodeGen::emitCpuRspRule(const IR::P4Action* action) {
  auto name = action->name;
  auto type = CamelCase(name);
  auto table = control->action_to_table[name];
  auto table_name = nameFromAnnotation(table->annotations, table->name);
  auto table_type = CamelCase(table_name);
  std::vector<cstring> fields;
  if (action->parameters->size() > 0) {
    auto params = action->parameters->to<IR::ParameterList>();
    if (params != nullptr) {
      for (auto p : *params->parameters) {
        fields.push_back(p->name);
      }
    }
    LOG1("// Action Response: need to update metadata");
  }
  builder->append_line("rule rl_cpu_resp if (cpu.not_running());");
  builder->incr_indent();
  builder->append_line("let pkt <- toGet(curr_packet_ff).get;"); // FIXME: bottleneck
  builder->append_format("%sActionRsp rsp = tagged %sRspT { pkt: pkt, meta: metadata};", table_type, type);
  builder->append_line("tx_info_prev_control_state.enq(rsp);");
  builder->decr_indent();
  builder->append_line("endrule");
}

void ActionCodeGen::emitActionBegin(const IR::P4Action* action) {
  cstring name = nameFromAnnotation(action->annotations, action->name);
  cstring orig_name = action->name.toString();
  cstring type = CamelCase(name);
  LOG1("action name " << name << " " << orig_name);
  const IR::P4Table* table = control->action_to_table[name];
  if (table == nullptr) {
    ::error("unable to find table from action %s", name);
  }
  table_name = nameFromAnnotation(table->annotations, table->name);
  table_type = CamelCase(table_name);
}

void ActionCodeGen::emitDropAction(const IR::P4Action* action) {
  cstring name = nameFromAnnotation(action->annotations, action->name);
  cstring type = CamelCase(name);
  const IR::P4Table* table = control->action_to_table[name];
  if (table == nullptr) {
    ::error("unable to find table from action %s", name);
  }
  cstring table_name = nameFromAnnotation(table->annotations, table->name);
  cstring table_type = CamelCase(table_name);

  builder->append_line("typedef Engine#(1, MetadataRequest, %sParam) %sAction;", table_type, type);
}

void ActionCodeGen::emitNoAction(const IR::P4Action* action) {
  cstring name = nameFromAnnotation(action->annotations, action->name);
  cstring type = CamelCase(name);
  const IR::P4Table* table = control->action_to_table[name];
  if (table == nullptr) {
    ::error("unable to find table from action %s", name);
  }
  cstring table_name = nameFromAnnotation(table->annotations, table->name);
  cstring table_type = CamelCase(table_name);

  builder->append_line("typedef Engine#(1, MetadataRequest, %sParam) %sAction;", table_type, type);
}

void ActionCodeGen::emitModifyAction(const IR::P4Action* action) {
  cstring name = nameFromAnnotation(action->annotations, action->name);
  cstring type = CamelCase(name);
  const IR::P4Table* table = control->action_to_table[name];
  if (table == nullptr) {
    ::error("unable to find table from action %s", name);
  }
  cstring table_name = nameFromAnnotation(table->annotations, table->name);
  cstring table_type = CamelCase(table_name);
  builder->append_line("typedef Engine#(1, MetadataRequest, %sParam) %sAction;", table_type, type);
  builder->append_line("instance Action_execute #(%sParam);", table_type);
  // FIXME: do one step for now..
  builder->incr_indent();
  builder->append_line("function ActionValue#(MetadataRequest) step_1 (MetadataRequest meta, %sParam param);", table_type);
  builder->incr_indent();
  builder->append_line("actionvalue");
  builder->incr_indent();
  builder->append_line("$display(\"(%%0d) step 1: \", $time, fshow(meta));");
  // table->params
  // invoke each action
  builder->append_line("return meta;");
  builder->decr_indent();
  builder->append_line("endactionvalue");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->decr_indent();
  builder->append_line("endinstance");
}

bool ActionCodeGen::isDropAction(const IR::P4Action* action) {
  bool is_drop = false;
  if (action->body == nullptr) {
    return false;
  }
  for (auto s : *action->body->components) {
    auto stmt = s->to<IR::MethodCallStatement>();
    if (stmt == nullptr) continue;
    auto expr = stmt->methodCall->to<IR::MethodCallExpression>();
    if (expr == nullptr) continue;

    if (expr->method->is<IR::PathExpression>()) {
      auto path = expr->method->to<IR::PathExpression>();
      if (path != nullptr && path->path->name == "mark_to_drop") {
        return true;
      }
    }
  }
  return is_drop;
}

bool ActionCodeGen::isNoAction(const IR::P4Action* action) {
  bool is_nop = false;
  if (action->body == nullptr) {
    return true;
  }
  if (action->body->components->size() == 0) {
    return true;
  }
  return is_nop;
}

void ActionCodeGen::postorder(const IR::P4Action* action) {
  auto stmt = action->body->to<IR::BlockStatement>();

  if (stmt == nullptr) {
    return;
  }
  emitActionBegin(action);
  if (isDropAction(action)) {
    emitDropAction(action);
  } else if (isNoAction(action)) {
    emitNoAction(action);
  } else {
    emitModifyAction(action);
  }
}

}  // namespace FPGA
