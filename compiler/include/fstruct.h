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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FSTRUCT_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FSTRUCT_H_

#include "ir/ir.h"
#include "program.h"
#include "bsvprogram.h"
#include "string_utils.h"

namespace FPGA {

class StructCodeGen : public Inspector {
 public:
  StructCodeGen(const FPGAProgram* program, CodeBuilder* builder) :
    program(program), builder(builder) {}
  bool preorder(const IR::Type_Header* header) override;
  bool preorder(const IR::Type_Struct* header) override;
  void emit();
 private:
  const FPGAProgram* program;
  CodeBuilder* builder;
  std::map<cstring, const IR::Type_Header*> header_map;
};

class HeaderCodeGen : public Inspector {
 public:
  HeaderCodeGen(const FPGAProgram* program, CodeBuilder* builder) :
    program(program), builder(builder) {}
  bool preorder(const IR::StructField* fld) override;
  bool preorder(const IR::Type_Header* hdr) override;
  bool preorder(const IR::Type_Stack* stk) override;
 private:
  const FPGAProgram* program;
  CodeBuilder* builder;
  std::vector<cstring> headers;
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FSTRUCT_H_ */
