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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_ACTION_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_ACTION_H_

#include "ir/ir.h"
#include "fcontrol.h"

namespace FPGA {

class ActionCodeGen : public Inspector {
 public:
  ActionCodeGen(FPGAControl* control, BSVProgram& bsv, CodeBuilder* builder) : 
    control(control), bsv(bsv), builder(builder) {}
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::Expression* expression) override;
  bool preorder(const IR::MethodCallExpression* expression) override;
  void postorder(const IR::P4Action* action) override;
  bool isDropAction(const IR::P4Action* action);
  bool isNoAction(const IR::P4Action* action);
 private:
  FPGAControl* control;
  BSVProgram & bsv;
  CodeBuilder* builder;
  cstring table_name;
  cstring table_type;
  void emitModifyAction(const IR::P4Action* action);
  void emitNoAction(const IR::P4Action* action);
  void emitDropAction(const IR::P4Action* action);
  void emitCpuRspRule(const IR::P4Action* action);
  void emitActionBegin(const IR::P4Action* action);
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_ACTION_H_ */
