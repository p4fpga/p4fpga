/*
Copyright 2015-2016 P4FPGA Project

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTEST_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTEST_H_

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

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FTEST_H_ */
