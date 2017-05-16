
#include "backend.h"
#include <boost/filesystem.hpp>
#include <fstream>

#include "ir/ir.h"
#include "lib/error.h"
#include "lib/nullstream.h"
#include "lib/path.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/toP4/toP4.h"
#include "program.h"
#include "type.h"
#include "options.h"
#include "bsvprogram.h"

namespace FPGA {

// backend is also a pass manager


void
Backend::run(const FPGAOptions& options, const IR::ToplevelBlock* toplevel,
             P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    // If you ever need to create FPGAType from P4Type
    FPGATypeFactory::createFactory(typeMap);

    // create Main.bsv
    // Runtime runtime();

    // create Program.bsv
    FPGAProgram fpgaprog(toplevel, refMap, typeMap);
    if (!fpgaprog.build())
      { ::error("FPGAprog build failed"); return; }

    if (options.outputFile.isNullOrEmpty())
      { ::error("Must specify output directory"); return; }

    boost::filesystem::path dir(options.outputFile);
    boost::filesystem::create_directory(dir);

    // TODO(rjs): start here to change to program
    BSVProgram bsv;
    CppProgram cpp;
    fpgaprog.emit(bsv, cpp);

    boost::filesystem::path parserFile("ParserGenerated.bsv");
    boost::filesystem::path parserPath = dir / parserFile;

    boost::filesystem::path structFile("StructGenerated.bsv");
    boost::filesystem::path structPath = dir / structFile;

    boost::filesystem::path deparserFile("DeparserGenerated.bsv");
    boost::filesystem::path deparserPath = dir / deparserFile;

    boost::filesystem::path controlFile("ControlGenerated.bsv");
    boost::filesystem::path controlPath = dir / controlFile;

    boost::filesystem::path unionFile("UnionGenerated.bsv");
    boost::filesystem::path unionPath = dir / unionFile;

    boost::filesystem::path apiDefFile("APIDefGenerated.bsv");
    boost::filesystem::path apiDefPath = dir / apiDefFile;

    boost::filesystem::path apiDeclFile("APIDeclGenerated.bsv");
    boost::filesystem::path apiDeclPath = dir / apiDeclFile;

    boost::filesystem::path progDeclFile("ProgDeclGenerated.bsv");
    boost::filesystem::path progDeclPath = dir / progDeclFile;

    boost::filesystem::path apiTypeDefFile("ConnectalTypes.bsv");
    boost::filesystem::path apiTypeDefPath = dir / apiTypeDefFile;

    boost::filesystem::path simFile("matchtable_model.cpp");
    boost::filesystem::path simPath = dir / simFile;

    std::ofstream(parserPath.native())   <<  bsv.getParserBuilder().toString();
    std::ofstream(deparserPath.native()) <<  bsv.getDeparserBuilder().toString();
    std::ofstream(structPath.native())   <<  bsv.getStructBuilder().toString();
    std::ofstream(controlPath.native())  <<  bsv.getControlBuilder().toString();
    std::ofstream(unionPath.native())    <<  bsv.getUnionBuilder().toString();
    std::ofstream(apiDefPath.native())  <<  bsv.getAPIDefBuilder().toString();
    std::ofstream(apiDeclPath.native())   <<  bsv.getAPIDeclBuilder().toString();
    std::ofstream(progDeclPath.native())   <<  bsv.getProgDeclBuilder().toString();
    std::ofstream(apiTypeDefPath.native()) << bsv.getConnectalTypeBuilder().toString();

    std::ofstream(simFile.native())      <<  cpp.getSimBuilder().toString();
}

}  // namespace FPGA
