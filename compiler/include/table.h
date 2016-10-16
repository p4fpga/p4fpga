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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TABLE_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TABLE_H_

#include "ir/ir.h"
#include "fcontrol.h"
#include "lib/ordered_map.h"
#include "string_utils.h"

namespace FPGA {

class TableKeyExtractor : public Inspector {
 public:
  std::map<cstring, const IR::StructField*> keymap;
  int key_width = 0;
  explicit TableKeyExtractor (FPGAProgram* program) :
    program(program) {}

  bool preorder(const IR::Member* member) {
    if (member->member == "isValid") return false;
    auto type = program->typeMap->getType(member->expr, true);
    if (type->is<IR::Type_Struct>()) {
      const IR::Type_StructLike* t = type->to<IR::Type_StructLike>();
      const IR::StructField* f = t->getField(member->member);
      int f_size = f->type->to<IR::Type_Bits>()->size;
      keymap.emplace(member->member, f);
      key_width += f_size;
    // from hdr
    } else if (type->is<IR::Type_Header>()) {
      const IR::Type_StructLike* t = type->to<IR::Type_StructLike>();
      const IR::StructField* f = t->getField(member->member);
      int f_size = f->type->to<IR::Type_Bits>()->size;
      keymap.emplace(member->member, f);
      key_width += f_size;
    }
    return false;
  }
 private:
  FPGAProgram*          program;
};

class TableParamExtractor : public Inspector {
 public:
  std::map<cstring, const IR::Type_Bits*> param_map;
  explicit TableParamExtractor (FPGAControl* control) :
    control(control) {}
  bool preorder(const IR::MethodCallExpression* methodcall) {
    auto k = control->actions.find(methodcall->method->toString());
    if (k != control->actions.end()) {
      auto params = k->second->parameters;
      for (auto p : *params->parameters) {
        auto type = p->type->to<IR::Type_Bits>();
        param_map[p->name.toString()] = type;
      }
    }
    return false;
  }
 private:
  FPGAControl*          control;
};

class ActionParamPrinter : public Inspector {
 public:
  std::vector<cstring> param_vec;
  explicit ActionParamPrinter (FPGAControl* control, CodeBuilder* builder, cstring name) :
    control(control), builder(builder), table_name(name) {}
  bool preorder(const IR::MethodCallExpression* expr) {
    // from action name to actual action declaration
    auto k = control->actions.find(expr->method->toString());
    if (k != control->actions.end()) {
      auto params = k->second->parameters;
      param_vec.clear();
      for (auto param : *params->parameters) {
        auto p = param->to<IR::Parameter>();
        if (p == nullptr) continue;
        cstring name = p->name.toString();
        param_vec.push_back(name);
      }
      cstring action_name = nameFromAnnotation(k->second->annotations, k->second->name);
      cstring action_type = CamelCase(action_name);
      builder->append_format("%s: begin", UpperCase(action_type));
      builder->incr_indent();
      if (param_vec.size() != 0) {
        builder->emitIndent();
        CHECK_NULL(action_type);
        builder->appendFormat("%sParam req = tagged %sReqT {", CamelCase(table_name), action_type);
        for (auto p : param_vec) {
          builder->appendFormat("%s: resp.%s", p, p);
          if (p != param_vec.back()) {
            builder->append(", ");
          }
        }
        builder->append("};");
        builder->newline();
        builder->append_format("fifos[%d].enq(tuple2(metadata, req));", action_idx);
      } else {
        builder->append_format("fifos[%d].enq(tuple2(metadata, ?));", action_idx);
      }
      builder->decr_indent();
      builder->append_line("end");
    }
    action_idx ++;
    return false;
  }
 private:
  int action_idx = 0;
  FPGAControl* control;
  CodeBuilder* builder;
  cstring table_name;
};

// per table code generator
class TableCodeGen : public Inspector {
 public:
  TableCodeGen(FPGAControl* control, CodeBuilder* builder, CodeBuilder* cpp_builder, CodeBuilder* type_builder) :
    control(control), builder(builder), cpp_builder(cpp_builder), type_builder(type_builder) {}
  bool preorder(const IR::P4Table* table) override;
  // bool preorder(const IR::MethodCallExpression* expr) override;
 private:
  FPGAControl* control;
  CodeBuilder* builder;
  CodeBuilder* cpp_builder;
  CodeBuilder* type_builder;
  int key_width = 0;
  int action_size = 0;
  int action_idx = 0;
  std::vector<std::pair<const IR::StructField*, int>> key_vec;
  std::vector<cstring> action_vec;
  cstring defaultActionName;
  cstring gatherTableKeys();
  cstring tableName;
  void emit(const IR::P4Table* table);
  void emitTableRequestType(const IR::P4Table* table);
  void emitActionEnum(const IR::P4Table* table);
  void emitTableResponseType(const IR::P4Table* table);
  void emitTypedefs(const IR::P4Table* table);
  void emitSimulation(const IR::P4Table* table);
  void emitFunctionLookup(const IR::P4Table* table);
  void emitFunctionExecute(const IR::P4Table* table);
  void emitIntfAddEntry(const IR::P4Table* table);
  void emitCpp(const IR::P4Table* table);
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TABLE_H_ */
