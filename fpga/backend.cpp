
#include "lib/error.h"
#include "lib/nullstream.h"
#include "frontends/p4/evaluator/evaluator.h"

#include "backend.h"
#include "fprogram.h"
#include "ftest.h"
#include "ftype.h"
//#include "codegen.h"

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

    auto test = new Test(toplevel->getProgram(), refMap, typeMap, toplevel);
    test->build();

    auto fpgaprog = new FPGAProgram(toplevel->getProgram(), refMap, typeMap, toplevel);
    if (!fpgaprog->build())
        return;
    if (options.outputFile.isNullOrEmpty())
        return;
    auto stream = openFile(options.outputFile, false);
    if (stream == nullptr)
        return;

    CodeBuilder builder;
    fpgaprog->emit(&builder);
    LOG1("emit fpgaprog");
    *stream << builder.toString();
    stream->flush();
}
}  // namespace FPGA
