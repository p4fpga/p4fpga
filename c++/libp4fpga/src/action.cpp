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

using namespace Control;

bool ActionCodeGen::preorder(const IR::AssignmentStatement* stmt) {
  append_line(bsv, "// %s = %s", stmt->left, stmt->right);
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
    LOG1("handle extern");
    return false;
  }

  auto actioncall = mi->to<P4::ActionCall>();
  if (actioncall != nullptr) {
    LOG1("action call");
    append_line(bsv, expression->toString());
    return false;
  }

  auto extFunc = mi->to<P4::ExternFunction>();
  if (extFunc != nullptr) {
    if (extFunc->method->name == "mark_to_drop") {
      append_line(bsv, "// mark_to_drop ");
    }
    return false;
  }

  LOG1(mi->methodType);
  return false;
}

void ActionCodeGen::emitCpuReqRule() {
  append_line(bsv, "rule rl_cpu_request if (cpu.not_running());");
  incr_indent(bsv);
  append_line(bsv, "let v = rx_info_prev_control_state.first;");
  append_line(bsv, "rx_info_prev_control_state.deq;");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void ActionCodeGen::emitCpuRspRule(const IR::P4Action* action) {
  auto name = action->name;
  auto type = CamelCase(name);
  auto table = control->action_to_table[name];
  auto table_name = nameFromAnnotation(table->annotations, table->name);
  auto table_type = CamelCase(table_name);
  std::vector<cstring> fields;
  cstring response = "";
  if (action->parameters->size() > 0) {
    auto params = action->parameters->to<IR::ParameterList>();
    if (params != nullptr) {
      for (auto p : *params->parameters) {
        fields.push_back(p->name);
      }
    }
    for (auto f : fields) {
      response += cstring(f) + ": " + cstring(f);
      if (f != fields.back()) {
        response += ", ";
      }
    }
  }
  append_line(bsv, "rule rl_cpu_resp if (cpu.not_running());");
  incr_indent(bsv);
  append_line(bsv, "let pkt <- toGet(curr_packet_ff).get;"); // FIXME: bottleneck
  append_format(bsv, "%sActionRsp rsp = tagged %sRspT {%s};", table_type, type, response);
  append_line(bsv, "tx_info_prev_control_state.enq(rsp);");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void ActionCodeGen::emitDropAction(const IR::P4Action* action) {
  auto name = action->name.toString();
  auto type = CamelCase(name);
  append_format(bsv, "// =============== action %s ==============", name);
  auto table = control->action_to_table[name];
  auto table_name = nameFromAnnotation(table->annotations, table->name);
  auto table_type = CamelCase(table_name);
  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);
  append_line(bsv, "interface Server#(%sActionReq, %sActionRsp) prev_control_state;", table_type, table_type);
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_line(bsv, "module mk%s (%s);", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);
  append_line(bsv, "RX #(%sActionReq) rx_prev_control_state <- mkRX;", table_type);
  append_line(bsv, "TX #(%sActionRsp) tx_prev_control_state <- mkTX;", table_type);
  append_line(bsv, "let rx_info_prev_control_state = rx_prev_control_state.u;");
  append_line(bsv, "let tx_info_prev_control_state = tx_prev_control_state.u;");
  append_line(bsv, "rule drop;");
  incr_indent(bsv);
  append_line(bsv, "let v = rx_info_prev_control_state.first;");
  append_line(bsv, "rx_info_prev_control_state.deq;");
  decr_indent(bsv);
  append_line(bsv, "endrule");
  append_line(bsv, "FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;");
  append_line(bsv, "interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);");
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  incr_indent(bsv);
  append_line(bsv, "cf_verbosity <= verbosity;");
  // extern verbosity
  decr_indent(bsv);
  append_line(bsv, "endmethod");
  decr_indent(bsv);
  append_line(bsv, "endmodule");
}

void ActionCodeGen::emitForwardAction(const IR::P4Action* action) {
  auto name = action->name.toString();
  auto type = CamelCase(name);
  append_format(bsv, "// =============== action %s ==============", name);
  auto table = control->action_to_table[name];
  auto table_name = nameFromAnnotation(table->annotations, table->name);
  auto table_type = CamelCase(table_name);
  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);
  append_line(bsv, "interface Server#(%sActionReq, %sActionRsp) prev_control_state;", table_type, table_type);
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_line(bsv, "module mk%s (%s);", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);
  append_line(bsv, "RX #(%sActionReq) rx_prev_control_state <- mkRX;", table_type);
  append_line(bsv, "TX #(%sActionRsp) tx_prev_control_state <- mkTX;", table_type);
  append_line(bsv, "let rx_info_prev_control_state = rx_prev_control_state.u;");
  append_line(bsv, "let tx_info_prev_control_state = tx_prev_control_state.u;");
  append_line(bsv, "interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);");
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  incr_indent(bsv);
  append_line(bsv, "cf_verbosity <= verbosity;");
  // extern verbosity
  decr_indent(bsv);
  append_line(bsv, "endmethod");
  decr_indent(bsv);
  append_line(bsv, "endmodule");

}

void ActionCodeGen::emitCPUAction(const IR::P4Action* action) {
  auto name = action->name.toString();
  auto type = CamelCase(name);
  append_format(bsv, "// =============== action %s ==============", name);
  auto table = control->action_to_table[name];
  auto table_name = nameFromAnnotation(table->annotations, table->name);
  auto table_type = CamelCase(table_name);
  // generate instruction for cpu;
  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);
  append_line(bsv, "interface Server#(%sActionReq, %sActionRsp) prev_control_state;", table_type, table_type);
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_line(bsv, "module mk%s (%s);", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);
  append_line(bsv, "RX #(%sActionReq) rx_prev_control_state <- mkRX;", table_type);
  append_line(bsv, "TX #(%sActionRsp) tx_prev_control_state <- mkTX;", table_type);
  append_line(bsv, "let rx_info_prev_control_state = rx_prev_control_state.u;");
  append_line(bsv, "let tx_info_prev_control_state = tx_prev_control_state.u;");
  append_line(bsv, "FIFOF#(PacketInstance) curr_packet_ff <- mkFIFOF;");
  append_line(bsv, "CPU cpu <- mkCPU(\"%s\", List::nil);", name);
  append_line(bsv, "IMem imem <- mkIMem(\"%s.hex\");", name);
  append_line(bsv, "mkConnection(cpu.imem_client, imem.cpu_server);");
  // Extern ??
  emitCpuReqRule();
  emitCpuRspRule(action);
  append_line(bsv, "interface prev_control_state = toServer(rx_prev_control_state.e, tx_prev_control_state.e);");
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  incr_indent(bsv);
  append_line(bsv, "cf_verbosity <= verbosity;");
  append_line(bsv, "cpu.set_verbosity(verbosity);");
  append_line(bsv, "imem.set_verbosity(verbosity);");
  // extern verbosity
  decr_indent(bsv);
  append_line(bsv, "endmethod");
  decr_indent(bsv);
  append_line(bsv, "endmodule");
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
  if (isNoAction(action)) {
    emitForwardAction(action);
  } else if (isDropAction(action)) {
    emitDropAction(action);
  } else {
    emitCPUAction(action);
  }
}

}  // namespace FPGA
