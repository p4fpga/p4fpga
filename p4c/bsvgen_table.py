# Copyright (c) 2016 Han Wang
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

import logging
from bsvgen_common import generate_table
from lib.sourceCodeBuilder import SourceCodeBuilder
from lib.utils import CamelCase
import lib.ast as ast

logger = logging.getLogger(__name__)

TBL_TEMPLATE = "MatchTable#(%(sz)s, SizeOf#(%(reqT)s), SizeOf#(%(rspT)s) tbl <- mkMatchTable();"

IRQ_TEMPLATE = """Vector#(%(sz)s, Bool) readyBits = map(fifoNotEmpty, %(fifo)s);
    Bool interruptStatus = False;
    Bit#(16) readyChannel = -1;
    for (Integer i=%(szminus1)s; i>=0; i=i-1) begin
        if (readyBits[i]) begin
            interruptStatus = True;
            readyChannel = fromInteger(i);
        end
    end
"""

class Table(object):
    required_attributes = ["name", "match_type", "max_size", "key", "actions"]
    def __init__(self, table_attrs):
        #check_attributes(name, table_attrs, Table.required_attributes)
        self.name = table_attrs["name"]
        self.match_type = table_attrs['match_type']
        self.depth = table_attrs['max_size']
        self.key = table_attrs.get('key', None)
        #self.req_attrs = table_attrs['request']
        #self.rsp_attrs = table_attrs['response']
        self.actions = table_attrs.get('actions', None)

    def __repr__(self):
        return "{} ({}, {}, {}, {})".format(
                    self.__class__.__name__,
                    self.match_type,
                    self.depth,
                    self.key,
                    self.actions)

    def buildStmt(self):
        stmt = []
        pdict = {"sz": 256, "reqT": "ReqT", "rspT": "RspT"}
        stmt.append(ast.Template(TBL_TEMPLATE, pdict))
        pdict = {"sz": 16, "szminus1": 15, "fifo": "pipeout"}
        stmt.append(ast.Template(IRQ_TEMPLATE, pdict))
        return stmt

    def buildRuleRequest(self):
        pass

    def buildRuleExecuteAction(self):
        pass

    def buildRuleResponse(self):
        pass

    def emitTableInterface(self, builder):
        logger.info("emitTable: {}".format(self.name))

        iname = CamelCase(self.name)
        table_intf = ast.Interface(iname, None, [], None)

        subintf_s = ast.Interface("prev_control_state_{}".format(0), None, [],
                    "Server #(BBRequest, BBResponse)") #FIXME
        table_intf.subinterfaces.append(subintf_s)

        subintf_c = ast.Interface("next_control_state_{}".format(0), None, [],
                    "Client #(BBRequest, BBResponse)")
        table_intf.subinterfaces.append(subintf_c)

        table_intf.emit(builder)

    def emitModule(self, builder):
        # module ast
        logger.info("emitModule: {}".format(self.name))
        mname = "mk{}".format(CamelCase(self.name))
        iname = CamelCase(self.name)
        params = []
        provisos = []
        decls = []
        stmt = self.build_stmt()
        module = ast.Module(mname, params, iname, provisos, decls, stmt)
        module.emit(builder)

    def emitRuleRequest(self):
        pass

    def emitRuleExecuteAction(self):
        pass

    def emitRuleResponse(self):
        pass

    def emitKeyType(self, builder):
        builder.emitIndent()

    def emitValueType(self, builder):
        pass

    def emit(self, builder):
        assert isinstance(builder, SourceCodeBuilder)
        self.emitKeyType(builder)
        self.emitValueType(builder)
        self.emitTableInterface(builder)
        self.emitModule(builder)

