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
#include "fprogram.h"

namespace FPGA {

namespace Deparser {

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
  bsv.getDeparserBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  bsv.getDeparserBuilder().appendFormat(s.c_str());
  bsv.getDeparserBuilder().newline();
}

template <typename... TArgs>
  void append_line(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
    bsv.getDeparserBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    bsv.getDeparserBuilder().appendLine(s.c_str());
  }

inline void incr_indent(BSVProgram & bsv) {
  bsv.getDeparserBuilder().increaseIndent();
}

inline void decr_indent(BSVProgram & bsv) {
  bsv.getDeparserBuilder().decreaseIndent();
}

}  // namespace Deparser

class FPGADeparser : public FPGAObject {
 public:
  const FPGAProgram* program;
  const IR::ControlBlock* controlBlock;
  std::vector<IR::BSV::DeparseState*> states;

  void emitEnums(BSVProgram & bsv);
  void emitRules(BSVProgram & bsv);
  void emitStates(BSVProgram & bsv);

  explicit FPGADeparser(const FPGAProgram* program, const IR::ControlBlock* block)
    : program(program), controlBlock(block) {};
  void emit(BSVProgram &bsv ) override;
  bool build();
};

}  // namespace FPGA

#endif
