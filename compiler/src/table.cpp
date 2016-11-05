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

namespace FPGA {

void TableCodeGen::emitTableRequestType(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  type_builder->append_line("import DefaultValue::*;");
  type_builder->append_line("typedef struct{");
  type_builder->incr_indent();
  if ((key_width % 9) != 0) {
    int pad = 9 - (key_width % 9);
    type_builder->append_line("Bit#(%d) padding;", pad);
  }
  for (auto k : key_vec) {
    const IR::StructField* f = k.first;
    int size = k.second;
    cstring fname = f->name.toString();
    if (size > 64) {
      int vec_size = size / 64;
      type_builder->append_line("Vector#(%d, Bit#(64)) %s;", vec_size, fname);
    } else {
      type_builder->append_line("Bit#(%d) %s;", size, fname);
    }
    //type_builder->append_format("Bit#(%d) %s;", size, fname);
  }
  type_builder->decr_indent();
  type_builder->append_format("} %sReqT deriving (Bits, FShow);", type);

  type_builder->append_line("instance DefaultValue#(%sReqT);", type);
  type_builder->incr_indent();
  type_builder->append_line("defaultValue = unpack(0);");
  type_builder->decr_indent();
  type_builder->append_line("endinstance");
}

void TableCodeGen::emitActionEnum(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  builder->append_line("typedef enum {");
  builder->incr_indent();
  // find out name of default action
  auto defaultAction = table->getDefaultAction();
  //if (defaultAction->is<IR::MethodCallExpression>()){
  //  auto e = defaultAction->to<IR::MethodCallExpression>();
  //  defaultActionName = control->toP4Action(e->method->toString());
  //  LOG1("table name " << name << e->method->toString());
  //  CHECK_NULL(defaultActionName);
  //}
  // put default action in first position
  auto actionList = table->getActionList()->actionList;
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::PathExpression>()) {
      // FIXME: handle action as path
      LOG1("Path " << elem->expression->to<IR::PathExpression>());
    } else if (elem->expression->is<IR::MethodCallExpression>()) {
      auto expr = elem->expression->to<IR::MethodCallExpression>();
      //auto t = control->program->typeMap->getType(e->method, true);
      //cstring n = control->toP4Action(expr->method->toString());
      //CHECK_NULL(n);
      //// put default action at position 0
      //if (n == defaultActionName) {
      //  action_vec.insert(action_vec.begin(), UpperCase(n));
      //} else {
      //  action_vec.push_back(UpperCase(n));
      //}
      action_vec.push_back(UpperCase(expr->method->toString()));
    }
  }
  // generate enum typedef
  for (auto action : action_vec) {
      if (action != action_vec.back()) {
        builder->append_line("%s,", action);
      } else {
        builder->append_line("%s", action);
      }
  }
  builder->decr_indent();
  builder->append_line("} %sActionT deriving (Bits, Eq, FShow);", type);
}

void TableCodeGen::emitTableResponseType(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  auto actionList = table->getActionList()->actionList;
  //builder->append_line("typedef struct {");
  //builder->incr_indent();
  //builder->append_line("%sActionT _action;", type);
  // if there is any params
  TableParamExtractor param_extractor(control);
  for (auto action : *actionList) {
    action->apply(param_extractor);
  }
  cstring tname = table->name.toString();
  type_builder->append_format("typedef struct {");
  type_builder->incr_indent();
  int action_key_size = ceil(log2(actionList->size()));
  LOG1("action list " << table->name << " " << actionList->size() << " " << action_key_size);
  type_builder->append_format("Bit#(%d) _action;", action_key_size);
  for (auto f : param_extractor.param_map) {
    cstring pname = f.first;
    const IR::Type_Bits* param = f.second;
    //builder->append_line("Bit#(%d) %s;", param->size, pname);
    type_builder->append_format("Bit#(%d) %s;", param->size, pname);
    action_size += param->size;
  }
  action_size += ceil(log2(actionList->size()));
  type_builder->decr_indent();
  type_builder->append_format("} %sRspT deriving (Bits, FShow);", type);
  //builder->decr_indent();
  //builder->append_line("} %sRspT deriving (Bits, Eq, FShow);", type);
}

