# Copyright (c) 2016 P4FPGA Project
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

import astbsv as ast
import bsvgen_common
import logging
import config
import sourceCodeBuilder
from utils import CamelCase, p4name, GetHeaderWidth
from ast_util import apply_pdict, apply_action_block, apply_if_verbosity

logger = logging.getLogger(__name__)

class Deparser(object):
    def __init__(self, deparse_states):
        self.deparse_states = deparse_states
        self.intf = None

    def funct_compute_next_state(self, state):
        TMP1 = "DeparserState nextState = StateDeparseStart;"
        TMP2 = "return nextState;"
        stmt = []
        stmt.append(ast.Template(TMP1))
        stmt.append(ast.Template(TMP2))
        fname = "compute_next_state"
        rtype = "DeparserState"
        params = "DeparserState state"
        funct = ast.Function(fname, rtype, params, stmt)
        return funct

    def rule_state_load(self, state, width):
        tmpl = []
        tmpl.append("rg_tmp[0] <= zeroExtend(data_this_cycle) << rg_shift_amt[0] | rg_tmp[0];")
        tmpl.append("UInt#(NumBytes) n_bytes_used = countOnes(mask_this_cycle);")
        tmpl.append("UInt#(NumBits) n_bits_used = cExtend(n_bytes_used) << 3;")
        tmpl.append("move_buffered_amt(cExtend(n_bits_used));")
        rname = "rl_deparse_%s_load" % (state.translate(None, "[]"))
        rcond = "(deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] < %d)" % (CamelCase(state), width)
        stmt = apply_pdict(tmpl, {})
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def rule_state_send(self, state, width):
        tmpl = []
        tmpl.append("succeed_and_next(%d);" % width)
        tmpl.append("deparse_state_ff.deq;")
        rname = "rl_deparse_%s_send" % (state.translate(None, "[]"))
        rcond = "(deparse_state_ff.first == StateDeparse%s) && (rg_buffered[0] >= %d)" % (CamelCase(state), width)
        stmt = apply_pdict(tmpl, {})
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def rule_state_next(self, state, width):
        tmpl = []
        tmpl.append("deparse_state_ff.enq(StateDeparse%s);" % CamelCase(state))
        tmpl.append("fetch_next_header(%d);" % width)
        rname = "rl_deparse_%s_next" % (state.translate(None, "[]"))
        rcond = "w_deparse_%s" % (state.translate(None, "[]"))
        stmt = apply_pdict(tmpl, {})
        rule = ast.Rule(rname, rcond, stmt)
        return rule

    def build_rules(self):
        stmt = []
        stmt.append(ast.Template('`ifdef DEPARSER_RULES\n'))
        for idx, s in enumerate(self.deparse_states):
            stmt.append(self.rule_state_next(s, GetHeaderWidth(s)))
            stmt.append(self.rule_state_load(s, GetHeaderWidth(s)))
            stmt.append(self.rule_state_send(s, GetHeaderWidth(s)))
        stmt.append(ast.Template('`endif // DEPARSER_RULES\n'))
        return stmt

    def build_struct(self):
        stmt = []
        stmt.append(ast.Template('`ifdef DEPARSER_STRUCT\n'))
        elem = []
        elem.append(ast.EnumElement("StateDeparseStart", None, None))
        for state in self.deparse_states:
            elem.append(ast.EnumElement("StateDeparse%s" % (CamelCase(state)), None, None))
        state = ast.Enum("DeparserState", elem)
        stmt.append(state)
        stmt.append(ast.Template('`endif // DEPARSER_STRUCT\n'))
        return stmt

    def build_state(self):
        stmt = []
        stmt.append(ast.Template("`ifdef DEPARSER_STATE\n"))
        for idx, state in enumerate(self.deparse_states):
            stmt.append(ast.Template("PulseWire w_deparse_%(name)s <- mkPulseWire();\n", {'name': state.translate(None, "[]")}))
        stmt.append(ast.Template("`endif // DEPARSER_STATE\n"))
        return stmt

    def emit(self, builder):
        for s in self.build_struct():
            s.emit(builder)
        for s in self.build_rules():
            s.emit(builder)
        for s in self.build_state():
            s.emit(builder)
