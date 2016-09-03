#pragma once

#include "codebuilder.h"

namespace FPGA {

  class BSVProgram
  {
  public:
    BSVProgram() { }
    CodeBuilder& getParserBuilder() { return parserBuilder_; }
    CodeBuilder& getDeparserBuilder() { return deparserBuilder_; }
    CodeBuilder& getHeaderBuilder() { return headerBuilder_; }
    CodeBuilder& getStructBuilder() { return structBuilder_; }
    CodeBuilder& getUnionBuilder()  { return unionBuilder_; }
    CodeBuilder& getStateBuilder()  { return stateBuilder_; }

  private:
    CodeBuilder parserBuilder_;
    CodeBuilder deparserBuilder_;
    CodeBuilder headerBuilder_;
    CodeBuilder structBuilder_;
    CodeBuilder unionBuilder_;
    CodeBuilder stateBuilder_;
  };

  class Graph {
   public:
    Graph() { }
    CodeBuilder& getGraphBuilder() { return graphBuilder_; }
   private:
    CodeBuilder graphBuilder_;
  };
} // namespace FPGA
