# Copyright 2016 Han Wang
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
from meta_ir.instance import MetaIRInstance
from bsvgen_common import emit_license

class Program(MetaIRInstance):
    ''' TODO '''
    def __init__(self, name, inputfile):
        """
        @brief mid-end IR constructor

        @param name The name of the instance
        @param input An object with the YAML description of the mid-end IR
        """
        local_dir = os.path.dirname(os.path.abspath(__file__))
        ir_meta_yml = os.path.join(local_dir, 'ir_meta.yml')
        super(Program, self).__init__(ir_meta_yml)

        self.name = name
        self.add_content(inputfile)

        # objects
        self.structs = {}
        self.tables = {}
        self.basic_blocks = {}
        self.controls = {}
        self.other_modules = {}
        self.other_processors = {}
        self.start_processor = []
        self.table_init = []

        # BIR processor layout
        for layout in self.processor_layout.values():
            if layout['format'] != 'list':
                logging.error("unsupported layout format")
                exit(1)

            last_proc = None
            for proc_name in layout['implementation']:
                curr_proc = self._get_processor(proc_name)
                if last_proc == None:
                    self.start_processor = curr_proc
                else:
                    last_proc.next_processor = curr_proc
                last_proc = curr_proc

    def _get_processor(self, name):
        if name in self.controls.keys():
            return self.controls[name]
        elif name in self.other_processors.keys():
            return self.other_processors[name]
        else:
            raise BIRError("unknown processor: {}".format(name))

    def build(self):
        """
        Build IR objects in P4 program
        """
        #for name, val in self.struct.items():
        #    self.bir_structs[name] = BSVBIRStruct(name, val)
        #for name, val in self.table.items():
        #    print 'table', name
        #    self.bir_tables[name] = BSVTable(name, val)
        #for name, val in self.other_module.items():
        #    for operation in val['operations']:
        #        module = "{}.{}".format(name, operation)
        #        self.bir_other_modules[module] = self._load_module(name, operation)
        #for name, val in self.basic_block.items():
        #    self.bir_basic_blocks[name] = BSVBasicBlock(name, val,
        #                                                self.bir_structs,
        #                                                self.bir_tables,
        #                                                self.bir_other_modules,
        #                                                bir_parser)

    def emit_structs(self, builder):
        for it in self.structs.values():
            it.emit(builder)

    def emit_basic_blocks(self, builder):
        for it in self.basic_blocks.values():
            it.emit(builder)

    def emit_tables(self, builder):
        for it in self.tables:
            it.emit(builder)

    def emit_controls(self, builder):
        for it in self.controls.values():
            it.emit(builder)

    def emit(self, builder, noisyFlag):
        """
        Emit Mid-end IR to BSV
        """
        self.emit_structs(builder)
        self.emit_basic_blocks(builder)
        self.emit_controls(builder)
        emit_license(builder)

