#include <stdio.h>
#include <string>
#include <iostream>

#include "ir/ir.h"
#include "lib/log.h"
#include "lib/crash.h"
#include "lib/exceptions.h"
#include "lib/gc.h"

#include "midend.h"
#include "options.h"
#include "backend.h"
#include "partition.h"
#include "resource.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/evaluator/evaluator.h"

// generate bsv
void compile(Options& options) {
    auto hook = options.getDebugHook();
    auto program = parseP4File(options);
    if (::errorCount() > 0)
        return;
    P4::FrontEnd frontend;
    frontend.addDebugHook(hook);
    program = frontend.run(options, program);
    if (::errorCount() > 0)
        return;

    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    program = midend.run(options, program);
    if (::errorCount() > 0)
        return;

    auto evaluator = new P4::EvaluatorPass(&midend.refMap, &midend.typeMap);
    PassManager backend = {
      evaluator
    };
    program->apply(backend);
    auto toplevel = evaluator->getToplevelBlock();

    FPGA::run_fpga_backend(options, toplevel, &midend.refMap, &midend.typeMap);
}

// partition p4 control flow
void partition(Options& options) {
    auto hook = options.getDebugHook();
    auto program = parseP4File(options);
    if (::errorCount() > 0)
        return;
    P4::FrontEnd frontend;
    frontend.addDebugHook(hook);
    program = frontend.run(options, program);
    if (::errorCount() > 0)
        return;

    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    program = midend.run(options, program);
    if (::errorCount() > 0)
        return;

    // list of tables to split
    // map : table -> resources
    //
    auto evaluator = new P4::EvaluatorPass(&midend.refMap, &midend.typeMap);
    PassManager backend = {
      new P4::ResourceEstimation(&midend.refMap, &midend.typeMap),
      new P4::Partition(&midend.refMap, &midend.typeMap),
      evaluator
    };
    backend.setName("Backend");
    backend.addDebugHook(hook);
    program = program->apply(backend);

    FPGA::run_partition_backend(options, program);
}

int main(int argc, char *const argv[]) {
    setup_gc_logging();
    setup_signals();

    Options options;
    if (options.process(argc, argv) != nullptr)
        options.setInputFile();
    if (::errorCount() > 0)
        exit(1);

    // compile(options);

    partition(options);

    if (options.verbosity > 0)
        std::cerr << "Done." << std::endl;
    return ::errorCount() > 0;
}
