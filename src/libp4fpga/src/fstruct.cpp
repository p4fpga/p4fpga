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

#include "fstruct.h"
#include "fparser.h"
#include "fcontrol.h"
#include "ir/ir.h"
#include "string_utils.h"

namespace FPGA {

bool StructCodeGen::preorder(const IR::Type_Header* hdr) {
  cstring name = hdr->name.toString();
  cstring header_type = CamelCase(name);
  auto it = header_map.find(name);
  if (it != header_map.end()) {
    // already in map, skip
    return false;
  }
  header_map.emplace(name, hdr);
  // do code gen
  builder->append_line("import DefaultValue::*;");
  builder->append_line("typedef struct {");
  builder->incr_indent();
  auto header_width = 0;
  for (auto f : *hdr->fields) {
    if (f->type->is<IR::Type_Bits>()) {
      auto width = f->type->to<IR::Type_Bits>()->size;
      auto name = f->name;
      builder->append_format("Bit#(%d) %s;", width, name.toString());
      header_width += width;
    }
  }
  builder->decr_indent();
  builder->append_format("} %s deriving (Bits, Eq);", header_type);
  builder->append_format("function %s extract_%s(Bit#(%d) data);", header_type, name, header_width);
  builder->incr_indent();
  builder->append_line("return unpack(byteSwap(data));");
  builder->decr_indent();
  builder->append_line("endfunction");
  return false;
}

void StructCodeGen::emit() {
  CHECK_NULL(builder);

  builder->append_line("typedef struct {");
  builder->incr_indent();
  // metadata used in table
  for (auto p : program->ingress->metadata_to_table) {
    auto name = nameFromAnnotation(p.first->annotations, p.first->name);
    auto size = p.first->type->to<IR::Type_Bits>()->size;
    builder->append_line("Maybe#(Bit#(%d)) %s;", size, name);
  }
  for (auto p : program->egress->metadata_to_table) {
    auto name = nameFromAnnotation(p.first->annotations, p.first->name);
    auto size = p.first->type->to<IR::Type_Bits>()->size;
    builder->append_line("Maybe#(Bit#(%d)) %s;", size, name);
  }
  // metadata used in control flow
  // TODO:
  for (auto s : program->parser->parseSteps) {
    builder->append_format("HeaderState %s;", s->name.toString());
  }
  builder->decr_indent();
  builder->append_line("} MetadataT deriving (Bits, Eq, FShow);");
  builder->append_line("instance DefaultValue#(MetadataT);");
  builder->incr_indent();
  builder->append_line("defaultValue = unpack(0);");
  builder->decr_indent();
  builder->append_line("endinstance");
}

}  // namespace FPGA

