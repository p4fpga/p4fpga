
#include "lib/error.h"
#include "lib/nullstream.h"
#include "frontends/p4/evaluator/evaluator.h"

#include "backend.h"
#include "fprogram.h"
#include "ftest.h"
#include "ftype.h"
#include "bsvprogram.h"

#include <boost/filesystem.hpp>

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

    boost::filesystem::path dir(options.outputFile);
    boost::filesystem::create_directory(dir);
      
    // TODO(rjs): start here to change to program
    BSVProgram bsv;
    fpgaprog.emit(bsv);
    LOG1("emit fpgaprog");

    boost::filesystem::path parserFile ("ParserGenerated.bsv");
    boost::filesystem::path parserPath = dir / parserFile;

    boost::filesystem::path structFile ("StructGenerated.bsv");
    boost::filesystem::path structPath = dir / structFile;
    
    std::ofstream(parserPath.native()) <<  bsv.getParserBuilder().toString();
    std::ofstream(structPath.native()) <<  bsv.getStructBuilder().toString();
    
}
}  // namespace FPGA
