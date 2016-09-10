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

#include <algorithm>
#include <string>
#include "table.h"
#include "fcontrol.h"
#include "string_utils.h"

/*
  info associated with a table
  - key, value
  - name
  - actions
 */

namespace FPGA {

using namespace Control;

//bool TableCodeGen::compareActionListElement

void TableCodeGen::emitTypedefs(const IR::P4Table* table) {
  // generate request typedef
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  if ((key_width % 9) != 0) {
    auto pad = 9 - (key_width % 9);
    //append_line(bsv, "`ifndef SIMULATION");
    append_line(bsv, "Bit#(%d) padding;", pad);
    //append_line(bsv, "`endif");
  }
  for (auto k : key_vec) {
    auto f = k.first;
    auto s = k.second;
    append_line(bsv, "Bit#(%d) %s;", s, f->name.toString());
  }
  decr_indent(bsv);
  append_format(bsv, "} %sReqT deriving (Bits, Eq, FShow);", type);

  // action enum
  append_line(bsv, "typedef enum {");
  incr_indent(bsv);
  // find out name of default action
  auto defaultAction = table->getDefaultAction();
  if (defaultAction->is<IR::MethodCallExpression>()){
    auto expression = defaultAction->to<IR::MethodCallExpression>();
    defaultActionName = expression->method->toString();
  }
  // put default action in first position
  auto actionList = table->getActionList()->actionList;
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::PathExpression>()) {
      // FIXME: handle action as path
      LOG1("Path " << elem->expression->to<IR::PathExpression>());
    } else if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto t = control->program->typeMap->getType(e->method, true);
      auto n = e->method->toString();
      // check if default action
      if (n == defaultActionName) {
        action_vec.insert(action_vec.begin(), UpperCase(n));
      } else {
        action_vec.push_back(UpperCase(n));
      }
    }
  }
  // generate enum typedef
  for (auto action : action_vec) {
      if (action != action_vec.back()) {
        append_line(bsv, "%s,", action);
      } else {
        append_line(bsv, "%s", action);
      }
  }
  decr_indent(bsv);
  append_line(bsv, "} %sActionT deriving (Bits, Eq, FShow);", type);

  // generate response typedef
  append_line(bsv, "typedef struct {");
  incr_indent(bsv);
  append_line(bsv, "%sActionT _action;", type);
  // if there is any params
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto n = e->method->toString();
      // from action name to actual action declaration
      auto k = control->basicBlock.find(n);
      if (k != control->basicBlock.end()) {
        auto params = k->second->parameters;
        for (auto p : *params->parameters) {
          auto type = p->type->to<IR::Type_Bits>();
          append_line(bsv, "Bit#(%d) %s;", type->size, p->name.toString());
          action_size += type->size;
        }
      }
    } else {
      ::warning("unhandled action type", action);
    }
  }
  action_size += ceil(log2(actionList->size()));
  decr_indent(bsv);
  append_line(bsv, "} %sRspT deriving (Bits, Eq, FShow);", type);
}

void TableCodeGen::emitSimulation(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto id = table->declid;
  auto remainder = key_width % 9;
  if (remainder != 0) {
    key_width = key_width + 9 - remainder;
  }
  append_line(bsv, "`ifndef SVDPI");
  append_format(bsv, "import \"BDPI\" function ActionValue#(Bit#(%d)) matchtable_read_%s(Bit#(%d) msgtype);", action_size, name, key_width);
  append_format(bsv, "import \"BDPI\" function Action matchtable_write_%s(Bit#(%d) msgtype, Bit#(%d) data);", name, key_width, action_size);
  append_line(bsv, "`endif");

  append_line(bsv, "instance MatchTableSim#(%d, %d, %d);", table->declid, key_width, action_size);
  incr_indent(bsv);
  append_format(bsv, "function ActionValue#(Bit#(%d)) matchtable_read(%d, Bit#(%d) key);", table->declid, action_size, key_width);
  append_line(bsv, "actionvalue");
  incr_indent(bsv);
  append_format(bsv, "let v <- matchtable_read_%s(key);", name);
  append_line(bsv, "return v;");
  decr_indent(bsv);
  append_line(bsv, "endactionvalue");
  append_line(bsv, "endfunction");

  append_format(bsv, "function Action matchtable_write(%d, Bit#(%d) key, Bit#(%d) data);", table->declid, key_width, action_size);
  append_line(bsv, "action");
  incr_indent(bsv);
  append_format(bsv, "matchtable_write_%s(key, data);", name);
  decr_indent(bsv);
  append_line(bsv, "endaction");
  append_line(bsv, "endfunction");
  decr_indent(bsv);
  append_line(bsv, "endinstance");
}

