
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_

#include "options.h"
#include "ir/ir.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace FPGA {

void run_fpga_backend(const Options& options, const IR::ToplevelBlock* toplevel,
                      P4::ReferenceMap* refMap, const P4::TypeMap* typeMap);

void run_partition_backend(const Options& options, const IR::P4Program* program);
}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_ */
