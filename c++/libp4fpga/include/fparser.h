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
#include "fprogram.h"
#include "ftype.h"
#include "bsvprogram.h"

namespace FPGA {

namespace Parser {
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
  bsv.getParserBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  bsv.getParserBuilder().appendFormat(s.c_str());
  bsv.getParserBuilder().newline();
}

template <typename... TArgs>
  void append_line(BSVProgram & bsv, const char* fmt, TArgs&&... args) {
    bsv.getParserBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    bsv.getParserBuilder().appendLine(s.c_str());
  }

inline void incr_indent(BSVProgram & bsv) {
  bsv.getParserBuilder().increaseIndent();
}

inline void decr_indent(BSVProgram & bsv) {
  bsv.getParserBuilder().decreaseIndent();
}

}  // namespace Parser

typedef std::map<const IR::ParserState*, IR::BSV::ParseState*> ParseStateMap;

class FPGAParserState : public FPGAObject {
 public:
  const IR::ParserState* state;
  const FPGAParser* parser;

  FPGAParserState(FPGAParser* parser, const IR::ParserState* state) :
    parser(parser), state(state) {}
  void emit(BSVProgram & bsv) override;
};

class FPGAParser : public FPGAObject {
 protected:
  // TODO(rjs): I think these should be const
  void emitEnums(BSVProgram & bsv);
  void emitStructs(BSVProgram & bsv);
  void emitFunctions(BSVProgram & bsv);
  void emitRules(BSVProgram & bsv);
  void emitBufferRule(BSVProgram & bsv, const IR::BSV::ParseState* state);
  void emitExtractionRule(BSVProgram & bsv, const IR::BSV::ParseState* state);
  void emitTransitionRule(BSVProgram & bsv, const IR::BSV::ParseState* state);
  void emitAcceptRule(BSVProgram & bsv);
  void emitAcceptedHeaders(BSVProgram & bsv, const IR::Type_Struct* headers);
  void emitUserMetadata(BSVProgram & bsv, const IR::Type_Struct* metadata);
  void emitStateElements(BSVProgram & bsv);

  std::vector<IR::BSV::Rule*>         rules;

 public:
  const FPGAProgram*            program;
  const P4::ReferenceMap*       refMap;
  const P4::TypeMap*            typeMap;
  const IR::ParserBlock*        parserBlock;
  std::vector<IR::BSV::ParseState*> states;
  const IR::Parameter*          packet;
  const IR::Parameter*          headers;
  const IR::Parameter*          userMetadata;
  const IR::Parameter*          stdMetadata;
  FPGAType*                     headerType;
  ParseStateMap                 parseStateMap;

  explicit FPGAParser(const FPGAProgram* program,
                      const IR::ParserBlock* block,
                      const P4::TypeMap* typeMap,
                      const P4::ReferenceMap* refMap);

  void emit(BSVProgram & bsv) override;
  bool build();
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FPARSER_H_ */
