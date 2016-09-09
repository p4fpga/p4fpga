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

void TableCodeGen::emit(const IR::TableBlock* table) {
  auto tbl = table->container->to<IR::P4Table>();
  auto name = tbl->name;
  auto type = CamelCase(name);
  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);

  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_line(bsv, "module mk%s (%s)", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);

  append_line(bsv, "RX #(MetadataRequest) rx_metadata <- mkRX;");
  append_line(bsv, "TX #(MetadataRequest) tx_metadata <- mkTX;");
  append_line(bsv, "let rx_info_metadata = rx_metadata.u;");
  append_line(bsv, "let tx_info_metadata = tx_metadata.u;");

  auto nActions = tbl->getActionList()->actionList->size();
  append_format(bsv, "Vector#(%d, FIFOF#(BBRequest)) bbReqFifo <- replicateM(mkFIFOF);", nActions);
  append_format(bsv, "Vector#(%d, FIFOF#(BBResponse)) bbRspFifo <- replicateM(mkFIFOF);", nActions);

  decr_indent(bsv);
  append_line(bsv, "endmodule");
}

bool TableCodeGen::preorder(const IR::TableBlock* table) {
  LOG1("Table " << table);
  auto tbl = table->container->to<IR::P4Table>();
  for (auto act : *tbl->getActionList()->actionList) {
    auto element = act->to<IR::ActionListElement>();
    if (element->expression->is<IR::PathExpression>()) {
      //LOG1("Path " << element->expression->to<IR::PathExpression>());
    } else if (element->expression->is<IR::MethodCallExpression>()) {
      auto expression = element->expression->to<IR::MethodCallExpression>();
      auto type = control->program->typeMap->getType(expression->method, true);
      auto action = expression->method->toString();
      //control->action_to_table[action] = tbl;
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
        //LOG1("header meta " << t->getField(m->member) << " " << table);
        auto f = t->getField(m->member);
        //control->metadata_to_table[f].insert(tbl);
      }
    }
  }

  emit(table);

  return false;
}

}  // namespace FPGA
