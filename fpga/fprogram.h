
#ifndef _BACKENDS_FPGA_FPGAOBJECT_H_
#define _BACKENDS_FPGA_FPGAOBJECT_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "codeGen.h"

namespace FPGA {

class FPGAProgram;

// Base class for FPGA objects
class FPGAObject {
 public:
    virtual ~FPGAObject() {}
    virtual void emit(CodeBuilder* builder) = 0;
    template<typename T> bool is() const { return to<T>() != nullptr; }
    template<typename T> const T* to() const {
        return dynamic_cast<const T*>(this); }
    template<typename T> T* to() {
        return dynamic_cast<T*>(this); }
};

class FPGAProgram : public FPGAObject {
 public:
    const IR::P4Program* program;
    const IR::ToplevelBlock*  toplevel;
    P4::ReferenceMap*    refMap;
    const P4::TypeMap*   typeMap;

    // write program as C source code
    void emit(CodeBuilder *builder) override;
    bool build();  // return 'true' on success

    FPGAProgram(const IR::P4Program* program, P4::ReferenceMap* refMap,
                const P4::TypeMap* typeMap, const IR::ToplevelBlock* toplevel) :
            program(program), toplevel(toplevel),
            refMap(refMap), typeMap(typeMap) {
    }

 private:
    void emitIncludes(CodeBuilder* builder);
    void emitPreamble(CodeBuilder* builder);
    void emitTypes(CodeBuilder* builder);
    void emitTables(CodeBuilder* builder);
    void emitHeaderInstances(CodeBuilder* builder);
    void createLocalVariables(CodeBuilder* builder);
    void emitPipeline(CodeBuilder* builder);
    void emitLicense(CodeBuilder* builder);
};

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGAOBJECT_H_ */
