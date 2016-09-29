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

#ifndef _BACKENDS_FPGA_FPGADEPARSER_H_
#define _BACKENDS_FPGA_FPGADEPARSER_H_

#include "ir/ir.h"
#include "program.h"

namespace FPGA {

class FPGADeparser : public FPGAObject {
 public:
  const FPGAProgram* program;
  const IR::ControlBlock* controlBlock;
  std::vector<IR::BSV::DeparseState*> states;
  CodeBuilder* builder;

  void emitEnums();
  void emitRules();
  void emitStates();

  explicit FPGADeparser(const FPGAProgram* program, const IR::ControlBlock* block)
    : program(program), controlBlock(block) { };
  void emit(BSVProgram &bsv ) override;
  bool build();
};

}  // namespace FPGA

#endif
