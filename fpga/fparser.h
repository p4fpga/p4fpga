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

#ifndef _BACKENDS_FPGA_FPGAPARSER_H_
#define _BACKENDS_FPGA_FPGAPARSER_H_

#include "ir/ir.h"
#include "fprogram.h"
#include "ftype.h"

namespace FPGA {

class FPGAParserState : public FPGAObject {
 public:
    const IR::ParserState* state;
    const FPGAParser* parser;

    FPGAParserState(const IR::ParserState* state, FPGAParser* parser) :
            state(state), parser(parser) {}
    void emit(CodeBuilder* builder) override;
};

class FPGAParser : public FPGAObject {
 public:
    const FPGAProgram*            program;
    const P4::TypeMap*            typeMap;
    const IR::ParserBlock*        parserBlock;
    std::vector<FPGAParserState*> states;
    const IR::Parameter*          packet;
    const IR::Parameter*          headers;
    FPGAType*                     headerType;

    explicit FPGAParser(const FPGAProgram* program, const IR::ParserBlock* block,
                        const P4::TypeMap* typeMap);
    void emit(CodeBuilder* builder) override;
    bool build();
};

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGAPARSER_H_ */
