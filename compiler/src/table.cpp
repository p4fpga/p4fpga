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

void TableCodeGen::emitTypedefs(const IR::P4Table* table) {
  // Typedef are emitted to two different files
  // - ConnectalType is used by Connectal to generate API
  // - Control is used by p4 pipeline
  // TODO: we can probably just generate ConnectalType and import it in Control
  cstring name = nameFromAnnotation(table->annotations, table->name);
  cstring type = CamelCase(name);
  type_builder->append_line("typedef struct{");
  type_builder->incr_indent();
  builder->append_line("typedef struct {");
  builder->incr_indent();
  if ((key_width % 9) != 0) {
    int pad = 9 - (key_width % 9);
    //builder->append_line("`ifndef SIMULATION");
    builder->append_line("Bit#(%d) padding;", pad);
    //builder->append_line("`endif");
  }
  for (auto k : key_vec) {
    const IR::StructField* f = k.first;
    int size = k.second;
    cstring fname = f->name.toString();
    builder->append_line("Bit#(%d) %s;", size, fname);
    type_builder->append_format("Bit#(%d) %s;", size, fname);
  }
  type_builder->decr_indent();
  builder->decr_indent();
  type_builder->append_format("} %sReqT deriving (Bits, FShow);", type);
  builder->append_format("} %sReqT deriving (Bits, Eq, FShow);", type);

  // action enum
  builder->append_line("typedef enum {");
  builder->incr_indent();
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
        builder->append_line("%s,", action);
      } else {
        builder->append_line("%s", action);
      }
  }
  builder->decr_indent();
  builder->append_line("} %sActionT deriving (Bits, Eq, FShow);", type);

  // generate response typedef
  builder->append_line("typedef struct {");
  builder->incr_indent();
  builder->append_line("%sActionT _action;", type);
  // if there is any params
  TableParamExtractor param_extractor(control);
  for (auto action : *actionList) {
    action->apply(param_extractor);
  }
  cstring tname = table->name.toString();
  type_builder->append_format("typedef struct {");
  type_builder->incr_indent();
  int action_key_size = ceil(log2(actionList->size()));
  LOG1("action list " << table->name << " " << actionList->size() << " " << action_key_size);
  type_builder->append_format("Bit#(%d) _action;", action_key_size);
  for (auto f : param_extractor.param_map) {
    cstring pname = f.first;
    const IR::Type_Bits* param = f.second;
    builder->append_line("Bit#(%d) %s;", param->size, pname);
    type_builder->append_format("Bit#(%d) %s;", param->size, pname);
    action_size += param->size;
  }
  action_size += ceil(log2(actionList->size()));
  type_builder->decr_indent();
  type_builder->append_format("} %sRspT deriving (Bits, FShow);", type);
  builder->decr_indent();
  builder->append_line("} %sRspT deriving (Bits, Eq, FShow);", type);
}

void TableCodeGen::emitSimulation(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto id = table->declid % 32;
  auto remainder = key_width % 9;
  if (remainder != 0) {
    key_width = key_width + 9 - remainder;
  }
  builder->append_line("`ifndef SVDPI");
  builder->append_format("import \"BDPI\" function ActionValue#(Bit#(%d)) matchtable_read_%s(Bit#(%d) msgtype);", action_size, camelCase(name), key_width);
  builder->append_format("import \"BDPI\" function Action matchtable_write_%s(Bit#(%d) msgtype, Bit#(%d) data);", camelCase(name), key_width, action_size);
  builder->append_line("`endif");

  builder->append_line("instance MatchTableSim#(%d, %d, %d);", id, key_width, action_size);
  builder->incr_indent();
  builder->append_format("function ActionValue#(Bit#(%d)) matchtable_read(Bit#(%d) id, Bit#(%d) key);", action_size, id, key_width);
  builder->append_line("actionvalue");
  builder->incr_indent();
  builder->append_format("let v <- matchtable_read_%s(key);", camelCase(name));
  builder->append_line("return v;");
  builder->decr_indent();
  builder->append_line("endactionvalue");
  builder->append_line("endfunction");

  builder->append_format("function Action matchtable_write(Bit#(%d) id, Bit#(%d) key, Bit#(%d) data);", id, key_width, action_size);
  builder->append_line("action");
  builder->incr_indent();
  builder->append_format("matchtable_write_%s(key, data);", camelCase(name));
  builder->decr_indent();
  builder->append_line("endaction");
  builder->append_line("endfunction");
  builder->decr_indent();
  builder->append_line("endinstance");
}

