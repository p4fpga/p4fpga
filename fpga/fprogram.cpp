#include "fprogram.h"
#include "frontends/p4/coreLibrary.h"

namespace FPGA {
bool FPGAProgram::build() {
    auto pack = toplevel->getMain();
    LOG1("build " << dumpToString(pack));
    return true;
}

void FPGAProgram::emit(CodeBuilder *builder) {
    // emitIncludes
    // emitPreamble
    // ...
}

}  // namespace FPGA
