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

#ifndef _BACKENDS_FPGA_FPGAPROGRAM_H_
#define _BACKENDS_FPGA_FPGAPROGRAM_H_

#include "ir/ir.h"
#include "frontends/p4/typeMap.h"
#include "frontends/p4/evaluator/evaluator.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "translator.h"
#include "bsvprogram.h"

namespace FPGA {

class FPGAProgram;
class FPGAParser;
class FPGAControl;
class FPGADeparser;

// // Base class for FPGA objects
class FPGAObject {
 public:
  virtual ~FPGAObject() {}
  virtual void emit(BSVProgram & bsv) {};
  virtual void emit(BSVProgram & bsv, CppProgram & cpp) {};
  template<typename T> bool is() const { return to<T>() != nullptr; }
  template<typename T> const T* to() const {
      return dynamic_cast<const T*>(this); }
  template<typename T> T* to() {
      return dynamic_cast<T*>(this); }
};

class FPGAProgram : public FPGAObject {
 public:
  const IR::ToplevelBlock*  toplevel;
  const IR::P4Program*      program;
  P4::ReferenceMap*         refMap;
  P4::TypeMap*              typeMap;
  // FIXME: dependency on v1model
  P4V1::V1Model&            v1model;
  FPGAParser*               parser;
  FPGAControl*              ingress;
  FPGAControl*              egress;
  FPGADeparser*             deparser;
  // TODO: flexible pipeline should have a map of these controlblocks
  std::map<cstring, const IR::Member*> metadata;

  // write program as bluespec source code
  void emit(BSVProgram & bsv, CppProgram & cpp); // override;
  bool build();  // return 'true' on success

  FPGAProgram(const IR::ToplevelBlock* toplevel,
              P4::ReferenceMap* refMap, P4::TypeMap* typeMap) :
      toplevel(toplevel),
      refMap(refMap), typeMap(typeMap),
      v1model(P4V1::V1Model::instance){
    program = toplevel->getProgram();
  }

 private:
  void emitIncludes(CodeBuilder* builder);
  void emitImportStatements(BSVProgram& bsv);
  void emitIncludeStatements(BSVProgram& bsv);
  void emitTypes(CodeBuilder* builder);
  void emitTables(CodeBuilder* builder);
  void emitHeaderInstances(CodeBuilder* builder);
  void emitPipeline(CodeBuilder* builder);
  void emitHeaders(CodeBuilder* builder);
  void emitMetadata(CodeBuilder* builder);
  void emitBuiltinMetadata(CodeBuilder* builder);
  void emitLicense(CodeBuilder* builder);
};

}  // namespace FPGA

#endif /* _BACKENDS_FPGA_FPGAPROGRAM_H_ */