void TableCodeGen::emitRuleHandleRequest(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  // handle table request
  builder->append_line("Vector#(2, FIFOF#(MetadataT)) metadata_ff <- replicateM(mkFIFOF);");
  builder->append_line("rule rl_handle_request;");
  builder->incr_indent();
  builder->append_line("let data = rx_info_metadata.first;");
  builder->append_line("rx_info_metadata.deq;");
  builder->append_line("let meta = data.meta;");
  builder->append_line("let pkt = data.pkt;");
  auto fields = cstring("");
  auto field_width = 0;
  for (auto k : key_vec) {
    auto f = k.first;
    auto s = k.second;
    LOG1("key size" << s);
    field_width += s;
    auto name = f->name.toString();
    builder->append_line("let %s = fromMaybe(?, meta.%s);", name, name);
    fields += name + cstring(": ") + name;
    if (k != key_vec.back()) {
      fields += cstring(",");
    }
  }
  if (field_width % 9 != 0) {
    fields += ", padding: 0";
  }
  builder->append_line("%sReqT req = %sReqT{%s};", type, type, fields);
  builder->append_line("matchTable.lookupPort.request.put(pack(req));");
  builder->append_line("packet_ff[0].enq(pkt);");
  builder->append_line("metadata_ff[0].enq(meta);");
  builder->decr_indent();
  builder->append_line("endrule");
}

void TableCodeGen::emitRuleHandleExecution(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  // handle action execution
  builder->append_line("rule rl_execute;");
  builder->incr_indent();
  builder->append_line("let rsp <- matchTable.lookupPort.response.get;");
  builder->append_line("let pkt <- toGet(packet_ff[0]).get;");
  builder->append_line("let meta <- toGet(metadata_ff[0]).get;");
  builder->append_line("if (rsp matches tagged Valid .data) begin");
  builder->incr_indent();
  builder->append_format("%sRspT resp = unpack(data);", type);
  builder->append_line("case (resp._action) matches");
  auto actionList = table->getActionList()->actionList;
  int idx = 0;
  builder->incr_indent();
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
          fields += cstring(", ");
          auto p = param->to<IR::Parameter>();
          auto name = p->name.toString();
          fields += name + cstring(": resp.") + name;
        }
        builder->append_format("%s: begin", UpperCase(t));
        builder->incr_indent();
        builder->append_format("%sActionReq req = tagged %sReqT {pkt: pkt, meta: meta %s};", type, t, fields);
        builder->append_format("bbReqFifo[%d].enq(req);", idx);
        builder->decr_indent();
        builder->append_line("end");
      }
      idx += 1;
    }
  }
  builder->decr_indent();
  builder->append_line("endcase");
  // builder->append_line("packet_ff[1].enq(pkt);");
  // builder->append_line("metadata_ff[1].enq(meta);");
  builder->decr_indent();
  builder->append_line("end");
  builder->decr_indent();
  builder->append_line("endrule");
}

void TableCodeGen::emitRuleHandleResponse(const IR::P4Table *table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  auto actionList = table->getActionList()->actionList;
  // handle table response
  builder->append_line("rule rl_handle_response;");
  builder->incr_indent();
  builder->append_line("let v <- toGet(bbRspFifo[readyChannel]).get;");
  // builder->append_line("let pkt <- toGet(packet_ff[1]).get;");
  // builder->append_line("let meta <- toGet(metadata_ff[1]).get;");
  builder->append_line("case (v) matches");
  builder->incr_indent();
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
        builder->append_format("tagged %sRspT {pkt: .pkt, meta: .meta} : begin", t);
        builder->incr_indent();
        builder->append_format("MetadataResponse rsp = tagged MetadataResponse {pkt: pkt, meta: meta};");
        builder->append_line("tx_info_metadata.enq(rsp);");
        builder->decr_indent();
        builder->append_line("end");
      }
    }
  }
  builder->decr_indent();
  builder->append_line("endcase");
  builder->decr_indent();
  builder->append_line("endrule");
}

