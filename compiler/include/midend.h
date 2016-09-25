
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_MIDEND_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_MIDEND_H_

#include "ir/ir.h"
#include "foptions.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

namespace FPGA {

class MidEnd {
    std::vector<DebugHook> hooks;
 public:
    P4::ReferenceMap       refMap;
    P4::TypeMap            typeMap;

    void addDebugHook(DebugHook hook) { hooks.push_back(hook); }
    const IR::P4Program* run(const FPGAOptions& options, const IR::P4Program* program);
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_MIDEND_H_ */
