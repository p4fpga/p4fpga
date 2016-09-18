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
  explicit TableKeyExtractor (FPGAProgram* program) :
    program(program) {}

  bool preorder(const IR::Member* member) {
    if (member->member == "isValid") return false;
    auto type = program->typeMap->getType(member->expr, true);
    if (type->is<IR::Type_Struct>()) {
      auto t = type->to<IR::Type_StructLike>();
      auto f = t->getField(member->member);
      keymap.emplace(member->member, f);
    // from hdr
    } else if (type->is<IR::Type_Header>()) {
      auto t = type->to<IR::Type_StructLike>();
      auto f = t->getField(member->member);
      keymap.emplace(member->member, f);
    }
    return false;
  }
 private:
  FPGAProgram*          program;
};


// per table code generator
class TableCodeGen : public Inspector {
 public:
  TableCodeGen(FPGAControl* control, BSVProgram & bsv, CppProgram & cpp) :
    control(control), bsv(bsv), cpp(cpp) {}
  bool preorder(const IR::P4Table* table) override;
 private:
  FPGAControl* control;
  BSVProgram & bsv;
  CppProgram & cpp;
  int key_width = 0;
  int action_size = 0;
  std::vector<std::pair<const IR::StructField*, int>> key_vec;
  std::vector<cstring> action_vec;
  std::map<cstring, const IR::Type_Bits*> param_map;

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
