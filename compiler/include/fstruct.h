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

namespace Struct {
inline static std::string format_string(boost::format& message) {
  return message.str();
}

template <typename TValue, typename... TArgs>
  std::string format_string(boost::format& message, TValue&& arg, TArgs&&... args) {
  message % std::forward<TValue>(arg);
  return format_string(message, std::forward<TArgs>(args)...);
}

template <typename... TArgs>
  void append_format(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
  bsv.getStructBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  bsv.getStructBuilder().appendFormat(s.c_str());
  bsv.getStructBuilder().newline();
}

template <typename... TArgs>
  void append_line(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
    bsv.getStructBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    bsv.getStructBuilder().appendLine(s.c_str());
  }

inline void incr_indent(BSVProgram & bsv) {
  bsv.getStructBuilder().increaseIndent();
}

inline void decr_indent(BSVProgram & bsv) {
  bsv.getStructBuilder().decreaseIndent();
}

}  // namespace Struct

class StructCodeGen : public Inspector {
 public:
  StructCodeGen(const FPGAProgram* program, BSVProgram& bsv) :
    bsv(bsv), program(program) {}
  bool preorder(const IR::Type_Header* header) override;
  void emit();
 private:
  BSVProgram & bsv;
  const FPGAProgram* program;
  std::map<cstring, const IR::Type_Header*> header_map;
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FSTRUCT_H_ */
