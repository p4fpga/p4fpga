
#include "backend.h"
#include <boost/filesystem.hpp>
#include <fstream>

#include "ir/ir.h"
#include "lib/error.h"
#include "lib/nullstream.h"
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
      { error("FPGAprog build failed"); return; }

    if (options.outputFile.isNullOrEmpty())
      { error("Must specify output directory"); return; }

    std::filesystem::path dir(options.outputFile.string());
    std::filesystem::create_directory(dir);

    // TODO(rjs): start here to change to program
    BSVProgram bsv;
    CppProgram cpp;
    fpgaprog.emit(bsv, cpp);

    std::filesystem::path parserFile("ParserGenerated.bsv");
    std::filesystem::path parserPath = dir / parserFile;

    std::filesystem::path structFile("StructGenerated.bsv");
    std::filesystem::path structPath = dir / structFile;

    std::filesystem::path deparserFile("DeparserGenerated.bsv");
    std::filesystem::path deparserPath = dir / deparserFile;

    std::filesystem::path controlFile("ControlGenerated.bsv");
    std::filesystem::path controlPath = dir / controlFile;

    std::filesystem::path unionFile("UnionGenerated.bsv");
    std::filesystem::path unionPath = dir / unionFile;

    std::filesystem::path apiDefFile("APIDefGenerated.bsv");
    std::filesystem::path apiDefPath = dir / apiDefFile;

    std::filesystem::path apiDeclFile("APIDeclGenerated.bsv");
    std::filesystem::path apiDeclPath = dir / apiDeclFile;

    std::filesystem::path progDeclFile("ProgDeclGenerated.bsv");
    std::filesystem::path progDeclPath = dir / progDeclFile;

    std::filesystem::path apiTypeDefFile("ConnectalTypes.bsv");
    std::filesystem::path apiTypeDefPath = dir / apiTypeDefFile;

    std::filesystem::path simFile("matchtable_model.cpp");
    std::filesystem::path simPath = dir / simFile;

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
