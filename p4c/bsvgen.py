# Copyright 2016 Han Wang
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
import argparse
import json
import logging
import os
import sys
import yaml
import p4fpga

from collections import OrderedDict
from p4c_bm import gen_json
from pkg_resources import resource_string
from lib.sourceCodeBuilder import SourceCodeBuilder

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
    argparser.add_argument('--output', '-o', type=str,
                           help='Output BSV file.')
    options = argparser.parse_args()

    if options.json:
        path_json = _validate_path(options.json)

    if options.output:
        path_output = _validate_path(options.output)

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

    noisyFlag = os.environ.get('D') == '1'
    #if noisyFlag:
    #    with open("generatedPipeline.json", "w") as fp:
    #        json.dump(ir, fp, indent=4, separators=(',', ': '))

    # entry point for backend
    builder = SourceCodeBuilder()
    try:
        ir.emit(builder, noisyFlag)
    except CompilationException, e:
        print "BUG:", e.show()
        sys.exit(1)

    if os.path.dirname(options.output) and \
        not os.path.exists(os.path.dirname(options.output)):
        os.makedirs(os.path.dirname(options.output))

    if options.output:
        with open(path_output, 'w') as bsv:
            bsv.write(builder.toString())

if __name__ == "__main__":
    main()

