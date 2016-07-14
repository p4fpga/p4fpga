
#include "lib/error.h"
#include "lib/nullstream.h"
#include "frontends/p4/evaluator/evaluator.h"

#include "fbackend.h"
#include "fprogram.h"
//#include "target.h"
//#include "fpgaType.h"

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

/*
    FPGATypeFactory::createFactory(typeMap);

    Target* target;
    if (options.target.isNullOrEmpty() || options.target == "bcc") {
        target = new BccTarget();
    } else if (options.target == "kernel") {
        target = new KernelSamplesTarget();
    } else {
        ::error("Unknown target %s; legal choices are 'bcc' and 'kernel'", options.target);
        return;
    }
*/
    auto fpgaprog = new FPGAProgram(toplevel->getProgram(), refMap, typeMap, toplevel);
    if (!fpgaprog->build())
        return;
    if (options.outputFile.isNullOrEmpty())
        return;
    auto stream = openFile(options.outputFile, false);
    if (stream == nullptr)
        return;

//    CodeBuilder builder(target);
//    fpgaprog->emit(&builder);
//    *stream << builder.toString();
//    stream->flush();
}

}  // namespace FPGA
