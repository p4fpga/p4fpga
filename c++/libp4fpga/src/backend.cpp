
#include "lib/error.h"
#include "lib/nullstream.h"
#include "frontends/p4/evaluator/evaluator.h"

#include "backend.h"
#include "fprogram.h"
#include "ftest.h"
#include "ftype.h"
//#include "codegen.h"
#include "bsvprogram.h"

namespace FPGA {
void run_fpga_backend(const Options& options, const IR::ToplevelBlock* toplevel,
                      P4::ReferenceMap* refMap, const P4::TypeMap* typeMap) {
    if (toplevel == nullptr)
        return;

    auto main = toplevel->getMain();
    if (main == nullptr) {
        ::error("Could not locate top-level block; is there a %1% module?", IR::P4Program::main);
        return;
    }

    FPGATypeFactory::createFactory(typeMap);

    Test test(toplevel->getProgram(), refMap, typeMap, toplevel);
    test.build();

    FPGAProgram fpgaprog(toplevel->getProgram(), refMap, typeMap, toplevel);
    if (!fpgaprog.build())
        return;
    if (options.outputFile.isNullOrEmpty())
        return;
    auto stream = openFile(options.outputFile, false);
    if (stream == nullptr)
        return;

    // TODO(rjs): start here to change to program
    BSVProgram bsv;
    fpgaprog.emit(bsv);
    LOG1("emit fpgaprog");
    *stream << bsv.getParserBuilder().toString();
    stream->flush();
}
}  // namespace FPGA
