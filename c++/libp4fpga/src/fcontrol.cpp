
#include "fcontrol.h"

namespace FPGA {

bool FPGAControl::build() {
    LOG1("control build");
    for (auto c : controlBlock->constantValue) {
        auto b = c.second;
        if (!b->is<IR::Block>()) continue;
        if (b->is<IR::TableBlock>()) {
            auto tblblk = b->to<IR::TableBlock>();
            LOG1("tbl " << tblblk);
        } else if (b->is<IR::ExternBlock>()) {
            auto ctrblk = b->to<IR::ExternBlock>();
            LOG1("ctrl " << ctrblk);
        } else {
            ::error("Unexpected block %s nested within control", b->toString());
        }
    }
    return true;
}

void FPGAControl::emit(BSVProgram & bsv) {
    //
}

}  // namespace FPGA