void TableCodeGen::emitRspFifoMux(const IR::P4Table *table) {
  auto actionList = table->getActionList()->actionList;
  auto nActions = actionList->size();
  // ready mux for all rsp fifo
  builder->append_format("Vector#(%d, Bool) readyBits = map(fifoNotEmpty, bbRspFifo);", nActions);
  builder->append_line("Bool interruptStatus = False;");
  builder->append_format("Bit#(%d) readyChannel = -1;", nActions);
  builder->append_format("for (Integer i=%d; i>=0; i=i-1) begin", nActions-1);
  builder->incr_indent();
  builder->append_line("if (readyBits[i]) begin");
  builder->incr_indent();
  builder->append_line("interruptStatus = True;");
  builder->append_line("readyChannel = fromInteger(i);");
  builder->decr_indent();
  builder->append_line("end");
  builder->decr_indent();
  builder->append_line("end");
}

void TableCodeGen::emitIntfAddEntry(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  builder->append_format("method Action add_entry(ConnectalTypes::%sReqT k, ConnectalTypes::%sRspT v);", type, type);
  builder->newline();

  TableKeyExtractor key_extractor(control->program);
  const IR::Key* key = table->getKey();
  if (key != nullptr) {
    builder->incr_indent();
    builder->append_format("let key = %sReqT{", type);
    for (auto k : *key->keyElements) {
      k->apply(key_extractor);
    }
    if ((key_extractor.key_width % 9) != 0) {
      builder->append_format("padding: 0, ");
    }
    for (auto it = key_extractor.keymap.begin(); it != key_extractor.keymap.end(); ++it) {
      const IR::StructField* field = it->second;
      cstring member = it->first;
      if (field->type->is<IR::Type_Bits>()) {
        int size = field->type->to<IR::Type_Bits>()->size;
        if (it != key_extractor.keymap.begin()) {
          builder->append_format(", ");
        }
        builder->append_format("%s: k.%s", member, member);
      }
    }
    builder->append_line("};");
    builder->append_format("let value = %sRspT{", type);
    builder->append_line("_action: unpack(v._action)");

    auto actionList = table->getActionList()->actionList;
    TableParamExtractor param_extractor(control);
    for (auto action : *actionList) {
      action->apply(param_extractor);
    }
    for (auto f : param_extractor.param_map) {
      cstring pname = f.first;
      builder->append_format(", %s : v.%s", pname, pname);
    }
    builder->append_line("};");
    builder->append_line("matchTable.add_entry.put(tuple2(pack(key), pack(value)));");
    builder->decr_indent();
  }
  builder->append_line("endmethod");
}

void TableCodeGen::emitIntfControlFlow(const IR::P4Table* table) {
  auto actionList = table->getActionList()->actionList;
  builder->append_line("interface prev_control_state = toServer(rx_metadata.e, tx_metadata.e);");
  int idx = 0;
  for (auto action : *actionList) {
    builder->append_line("interface next_control_state_%d = toClient(bbReqFifo[%d], bbRspFifo[%d]);", idx, idx, idx);
    idx ++;
  }
}

void TableCodeGen::emitIntfVerbosity(const IR::P4Table* table) {
  builder->append_line("method Action set_verbosity(int verbosity);");
  builder->incr_indent();
  builder->append_line("cf_verbosity <= verbosity;");
  builder->decr_indent();
  builder->append_line("endmethod");
  builder->decr_indent();
}

