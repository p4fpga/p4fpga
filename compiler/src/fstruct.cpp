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
  builder->append_line("typedef struct {");
  builder->incr_indent();
  int header_width = 0;
  for (auto f : *hdr->fields) {
    if (f->type->is<IR::Type_Bits>()) {
      int size = f->type->to<IR::Type_Bits>()->size;
      cstring name = f->name.toString();
      if (size > 64) {
        int vec_size = size / 64;
        builder->append_line("Vector#(%d, Bit#(64)) %s;", vec_size, name);
        int remainder = size % 64; //FIXME:
        if (remainder != 0) {
          builder->append_line("Bit#(%d) %s_;", remainder, name);
        }
      } else {
        builder->append_line("Bit#(%d) %s;", size, name);
      }
      header_width += size;
    }
  }
  builder->decr_indent();
  builder->append_format("} %s deriving (Bits, Eq, FShow);", header_type);
  builder->append_format("function %s extract_%s(Bit#(%d) data);", header_type, name, header_width);
  builder->incr_indent();
  builder->append_line("return unpack(byteSwap(data));");
  builder->decr_indent();
  builder->append_line("endfunction");
  return false;
}

bool StructCodeGen::preorder(const IR::Type_Struct* hdr) {
  cstring name = hdr->name.toString();
  cstring header_type = CamelCase(name);
  builder->append_line("typedef struct {");
  builder->incr_indent();
  int header_width = 0;
  for (auto f : *hdr->fields) {
    if (f->type->is<IR::Type_Bits>()) {
      int size = f->type->to<IR::Type_Bits>()->size;
      cstring name = f->name.toString();
      builder->append_line("Bit#(%d) %s;", size, name);
      header_width += size;
    }
  }
  builder->decr_indent();
  builder->append_format("} %s deriving (Bits, Eq, FShow);", header_type);
  builder->append_line("instance DefaultValue#(%s);", header_type);
  builder->incr_indent();
  builder->append_line("defaultValue = unpack(0);");
  builder->decr_indent();
  builder->append_line("endinstance");
  return false;
}

bool HeaderCodeGen::preorder(const IR::StructField* field) {
  cstring header_type = CamelCase(field->type->getP4Type()->toString());
  cstring header_name = field->getName().toString();
  if (field->type->is<IR::Type_Header>()) {
    visit(field->type);;
    builder->append_line("Maybe#(Header#(%s)) %s;", header_type, header_name);
  } else if (field->type->is<IR::Type_Stack>()) {
    visit(field->type);
    builder->appendFormat(" %s;", header_name);
    builder->newline();
  } else {}
  return false;
}

bool HeaderCodeGen::preorder(const IR::Type_Header* hdr) {
  return false;
}

bool HeaderCodeGen::preorder(const IR::Type_Stack* stk) {
  builder->emitIndent();
  LOG1("xxxx" << stk->elementType->getP4Type());
  builder->appendFormat("Vector#(%d, Maybe#(Header#(%s)))", stk->getSize(), CamelCase(stk->elementType->getP4Type()->toString()));
  return false;
}

}  // namespace FPGA

