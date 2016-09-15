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
  cstring defaultActionName;
  void emit(const IR::P4Table* table);
  void emitTypedefs(const IR::P4Table* table);
  void emitSimulation(const IR::P4Table* table);
  void emitRuleHandleRequest(const IR::P4Table* table);
  void emitRuleHandleExecution(const IR::P4Table* table);
  void emitRuleHandleResponse(const IR::P4Table* table);
  void emitRspFifoMux(const IR::P4Table* table);
  void emitCpp(const IR::P4Table* table);
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TABLE_H_ */
