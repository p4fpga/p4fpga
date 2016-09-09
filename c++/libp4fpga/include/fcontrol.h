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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_

#include "ir/ir.h"
#include "fprogram.h"
#include "analyzer.h"

namespace FPGA {

namespace Control {
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
  bsv.getControlBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  bsv.getControlBuilder().appendFormat(s.c_str());
  bsv.getControlBuilder().newline();
}

template <typename... TArgs>
  void append_line(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
    bsv.getControlBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    bsv.getControlBuilder().appendLine(s.c_str());
  }

inline void incr_indent(BSVProgram & bsv) {
  bsv.getControlBuilder().increaseIndent();
}

inline void decr_indent(BSVProgram & bsv) {
  bsv.getControlBuilder().decreaseIndent();
}

}  // namespace Control

class FPGAControl : public FPGAObject {
 public:
    const FPGAProgram*            program;
    const IR::ControlBlock*       controlBlock;
    FPGA::CFG*                    cfg;

    // map from action name to P4Action
    std::map<cstring, const IR::P4Action*>    basicBlock;
    // map from table name to TableBlock
    std::map<cstring, const IR::P4Table*>  tables;
    // map from extern name to ExternBlock
    std::map<cstring, const IR::ExternBlock*> externs;

    std::map<const IR::StructField*, std::set<const IR::P4Table*>> metadata_to_table;
    std::map<const IR::StructField*, cstring> metadata_to_action;
    std::map<cstring, const IR::P4Table*> action_to_table;
    std::map<const IR::P4Table*, std::set<std::pair<const IR::StructField*, const IR::P4Table*> > > adj_list;

    explicit FPGAControl(const FPGAProgram* program, const IR::ControlBlock* block)
      : program(program), controlBlock(block) {}

    virtual ~FPGAControl() {}
    void emit(BSVProgram & bsv);
    void emitTableRule(BSVProgram & bsv, const CFG::TableNode* node);
    void emitCondRule(BSVProgram & bsv, const CFG::IfNode* node);
    void emitEntryRule(BSVProgram & bsv, const CFG::Node* node);
    void emitExitRule(BSVProgram & bsv, const CFG::Node* node);
    void emitDeclaration(BSVProgram & bsv);
    void emitConnection(BSVProgram & bsv);
    void emitDebugPrint(BSVProgram & bsv);
    void emitFifo(BSVProgram & bsv);
    void emitTables(BSVProgram & bsv);
    void emitActions(BSVProgram & bsv);
    bool build();
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_ */
