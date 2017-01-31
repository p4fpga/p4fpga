
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
#include "ftest.h"
#include "ftype.h"
#include "foptions.h"
#include "bsvprogram.h"

namespace FPGA {

void run_fpga_backend(const FPGAOptions& options, const IR::ToplevelBlock* toplevel,
                      P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
    CHECK_NULL(toplevel);
    CHECK_NULL(toplevel->getMain());

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

void generate_metadata_profile(const IR::P4Program* program) {
    // Graph graph;
    // fpgaprog.generateGraph(graph);

    // boost::filesystem::path graphFile("graph.dot");
    // boost::filesystem::path graphPath = dir / graphFile;

    // std::ofstream(graphPath.native()) << graph.getGraphBuilder().toString();
}

void generate_table_profile(const FPGAOptions& options, FPGA::Profiler* profgen) {
    boost::filesystem::path dir(options.outputFile);
    boost::filesystem::create_directory(dir);
    boost::filesystem::path profileFile("table.prof");
    boost::filesystem::path profilePath = dir / profileFile;
    std::ofstream(profilePath.native()) << profgen->getTableProfiler().toString();
}

void generate_partition(const FPGAOptions& options, const IR::P4Program* program, cstring idx) {
    Util::PathName pathname(options.file);
    auto filename = pathname.getBasename() + idx + cstring(".p4");
    boost::filesystem::path dir(options.outputFile);
    boost::filesystem::create_directory(dir);
    boost::filesystem::path p4File(filename);
    boost::filesystem::path p4Path = dir / p4File;
    auto stream = openFile(p4Path.c_str(), true);
    P4::ToP4 toP4(stream, false, nullptr);
    program->apply(toP4);
}

}  // namespace FPGA