void TableCodeGen::emitTypedefs(const IR::P4Table* table) {
  // Typedef are emitted to two different files
  // - ConnectalType is used by Connectal to generate API
  // - Control is used by p4 pipeline
  // TODO: we can probably just generate ConnectalType and import it in Control
  emitTableRequestType(table);
  emitActionEnum(table);
  emitTableResponseType(table);
}

void TableCodeGen::emitSimulation(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto id = table->declid % 32;
  auto remainder = key_width % 9;
  if (remainder != 0) {
    key_width = key_width + 9 - remainder;
  }
  builder->append_line("`MATCHTABLE_SIM(%d, %d, %d, %s)", id, key_width, action_size, name);
}

cstring TableCodeGen::gatherTableKeys() {
  cstring fields = "";
  int field_width = 0;
  for (auto k : key_vec) {
    auto f = k.first;
    auto s = k.second;
    LOG1("key size" << s);
    field_width += s;
    cstring name = f->name.toString();
    fields += name + cstring(": ") + name;
    if (k != key_vec.back()) {
      fields += cstring(",");
    }
  }
  if (field_width % 9 != 0) {
    fields += ", padding: 0";
  }
  return fields;
}

void TableCodeGen::emitFunctionLookup(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  builder->append_line("instance Table_request #(ConnectalTypes::%sReqT);", type);
  builder->incr_indent();
  builder->append_line("function ConnectalTypes::%sReqT table_request(MetadataRequest data);", type);
  builder->incr_indent();
  cstring fields = gatherTableKeys();
  // FIXME: work around for SOSR
  builder->append_line("ConnectalTypes::%sReqT v = defaultValue;", type);
  builder->append_line("if (data.meta.hdr.ethernet matches tagged Valid .ethernet) begin");
  builder->incr_indent();
  builder->append_line("let dstAddr = ethernet.hdr.dstAddr;");
  builder->append_line("v = ConnectalTypes::%sReqT {%s};", type, fields);
  builder->decr_indent();
  builder->append_line("end");
  builder->append_line("return v;");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->decr_indent();
  builder->append_line("endinstance");
}

void TableCodeGen::emitFunctionExecute(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  //const IR::IndexedVector<IR::ActionListElement>* actionList
  auto actionList = table->getActionList()->actionList;
  int actionSize = (actionList != nullptr) ? actionList->size() : 0;
  builder->append_line("instance Table_execute #(ConnectalTypes::%sRspT, %sParam, %d);", type, type, actionSize);
  builder->incr_indent();
  builder->append_line("function Action table_execute(ConnectalTypes::%sRspT resp, MetadataRequest metadata, Vector#(%d, FIFOF#(Tuple2#(MetadataRequest, %sParam))) fifos);", type, actionSize, type);
  builder->incr_indent();
  builder->append_line("action");
  builder->append_line("case (unpack(resp._action)) matches");
  builder->incr_indent();
  if (actionList != nullptr) {
    ActionParamPrinter printer(control, builder, name);
    for (auto p : *actionList) {
      p->apply(printer);
    }
  }
  builder->decr_indent();
  builder->append_line("endcase");
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->decr_indent();
  builder->append_line("endinstance");
}

