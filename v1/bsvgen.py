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
import argparse, logging, json, re, os, sys, yaml
import astbsv as ast
import p4fpga, top, bsvgen_table
from sourceCodeBuilder import SourceCodeBuilder
from collections import OrderedDict
from p4c_bm import gen_json
from pkg_resources import resource_string
from bsvgen_common import emit_license, emit_import
from utils import CamelCase

# to be used for a destination file
def _validate_path(path):
    path = os.path.abspath(path)
    if not os.path.isdir(os.path.dirname(path)):
        print path, "is not a valid path because",\
            os.path.dirname(path), "is not a valid directory"
        sys.exit(1)
    if os.path.exists(path) and not os.path.isfile(path):
        print path, "exists and is not a file"
        sys.exit(1)
    return path


# to be used for a source file
def _validate_file(path):
    path = _validate_path(path)
    if not os.path.exists(path):
        print path, "does not exist"
        sys.exit(1)
    return path


def _validate_dir(path):
    path = os.path.abspath(path)
    if not os.path.isdir(path):
        print path, "is not a valid directory"
        sys.exit(1)
    return path

def generate_file(obj, filename):
    assert type(filename) is str
    builder = SourceCodeBuilder()
    obj.emit(builder)
    with open(filename, 'w') as bsv:
        bsv.write(builder.toString())

def generate_struct(ir):
    builder = SourceCodeBuilder()
    builder.appendLine("import DefaultValue::*;")
    builder.appendLine("import Utils::*;")
    builder.appendLine("import Ethernet::*;")
    for idx, p in enumerate(ir.structs.values()):
        p.emit(builder)
    with open(os.path.join('generatedbsv', 'StructGenerated.bsv'), 'w') as bsv:
        bsv.write(builder.toString())

def generate_parser(ir):
    for idx, p in enumerate(ir.parsers.values()):
        generate_file(p, os.path.join('generatedbsv', "ParserGenerated.bsv"))

def generate_deparser(ir):
    for idx, p in enumerate(ir.deparsers.values()):
        generate_file(p, os.path.join('generatedbsv', 'DeparserGenerated.bsv'))

def generate_basicblock(ir):
    for name, p in ir.basic_blocks.items():
        builder = SourceCodeBuilder()
        builder.appendLine("import ClientServer::*;")
        builder.appendLine("import ConfigReg::*;")
        builder.appendLine("import Connectable::*;")
        builder.appendLine("import UnionGenerated::*;")
        builder.appendLine("import TxRx::*;")
        builder.appendLine("import FIFOF::*;")
        builder.appendLine("import GetPut::*;")
        builder.appendLine("import Ethernet::*;")
        builder.appendLine("import Pipe::*;")
        builder.appendLine("import Utils::*;")
        builder.appendLine("import DefaultValue::*;")
        builder.appendLine("import CPU::*;")
        builder.appendLine("import IMem::*;")
        p.emit(builder);
        with open(os.path.join('generatedbsv', '%s.bsv' % (CamelCase(name))), 'w') as bsv:
            bsv.write(builder.toString())

def generate_table(ir):
    for c in ir.controls.values():
        for name, t in sorted(c.tables.items()):
            builder = SourceCodeBuilder()
            builder.appendLine("import ClientServer::*;")
            builder.appendLine("import ConfigReg::*;")
            builder.appendLine("import UnionGenerated::*;")
            builder.appendLine("import StructGenerated::*;")
            builder.appendLine("import TxRx::*;")
            builder.appendLine("import FIFOF::*;")
            builder.appendLine("import Ethernet::*;")
            builder.appendLine("import MatchTable::*;")
            builder.appendLine("import Vector::*;")
            builder.appendLine("import Pipe::*;")
            builder.appendLine("import GetPut::*;")
            builder.appendLine("import Utils::*;")
            builder.appendLine("import DefaultValue::*;")
            t.emit(builder);
            with open(os.path.join('generatedbsv', '%s.bsv' % (CamelCase(name))), 'w') as bsv:
                bsv.write(builder.toString())

