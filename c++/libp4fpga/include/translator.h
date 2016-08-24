#include "ir/ir.h"

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TRANSLATOR_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TRANSLATOR_H_
namespace FPGA {

class FPGAProgram;

class ExpressionTranslator : public Inspector {
 public:
    explicit ExpressionTranslator(FPGAProgram *program) {}
    FPGAProgram *program;

    void postorder(const IR::AssignmentStatement *e) override {
        LOG1("TEST " << e);
    }

    void postorder(const IR::PathExpression *e) override {
        LOG1("PATH");
    }

    void translate(const IR::Expression *e) {
        LOG1("translate " << e);
    }
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_TRANSLATOR_H_ */
