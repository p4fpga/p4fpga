
#ifndef EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_
#define EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_

#include "ir/ir.h"
#include "fprogram.h"

namespace FPGA {

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
  graph.getGraphBuilder().emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  graph.getGraphBuilder().appendFormat(s.c_str());
  graph.getGraphBuilder().newline();
}

template <typename... TArgs>
  void append_line(Graph & graph, const char* fmt, TArgs&&... args) {
    graph.getGraphBuilder().emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    graph.getGraphBuilder().appendLine(s.c_str());
  }

inline void incr_indent(Graph & graph) {
  graph.getGraphBuilder().increaseIndent();
}

inline void decr_indent(Graph & graph) {
  graph.getGraphBuilder().decreaseIndent();
}

}  // namespace Graph


class FPGAControl : public FPGAObject {
 public:
    const FPGAProgram*            program;
    const IR::ControlBlock*       controlBlock;

    std::map<cstring, IR::P4Action*>   actions;
    std::map<const IR::StructField*, std::set<const IR::P4Table*>> metadata_to_table;
    std::map<const IR::StructField*, cstring> metadata_to_action;
    std::map<cstring, const IR::P4Table*> action_to_table;
    std::map<const IR::P4Table*, std::set<std::pair<const IR::StructField*, const IR::P4Table*> > > adj_list;

    explicit FPGAControl(const FPGAProgram* program, const IR::ControlBlock* block)
      : program(program), controlBlock(block) {}

    virtual ~FPGAControl() {}
    void emit(BSVProgram & bsv);
    void plot_v_table_e_meta(Graph & graph);
    void plot_v_meta_e_table(Graph & graph);
    // void emitDeclaration(const IR::Declaration* decl, CodeBuilder *builder);
    // void emitTables(CodeBuilder* builder);
    bool build();
};

}  // namespace FPGA

#endif /* EXTENSIONS_CPP_LIBP4FPGA_INCLUDE_FCONTROL_H_ */
