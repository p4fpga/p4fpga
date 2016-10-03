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

#include "fdeparser.h"
#include "ir/ir.h"
#include "vector_utils.h"
#include "string_utils.h"

namespace FPGA {

class DeparserBuilder : public Inspector {
  public:
    DeparserBuilder(FPGADeparser* deparser, const FPGAProgram* program) :
      deparser(deparser), program(program) {}
    bool preorder(const IR::MethodCallStatement* stat) override
    { visit(stat->methodCall); return false; }
    bool preorder(const IR::MethodCallExpression* expression) override;
    bool preorder(const IR::Member* member) override;
  private:
    const FPGAProgram* program;
    FPGADeparser* deparser;
};

bool DeparserBuilder::preorder(const IR::MethodCallExpression* expression) {
  // packet.emit
  auto emit = expression->method;
  for (auto h : MakeZipRange(*expression->typeArguments, *expression->arguments)) {
    auto typeName = h.get<0>();
    auto instName = h.get<1>();
    auto type = program->typeMap->getType(typeName, true);

    // get header width
    auto hdr_width = type->width_bits();
    // create deparse state for each header
    if (type->is<IR::Type_StructLike>()) {
      auto t = type->to<IR::Type_StructLike>();
      if (instName->is<IR::Member>()) {
        auto member = instName->to<IR::Member>();
        auto name = member->member;
        deparser->states.push_back(new IR::BSV::DeparseState(name, t->fields, hdr_width));
      }
    }
    // unroll header stack to individual headers and create deparse state for each one
    else if (type->is<IR::Type_Stack>()){
      auto stk = type->to<IR::Type_Stack>();
      for (int i = 0; i < stk->getSize(); i++) {
        if (stk->elementType->is<IR::Type_StructLike>()) {
          auto t = stk->elementType->to<IR::Type_StructLike>();
          auto hdr_width = stk->elementType->width_bits();
          if (instName->is<IR::Member>()) {
            auto member = instName->to<IR::Member>();
            auto name = member->member + std::to_string(i);
            deparser->states.push_back(new IR::BSV::DeparseState(name.c_str(), t->fields, hdr_width));
          }
        }
      }
    }
  }
  return false;
}

bool DeparserBuilder::preorder(const IR::Member* member) {
  if (member->expr->is<IR::PathExpression>()) {
    auto et = member->expr->to<IR::PathExpression>();
    // LOG1(et->path->name);
  }
  return false;
}

class DeparserRuleVisitor : public Inspector {
  public:
    DeparserRuleVisitor(const FPGADeparser* deparser, CodeBuilder* builder) :
      builder(builder) {}
    bool preorder(const IR::BSV::DeparseState* state) override;
  private:
    const FPGAProgram* program;
    CodeBuilder* builder;
};

bool DeparserRuleVisitor::preorder(const IR::BSV::DeparseState* state) {
  auto width = state->width_bits;
  auto hdr = state->to<IR::Type_Header>();
  auto name = hdr->name.name;

  // Rule: next deparse state
  builder->append_format("rule rl_deparse_%s_next if (w_%s);", name, name);
  builder->incr_indent();
  builder->append_format("deparse_state_ff.enq(StateDeparse%s);", CamelCase(name));
  builder->append_format("fetch_next_header(%d);", width);
  builder->decr_indent();
  builder->append_line("endrule");
  builder->append_line("");

  // Rule: append bits to buffer
  builder->append_format("rule rl_deparse_%s_load if ((deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] < %d));", name, CamelCase(name), width);
  builder->incr_indent();
  builder->append_format("dbprint(3, $format(\"deparse load %s\"));", name);
  builder->append_format("rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
  builder->append_format("UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);");
  builder->append_format("UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;");
  builder->append_format("move_buffered_amt(cExtend(n_bits_used));");
  builder->decr_indent();
  builder->append_line("endrule");
  builder->append_line("");

  // Rule: enough bits in buffer, send header
  builder->append_format("rule rl_deparse_%s_send if ((deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] > %d));", name, CamelCase(name), width);
  builder->incr_indent();
  builder->append_format("dbprint(3, $format(\"deparse send %s\"));", name);
  builder->append_format("succeed_and_next(%d);", width);
  builder->append_line("deparse_state_ff.deq;");
  builder->append_line("let metadata = meta[0];");
  builder->append_format("metadata.hdr.%s = updateState(metadata.hdr.%s, tagged StructDefines::NotPresent);", name, name);
  builder->append_line("transit_next_state(metadata);");
  builder->append_line("meta[0] <= metadata;");
  builder->decr_indent();
  builder->append_line("endrule");
  builder->append_line("");
  return false;
}

class DeparserStateVisitor : public Inspector {
  public:
    DeparserStateVisitor(const FPGADeparser* deparser, CodeBuilder* builder) :
      builder(builder) {}
    bool preorder(const IR::BSV::DeparseState* state) override;
  private:
    const FPGAProgram* program;
    CodeBuilder* builder;
};

bool DeparserStateVisitor::preorder(const IR::BSV::DeparseState* state) {
  auto hdr = state->to<IR::Type_Header>();
  auto name = hdr->name.name;
  builder->append_format("PulseWire w_%s <- mkPulseWire();", name);
  return false;
}

// Convert emit() to IR::BSV::DeparseState
bool FPGADeparser::build() {
  auto stat = controlBlock->container->body;
  DeparserBuilder visitor(this, program);
  stat->apply(visitor);
  return true;
}

void FPGADeparser::emitEnums() {
  builder->append_line("`ifdef DEPARSER_STRUCT");
  builder->append_line("typedef enum {");
  builder->incr_indent();
  builder->append_line("StateDeparseStart,");
  for (auto r : states) {
    auto name = r->name.name;
    if (r != states.back()) {
      builder->append_format("StateDeparse%s,", CamelCase(name));
    } else {
      builder->append_format("StateDeparse%s", CamelCase(name));
    }
  }
  builder->decr_indent();
  builder->append_line("} DeparserState deriving (Bits, Eq, FShow);");
  builder->append_line("`endif  // DEPARSER_STRUCT");
}

void FPGADeparser::emitRules() {
  builder->append_line("`ifdef DEPARSER_RULES");
  // deparse rules are mutually exclusive
  std::vector<cstring> exclusive_rules;
  for (auto r : states) {
    cstring rl = cstring("rl_deparse_") + r->name.toString() + cstring("_next");
    exclusive_rules.push_back(rl);
  }
  auto exclusive_annotation = cstring("(* mutually_exclusive=\"");
  for (auto r : exclusive_rules) {
    exclusive_annotation += r;
    if (r != exclusive_rules.back()) {
      exclusive_annotation += cstring(",");
    }
  }
  exclusive_annotation += cstring("\" *)");
  builder->append_line(exclusive_annotation);
  DeparserRuleVisitor visitor(this, builder);
  for (auto r : states) {
    r->apply(visitor);
  }
  builder->append_line("`endif  // DEPARSER_RULES");
}

void FPGADeparser::emitStates() {
  builder->append_line("`ifdef DEPARSER_STATE");

  // pulsewire to initiate next state
  DeparserStateVisitor visitor(this, builder);
  for (auto r : states) {
    r->apply(visitor);
  }
  builder->append_line("");

  // Function: next_parse_state
  auto len = states.size();
  // bit0 is by default 0.
  auto lenp1 = len + 1;
  builder->append_format("function Bit#(%d) nextDeparseState(MetadataT metadata);", lenp1);
  builder->incr_indent();
  builder->append_format("Vector#(%d, Bool) headerValid;", lenp1);
  builder->append_line("headerValid[0] = False;");
  for (int i = 0; i < states.size(); i++) {
    auto name = states.at(i)->name.name;
    builder->append_format("headerValid[%d] = checkForward(metadata.hdr.%s);", i+1, name);
  }
  builder->append_line("let vec = pack(headerValid);");
  builder->append_line("return vec;");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->append_line("");

  // Function: transit_next_state
  builder->append_line("function Action transit_next_state(MetadataT metadata);");
  builder->incr_indent();
  builder->append_line("action");
  builder->append_line("let vec = nextDeparseState(metadata);");
  builder->append_line("if (vec == 0) begin");
  builder->incr_indent();
  builder->append_line("w_deparse_header_done.send();");
  builder->decr_indent();
  builder->append_line("end");
  builder->append_line("else begin");
  builder->incr_indent();
  auto nextVecLen = ceil(log2(lenp1));
  builder->append_format("Bit#(%d) nextHeader = truncate(pack(countZerosLSB(vec)%% %d));", nextVecLen, lenp1 );
  builder->append_line("DeparserState nextState = unpack(nextHeader);");
  builder->append_line("case (nextState) matches");
  builder->incr_indent();
  for (int i = 0; i < states.size(); i++) {
    auto name = states.at(i)->name.name;
    builder->append_format("StateDeparse%s: w_%s.send();", CamelCase(name), name);
  }
  builder->append_line("default: $display(\"ERROR: unknown states.\");");
  builder->decr_indent();
  builder->append_line("endcase");
  builder->decr_indent();
  builder->append_line("end");
  builder->append_line("endaction");
  builder->decr_indent();
  builder->append_line("endfunction");
  builder->append_line("let initState = StateDeparse%s;", CamelCase(states[0]->name.toString()));
  builder->append_line("`endif  // DEPARSER_STATE");
}

void FPGADeparser::emit(BSVProgram & bsv) {
  builder = &bsv.getDeparserBuilder();
  emitEnums();
  emitRules();
  emitStates();
}

}  // namespace FPGA
