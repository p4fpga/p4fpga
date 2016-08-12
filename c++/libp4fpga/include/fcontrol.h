
#ifndef _BACKENDS_FPGA_FPGACONTROL_H_
#define _BACKENDS_FPGA_FPGACONTROL_H_

#include "ir/ir.h"
#include "fprogram.h"
//#include "ftable.h"

namespace FPGA {

class FPGAControl : public FPGAObject {
 public:
    const FPGAProgram*            program;
    const IR::ControlBlock*       controlBlock;
    const IR::Parameter*          headers;
    const IR::Parameter*          accept;

    std::set<const IR::Parameter*> toDereference;
//    std::map<cstring, FPGATable*>  tables;

    explicit FPGAControl(const FPGAProgram* program, const IR::ControlBlock* block)
      : program(program), controlBlock(block), headers(nullptr), accept(nullptr) {}

    virtual ~FPGAControl() {}
    void emit(BSVProgram & bsv);
    //void emitDeclaration(const IR::Declaration* decl, CodeBuilder *builder);
    //void emitTables(CodeBuilder* builder);
    bool build();
//    FPGATable* getTable(cstring name) const {
//        auto result = get(tables, name);
//        BUG_CHECK(result != nullptr, "No table named %1%", name);
//        return result; }
};

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGACONTROL_H_ */
