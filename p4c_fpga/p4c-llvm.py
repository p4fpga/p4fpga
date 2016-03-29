#!/usr/bin/env python

import argparse
import os
import traceback
import sys
from p4_hlir.main import HLIR
from compilationException import *
from programSerializer import ProgramSerializer
import llvmProgram
import llvmlite.ir as llvmIR

def get_parser():
    parser = argparse.ArgumentParser(description='p4c-llvm arguments')
    parser.add_argument('source', metavar='source', type=str,
                        help='a P4 source file to compile')
    parser.add_argument('-emit-llvm', dest='emit_llvm', action='store_true',
                        help='Use the LLVM representation for codegen')
    return parser


def process(input_args):
    parser = get_parser()
    args, unparsed_args = parser.parse_known_args(input_args)

    has_remaining_args = False
    preprocessor_args = []
    for a in unparsed_args:
        if a[:2] == "-D" or a[:2] == "-I" or a[:2] == "-U":
            input_args.remove(a)
            preprocessor_args.append(a)
        else:
            has_remaining_args = True

    # trigger error
    if has_remaining_args:
        parser.parse_args(input_args)

    print("*** Compiling ", args.source)
    return compileP4(args.source, args.emit_llvm, preprocessor_args)


class CompileResult(object):
    def __init__(self, kind, error):
        self.kind = kind
        self.error = error

    def __str__(self):
        if self.kind == "OK":
            return "Compilation successful"
        else:
            return "Compilation failed with error: " + self.error


def compileP4(inputFile, gen_file, preprocessor_args):
    h = HLIR(inputFile)

    for parg in preprocessor_args:
        h.add_preprocessor_args(parg)
    if not h.build():
        return CompileResult("HLIR", "Error while building HLIR")

    try:
        basename = os.path.basename(inputFile)
        basename = os.path.splitext(basename)[0]

        e = llvmProgram.LLVMProgram(basename, h)
        serializer = ProgramSerializer()
        e.tollvm(serializer)
        f = open(basename+'.ll', 'w')
        f.write(str(e.module))
        bsv = open(basename.capitalize()+'.bsv', 'w')
        bsv.write(serializer.toString())
        return CompileResult("OK", "")
    except CompilationException, e:
        prefix = ""
        if e.isBug:
            prefix = "### Compiler bug: "
        return CompileResult("bug", prefix + e.show())
    except NotSupportedException, e:
        return CompileResult("not supported", e.show())
    except:
        return CompileResult("exception", traceback.format_exc())


# main entry point
if __name__ == "__main__":
    result = process(sys.argv[1:])
    if result.kind != "OK":
        print(str(result))
