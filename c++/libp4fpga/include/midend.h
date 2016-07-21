
#ifndef _BACKENDS_FPGA_MIDEND_H_
#define _BACKENDS_FPGA_MIDEND_H_

#include "ir/ir.h"
#include "options.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"

namespace FPGA {

class MidEnd {
    std::vector<DebugHook> hooks;
 public:
    P4::ReferenceMap       refMap;
    P4::TypeMap            typeMap;

    void addDebugHook(DebugHook hook) { hooks.push_back(hook); }
    const IR::ToplevelBlock* run(Options& options, const IR::P4Program* program);
};

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_MIDEND_H_ */
