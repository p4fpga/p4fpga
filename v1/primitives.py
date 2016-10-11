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

import math
import astbsv as ast
from utils import CamelCase, GetFieldWidth, p4name
import primitives as prm

def get_reg_array_size(name, json_dict):
    for array in json_dict['register_arrays']:
        if array['name'] == name:
            bitwidth = array['bitwidth']
            size = array['size']
            return bitwidth, int(math.log(size+1, 2))

class Primitive(object):
    """
    base class for primitive
    """
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self): return []
    def buildFFs(self): return []
    def buildTXRX(self, json_dict): return []
    def buildInterface(self, json_dict): return []
    def buildInterfaceDef(self): return []

    def buildRequest(self, json_dict, runtime_data): return []
    def buildResponse(self): return []
    def buildTempReg(self, json_dict): return []
    def readTempReg(self, json_dict): return []
    def getDstReg(self, json_dict): return None

class ModifyField(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def __repr__(self):
        return "%s %s" %(self.op, self.parameters)

    def buildTempReg(self, json_dict=None):
        TMP1 = "Reg#(Bit#(%(dsz)s)) %(field)s <- mkReg(0);"
        stmt = []
        dst_value = self.parameters[0]['value']
        dst_type = self.parameters[0]['type']
        field = p4name(dst_value)
        dsz = GetFieldWidth(dst_value)
        if dsz < 64: #FIXME: only support 64-bit for now
            dsz = 64
        pdict = {"dsz": dsz, "field": field}
        stmt.append(ast.Template(TMP1, pdict))
        return stmt

    def readTempReg(self, json_dict=None):
        TMP1 = "Bit#(%(dsz)s) %(field)s = %(funct)s(%(tmpReg)s);"
        stmt = []
        dst_value = self.parameters[0]['value']
        dst_type = self.parameters[0]['type']
        dsz = GetFieldWidth(dst_value)
        pdict = {'dsz': dsz,
                 'field': dst_value[1],
                 'tmpReg': p4name(dst_value),
                 'funct' : "truncate" if (dsz < 64) else "" }
        stmt.append(ast.Template(TMP1, pdict))
        return stmt

    def buildRequest(self, json_dict=None, runtime_data=None):
        TMP1 = "%s <= %s;"
        stmt = []
        src_value = self.parameters[1]['value']
        src_type = self.parameters[1]['type']
        dst_value = self.parameters[0]['value']
        dst_type = self.parameters[0]['type']
        if src_type == 'runtime_data':
            assert runtime_data is not None
            src = runtime_data[src_value]

            stmt.append(ast.Template(TMP1 % (p4name(dst_value), "runtime_%s" % (src['name']))))
        elif src_type == 'hexstr':
            stmt.append(ast.Template(TMP1 % (p4name(dst_value), "%s" % (src_value.replace("0x", "'h")))))
        else:
            stmt.append(ast.Template(TMP1 % (p4name(dst_value), p4name(src_value))))
        return stmt

class RegisterRead(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def buildRequest(self, json_dict=None, runtime_data=None):
        TMP1 = "let %(name)s_req = RegRequest { addr: %(addr)s, data: ?, write: False };"
        TMP2 = "tx_info_%(name)s.enq(%(name)s_req);"
        name = self.parameters[1]['value']
        ptype = CamelCase(name) #FIXME
        if type(self.parameters[2]['value']) is list:
            addr = p4name(self.parameters[2]['value'])
        else:
            addr = self.parameters[2]['value'][0]
        stmt = []
        if addr != "0":
            addr = "truncate(" + addr + ")"
        pdict = {"name": name, "type": ptype, "addr": addr}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        return stmt

    def buildResponse(self):
        TMP1 = "let v_%(name)s = rx_info_%(tname)s.first;"
        TMP2 = "rx_info_%(tname)s.deq;"
        TMP3 = "let %(name)s = v_%(name)s.data;"
        name = p4name(self.parameters[0]['value'])
        tname = self.parameters[1]['value']
        stmt = []
        stmt.append(ast.Template(TMP1, {"name": name, "tname": tname}))
        stmt.append(ast.Template(TMP2, {"name": name, "tname": tname}))
        stmt.append(ast.Template(TMP3, {"name": name, "tname": tname}))
        return stmt

    def buildTXRX(self, json_dict):
        TMP1 = "TX #(RegRequest#(%(asz)s, %(dsz)s)) tx_%(name)s <- mkTX;"
        TMP2 = "RX #(RegResponse#(%(dsz)s)) rx_%(name)s <- mkRX;"
        TMP3 = "let tx_info_%(name)s = tx_%(name)s.u;"
        TMP4 = "let rx_info_%(name)s = rx_%(name)s.u;"
        stmt = []
        name = self.parameters[1]['value']
        dsz, asz= get_reg_array_size(name, json_dict)
        pdict = {'name': name, 'asz': asz, 'dsz': dsz}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP3, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildInterface(self, json_dict):
        TMP1 = "Client#(RegRequest#(%(asz)s, %(dsz)s), RegResponse#(%(dsz)s))"
        stmt = []
        name = self.parameters[1]['value']
        tname = self.parameters[0]['value'][1]
        ptype = CamelCase(tname)
        dsz, asz= get_reg_array_size(name, json_dict)
        pdict = {'name': name, 'asz': asz, 'dsz': dsz}
        intf = ast.Interface(name, TMP1 % pdict)
        stmt.append(intf)
        return stmt

    def buildInterfaceDef(self):
        TMP1 = "interface %(name)s = toClient(tx_%(name)s.e, rx_%(name)s.e);"
        stmt = []
        name = self.parameters[1]['value']
        tname = self.parameters[0]['value'][1]
        ptype = CamelCase(name)
        pdict = {"name": name, "tname": tname}
        stmt.append(ast.Template(TMP1, pdict))
        return stmt

class RegisterWrite(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def getDstReg(self, json_dict):
        name = self.parameters[0]['value']
        dsz, _ = get_reg_array_size(name, json_dict)
        return (dsz, p4name(self.parameters[2]['value']))

    def getName(self):
        return self.parameters[0]['value']

    def buildRequest(self, json_dict=None, runtime_data=None):
        TMP1 = "let %(name)s_req = RegRequest { addr: truncate(%(addr)s), data: %(data)s, write: True };"
        TMP2 = "tx_info_%(name)s.enq(%(name)s_req);"
        TMP4 = "rg_%(field)s <= %(field)s;"
        name = self.parameters[0]['value']
        ptype = CamelCase(name)
        if type(self.parameters[1]['value']) is list:
            addr = p4name(self.parameters[1]['value'])
        else:
            addr = self.parameters[1]['value'][0]
        if type(self.parameters[2]['value']) is list:
            data = p4name(self.parameters[2]['value'])
        else:
            data = self.parameters[2]['value'][0]
        stmt = []
        _, field = self.getDstReg(json_dict)
        pdict = {"name": name, "type": ptype, "addr": addr, "data": data, "field": field}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildTXRX(self, json_dict):
        TMP1 = "TX #(RegRequest#(%(asz)s, %(dsz)s)) tx_%(name)s <- mkTX;"
        TMP2 = "RX #(RegResponse#(%(dsz)s)) rx_%(name)s <- mkRX;"
        TMP3 = "let tx_info_%(name)s = tx_%(name)s.u;"
        TMP4 = "let rx_info_%(name)s = rx_%(name)s.u;"
        stmt = []
        name = self.parameters[0]['value']
        field = p4name(self.parameters[2]['value'])
        dsz, asz= get_reg_array_size(name, json_dict)
        pdict = {'name': name, 'asz': asz, 'dsz': dsz, 'field': field}
        stmt.append(ast.Template(TMP1, pdict))
        stmt.append(ast.Template(TMP2, pdict))
        stmt.append(ast.Template(TMP3, pdict))
        stmt.append(ast.Template(TMP4, pdict))
        return stmt

    def buildInterface(self, json_dict):
        TMP1 = "Client#(RegRequest#(%(asz)s, %(dsz)s), RegResponse#(%(dsz)s))"
        stmt = []
        name = self.parameters[0]['value']
        tname = self.parameters[2]['value'][1]
        dsz, asz= get_reg_array_size(name, json_dict)
        pdict = {'name': name, 'asz': asz, 'dsz': dsz}
        intf = ast.Interface(name)
        intf.typedef = TMP1 % pdict
        stmt.append(intf)
        return stmt

    def buildInterfaceDef(self):
        TMP1 = "interface %(name)s = toClient(tx_%(name)s.e, rx_%(name)s.e);"
        stmt = []
        name = self.parameters[0]['value']
        tname = self.parameters[2]['value'][1]
        ptype = CamelCase(name)
        pdict = {"name": name, "tname": tname}
        stmt.append(ast.Template(TMP1, pdict))
        return stmt

class RemoveHeader(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class AddHeader(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class Drop(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class Nop(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class AddToField(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class SubtractFromField(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class CloneIngressPktToEgress(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters

    def build(self):
        stmt = []
        return stmt

class Count(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class ModifyFieldWithHashBasedOffset(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class CopyHeader(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class BitXor(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class CloneEgressPktToEgress(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class GenerateDigest(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class Add(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class Subtract(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class BitOr(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class Push(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class ModifyFieldRngUniform(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt

class ExecuteMeter(Primitive):
    def __init__(self, op, parameters):
        self.op = op
        self.parameters = parameters
    def build(self):
        stmt = []
        return stmt


