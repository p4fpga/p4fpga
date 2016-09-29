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
    auto k = control->basicBlock.find(methodcall->method->toString());
    if (k != control->basicBlock.end()) {
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

// per table code generator
class TableCodeGen : public Inspector {
 public:
  TableCodeGen(FPGAControl* control, CodeBuilder* builder, CodeBuilder* cbuilder, CodeBuilder* type_builder) :
    control(control), builder(builder), cbuilder(cbuilder), type_builder(type_builder) {}
  bool preorder(const IR::P4Table* table) override;
 private:
  FPGAControl* control;
  CodeBuilder* builder;
  CodeBuilder* cbuilder;
  CodeBuilder* type_builder;
  int key_width = 0;
  int action_size = 0;
  std::vector<std::pair<const IR::StructField*, int>> key_vec;
  std::vector<cstring> action_vec;
  cstring defaultActionName;
  void emit(const IR::P4Table* table);
  void emitTypedefs(const IR::P4Table* table);
  void emitSimulation(const IR::P4Table* table);
  void emitRuleHandleRequest(const IR::P4Table* table);
  void emitRuleHandleExecution(const IR::P4Table* table);
  void emitRuleHandleResponse(const IR::P4Table* table);
  void emitRspFifoMux(const IR::P4Table* table);
  void emitIntfAddEntry(const IR::P4Table* table);
  void emitIntfControlFlow(const IR::P4Table* table);
  void emitIntfVerbosity(const IR::P4Table* table);
  void emitCpp(const IR::P4Table* table);
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TABLE_H_ */
