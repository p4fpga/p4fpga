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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FUNION_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FUNION_H_

#include "ir/ir.h"
#include "fcontrol.h"
#include "bsvprogram.h"
#include "string_utils.h"

namespace FPGA {

namespace Union {
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
  bsv.getUnionBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  bsv.getUnionBuilder().appendFormat(s.c_str());
  bsv.getUnionBuilder().newline();
}

template <typename... TArgs>
  void append_line(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
    bsv.getUnionBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    bsv.getUnionBuilder().appendLine(s.c_str());
  }

inline void incr_indent(BSVProgram & bsv) {
  bsv.getUnionBuilder().increaseIndent();
}

inline void decr_indent(BSVProgram & bsv) {
  bsv.getUnionBuilder().decreaseIndent();
}

}  // namespace Union

class UnionCodeGen : public Inspector {
 public:
  UnionCodeGen(FPGAControl* control, BSVProgram& bsv):
    control(control), bsv(bsv) {}
  bool preorder(const IR::P4Table* table) override;
 private:
  FPGAControl* control;
  BSVProgram & bsv;
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FUNION_H_ */