void TableCodeGen::emitIntfAddEntry(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  builder->append_format("method Action add_entry(ConnectalTypes::%sReqT k, ConnectalTypes::%sRspT v);", type, type);
  builder->newline();

  TableKeyExtractor key_extractor(control->program);
  const IR::Key* key = table->getKey();
  if (key != nullptr) {
    builder->incr_indent();
    builder->append_format("let key = %sReqT{", type);
    for (auto k : *key->keyElements) {
      k->apply(key_extractor);
    }
    if ((key_extractor.key_width % 9) != 0) {
      builder->append_format("padding: 0, ");
    }
    for (auto it = key_extractor.keymap.begin(); it != key_extractor.keymap.end(); ++it) {
      const IR::StructField* field = it->second;
      cstring member = it->first;
      if (field->type->is<IR::Type_Bits>()) {
        int size = field->type->to<IR::Type_Bits>()->size;
        if (it != key_extractor.keymap.begin()) {
          builder->append_format(", ");
        }
        builder->append_format("%s: k.%s", member, member);
      }
    }
    builder->append_line("};");
    builder->append_format("let value = %sRspT{", type);
    builder->append_line("_action: unpack(v._action)");

    auto actionList = table->getActionList()->actionList;
    TableParamExtractor param_extractor(control);
    for (auto action : *actionList) {
      action->apply(param_extractor);
    }
    for (auto f : param_extractor.param_map) {
      cstring pname = f.first;
      builder->append_format(", %s : v.%s", pname, pname);
    }
    builder->append_line("};");
    builder->append_line("matchTable.add_entry.put(tuple2(pack(key), pack(value)));");
    builder->decr_indent();
  }
  builder->append_line("endmethod");
}

void TableCodeGen::emit(const IR::P4Table* table) {
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  int id = table->declid % 32;
  //const IR::IndexedVector<IR::ActionListElement>* actionList
  auto actionList = table->getActionList()->actionList;
  int actionSize = (actionList != nullptr) ? actionList->size() : 0;
  CHECK_NULL(builder);
  builder->append_line("typedef Table#(%d, MetadataRequest, %sParam, ConnectalTypes::%sReqT, ConnectalTypes::%sRspT) %sTable;", actionSize, type, type, type, type);
  builder->append_line("typedef MatchTable#(1, %d, %d, SizeOf#(ConnectalTypes::%sReqT), SizeOf#(ConnectalTypes::%sRspT)) %sMatchTable;", id, 256, type, type, type);
  builder->append_line("`SynthBuildModule1(mkMatchTable, String, %sMatchTable, mkMatchTable_%s)", type, type);
  emitFunctionLookup(table);
  emitFunctionExecute(table);
}

void TableCodeGen::emitCpp(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  cpp_builder->append_line("typedef uint64_t %sReqT;", type);
  cpp_builder->append_line("typedef uint64_t %sRspT;", type);
  cpp_builder->append_line("std::unordered_map<%sReqT, %sRspT> tbl_%s;", type, type, name);
  cpp_builder->append_line("extern \"C\" %sReqT matchtable_read_%s(%sReqT rdata) {", type, name, type);
  cpp_builder->incr_indent();
  cpp_builder->append_line("auto it = tbl_%s.find(rdata);", name);

  cpp_builder->append_line("if (it != tbl_%s.end()) {", name);
  cpp_builder->incr_indent();
  cpp_builder->append_line("return tbl_%s[rdata];", name);
  cpp_builder->decr_indent();
  cpp_builder->append_line("} else {");
  cpp_builder->incr_indent();
  cpp_builder->append_line("return 0;");
  cpp_builder->decr_indent();
  cpp_builder->append_line("}");
  cpp_builder->decr_indent();
  cpp_builder->append_line("}");

  cpp_builder->append_line("extern \"C\" void matchtable_write_%s(%sReqT wdata, %sRspT action){", name, type, type);
  cpp_builder->incr_indent();
  cpp_builder->append_line("tbl_%s[wdata] = action;", name);
  cpp_builder->decr_indent();
  cpp_builder->append_line("}");
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
  if (keys != nullptr) {
    for (auto key : *keys->keyElements) {
      auto element = key->to<IR::KeyElement>();
      if (element->expression->is<IR::Member>()) {
        auto m = element->expression->to<IR::Member>();
        auto type = control->program->typeMap->getType(m->expr, true);
        if (type->is<IR::Type_Struct>()) {
          auto t = type->to<IR::Type_StructLike>();
          auto f = t->getField(m->member);
          auto f_size = f->type->to<IR::Type_Bits>()->size;
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
  }
  //FIXME: switch.p4 does not like this.
  emitTypedefs(tbl);
  emitSimulation(tbl);
  emit(tbl);
  emitCpp(tbl);
  return false;
}

}  // namespace FPGA
