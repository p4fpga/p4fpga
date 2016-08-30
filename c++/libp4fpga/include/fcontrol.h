
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_

#include "ir/ir.h"
#include "fprogram.h"

namespace FPGA {

class FPGAControl : public FPGAObject {
 public:
    const FPGAProgram*            program;
    const IR::ControlBlock*       controlBlock;
    const IR::Parameter*          headers;
    const IR::Parameter*          accept;

    std::set<const IR::Parameter*> toDereference;
//  std::map<cstring, FPGATable*>  tables;
//  // map for std::map<cstring, FPGADataflow*> dataflow;

    explicit FPGAControl(const FPGAProgram* program, const IR::ControlBlock* block)
      : program(program), controlBlock(block), headers(nullptr), accept(nullptr) {}

    virtual ~FPGAControl() {}
    void emit(BSVProgram & bsv);
    // void emitDeclaration(const IR::Declaration* decl, CodeBuilder *builder);
    // void emitTables(CodeBuilder* builder);
    bool build();
//    FPGATable* getTable(cstring name) const {
//        auto result = get(tables, name);
//        BUG_CHECK(result != nullptr, "No table named %1%", name);
//        return result; }
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_ */
