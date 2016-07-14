#include <stdio.h>
#include <string>
#include <iostream>

#include "ir/ir.h"
#include "lib/log.h"
#include "lib/crash.h"
#include "lib/exceptions.h"
#include "lib/gc.h"

int main(int argc, char *const argv[]) {
    setup_gc_logging();
    setup_signals();

    return ::errorCount() > 0;
}

