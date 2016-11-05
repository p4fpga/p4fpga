// Copyright (c) 2016 Cornell University.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

typedef Bit#(32) Instr;
typedef Bit#(7) Opcode;
typedef Bit#(5) RegIdx;

Opcode op_OP_IMM = 7'b00_100_11;
Bit#(3) f3_ADDI = 3'b000;
Bit#(3) f3_SLLI = 3'b001;
Bit#(3) f3_SLTI = 3'b010;
Bit#(3) f3_XORI = 3'b100;
Bit#(3) f3_ANDI = 3'b111;

Opcode op_OP = 7'b01_100_11;

Opcode op_STORE = 7'b01_000_11;
Bit#(3) f3_SB = 3'b000;
Bit#(3) f3_SH = 3'b001;
Bit#(3) f3_SW = 3'b010;
Bit#(3) f3_SD = 3'b011;

Opcode op_RET = 7'b00_000_00;

function Opcode   instr_opcode (Instr x); return x [6:0]; endfunction
function Bit#(3)  instr_funct3 (Instr x); return x [14:12]; endfunction
function Bit#(7)  instr_funct7 (Instr x); return x [31:25]; endfunction
function Bit#(10) instr_funct10 (Instr x); return { x[31:25], x[14:12] }; endfunction

function Bit#(5)  instr_rd     (Instr x); return x [11:7]; endfunction
function Bit#(5)  instr_rs1    (Instr x); return x [19:15]; endfunction
function Bit#(5)  instr_rs2    (Instr x); return x [24:20]; endfunction
function Bit#(5)  instr_rs3    (Instr x); return x [31:27]; endfunction

function Bit#(12) instr_imm12_I (Instr x); return x [31:20]; endfunction

