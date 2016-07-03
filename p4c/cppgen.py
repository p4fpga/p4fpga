# Copyright 2016 P4FPGA Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import os, sys, utils

def emitType(ksz):
    assert type(ksz) is int
    if ksz <= 16:
        return "uint16_t"
    elif ksz <= 32:
        return "uint32_t"
    elif ksz <= 64:
        return "uint64_t"
    else:
        return "uint32_t*"

def generate_tables(name, ksz, vsz, generated_cpp):
    reqT = utils.CamelCase(name) + "ReqT"
    rspT = utils.CamelCase(name) + "RspT"
    generated_cpp.write("typedef %s %s;\n" % (emitType(ksz), reqT))
    generated_cpp.write("typedef %s %s;\n" % (emitType(vsz), rspT))
    generated_cpp.write("std::unordered_map<%s, %s> %s_table;\n" %(reqT, rspT, name))
    generated_cpp.write("extern \"C\" %s matchtable_read_%s(%s rdata)\n" %(rspT, name, reqT))
    generated_cpp.write("{\n")
    generated_cpp.write("   auto it = %s_table.find(rdata);\n" % (name))
    generated_cpp.write("   if (it != %s_table.end()) {\n" % (name))
    generated_cpp.write("       return %s_table[rdata];\n" % (name))
    generated_cpp.write("   } else {\n")
    generated_cpp.write("       return 0;\n")
    generated_cpp.write("   }\n")
    generated_cpp.write("}\n")
    generated_cpp.write("extern \"C\" void matchtable_write_%s(%s wdata, %s action)\n" % (name, reqT, rspT))
    generated_cpp.write("{\n")
    generated_cpp.write("   %s_table[wdata] = action;\n" % (name))
    generated_cpp.write("}\n")

def generate_cpp(project_dir, noisyFlag, jsondata):
    global verbose
    def create_cpp_file(name):
        fname = os.path.join(project_dir, 'jni', name)
        f = utils.createDirAndOpen(fname, 'w')
        if verbose:
            print "Writing file ", fname
        return f

    verbose = noisyFlag
    generatedCFiles = []
    cppname = "matchtable_model.cpp"
    generated_cpp = create_cpp_file(cppname)
    generatedCFiles.append(generated_cpp)
    generated_cpp.write("#include <iostream>\n")
    generated_cpp.write("#include <unordered_map>\n")
    generated_cpp.write("#ifdef __cplusplus\n")
    generated_cpp.write("extern \"C\" {\n")
    generated_cpp.write("#endif\n")
    generated_cpp.write("#include <stdio.h>\n")
    generated_cpp.write("#include <stdlib.h>\n")
    generated_cpp.write("#include <string.h>\n")
    generated_cpp.write("#include <stdint.h>\n")

    for cfg in jsondata:
        name = cfg['name']
        ksz = cfg['ksz']
        vsz = cfg['vsz']
        generate_tables(name, ksz, vsz, generated_cpp)

    generated_cpp.write("#ifdef __cplusplus\n")
    generated_cpp.write("}\n")
    generated_cpp.write("#endif\n")
    generated_cpp.close()
    return generatedCFiles
