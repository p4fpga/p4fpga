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

#ifndef P4FPGA_INCLUDE_FUNION_H_
#define P4FPGA_INCLUDE_FUNION_H_

#include "ir/ir.h"
#include "fcontrol.h"
#include "bsvprogram.h"
#include "string_utils.h"

namespace FPGA {

class UnionCodeGen : public Inspector {
 public:
  UnionCodeGen(FPGAControl* control, CodeBuilder* builder):
    control(control), builder(builder) {}
  bool preorder(const IR::P4Table* table) override;
  bool preorder(const IR::MethodCallExpression* expr) override;
  void emit();
 private:
  FPGAControl* control;
  CodeBuilder* builder;
};

}  // namespace FPGA

#endif /* P4FPGA_INCLUDE_FUNION_H_ */
