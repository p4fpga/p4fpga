#include "metadata-analysis.h"
#include "vector_utils.h"

namespace P4 {

namespace Dot {
inline static std::string format_string(boost::format& message) {
  return message.str();
}

template <typename TValue, typename... TArgs>
  std::string format_string(boost::format& message, TValue&& arg, TArgs&&... args) {
  message % std::forward<TValue>(arg);
  return format_string(message, std::forward<TArgs>(args)...);
}

template <typename... TArgs>
  void append_format(Graph & graph, const char* fmt, TArgs&&... args) {
  graph.emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  graph.appendFormat(s.c_str());
  graph.newline();
}

template <typename... TArgs>
  void append_line(Graph & graph, const char* fmt, TArgs&&... args) {
    graph.emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    graph.appendLine(s.c_str());
  }

inline void incr_indent(Graph & graph) {
  graph.increaseIndent();
}

inline void decr_indent(Graph & graph) {
  graph.decreaseIndent();
}

}  // namespace Dot

bool DoMetadataAnalysis::preorder(const IR::TableBlock* table) {
  // LOG1("Table " << table);
  for (auto act : *table->container->getActionList()->actionList) {
    auto element = act->to<IR::ActionListElement>();
    if (element->expression->is<IR::PathExpression>()) {
      //LOG1("Path " << element->expression->to<IR::PathExpression>());
    } else if (element->expression->is<IR::MethodCallExpression>()) {
      auto expression = element->expression->to<IR::MethodCallExpression>();
      auto type = typeMap->getType(expression->method, true);
      auto action = expression->method->toString();
      action_to_table[action] = table->container;
    }
  }

  // visit keys
  auto keys = table->container->getKey();
  if (keys == nullptr) return false;

  for (auto key : *keys->keyElements) {
    auto element = key->to<IR::KeyElement>();
    if (element->expression->is<IR::Member>()) {
      auto m = element->expression->to<IR::Member>();
      auto type = typeMap->getType(m->expr, true);
      if (type->is<IR::Type_Struct>()) {
        auto t = type->to<IR::Type_StructLike>();
        //LOG1("header meta " << t->getField(m->member) << " " << table);
        auto f = t->getField(m->member);
        metadata_to_table[f].insert(table->container);
      }
    }
  }
  return false;
}

bool DoMetadataAnalysis::preorder(const IR::AssignmentStatement* stmt) {
  //LOG1("assignment " << stmt->left << stmt->right);
  visit(stmt->left);
  //FIXME: only take care of metadata write
  // visit(stmt->right);
  return false;
}

bool DoMetadataAnalysis::preorder(const IR::Expression* expression) {
  // accessing part of metadata struct, thus member type
  if (expression->is<IR::Member>()) {
    auto m = expression->to<IR::Member>();
    auto type = typeMap->getType(m->expr, true);
    if (type->is<IR::Type_Struct>()) {
      auto t = type->to<IR::Type_StructLike>();
      auto f = t->getField(m->member);
      //metadata_to_action[f] = name; //FIXME: action?
    }
  }
  return false;
}

// table as vertex, metadata as edge
void DoMetadataAnalysis::plot_v_table_e_meta(Graph & graph) {
  Dot::append_line(graph, "graph g {");
  Dot::append_line(graph, "concentrate=true;");
  Dot::incr_indent(graph);
  for (auto n : adj_list) {
    for (auto m : n.second) {
      Dot::append_format(graph, "%s -- %s [ label = \"%s\"];", n.first->name.toString(), m.second->name.toString(), m.first);
      //Dot::append_format(graph, "%s -- %s;", n.first->name.toString(), m.second->name.toString());
    }
  }
  Dot::decr_indent(graph);
  Dot::append_line(graph, "}");
}

// metadata as vertex, table as edge
void DoMetadataAnalysis::plot_v_meta_e_table(Graph & graph) {
  std::map<const IR::StructField*, int> weight;
  int metadata_total_width = 0;
  Dot::append_line(graph, "graph g {");
  Dot::append_line(graph, "concentrate=true;");
  Dot::incr_indent(graph);
  for (auto n : metadata_to_table) {
    if (n.first->type->is<IR::Type_Bits>()) {
      auto width = n.first->type->to<IR::Type_Bits>()->size;
      // LOG1(n.first << " " << width);
      metadata_total_width += width;
    }
    for (auto m : metadata_to_table) {
      if (m == n) continue;
      for (auto t : n.second) {
        std::set<const IR::P4Table*>::iterator it;
        it = m.second.find(t);
        if (it != m.second.end()) {
          //Dot::append_format(graph, "%s -- %s [ label = \"%s\"];", n.first->name.toString(), m.first->name.toString(), t->name.toString());
          weight[n.first]++;
        }
      }
    }
  }
  LOG1("Total metadata width " << metadata_total_width);
  Dot::decr_indent(graph);
  Dot::append_line(graph, "}");
}


}  // namespace P4
