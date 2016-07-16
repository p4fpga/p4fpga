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
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"

void compile(Options& options) {
    auto hook = options.getDebugHook();
    auto program = parseP4File(options);
    if (::errorCount() > 0)
        return;
    FrontEnd frontend;
    frontend.addDebugHook(hook);
    program = frontend.run(options, program);
    if (::errorCount() > 0)
        return;

    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    auto toplevel = midend.run(options, program);
    if (::errorCount() > 0)
        return;

    FPGA::run_fpga_backend(options, toplevel, &midend.refMap, &midend.typeMap);
}

int main(int argc, char *const argv[]) {
    setup_gc_logging();
    setup_signals();

    Options options;
    if (options.process(argc, argv) != nullptr)
        options.setInputFile();
    if (::errorCount() > 0)
        exit(1);

    compile(options);

    if (options.verbosity > 0)
        std::cerr << "Done." << std::endl;
    return ::errorCount() > 0;
}
