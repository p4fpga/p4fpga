
#ifndef _BACKENDS_FPGA_FPGAOPTIONS_H_
#define _BACKENDS_FPGA_FPGAOPTIONS_H_

#include <getopt.h>
#include "frontends/common/options.h"

class Options : public CompilerOptions {
 public:
    Options() {
        langVersion = CompilerOptions::FrontendVersion::P4_16;
    }
};

#endif /* _BACKENDS_FPGA_FPGAOPTIONS_H_ */
