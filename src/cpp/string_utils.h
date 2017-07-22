// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef FPGA_STRING_UTILS_H
#define FPGA_STRING_UTILS_H

#include <string>
#include <vector>
#include <sstream>
#include <string.h>
#include "lib/cstring.h"

namespace FPGA {

/// Return `source` as a_string_in_snake_case.
/// https://en.wikipedia.org/wiki/Snake_case
cstring SnakeCase(const cstring& source);

/// Return `source` as AStringInCamelCase.
/// https://en.wikipedia.org/wiki/CamelCase
cstring CamelCase(const cstring& source);

/// Return `source` as aStringInCamelCase.
cstring camelCase(const cstring& source);

/// Return `source` as ASTRINGINUPPERCASE.
cstring UpperCase(const cstring& source);

/// Return `source` with '.' replaced with '$'
cstring RemoveDot(const cstring& source);

// join a vector of elements by a delimiter object.  ostream<< must be defined
// for both class S and T and an ostream, as it is e.g. in the case of strings
// and character arrays
template<class S, class T>
std::string join(std::vector<T>& elems, S& delim) {
std::stringstream ss;
typename std::vector<T>::iterator e = elems.begin();
  ss << *e++;
  for (; e != elems.end(); ++e) {
    ss << delim << *e;
  }
  return ss.str();
}

}  // namespace FPGA
#endif  // FPGA_STRING_UTILS_H