void TableCodeGen::emitRuleHandleRequest(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  // handle table request
  append_line(bsv, "Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);");
  append_line(bsv, "rule rl_handle_request;");
  incr_indent(bsv);
  append_line(bsv, "let data = rx_info_metadata.first;");
  append_line(bsv, "rx_info_metadata.deq;");
  append_line(bsv, "let meta = data.meta;");
  append_line(bsv, "let pkt = data.pkt;");
  auto fields = cstring("");
  for (auto k : key_vec) {
    auto f = k.first;
    auto s = k.second;
    auto name = f->name.toString();
    append_line(bsv, "let %s = fromMaybe(?, meta.%s);", name, name);
    fields += name + cstring(":") + name;
    if (k != key_vec.back()) {
      fields += cstring(",");
    }
  }
  append_format(bsv, "%sReqT req = %sReqT{%s};", type, type, fields);
  append_line(bsv, "matchTable.lookupPort.request.put(pack(req));");
  append_line(bsv, "packet_ff[0].enq(pkt);");
  append_line(bsv, "metadata_ff[0].enq(meta);");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void TableCodeGen::emitRuleHandleExecution(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  // handle action execution
  append_line(bsv, "rule rl_execute;");
  incr_indent(bsv);
  append_line(bsv, "let rsp <- matchTable.lookupPort.response.get;");
  append_line(bsv, "let pkt <- toGet(packet_ff[0]).get;");
  append_line(bsv, "let meta <- toGet(metadata_ff[0]).get;");
  append_line(bsv, "if (rsp matches tagged Valid .data) begin");
  incr_indent(bsv);
  append_format(bsv, "%sRspT resp = unpack(data);", type);
  append_line(bsv, "case (resp._action) matches");
  auto actionList = table->getActionList()->actionList;
  int idx = 0;
  incr_indent(bsv);
  for (auto action : *actionList) {
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto n = e->method->toString();
      auto t = CamelCase(n);
      // from action name to actual action declaration
      auto k = control->basicBlock.find(n);
      if (k != control->basicBlock.end()) {
        auto fields = cstring("");
        auto params = k->second->parameters;
        for (auto param : *params->parameters) {
          auto p = param->to<IR::Parameter>();
          auto name = p->name.toString();
          fields += name + cstring(": ") + name;
          if (p != params->parameters->back()) {
            fields += cstring(", ");
          }
        }
        append_format(bsv, "%s: begin", UpperCase(t));
        incr_indent(bsv);
        append_format(bsv, "%sActionReq req = tagged %sReqT {%s};", type, t, fields);
        append_format(bsv, "bbReqFifo[%d].enq(req);", idx);
        decr_indent(bsv);
        append_line(bsv, "end");
      }
      idx += 1;
    }
  }
  decr_indent(bsv);
  append_line(bsv, "endcase");
  append_line(bsv, "packet_ff[1].enq(pkt);");
  append_line(bsv, "metadata_ff[1].enq(meta);");
  decr_indent(bsv);
  append_line(bsv, "end");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void TableCodeGen::emitRuleHandleResponse(const IR::P4Table *table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  auto actionList = table->getActionList()->actionList;
  // handle table response
  append_line(bsv, "rule rl_handle_response;");
  incr_indent(bsv);
  append_line(bsv, "let v <- toGet(bbRspFifo[readyChannel]).get;");
  append_line(bsv, "let pkt <- toGet(packet_ff[1]).get;");
  append_line(bsv, "let meta <- toGet(metadata_ff[1]).get;");
  append_line(bsv, "case (v) matches");
  incr_indent(bsv);
  for (auto action : *actionList) {
    auto fields = cstring("");
    auto elem = action->to<IR::ActionListElement>();
    if (elem->expression->is<IR::MethodCallExpression>()) {
      auto e = elem->expression->to<IR::MethodCallExpression>();
      auto n = e->method->toString();
      auto t = CamelCase(n);
      // from action name to actual action declaration
      auto k = control->basicBlock.find(n);
      if (k != control->basicBlock.end()) {
        auto params = k->second->parameters;
        for (auto param : *params->parameters) {
          auto p = param->to<IR::Parameter>();
          auto type = p->type->to<IR::Type_Bits>();
          fields += p->name.toString() + cstring(": .") + p->name.toString();
          if (p != params->parameters->back()) {
            fields += cstring(", ");
          }
        }
        append_format(bsv, "tagged %sRspT {%s} : begin", t, fields);
        incr_indent(bsv);
        //append_format(bsv, "%sResponse rsp = tagged %s%sRspT {pkt: pkt, meta: meta};", type, type, t);
        //append_line(bsv, "tx_info_metadata.enq(rsp);");
        decr_indent(bsv);
        append_line(bsv, "end");
      }
    }
  }
  decr_indent(bsv);
  append_line(bsv, "endcase");
  append_format(bsv, "MetadataResponse rsp = MetadataResponse {pkt: pkt, meta: meta};");
  append_line(bsv, "tx_info_metadata.enq(rsp);");
  decr_indent(bsv);
  append_line(bsv, "endrule");
}

void TableCodeGen::emitRspFifoMux(const IR::P4Table *table) {
  auto actionList = table->getActionList()->actionList;
  auto nActions = actionList->size();
  // ready mux for all rsp fifo
  append_format(bsv, "Vector#(%d, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);", nActions);
  append_line(bsv, "Bool interruptStatus = False;");
  append_format(bsv, "Bit#(%d) readyChannel = -1;", nActions);
  append_format(bsv, "for (Integer i=%d; i>=0; i=i-1) begin", nActions-1);
  incr_indent(bsv);
  append_line(bsv, "if (readyBits[i]) begin");
  incr_indent(bsv);
  append_line(bsv, "interruptStatus = True;");
  append_line(bsv, "readyChannel = fromInteger(i);");
  decr_indent(bsv);
  append_line(bsv, "end");
  decr_indent(bsv);
  append_line(bsv, "end");
}

void TableCodeGen::emit(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  auto actionList = table->getActionList()->actionList;
  auto nActions = actionList->size();

  append_line(bsv, "(* synthesize *)");
  append_format(bsv, "module mkMatchTable_256_%s(MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)));", type, table->declid, type, type);
  incr_indent(bsv);
  append_line(bsv, "(* hide *)");
  append_format(bsv, "MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)) ifc <- mkMatchTable(\"%s\");", table->declid, type, type, name);
  append_line(bsv, "return ifc;");
  decr_indent(bsv);
  append_line(bsv, "endmodule");

  append_format(bsv, "// =============== table %s ==============", name);
  append_line(bsv, "interface %s;", type);
  incr_indent(bsv);
  //FIXME: more than one action;
  append_line(bsv, "interface Server#(MetadataRequest, MetadataResponse) prev_control_state;");
  int idx = 0;
  for (auto action : *actionList) {
    append_line(bsv, "interface Client#(%sActionReq, %sActionRsp) next_control_state_%d;", type, type, idx);
    idx ++;
  }
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  decr_indent(bsv);
  append_line(bsv, "endinterface");
  append_line(bsv, "(* synthesize *)");
  append_format(bsv, "module mk%s (Control::%s);", type, type);
  incr_indent(bsv);
  control->emitDebugPrint(bsv);

  append_line(bsv, "RX #(MetadataRequest) rx_metadata <- mkRX;");
  append_line(bsv, "TX #(MetadataResponse) tx_metadata <- mkTX;");
  append_line(bsv, "let rx_info_metadata = rx_metadata.u;");
  append_line(bsv, "let tx_info_metadata = tx_metadata.u;");

  append_format(bsv, "Vector#(%d, FIFOF#(%sActionReq)) bbReqFifo <- replicateM(mkFIFOF);", nActions, type);
  append_format(bsv, "Vector#(%d, FIFOF#(%sActionRsp)) bbRspFifo <- replicateM(mkFIFOF);", nActions, type);
  append_line(bsv, "Vector#(2, FIFOF#(PacketInstance)) packet_ff <- replicateM(mkFIFOF);");
  append_line(bsv, "MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)) matchTable <- mkMatchTable_256_%s;", table->declid, type, type, type);

  emitRspFifoMux(table);
  emitRuleHandleRequest(table);
  emitRuleHandleExecution(table);
  emitRuleHandleResponse(table);

  append_line(bsv, "interface prev_control_state = toServer(rx_metadata.e, tx_metadata.e);");
  idx = 0;
  for (auto action : *actionList) {
    append_line(bsv, "interface next_control_state_%d = toClient(bbReqFifo[%d], bbRspFifo[%d]);", idx, idx, idx);
    idx ++;
  }
  append_line(bsv, "method Action set_verbosity(int verbosity);");
  incr_indent(bsv);
  append_line(bsv, "cf_verbosity <= verbosity;");
  decr_indent(bsv);
  append_line(bsv, "endmethod");
  decr_indent(bsv);
  append_line(bsv, "endmodule");
}

bool TableCodeGen::preorder(const IR::P4Table* table) {
  auto tbl = table->to<IR::P4Table>();
  for (auto act : *tbl->getActionList()->actionList) {
    auto element = act->to<IR::ActionListElement>();
    if (element->expression->is<IR::PathExpression>()) {
      LOG1("Path " << element->expression->to<IR::PathExpression>());
    } else if (element->expression->is<IR::MethodCallExpression>()) {
      auto expression = element->expression->to<IR::MethodCallExpression>();
      auto type = control->program->typeMap->getType(expression->method, true);
      auto action = expression->method->toString();
      //control->action_to_table[action] = tbl;
      LOG1("action " << action);
    }
  }

  // visit keys
  auto keys = tbl->getKey();
  if (keys == nullptr) return false;

  for (auto key : *keys->keyElements) {
    auto element = key->to<IR::KeyElement>();
    if (element->expression->is<IR::Member>()) {
      auto m = element->expression->to<IR::Member>();
      auto type = control->program->typeMap->getType(m->expr, true);
      if (type->is<IR::Type_Struct>()) {
        auto t = type->to<IR::Type_StructLike>();
        auto f = t->getField(m->member);
        auto f_size = f->type->to<IR::Type_Bits>()->size;
        //control->metadata_to_table[f].insert(tbl);
        key_vec.push_back(std::make_pair(f, f_size));
        key_width += f_size;
      } else if (type->is<IR::Type_Header>()){
        auto t = type->to<IR::Type_Header>();
        auto f = t->getField(m->member);
        auto f_size = f->type->to<IR::Type_Bits>()->size;
        key_vec.push_back(std::make_pair(f, f_size));
        key_width += f_size;
      }
    }
  }

  emitTypedefs(tbl);
  emitSimulation(tbl);
  emit(tbl);

  return false;
}

}  // namespace FPGA
