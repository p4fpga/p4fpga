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
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/simplify.h"

int main(int argc, char *const argv[]) {
    setup_gc_logging();
    setup_signals();

    FPGAOptions options;

    if (options.process(argc, argv) != nullptr)
        options.setInputFile();
    if (::errorCount() > 0)
        return 1;

    auto hook = options.getDebugHook();

    auto program = P4::parseP4File(options);
    if (program == nullptr || ::errorCount() > 0)
        return 1;
    try {
        P4::FrontEnd frontend;
        frontend.addDebugHook(hook);
        program = frontend.run(options, program);
    } catch (const Util::P4CExceptionBase &bug) {
        std::cerr << bug.what() << std::endl;
        return 1;
    }
    if (program == nullptr || ::errorCount() > 0)
        return 1;


    const IR::ToplevelBlock* toplevel = nullptr;
    FPGA::MidEnd midend;
    midend.addDebugHook(hook);
    try {
        toplevel = midend.run(program, options);
        if (::errorCount() > 0)
            exit(1);
    } catch (const Util::P4CExceptionBase &bug) {
        std::cerr << bug.what() << std::endl;
        return 1;
    }
    if (program == nullptr || ::errorCount() > 0)
        return 1;

    FPGA::Backend backend(&midend.refMap, &midend.typeMap);
    try {
        backend.run(options, toplevel, &midend.refMap, &midend.typeMap);
    } catch (const Util::P4CExceptionBase &bug) {
        std::cerr << bug.what() << std::endl;
        return 1;
    }
    if (program == nullptr || ::errorCount() > 0)
        return 1;


    return ::errorCount() > 0;
}