void TableCodeGen::emit(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  auto id = table->declid % 32;
  auto actionList = table->getActionList()->actionList;
  auto nActions = actionList->size();
  CHECK_NULL(builder);
  builder->append_line("(* synthesize *)");
  builder->append_line("module mkMatchTable_256_%s(MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)));", type, id, type, type);
  builder->incr_indent();
  builder->append_line("(* hide *)");
  builder->append_line("MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)) ifc <- mkMatchTable(\"%s\");", id, type, type, name);
  builder->append_line("return ifc;");
  builder->decr_indent();
  builder->append_line("endmodule");

  builder->append_format("// =============== table %s ==============", name);
  builder->append_line("interface %s;", type);
  builder->incr_indent();
  //FIXME: more than one action;
  builder->append_line("interface Server#(MetadataRequest, MetadataResponse) prev_control_state;");
  int idx = 0;
  for (auto action : *actionList) {
    builder->append_line("interface Client#(%sActionReq, %sActionRsp) next_control_state_%d;", type, type, idx);
    idx ++;
  }
  builder->append_line("method Action add_entry(ConnectalTypes::%sReqT key, ConnectalTypes::%sRspT value);", type, type);
  builder->append_line("method Action set_verbosity(int verbosity);");
  builder->decr_indent();
  builder->append_line("endinterface");
  builder->append_line("(* synthesize *)");
  builder->append_format("module mk%s (Control::%s);", type, type);
  builder->incr_indent();
  //control->emitDebugPrint(bsv);

  builder->append_line("RX #(MetadataRequest) rx_metadata <- mkRX;");
  builder->append_line("TX #(MetadataResponse) tx_metadata <- mkTX;");
  builder->append_line("let rx_info_metadata = rx_metadata.u;");
  builder->append_line("let tx_info_metadata = tx_metadata.u;");

  builder->append_format("Vector#(%d, FIFOF#(%sActionReq)) bbReqFifo <- replicateM(mkFIFOF);", nActions, type);
  builder->append_format("Vector#(%d, FIFOF#(%sActionRsp)) bbRspFifo <- replicateM(mkFIFOF);", nActions, type);
  builder->append_line("Vector#(2, FIFOF#(PacketInstance)) packet_ff <- replicateM(mkFIFOF);");
  builder->append_line("MatchTable#(%d, 256, SizeOf#(%sReqT), SizeOf#(%sRspT)) matchTable <- mkMatchTable_256_%s;", id, type, type, type);

  emitRspFifoMux(table);
  emitRuleHandleRequest(table);
  emitRuleHandleExecution(table);
  emitRuleHandleResponse(table);
  emitIntfControlFlow(table);
  emitIntfAddEntry(table);
  emitIntfVerbosity(table);
  builder->append_line("endmodule");
}

void TableCodeGen::emitCpp(const IR::P4Table* table) {
  auto name = nameFromAnnotation(table->annotations, table->name);
  auto type = CamelCase(name);
  cbuilder->append_line("typedef uint64_t %sReqT;", type);
  cbuilder->append_line("typedef uint64_t %sRspT;", type);
  cbuilder->append_line("std::unordered_map<%sReqT, %sRspT> tbl_%s;", type, type, name);
  cbuilder->append_line("extern \"C\" %sReqT matchtable_read_%s(%sReqT rdata) {", type, camelCase(name), type);
  cbuilder->incr_indent();
  cbuilder->append_line("auto it = tbl_%s.find(rdata);", name);

  cbuilder->append_line("if (it != tbl_%s.end()) {", name);
  cbuilder->incr_indent();
  cbuilder->append_line("return tbl_%s[rdata];", name);
  cbuilder->decr_indent();
  cbuilder->append_line("} else {");
  cbuilder->incr_indent();
  cbuilder->append_line("return 0;");
  cbuilder->decr_indent();
  cbuilder->append_line("}");
  cbuilder->decr_indent();
  cbuilder->append_line("}");

  cbuilder->append_line("extern \"C\" void matchtable_write_%s(%sReqT wdata, %sRspT action){", camelCase(name), type, type);
  cbuilder->incr_indent();
  cbuilder->append_line("tbl_%s[wdata] = action;", name);
  cbuilder->decr_indent();
  cbuilder->append_line("}");
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
  if (keys != nullptr) {
    for (auto key : *keys->keyElements) {
      auto element = key->to<IR::KeyElement>();
      if (element->expression->is<IR::Member>()) {
        auto m = element->expression->to<IR::Member>();
        auto type = control->program->typeMap->getType(m->expr, true);
        if (type->is<IR::Type_Struct>()) {
          auto t = type->to<IR::Type_StructLike>();
          auto f = t->getField(m->member);
          auto f_size = f->type->to<IR::Type_Bits>()->size;
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
  }
  //FIXME: switch.p4 does not like this.
  emitTypedefs(tbl);
  emitSimulation(tbl);
  emit(tbl);
  emitCpp(tbl);

  return false;
}

}  // namespace FPGA
