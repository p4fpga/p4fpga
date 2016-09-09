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
#include "ir/ir.h"
#include "string_utils.h"

namespace FPGA {

using namespace Struct;

bool StructCodeGen::preorder(const IR::Type_Header* type) {
  append_line(bsv, "import DefaultValue::*;");
  auto hdr = type->to<IR::Type_Header>();
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  auto header_width = 0;
  for (auto f : *hdr->fields) {
    if (f->type->is<IR::Type_Bits>()) {
      auto width = f->type->to<IR::Type_Bits>()->size;
      auto name = f->name;
      append_format(bsv, "Bit#(%d) %s;", width, name.toString());
      header_width += width;
    }
  }
  decr_indent(bsv);
  auto name = hdr->name.toString();
  auto header_type = CamelCase(name);
  append_format(bsv, "} %s deriving (Bits, Eq);", header_type);
  append_format(bsv, "function %s extract_%s(Bit#(%d) data);", header_type, name, header_width);
  incr_indent(bsv);
  append_line(bsv, "return unpack(byteSwap(data));");
  decr_indent(bsv);
  append_line(bsv, "endfunction");
  return false;
}

// TODO need to generate MetadataT

// bool StructCodeGen::preorder(const IR::TableBlock* table) {
//
// }
// collect all metadata used by table..
// collect all header and assign HeaderState

}  // namespace FPGA
