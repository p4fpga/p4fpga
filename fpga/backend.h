
#ifndef _BACKENDS_FPGA_FPGABACKEND_H_
#define _BACKENDS_FPGA_FPGABACKEND_H_

#include "options.h"
#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace FPGA {

void run_fpga_backend(const Options& options, const IR::ToplevelBlock* toplevel,
                      P4::ReferenceMap* refMap, const P4::TypeMap* typeMap);

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGABACKEND_H_ */
