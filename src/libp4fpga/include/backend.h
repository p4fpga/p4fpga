
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_

#include "foptions.h"
#include "ir/ir.h"
#include "bsvprogram.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace FPGA {

void run_fpga_backend(const FPGAOptions& options, const IR::ToplevelBlock* toplevel,
                      P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

void generate_partition(const FPGAOptions& options, const IR::P4Program* program, cstring idx);
void generate_table_profile(const FPGAOptions& options, FPGA::Profiler* profile);
void generate_metadata_profile(const IR::P4Program* program);

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_ */
