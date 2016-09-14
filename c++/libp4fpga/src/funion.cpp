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

using namespace Union;

bool UnionCodeGen::preorder(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);

  append_line(bsv, "typedef union tagged {");
  incr_indent(bsv);
  for (auto act : *table->getActionList()->actionList) {
    auto elem = act->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto expr = elem->expression->to<IR::MethodCallExpression>();
      auto action = expr->method->toString();
      LOG1("action type " << action << " " << expr->method->node_type_name());
      auto ty = CamelCase(action);
      append_line(bsv, "struct {");
      incr_indent(bsv);
      append_line(bsv, "PacketInstance pkt;");
      append_line(bsv, "MetadataT meta;");
      auto k = control->basicBlock.find(action);
      if (k != control->basicBlock.end()) {
        auto params = k->second->parameters;
        for (auto p : *params->parameters) {
          auto type = p->type->to<IR::Type_Bits>();
          append_line(bsv, "Bit#(%d) %s;", type->size, p->name.toString() );
        }
      }
      decr_indent(bsv);
      append_line(bsv, "} %sReqT;", ty);
    }
  }
  decr_indent(bsv);
  append_line(bsv, "} %sActionReq deriving (Bits, Eq, FShow);", type);

  append_line(bsv, "typedef union tagged {");
  incr_indent(bsv);
  for (auto act : *table->getActionList()->actionList) {
    auto elem = act->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto expr = elem->expression->to<IR::MethodCallExpression>();
      auto action = expr->method->toString();
      auto ty = CamelCase(action);
      append_line(bsv, "struct {");
      incr_indent(bsv);
      append_line(bsv, "PacketInstance pkt;");
      append_line(bsv, "MetadataT meta;");
      decr_indent(bsv);
      append_line(bsv, "} %sRspT;", ty);
    }
  }
  decr_indent(bsv);
  append_line(bsv, "} %sActionRsp deriving (Bits, Eq, FShow);", type);
  return false;
}

void UnionCodeGen::emit() {
  append_line(bsv, "import Ethernet::*;");
  append_line(bsv, "import StructDefines::*;");
}

}  // namespace FPGA

