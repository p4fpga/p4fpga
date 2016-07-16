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

#include "fparser.h"
#include "codeGen.h"

namespace FPGA {

namespace {
class StateTranslationVisitor : public CodeGenInspector {
    bool hasDefault;
    P4::P4CoreLibrary& p4lib;
    const FPGAParserState* state;

//    void compileExtractField(const IR::Expression* expr, cstring name,
//                             unsigned alignment, FPGAType* type);
//    void compileExtract(const IR::Vector<IR::Expression>* args);

 public:
    StateTranslationVisitor(const FPGAParserState* state, CodeBuilder* builder) :
            CodeGenInspector(builder, state->parser->program->typeMap),
            hasDefault(false), p4lib(P4::P4CoreLibrary::instance), state(state) {}
//    using CodeGenInspector::preorder;
//    bool preorder(const IR::ParserState* state) override;
//    bool preorder(const IR::SelectCase* selectCase) override;
//    bool preorder(const IR::SelectExpression* expression) override;
//    bool preorder(const IR::Member* expression) override;
//    bool preorder(const IR::MethodCallExpression* expression) override;
//    bool preorder(const IR::MethodCallStatement* stat) override
//    { visit(stat->methodCall); return false; }
};
}  // namespace


//////////////////////////////////////////////////////////////////

void FPGAParserState::emit(CodeBuilder* builder) {
    //StateTranslationVisitor visitor(this, builder);
    //state->apply(visitor);
}

FPGAParser::FPGAParser(const FPGAProgram* program,
                       const IR::ParserBlock* block, const P4::TypeMap* typeMap) :
        program(program), typeMap(typeMap), parserBlock(block), packet(nullptr),
        headers(nullptr), headerType(nullptr) {}

void FPGAParser::emit(CodeBuilder *builder) {
    for (auto s : states)
        s->emit(builder);
}

bool FPGAParser::build() {
    auto pl = parserBlock->container->type->applyParams;
    if (pl->size() != 2) {
        ::error("Expected parser to have exactly 2 parameters");
        return false;
    }

    // TODO: more checks on these parameter types
    auto it = pl->parameters->begin();
    packet = *it; ++it;
    headers = *it;
    for (auto state : *parserBlock->container->states) {
        auto ps = new FPGAParserState(state, this);
        states.push_back(ps);
    }

    auto ht = typeMap->getType(headers);
    if (ht == nullptr)
        return false;
    headerType = FPGATypeFactory::instance->create(ht);
    LOG1("headerType" << headerType);
    return true;
}

} // namespace FPGA
