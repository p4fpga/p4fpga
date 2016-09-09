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

#include <algorithm>
#include <string>
#include "table.h"
#include "fcontrol.h"
#include "string_utils.h"

/*
  info associated with a table
  - key, value
  - name
  - actions
 */

namespace FPGA {

using namespace Control;

//bool TableCodeGen::compareActionListElement

void TableCodeGen::emitTypedefs(const IR::P4Table* table) {
  // generate request typedef
  auto name = table->name.toString();
  auto type = CamelCase(name);
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  if ((key_width % 9) != 0) {
    auto pad = 9 - (key_width % 9);
    append_line(bsv, "Bit#(%d) padding;", pad);
  }
  for (auto k : key_vec) {
    auto f = k.first;
    auto s = k.second;
    append_line(bsv, "Bit#(%d) %s;", s, f->name.toString());
  }
  decr_indent(bsv);
  append_format(bsv, "} %sReqT deriving (Bits, Eq, FShow);", type);

  // action enum
  append_line(bsv, "typedef enum {");
  incr_indent(bsv);
  // find out name of default action
  auto defaultAction = table->getDefaultAction();
  if (defaultAction->is<IR::MethodCallExpression>()){
    auto expression = defaultAction->to<IR::MethodCallExpression>();
    defaultActionName = expression->method->toString();
  }
  // put default action in first position
  auto actionList = table->getActionList()->actionList;
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::PathExpression>()) {
      // FIXME: handle action as path
      LOG1("Path " << elem->expression->to<IR::PathExpression>());
    } else if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto t = control->program->typeMap->getType(e->method, true);
      auto n = e->method->toString();
      // check if default action
      if (n == defaultActionName) {
        action_vec.insert(action_vec.begin(), UpperCase(n));
      } else {
        action_vec.push_back(UpperCase(n));
      }
    }
  }
  // generate enum typedef
  for (auto action : action_vec) {
      if (action != action_vec.back()) {
        append_line(bsv, "%s,", action);
      } else {
        append_line(bsv, "%s", action);
      }
  }
  decr_indent(bsv);
  append_line(bsv, "} %sActionT deriving (Bits, Eq, FShow);", type);

  // generate response typedef
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  append_line(bsv, "%sActionT action;", type);
  // if there is any params
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto n = e->method->toString();
      // from action name to actual action declaration
      auto k = control->basicBlock.find(n);
      if (k != control->basicBlock.end()) {
        auto params = k->second->parameters;
        for (auto p : *params->parameters) {
          auto type = p->type->to<IR::Type_Bits>();
          append_line(bsv, "Bit#(%d) %s;", type->size, p->name.toString());
        }
      }
    }
  }
  decr_indent(bsv);
  append_line(bsv, "} %sRspT deriving (Bits, Eq, FShow);", type);
}
void TableCodeGen::emit(const IR::P4Table* table) {
  auto name = table->name.toString();
  auto type = CamelCase(name);

  append_format(bsv, "// =============== table %s ==============", name);

  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);
  append_line(bsv, "Server#(MetadataRequest, MetadataResponse) prev_control_state;");
  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_format(bsv, "module mk%s (%s);", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);

  append_line(bsv, "RX #(MetadataRequest) rx_metadata <- mkRX;");
  append_line(bsv, "TX #(MetadataRequest) tx_metadata <- mkTX;");
  append_line(bsv, "let rx_info_metadata = rx_metadata.u;");
  append_line(bsv, "let tx_info_metadata = tx_metadata.u;");

  auto nActions = table->getActionList()->actionList->size();
  append_format(bsv, "Vector#(%d, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);", nActions);
  append_format(bsv, "Vector#(%d, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);", nActions);

  decr_indent(bsv);
  append_line(bsv, "endmodule");
}

bool TableCodeGen::preorder(const IR::P4Table* table) {
  auto tbl = table->to<IR::P4Table>();
  for (auto act : *tbl->getActionList()->actionList) {
    auto element = act->to<IR::ActionListElement>();
    if (element->expression->is<IR::PathExpression>()) {
      LOG1("Path " << element->expression->to<IR::PathExpression>());
    } else if (element->expression->is<IR::MethodCallExpression>()) {
      auto expression = element->expression->to<IR::MethodCallExpression>();
      auto type = control->program->typeMap->getType(expression->method, true);
      auto action = expression->method->toString();
      //control->action_to_table[action] = tbl;
      LOG1("action " << action);
    }
  }

  // visit keys
  auto keys = tbl->getKey();
  if (keys == nullptr) return false;

  for (auto key : *keys->keyElements) {
    auto element = key->to<IR::KeyElement>();
    if (element->expression->is<IR::Member>()) {
      auto m = element->expression->to<IR::Member>();
      auto type = control->program->typeMap->getType(m->expr, true);
      if (type->is<IR::Type_Struct>()) {
        auto t = type->to<IR::Type_StructLike>();
        auto f = t->getField(m->member);
        auto f_size = f->type->to<IR::Type_Bits>()->size;
        //control->metadata_to_table[f].insert(tbl);
        key_vec.push_back(std::make_pair(f, f_size));
        key_width += f_size;
      } else if (type->is<IR::Type_Header>()){
        auto t = type->to<IR::Type_Header>();
        auto f = t->getField(m->member);
        auto f_size = f->type->to<IR::Type_Bits>()->size;
        key_vec.push_back(std::make_pair(f, f_size));
        key_width += f_size;
      }
    }
  }


  emitTypedefs(tbl);
  emit(tbl);

  return false;
}

}  // namespace FPGA
