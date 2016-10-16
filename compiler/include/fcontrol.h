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
#include "program.h"
#include "analyzer.h"
#include "action.h"

namespace FPGA {

class FPGAParser;

class FPGAControl { // : public FPGAObject {
 public:
    const P4::ReferenceMap*       refMap;
    const P4::TypeMap*            typeMap;
    const IR::ControlBlock*       controlBlock;
    FPGAProgram*                  program;
    FPGA::CFG*                    cfg;
    CodeBuilder*                  builder;
    CodeBuilder*                  cpp_builder;
    CodeBuilder*                  type_builder;
    CodeBuilder*                  api_def;
    CodeBuilder*                  api_decl;
    CodeBuilder*                  prog_decl;

    // map from action name to P4Action
    std::map<cstring, const IR::P4Action*>    actions;
    // map from table name to TableBlock
    std::map<cstring, const IR::P4Table*>     tables;
    // map from extern name to ExternBlock
    std::map<cstring, const IR::ExternBlock*> externs;

    std::map<const IR::StructField*, std::set<const IR::P4Table*>> metadata_to_table;
    std::map<const IR::StructField*, cstring> metadata_to_action;
    std::map<cstring, const IR::P4Table*> action_to_table;

    explicit FPGAControl(FPGAProgram* program,
                         const IR::ControlBlock* block,
                         const P4::TypeMap* typeMap,
                         const P4::ReferenceMap* refMap)
      : program(program), controlBlock(block), typeMap(typeMap), refMap(refMap) {}

    virtual ~FPGAControl() {}
    cstring toP4Action (cstring inst);
    void emit(BSVProgram & bsv, CppProgram & cpp);
    void emitTableRule(BSVProgram & bsv, const CFG::TableNode* node);
    void emitCondRule(BSVProgram & bsv, const CFG::IfNode* node);
    void emitEntryRule(BSVProgram & bsv, const CFG::Node* node);
    void emitDeclaration(BSVProgram & bsv);
    void emitConnection(BSVProgram & bsv);
    void emitFifo(BSVProgram & bsv);
    void emitTables();
    void emitActions(BSVProgram & bsv);
    void emitActionTypes(BSVProgram & bsv);
    void emitAPI(BSVProgram & bsv, cstring cbtype);
    bool build();
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_ */
