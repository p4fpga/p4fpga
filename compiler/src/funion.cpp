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

#include "funion.h"
#include "ir/ir.h"
#include "string_utils.h"

namespace FPGA {

bool UnionCodeGen::preorder(const IR::MethodCallExpression* expr) {
  cstring type = CamelCase(expr->method->toString());
  builder->append_line("struct {");
  builder->incr_indent();
  auto k = control->basicBlock.find(expr->method->toString());
  if (k != control->basicBlock.end()) {
    const IR::ParameterList* params = k->second->parameters;
    for (auto p : *params->parameters) {
      int size = p->type->width_bits();
      cstring name = p->name.toString();
      builder->append_line("Bit#(%d) %s;", size, name);
    }
  }
  builder->decr_indent();
  builder->append_line("} %sReqT;", type);
  return false;
}

bool UnionCodeGen::preorder(const IR::P4Table* table) {
  CHECK_NULL(table);
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);

  CHECK_NULL(builder);
  builder->append_line("typedef union tagged {");
  builder->incr_indent();
  UnionCodeGen visitor(control, builder);
  table->getActionList()->apply(visitor);
  builder->decr_indent();
  builder->append_line("} %sActionReq deriving (Bits, Eq, FShow);", type);
  return false;
}

void UnionCodeGen::emit() {
  builder->append_line("import Ethernet::*;");
  builder->append_line("import StructDefines::*;");
}

}  // namespace FPGA

