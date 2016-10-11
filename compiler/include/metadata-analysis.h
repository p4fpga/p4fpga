#ifndef _BACKENDS_P4_METADATA_ANALYSIS_H_
#define _BACKENDS_P4_METADATA_ANALYSIS_H_

#include "ir/ir.h"
#include "lib/sourceCodeBuilder.h"
#include "frontends/p4/typeChecking/typeChecker.h"

namespace P4 {

class Graph : public Util::SourceCodeBuilder {
 public:
  Graph() {}
};

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

class DoMetadataAnalysis : public Inspector {
  const ReferenceMap* refMap;
  const TypeMap*      typeMap;

  std::map<cstring, IR::P4Action*>   actions;
  std::map<const IR::StructField*, std::set<const IR::P4Table*>> metadata_to_table;
  std::map<const IR::StructField*, cstring> metadata_to_action;
  std::map<cstring, const IR::P4Table*> action_to_table;
  std::map<const IR::P4Table*, std::set<std::pair<const IR::StructField*, const IR::P4Table*> > > adj_list;
 public:
  DoMetadataAnalysis(const ReferenceMap* refMap, const TypeMap* typeMap) :
          refMap(refMap), typeMap(typeMap)
  { CHECK_NULL(refMap); CHECK_NULL(typeMap); setName("DoMetadataAnalysis"); }
  bool preorder(const IR::TableBlock* table) override;
  bool preorder(const IR::AssignmentStatement* stmt) override;
  bool preorder(const IR::Expression* expression) override;

  void plot_v_table_e_meta(Graph & graph);
  void plot_v_meta_e_table(Graph & graph);
};


class MetadataAnalysis: public PassManager {
 public:
  MetadataAnalysis(ReferenceMap* refMap, TypeMap* typeMap) {
    passes.push_back(new TypeChecking(refMap, typeMap));
    passes.push_back(new DoMetadataAnalysis(refMap, typeMap));
    setName("Metadata Analysis");
  }
};

}  // namespace P4

#endif /* _BACKENDS_P4_METADATA_ANALYSIS_H_ */
