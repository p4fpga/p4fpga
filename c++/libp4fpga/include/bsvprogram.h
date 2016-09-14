#pragma once

#include "codebuilder.h"

namespace FPGA {

class BSVProgram {
 public:
  BSVProgram() { }
  CodeBuilder& getParserBuilder() { return parserBuilder_; }
  CodeBuilder& getDeparserBuilder() { return deparserBuilder_; }
  CodeBuilder& getStructBuilder() { return structBuilder_; }
  CodeBuilder& getUnionBuilder()  { return unionBuilder_; }
  CodeBuilder& getControlBuilder() { return controlBuilder_; }

 private:
  CodeBuilder parserBuilder_;
  CodeBuilder deparserBuilder_;
  CodeBuilder structBuilder_;
  CodeBuilder unionBuilder_;
  CodeBuilder controlBuilder_;
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