def generate_union(ir):
    # tagged union BBRequest
    def emit_union_bb_request(builder):
        # emit union for basicblock req & rsp
        stmt = []
        requests = []
        for it in ir.basic_blocks.values():
            requests.append(it.request)
        if len(requests) != 0:
            union = ast.TypeDef ("union tagged", "BBRequest", requests)
            union.emit(builder)

    # tagged union BBResponse
    def emit_union_bb_response(builder):
        stmt = []
        responses = []
        for it in ir.basic_blocks.values():
            responses.append(it.response)
        if len(responses) != 0:
            union = ast.TypeDef ("union tagged", "BBResponse", responses)
            union.emit(builder)

    builder = SourceCodeBuilder()
    builder.appendLine("import Ethernet::*;")
    emit_union_bb_request(builder)
    emit_union_bb_response(builder)
    with open(os.path.join('generatedbsv', 'UnionGenerated.bsv'), 'w') as bsv:
        bsv.write(builder.toString())

def generate_pipeline(ir):
    def emit_include(builder):
        for n in ir.basic_blocks.keys():
            builder.appendLine("import %s::*;" % CamelCase(n))
        for ctrl in ir.controls.values():
            for n in ctrl.tables.keys():
                builder.appendLine("import %s::*;" % CamelCase(n))
        builder.appendLine("import UnionGenerated::*;")
    for c in ir.controls.values():
        builder = SourceCodeBuilder()
        emit_import(builder)
        emit_include(builder)
        c.emit(builder)
        emit_license(builder)
        with open(os.path.join('generatedbsv', '%s.bsv' % (CamelCase(c.name))), 'w') as bsv:
            bsv.write(builder.toString())

def main():
    argparser = argparse.ArgumentParser(
            description="P4 to Bluespec Translator")
    argparser.add_argument('source', metavar='source', type=str,
                           help='A source file to include in the P4 program.')
    argparser.add_argument('--json', dest='json', type=str,
                           help='Dump the JSON representation to this file.',
                           required=False)
    argparser.add_argument('--p4-v1.1', action='store_true',
                           help='Run the compiler on a P4 v1.1 program.',
                           default=False, required=False)
    argparser.add_argument('--mem', action='store_true',
                           help='Generate Pipeline with Shared Buffer.',
                           default=False, required=False)
    options = argparser.parse_args()

    if options.json:
        path_json = _validate_path(options.json)

    p4_v1_1 = getattr(options, 'p4_v1.1')
    if p4_v1_1:
        try:
            import p4_hlir_v1_1  # NOQA
        except ImportError:  # pragma: no cover
            print "You requested P4 v1.1 but the corresponding p4-hlir",\
                "package does not seem to be installed"
            sys.exit(1)

    if p4_v1_1:
        from p4_hlir_v1_1.main import HLIR
        primitives_res = 'primitives_v1_1.json'
    else:
        from p4_hlir.main import HLIR
        primitives_res = 'primitives.json'

    h = HLIR(options.source)

    more_primitives = json.loads(resource_string(__name__, primitives_res))
    h.add_primitives(more_primitives)

    if not h.build(analyze=False):
        print "Error while building HLIR"
        sys.exit(1)

    # frontend
    json_dict = gen_json.json_dict_create(h, None, p4_v1_1)
    if options.json:
        print "Generating json output to", path_json
        with open(path_json, 'w') as fp:
            json.dump(json_dict, fp, indent=4, separators=(',', ': '))

    # entry point for mid-end
    ir = p4fpga.ir_create(json_dict);

    if not os.path.exists("generatedbsv"):
        os.makedirs("generatedbsv")

    p4name = os.path.splitext(os.path.basename(options.source))[0]
    p4name = re.sub(r'\d+[-]+','', p4name)

    generate_struct(ir)
    generate_parser(ir)
    generate_deparser(ir)
    generate_basicblock(ir)
    generate_union(ir)
    generate_table(ir)
    generate_pipeline(ir)

    with_mem = getattr(options, 'mem')
    if with_mem:
        generate_file(top.TopMemory(p4name), os.path.join('generatedbsv', "Main.bsv"))
    else:
        generate_file(top.TopStream(p4name), os.path.join('generatedbsv', 'Main.bsv'))

    generate_file(top.API(p4name), os.path.join('generatedbsv', "MainAPI.bsv"))
    generate_file(top.Defs([]), os.path.join('generatedbsv', "MainDefs.bsv"))

    bsvgen_table.simgen()

if __name__ == "__main__":
    main()

