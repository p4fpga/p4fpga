#pragma once

#include "codebuilder.h"

namespace FPGA {

  class BSVProgram
  {
  public:
    BSVProgram() { }
    CodeBuilder& getParserBuilder() { return parserBuilder_; }
    CodeBuilder& getHeaderBuilder() { return headerBuilder_; }
    CodeBuilder& getStructBuilder() { return structBuilder_; }
    CodeBuilder& getUnionBuilder()  { return unionBuilder_; }
    CodeBuilder& getStateBuilder()  { return stateBuilder_; }

  private:
    CodeBuilder parserBuilder_;
    CodeBuilder headerBuilder_;
    CodeBuilder structBuilder_;
    CodeBuilder unionBuilder_;
    CodeBuilder stateBuilder_;    
  };        
} // namespace FPGA
