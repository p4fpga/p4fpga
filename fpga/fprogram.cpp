#include "fprogram.h"
#include "frontends/p4/coreLibrary.h"

namespace FPGA {
bool FPGAProgram::build() {
    auto package = toplevel->getMain();

    auto parserBlock = package->getParameterValue(v1model.sw.parser.name);
    auto parser  = parserBlock->to<IR::ParserBlock>()->container;

    // header
    auto hdr = parser->type->applyParams->getParameter(v1model.parser.headersParam.index);
    auto headersType = typeMap->getType(hdr->getNode(), true);
    auto ht = headersType->to<IR::Type_Struct>();
    for (auto f: *ht->fields) {

    }

    // metadata

    // parser_state

    // parser = new FPGAParser();
    // bool success = parser->build();
    // if (!success)
    //   return success;

    // control block

    return true;
}

void FPGAProgram::emit(CodeBuilder *builder) {
    // emitIncludes
    // emitPreamble
    // ...
}

}  // namespace FPGA
