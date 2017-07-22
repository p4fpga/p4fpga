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

class FPGAOptions : public CompilerOptions {
 public:
  std::vector<cstring> partitions;
  bool dumpTable = false;
  cstring runtime = nullptr;
  FPGAOptions() {
    registerOption("-P", "partition1[,partition2]",
                   [this](const char *arg) {
                      auto copy = strdup(arg);
                      while (auto partition = strsep(&copy, ","))
                        partitions.push_back(partition);
                      return true;},
                   "Partition control flow at specific table id");
    registerOption("--profile", nullptr,
                   [this](const char*) { dumpTable = true; return true; },
                   "Dump table resource utilization");
    registerOption("-R", "runtime",
                   [this](const char* arg) {
                      runtime = arg; return true; },
                   "Runtime type (stream/sharedmem)");
  }
};

#endif
