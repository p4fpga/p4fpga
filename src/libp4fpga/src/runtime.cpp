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

// runtime implements either streaming or shared memory support
//

namespace FPGA {

class Runtime : public FPGAObject {
 protected:
  int num_ports;
  cstring type;
  cstring device; // Xilinx or Altera
  explicit Runtime() {}
 public:
  enum Mode{
    STREAM,
    MEMORY
  };
  virtual void emit() {}
};

// emit Runtime.bsv
class StreamingRuntime : public Runtime {
  // emit
  void emit() {
    // instantiate PHY
    // instantiate MAC
    // instantiate TX/RX Ring ??
    // instantiate PktGen/PktCap
    // create Runtime API
  }
};

class SharedMemoryRuntime : public Runtime {
  void emit() {
    // instantiate PHY
    // instantiate MAC
    // instantiate Shared Memory
    // instantiate TX/RX Ring ??
    // instantiate PktGen/PktCap
    // create Runtime API
  }
};

}  // namespace FPGA
