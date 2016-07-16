#ifndef _BACKENDS_FPGA_FPGATEST_H_
#define _BACKENDS_FPGA_FPGATEST_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"

namespace FPGA {

class Test {
 public:
    const IR::P4Program*      program;
    const IR::ToplevelBlock*  toplevel;
    P4::ReferenceMap*         refMap;
    const P4::TypeMap*        typeMap;
    P4V1::V1Model&            v1model;

    Test(const IR::P4Program* program, P4::ReferenceMap* refMap,
         const P4::TypeMap* typeMap, const IR::ToplevelBlock* toplevel) :
            program(program), toplevel(toplevel),
            refMap(refMap), typeMap(typeMap),
            v1model(P4V1::V1Model::instance) {}
    void build();

 private:
    void ir_toplevel();
    void ir_metadata();
    void ir_parser_state();

};

} // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGATEST_H_ */
