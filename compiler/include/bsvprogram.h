//#pragma once

#ifndef P4FPGA_INCLUDE_BSVPROGRAM_H_
#define P4FPGA_INCLUDE_BSVPROGRAM_H_

#include "ir/ir.h"
#include "lib/sourceCodeBuilder.h"
#include "frontends/p4/typeMap.h"

namespace FPGA {

class CodeBuilder : public Util::SourceCodeBuilder {
 public:
    explicit CodeBuilder() {}

    template <typename... TArgs>
    void append_line(const char* fmt, TArgs&&... args);

    template <typename... TArgs>
    void append_format(const char* fmt, TArgs&&... args);

    void incr_indent() { increaseIndent(); }
    void decr_indent() { decreaseIndent(); }

    template <typename TValue, typename... TArgs>
      std::string format_string(boost::format& message, TValue&& arg, TArgs&&... args);
    std::string format_string(boost::format& message) { return message.str(); };
};

template <typename TValue, typename... TArgs>
  std::string CodeBuilder::format_string(boost::format& message, TValue&& arg, TArgs&&... args) {
  message % std::forward<TValue>(arg);
  return format_string(message, std::forward<TArgs>(args)...);
}

template <typename... TArgs>
  void CodeBuilder::append_format(const char* fmt, TArgs&&... args) {
  emitIndent();
  boost::format msg(fmt);
  std::string s = format_string(msg, std::forward<TArgs>(args)...);
  appendFormat(s.c_str());
  newline();
}

template <typename... TArgs>
  void CodeBuilder::append_line(const char* fmt, TArgs&&... args) {
    emitIndent();
    boost::format msg(fmt);
    std::string s = format_string(msg, std::forward<TArgs>(args)...);
    appendLine(s.c_str());
  }

class BSVProgram {
 public:
  BSVProgram() { }
  CodeBuilder& getParserBuilder() { return parserBuilder_; }
  CodeBuilder& getDeparserBuilder() { return deparserBuilder_; }
  CodeBuilder& getStructBuilder() { return structBuilder_; }
  CodeBuilder& getUnionBuilder()  { return unionBuilder_; }
  CodeBuilder& getControlBuilder() { return controlBuilder_; }
  CodeBuilder& getAPIDefBuilder() { return apiDefBuilder_; }
  CodeBuilder& getAPIDeclBuilder() { return apiDeclBuilder_; }
  CodeBuilder& getProgDeclBuilder() { return progDeclBuilder_; }
  CodeBuilder& getConnectalTypeBuilder() { return connectalTypeBuilder_; }

 private:
  CodeBuilder parserBuilder_;
  CodeBuilder deparserBuilder_;
  CodeBuilder structBuilder_;
  CodeBuilder unionBuilder_;
  CodeBuilder controlBuilder_;
  CodeBuilder apiDefBuilder_;
  CodeBuilder apiDeclBuilder_;
  CodeBuilder progDeclBuilder_;
  CodeBuilder connectalTypeBuilder_;
};

class CppProgram {
 public:
  CppProgram() {}
  CodeBuilder& getSimBuilder() { return simBuilder_; }
 private:
  CodeBuilder simBuilder_;
};

class Profiler {
 public:
  Profiler() {}
  CodeBuilder& getTableProfiler() { return tableProfiler_; }
 private:
  CodeBuilder tableProfiler_;
};

class Partitioner {
 public:
  Partitioner() {}
  CodeBuilder& getPartitioner() { return p4Partitioner_; }
 private:
  CodeBuilder p4Partitioner_;
};

} // namespace FPGA

#endif  /* P4FPGA_INCLUDE_BSVPROGRAM_H_ */
