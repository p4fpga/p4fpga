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

#include "funion.h"
#include "ir/ir.h"
#include "string_utils.h"

namespace FPGA {

bool UnionCodeGen::preorder(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);

  builder->append_line("typedef union tagged {");
  builder->incr_indent();
  for (auto act : *table->getActionList()->actionList) {
    auto elem = act->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto expr = elem->expression->to<IR::MethodCallExpression>();
      auto action = expr->method->toString();
      LOG1("action type " << action << " " << expr->method->node_type_name());
      auto ty = CamelCase(action);
      builder->append_line("struct {");
      builder->incr_indent();
      builder->append_line("PacketInstance pkt;");
      builder->append_line("MetadataT meta;");
      auto k = control->basicBlock.find(action);
      if (k != control->basicBlock.end()) {
        auto params = k->second->parameters;
        for (auto p : *params->parameters) {
          auto type = p->type->to<IR::Type_Bits>();
          builder->append_line("Bit#(%d) %s;", type->size, p->name.toString() );
        }
      }
      builder->decr_indent();
      builder->append_line("} %sReqT;", ty);
    }
  }
  builder->decr_indent();
  builder->append_line("} %sActionReq deriving (Bits, Eq, FShow);", type);

  builder->append_line("typedef union tagged {");
  builder->incr_indent();
  for (auto act : *table->getActionList()->actionList) {
    auto elem = act->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto expr = elem->expression->to<IR::MethodCallExpression>();
      auto action = expr->method->toString();
      auto ty = CamelCase(action);
      builder->append_line("struct {");
      builder->incr_indent();
      builder->append_line("PacketInstance pkt;");
      builder->append_line("MetadataT meta;");
      builder->decr_indent();
      builder->append_line("} %sRspT;", ty);
    }
  }
  builder->decr_indent();
  builder->append_line("} %sActionRsp deriving (Bits, Eq, FShow);", type);
  return false;
}

void UnionCodeGen::emit() {
  builder->append_line("import Ethernet::*;");
  builder->append_line("import StructDefines::*;");
}

}  // namespace FPGA

