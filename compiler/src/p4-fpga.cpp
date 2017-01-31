#include <stdio.h>
#include <string>
#include <iostream>

#include "ir/ir.h"
#include "lib/log.h"
#include "lib/crash.h"
#include "lib/exceptions.h"
#include "lib/gc.h"

#include "midend.h"
#include "foptions.h"
#include "backend.h"
#include "partition.h"
//#include "profile.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/simplify.h"

// generate bsv
void compile(FPGAOptions& options, const IR::P4Program* program) {
    auto hook = options.getDebugHook();

    P4::FrontEnd frontend;
    frontend.addDebugHook(hook);
    auto pf = frontend.run(options, program);
    if (::errorCount() > 0)
        exit(1);

    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    pf = midend.run(options, pf);
    if (::errorCount() > 0)
        exit(1);

    // TODO: why do we need an evaluator pass?
    auto evaluator = new P4::EvaluatorPass(&midend.refMap, &midend.typeMap);
    PassManager backend = {
      evaluator
    };
    pf->apply(backend);
    auto toplevel = evaluator->getToplevelBlock();

    FPGA::run_fpga_backend(options, toplevel, &midend.refMap, &midend.typeMap);
}

// partition p4 control flow
void partition(FPGAOptions& options, const IR::P4Program* program) {
    auto hook = options.getDebugHook();
    P4::FrontEnd frontend;
    frontend.addDebugHook(hook);
    auto pf = frontend.run(options, program);
    if (::errorCount() > 0)
        exit(1);

    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    pf = midend.run(options, pf);
    if (::errorCount() > 0)
        exit(1);

    // pass: collect table statistics
    // auto profgen = new FPGA::Profiler();
    // PassManager profile = {
    //   new P4::ResourceEstimation(&midend.refMap, &midend.typeMap, profgen),
    // };
    // profile.setName("Profile");
    // profile.addDebugHook(hook);
    // pf = pf->apply(profile);
    // FPGA::generate_table_profile(options, profgen);

    // pass: partition tables
    // int tbegin = 0;
    // int tend = 0;
    // for (auto np : options.partitions) {
    //   tend = std::stoi(np.c_str(), nullptr, 10);
    //   PassManager backend = {
    //     new P4::Partition(&midend.refMap, &midend.typeMap, tbegin, tend),
    //     new P4::SimplifyControlFlow(&midend.refMap, &midend.typeMap),
    //   };
    //   backend.setName("Partition");
    //   backend.addDebugHook(hook);
    //   auto p = pf->apply(backend);
    //   FPGA::generate_partition(options, p, np);
    //   tbegin = tend;
    // }
}

int main(int argc, char *const argv[]) {
    setup_gc_logging();
    setup_signals();

    FPGAOptions options;
    if (options.process(argc, argv) != nullptr)
        options.setInputFile();
    if (::errorCount() > 0)
        exit(1);

    // NOTE: reason that we do parseP4File here is because
    // parseP4File() cannot be called twice in current impl
    auto program = parseP4File(options);
    if (::errorCount() > 0)
        exit(1);

    compile(options, program);

    //partition(options, program);

    return ::errorCount() > 0;
}
