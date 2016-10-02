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

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FPARSER_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FPARSER_H_

#include "ir/ir.h"
#include "program.h"
#include "ftype.h"
#include "bsvprogram.h"

namespace FPGA {

typedef std::map<const IR::ParserState*, IR::BSV::ParseStep*> ParseStepMap;

class FPGAParser : public FPGAObject {
 protected:
  // TODO(rjs): I think these should be const
  void emitEnums(BSVProgram & bsv);
  void emitStructs(BSVProgram & bsv);
  void emitFunctions(BSVProgram & bsv);
  void emitRules(BSVProgram & bsv);
  //void emitBufferRule(BSVProgram & bsv, const IR::BSV::ParseStep* state);
  void emitExtractionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state);
  void emitTransitionRule(BSVProgram & bsv, const IR::BSV::ParseStep* state);
  void emitAcceptRule(BSVProgram & bsv);
  void emitAcceptedHeaders(BSVProgram & bsv, const IR::Type_Struct* headers);
  void emitUserMetadata(BSVProgram & bsv, const IR::Type_Struct* metadata);
  void emitStateElements(BSVProgram & bsv);

  std::vector<IR::BSV::Rule*>         rules;

 public:
  FPGAProgram*            program;
  const P4::ReferenceMap*       refMap;
  const P4::TypeMap*            typeMap;
  const IR::ParserBlock*        parserBlock;
  const IR::Parameter*          packet;
  const IR::Parameter*          headers;
  const IR::Parameter*          userMetadata;
  const IR::Parameter*          stdMetadata;
  FPGAType*                     headerType;
  CodeBuilder*                  builder;

  // map from IR::ParserState to IR::BSV::ParseStep
  // the latter subclasses Type_Header, from which we
  // compute bit width of next parse state.
  ParseStepMap                  parseStateMap;
  std::vector<IR::BSV::ParseStep*> parseSteps;
  std::set<cstring>             pulse_wire_set;
  const IR::ParserState*        initState;

  explicit FPGAParser(FPGAProgram* program,
                      const IR::ParserBlock* block,
                      const P4::TypeMap* typeMap,
                      const P4::ReferenceMap* refMap);

  void emit(BSVProgram & bsv) override;
  bool build();
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FPARSER_H_ */
