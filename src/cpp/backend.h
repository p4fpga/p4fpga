
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_

#include "options.h"
#include "ir/ir.h"
#include "bsvprogram.h"
#include "frontends/p4/evaluator/evaluator.h"

namespace FPGA {

class Backend {
    std::vector<DebugHook> hooks;
 public:
    P4::ReferenceMap*     refMap;
    P4::TypeMap*          typeMap;

    void run(const FPGAOptions& options, const IR::ToplevelBlock* block,
             P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
    explicit Backend(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
        refMap(refMap), typeMap(typeMap) {}
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_BACKEND_H_ */
