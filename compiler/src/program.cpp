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
#include "fstruct.h"
#include "program.h"
#include "fparser.h"
#include "fcontrol.h"
#include "fdeparser.h"

namespace FPGA {
bool FPGAProgram::build() {
  auto pack = toplevel->getMain();
  bool success = false;
  /*
   * We assume a v1model: parser -> ingress -> egress -> deparser.
   * As a result, FPGAParser, FPGAControl are created staticaly here.
   * A better solution should be reading arch.p4 first, then create
   * pipeline objects dynamically based on what's specified in arch.p4
   */
  LOG1("Building Parser");
  auto pb = pack->getParameterValue(v1model.sw.parser.name)
                ->to<IR::ParserBlock>();
  BUG_CHECK(pb != nullptr, "No parser block found");
  CHECK_NULL(typeMap);
  parser = new FPGAParser(this, pb, typeMap, refMap);
  success = parser->build();
  if (!success)
      return success;

  LOG1("Building Ingress");
  auto cb = pack->getParameterValue(v1model.sw.ingress.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(cb != nullptr, "No control block found");
  // control block
  ingress = new FPGAControl(this, cb, typeMap, refMap);
  success = ingress->build();
  if (!success)
      return success;

  LOG1("Building Egress");
  auto eb = pack->getParameterValue(v1model.sw.egress.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(eb != nullptr, "No egress block found");
  egress = new FPGAControl(this, eb, typeMap, refMap);
  success = egress->build();
  if (!success)
    return success;

  LOG1("Building Deparser");
  auto db = pack->getParameterValue(v1model.sw.deparser.name)
                ->to<IR::ControlBlock>();
  BUG_CHECK(db != nullptr, "No deparser block found");
  deparser = new FPGADeparser(this, db);
  success = deparser->build();
  if (!success)
    return success;

  return true;
}

void FPGAProgram::emitImportStatements(BSVProgram & bsv) {
  CodeBuilder* builder = &bsv.getControlBuilder();
  builder->append_line("import Library::*;");
  builder->append_line("import StructDefines::*;");
  builder->append_line("import UnionDefines::*;");
  builder->append_line("import ConnectalTypes::*;");
  builder->append_line("import Table::*;");
  builder->append_line("import Engine::*;");
  builder->append_line("import Pipe::*;");
  builder->append_line("import Lists::*;");
}

void FPGAProgram::emitIncludeStatements(BSVProgram & bsv) {
  CodeBuilder* builder = &bsv.getControlBuilder();
  builder->append_line("`include \"TieOff.defines\"");
  builder->append_line("`include \"Debug.defines\"");
  builder->append_line("`include \"SynthBuilder.defines\"");
  builder->append_line("`include \"MatchTable.defines\"");
}

void FPGAProgram::emitBuiltinMetadata(CodeBuilder* builder) {
  const IR::Type_Struct* stdmeta = typeMap->getType(parser->stdMetadata)->to<IR::Type_Struct>();
  builder->append_line("typedef struct {");
  builder->incr_indent();
  for (auto h : *stdmeta->fields) {
    auto type = typeMap->getType(h);
    auto name = h->name.toString();
    builder->append_format("Maybe#(Bit#(%d)) %s;", type->width_bits(), name);
  }
  builder->decr_indent();
  builder->append_line("} StandardMetadataT deriving (Bits, Eq, FShow);");
  builder->append_line("instance DefaultValue#(StandardMetadataT);");
  builder->incr_indent();
  builder->append_line("defaultValue = unpack(0);");
  builder->decr_indent();
  builder->append_line("endinstance");

}
void FPGAProgram::emitMetadata(CodeBuilder* builder) {
  builder->append_line("typedef struct {");
  builder->incr_indent();
  // implicit metadata in table.
  for (auto p : ingress->metadata_to_table) {
    auto name = nameFromAnnotation(p.first->annotations, p.first->name);
    auto size = p.first->type->to<IR::Type_Bits>()->size;
    builder->append_line("Maybe#(Bit#(%d)) %s;", size, name);
  }
  for (auto p : egress->metadata_to_table) {
    auto name = nameFromAnnotation(p.first->annotations, p.first->name);
    auto size = p.first->type->to<IR::Type_Bits>()->size;
    builder->append_line("Maybe#(Bit#(%d)) %s;", size, name);
  }

  // FIXME: place into Metadata?
  // Implicit metadata in control flow.

  // Standard Metadata

  // Metadata declared by user.
  const IR::Type_Struct* usermeta = typeMap->getType(parser->userMetadata)->to<IR::Type_Struct>();
  CHECK_NULL(usermeta);
  for (auto h : *usermeta->fields) {
    auto type = typeMap->getType(h);
    auto name = h->name.toString();
    if (type->is<IR::Type_Struct>()) {
      const IR::Type_Struct* ty = type->to<IR::Type_Struct>();
      builder->append_format("Maybe#(%s) %s;", CamelCase(ty->name.toString()), name);
    }
  }
  builder->decr_indent();
  builder->append_line("} Metadata deriving (Bits, Eq, FShow);");
  builder->append_line("instance DefaultValue#(Metadata);");
  builder->incr_indent();
  builder->append_line("defaultValue = unpack(0);");
  builder->decr_indent();
  builder->append_line("endinstance");
}

void FPGAProgram::emitHeaders(CodeBuilder* builder) {
  builder->append_line("typedef struct {");
  builder->incr_indent();
  HeaderCodeGen visitor(this, builder);
  auto type = typeMap->getType(parser->headers);
  if (type != nullptr) {
    type->apply(visitor);
  }
  builder->decr_indent();
  builder->append_line("} Headers deriving (Bits, Eq, FShow);");
}

void FPGAProgram::emit(BSVProgram & bsv, CppProgram & cpp) {
  for (auto f : parser->parseStateMap) {
    LOG1(f.first << f.second);
  }
  // emits import statement to all generated files
  emitImportStatements(bsv);
  emitIncludeStatements(bsv);

  parser->emit(bsv);
  ingress->emit(bsv, cpp);
  egress->emit(bsv, cpp);
  deparser->emit(bsv);

  // must generate metadata after processing pipelines
  CodeBuilder* builder = &bsv.getStructBuilder();
  emitHeaders(builder);
  emitMetadata(builder);
  emitBuiltinMetadata(builder);

}
}  // namespace FPGA
