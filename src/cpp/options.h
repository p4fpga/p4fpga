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

#ifndef FPGA_OPTIONS_H
#define FPGA_OPTIONS_H

#include <getopt.h>
#include <frontends/common/options.h>

class FPGAOptions : public P4::CompilerOptions {
 public:
  std::vector<P4::cstring> partitions;
  bool dumpTable = false;
  P4::cstring runtime = nullptr;
  P4::cstring outputFile = nullptr;
  FPGAOptions() {
    registerOption("-P", "partition1[,partition2]",
                   [this](const char *arg) {
                      auto copy = strdup(arg);
                      while (auto partition = strsep(&copy, ","))
                        partitions.push_back(P4::cstring(partition));
                      return true;},
                   "Partition control flow at specific table id");
    registerOption("--profile", nullptr,
                   [this](const char*) { dumpTable = true; return true; },
                   "Dump table resource utilization");
    registerOption("-R", "runtime",
                   [this](const char* arg) {
                      runtime = P4::cstring(arg); return true; },
                   "Runtime type (stream/sharedmem)");
    registerOption("-o", "outfile", [this](const char *arg)
                   { outputFile = P4::cstring(arg); return true; },
                   "Write output to outfile");
  }
};

using FPGAContext = P4::P4CContextWithOptions<FPGAOptions>;


#endif
