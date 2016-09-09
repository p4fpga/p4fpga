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

using namespace Deparser;

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
    DeparserRuleVisitor(const FPGADeparser* deparser, BSVProgram& bsv) :
      bsv_(bsv) {}
    bool preorder(const IR::BSV::DeparseState* state) override;
  private:
    const FPGAProgram* program;
    BSVProgram & bsv_;
};

bool DeparserRuleVisitor::preorder(const IR::BSV::DeparseState* state) {
  auto width = state->width_bits;
  auto hdr = state->to<IR::Type_Header>();
  auto name = hdr->name.name;

  // Rule: next deparse state
  append_format(bsv_, "rule rl_deparse_%s_next if (w_%s);", name, name);
  incr_indent(bsv_);
  append_format(bsv_, "deparse_state_ff.enq(StateDeparse%s);", CamelCase(name));
  append_format(bsv_, "fetch_next_header(%d);", width);
  decr_indent(bsv_);
  append_line(bsv_, "endrule");
  append_line(bsv_, "");

  // Rule: append bits to buffer
  append_format(bsv_, "rule rl_deparse_%s_load if ((deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] < %d));", name, CamelCase(name), width);
  incr_indent(bsv_);
  append_format(bsv_, "rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];");
  append_format(bsv_, "UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);");
  append_format(bsv_, "UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;");
  append_format(bsv_, "move_buffered_amt(cExtend(n_bits_used));");
  decr_indent(bsv_);
  append_line(bsv_, "endrule");
  append_line(bsv_, "");

  // Rule: enough bits in buffer, send header
  append_format(bsv_, "rule rl_deparse_%s_send if ((deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] > %d));", name, CamelCase(name), width);
  incr_indent(bsv_);
  append_format(bsv_, "succeed_and_next(%d);", width);
  append_line(bsv_, "deparse_state_ff.deq;");
  append_line(bsv_, "let metadata = meta[0];");
  append_format(bsv_, "metadata.%s = tagged NotPresent;", name);
  append_line(bsv_, "transit_next_state(metadata);");
  append_line(bsv_, "meta[0] <= metadata;");
  decr_indent(bsv_);
  append_line(bsv_, "endrule");
  append_line(bsv_, "");
  return false;
}

class DeparserStateVisitor : public Inspector {
  public:
    DeparserStateVisitor(const FPGADeparser* deparser, BSVProgram& bsv) :
      bsv_(bsv) {}
    bool preorder(const IR::BSV::DeparseState* state) override;
  private:
    const FPGAProgram* program;
    BSVProgram & bsv_;
};

bool DeparserStateVisitor::preorder(const IR::BSV::DeparseState* state) {
  auto hdr = state->to<IR::Type_Header>();
  auto name = hdr->name.name;
  append_format(bsv_, "PulseWire w_deparse_%s <- mkPulseWire();", name);
  return false;
}

// Convert emit() to IR::BSV::DeparseState
bool FPGADeparser::build() {
  //LOG1(program->typeMap);
  auto stat = controlBlock->container->body;
  DeparserBuilder visitor(this, program);
  stat->apply(visitor);
  return true;
}

void FPGADeparser::emitEnums(BSVProgram & bsv) {
  append_line(bsv, "`ifdef DEPARSER_STRUCT");
  append_line(bsv, "typedef enum {");
  incr_indent(bsv);
  for (auto r : states) {
    auto name = r->name.name;
    if (r != states.back()) {
      append_format(bsv, "StateDeparse%s,", CamelCase(name));
    } else {
      append_format(bsv, "StateDeparse%s", CamelCase(name));
    }
  }
  decr_indent(bsv);
  append_line(bsv, "} DeparserState deriving (Bits, Eq, FShow);");
  append_line(bsv, "`endif  // DEPARSER_STRUCT");
}

void FPGADeparser::emitRules(BSVProgram & bsv) {
  append_line(bsv, "`ifdef DEPARSER_RULES");
  // deparse rules are mutually exclusive
  DeparserRuleVisitor visitor(this, bsv);
  for (auto r : states) {
    r->apply(visitor);
  }
  append_line(bsv, "`endif  // DEPARSER_RULES");
}

void FPGADeparser::emitStates(BSVProgram & bsv) {
  append_line(bsv, "`ifdef DEPARSER_STATE");

  // pulsewire to initiate next state
  DeparserStateVisitor visitor(this, bsv);
  for (auto r : states) {
    r->apply(visitor);
  }
  append_line(bsv, "");

  // Function: next_parse_state
  auto len = states.size();
  append_format(bsv, "function Bit#(%d) nextDeparseState(MetadataT metadata);", len);
  incr_indent(bsv);
  append_format(bsv, "Vector#(%d, Bool) headerValid;", len);
  for (int i = 0; i < states.size(); i++) {
    auto name = states.at(i)->name.name;
    append_format(bsv, "headerValid[%d] = metadata.%s matches tagged Forward ? True : False;", i, name);
  }
  append_line(bsv, "let vec = pack(headerValid);");
  append_line(bsv, "return vec;");
  decr_indent(bsv);
  append_line(bsv, "endfunction");
  append_line(bsv, "");

  // Function: transit_next_state
  append_format(bsv, "function Action transit_next_state(MetadataT metadata);");
  incr_indent(bsv);
  append_line(bsv, "action");
  append_line(bsv, "let vec = nextDeparseState(metadata);");
  append_line(bsv, "if (vec == 0) begin");
  incr_indent(bsv);
  append_line(bsv, "w_deparse_header_done.send();");
  decr_indent(bsv);
  append_line(bsv, "end");
  append_line(bsv, "else begin");
  incr_indent(bsv);
  append_line(bsv, "let nextHeader = pack(countZerosLSB(vec));");
  append_line(bsv, "DeparserState nextState = unpack(nextHeader);");
  append_line(bsv, "case (nextState) matches");
  incr_indent(bsv);
  for (int i = 0; i < states.size(); i++) {
    auto name = states.at(i)->name.name;
    append_format(bsv, "StateDeparse%s: w_deparse_%s.send();", CamelCase(name), name);
  }
  append_line(bsv, "default: $display(\"ERROR: unknown states.\");");
  decr_indent(bsv);
  append_line(bsv, "endcase");
  decr_indent(bsv);
  append_line(bsv, "end");
  append_line(bsv, "endaction");
  decr_indent(bsv);
  append_line(bsv, "endfunction");
  append_line(bsv, "`endif  // DEPARSER_STATE");
}

void FPGADeparser::emit(BSVProgram & bsv) {
  emitEnums(bsv);
  emitRules(bsv);
  emitStates(bsv);
}

}  // namespace FPGA
