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

#include "frontends/p4/coreLibrary.h"
#include "fprogram.h"
#include "fparser.h"
#include "fcontrol.h"

namespace FPGA {
bool FPGAProgram::build() {
  auto pack = toplevel->getMain();

  auto pb = pack->getParameterValue(v1model.sw.parser.name)
              ->to<IR::ParserBlock>();
  BUG_CHECK(pb != nullptr, "No parser block found");

  /*
   * We assume a v1model: parser -> ingress -> egress -> deparser.
   * As a result, FPGAParser, FPGAControl are created staticaly here.
   * A better solution should be reading arch.p4 first, then create
   * pipeline objects dynamically based on what's specified in arch.p4
   */
  parser = new FPGAParser(this, pb, typeMap);
  bool success = parser->build();
  if (!success)
      return success;

  auto cb = pack->getParameterValue(v1model.sw.ingress.name)
                    ->to<IR::ControlBlock>();
  BUG_CHECK(cb != nullptr, "No control block found");
  // control block
  control = new FPGAControl(this, cb);
  success = control->build();
  if (!success)
      return success;

  return true;
}

void FPGAProgram::emit(BSVProgram & bsv) {
  // target->parser->emit(builder);
  parser->emit(bsv);
  // emitIncludes
  // emitPreamble
}

}  // namespace FPGA
