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
#include "fdeparser.h"

namespace FPGA {
bool FPGAProgram::build() {
  auto pack = toplevel->getMain();

  /*
   * We assume a v1model: parser -> ingress -> egress -> deparser.
   * As a result, FPGAParser, FPGAControl are created staticaly here.
   * A better solution should be reading arch.p4 first, then create
   * pipeline objects dynamically based on what's specified in arch.p4
   */
  auto pb = pack->getParameterValue(v1model.sw.parser.name)
                ->to<IR::ParserBlock>();
  BUG_CHECK(pb != nullptr, "No parser block found");
  parser = new FPGAParser(this, pb, typeMap, refMap);
  bool success = parser->build();
  if (!success)
      return success;

  auto cb = pack->getParameterValue(v1model.sw.ingress.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(cb != nullptr, "No control block found");
  // control block
  ingress = new FPGAControl(this, cb);
  success = ingress->build();
  if (!success)
      return success;

  auto eb = pack->getParameterValue(v1model.sw.egress.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(eb != nullptr, "No egress block found");
  egress = new FPGAControl(this, eb);
  success = egress->build();
  if (!success)
    return success;

  LOG1("deparser " << v1model.sw.deparser.name);
  auto db = pack->getParameterValue(v1model.sw.deparser.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(db != nullptr, "No deparser block found");
  deparser = new FPGADeparser(this, db);
  success = deparser->build();
  if (!success)
    return success;

  return true;
}

void FPGAProgram::emit(BSVProgram & bsv) {
  parser->emit(bsv);
  ingress->emit(bsv);
  egress->emit(bsv);
  deparser->emit(bsv);
  // TODO: emit main.bsv
}

void FPGAProgram::generateGraph(Graph & graph) {
  ingress->plot_v_table_e_meta(graph);
  egress->plot_v_table_e_meta(graph);
  ingress->plot_v_meta_e_table(graph);
  egress->plot_v_meta_e_table(graph);
}

}  // namespace FPGA
