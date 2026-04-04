// Copyright (c) 2025 P4FPGA Project

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

/*
  VLIW RISC-V Action Processor Core for P4FPGA

  8-wide VLIW core: each cycle executes 8 RISC-V instructions in parallel.
  The C++ compiler packs independent operations into VLIW words using a
  fixed read -> compute -> write phase model.

  VLIW word = 8 x 32-bit RV32I instructions = 256 bits
  Program memory = 64 VLIW words (64 x 256 bits)
  Typical P4 action completes in 3 cycles.
*/

import BUtils::*;
import BuildVector::*;
import ClientServer::*;
import ConfigReg::*;
import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Vector::*;
import RegFile::*;
import BRAM::*;
import Pipe::*;
import TxRx::*;
import SpecialFIFOs::*;
import Utils::*;
import FShow::*;
import StmtFSM::*;

`include "ConnectalProjectConfig.bsv"
`include "Debug.defines"

// Number of parallel execution slots
typedef 8 NumSlots;
Integer numSlots = valueOf(NumSlots);

// VLIW instruction word: 8 x 32-bit instructions
typedef Vector#(NumSlots, Bit#(32)) VLIWWord;

// NOP encoding: addi x0, x0, 0
Bit#(32) rvNOP = 32'h00000013;

// RISC-V opcodes
typedef enum {
  OP_IMM  = 7'b0010011,
  OP      = 7'b0110011,
  LOAD    = 7'b0000011,
  STORE   = 7'b0100011,
  BRANCH  = 7'b1100011,
  LUI     = 7'b0110111,
  AUIPC   = 7'b0010111,
  JAL     = 7'b1101111,
  JALR    = 7'b1100111,
  P4_EXT  = 7'b1110011
} RiscVOpcode deriving(Bits, Eq, FShow);

// ALU funct3
typedef enum {
  ADD_SUB = 3'b000,
  SLL     = 3'b001,
  SLT     = 3'b010,
  SLTU    = 3'b011,
  XOR     = 3'b100,
  SRL_SRA = 3'b101,
  OR      = 3'b110,
  AND     = 3'b111
} RiscVFunct3 deriving(Bits, Eq, FShow);

// P4 custom extensions (funct3 field of P4_EXT opcode)
typedef enum {
  EXT_FIELD   = 3'b000,
  INS_FIELD   = 3'b001,
  ADD_HEADER  = 3'b010,
  REM_HEADER  = 3'b011,
  CHECKSUM    = 3'b100,
  TBL_LOOKUP  = 3'b101,
  PKT_MODIFY  = 3'b110,
  META_ACCESS = 3'b111
} P4ExtFunct3 deriving(Bits, Eq, FShow);

// Processor state
typedef enum {
  Idle,
  Fetch,
  Execute,
  WriteBack
} ProcState deriving(Bits, Eq, FShow);

// Header state constants
Bit#(3) headerNotPresent = 3'd0;
Bit#(3) headerForward    = 3'd1;

// Result from one ALU slot
typedef struct {
  Bool     writeReg;     // should write to register file?
  Bit#(5)  rd;           // destination register
  Bit#(32) rdVal;        // value to write
  Bool     writeMeta;    // should write to metaBits?
  Bit#(32) metaOffset;   // bit offset for meta write
  Bit#(32) metaVal;      // value for meta write
  Bit#(8)  metaWidth;    // bit width for meta write (32 for normal, 3 for header state)
  Bool     updatePC;     // should update PC?
  Bit#(8)  newPC;        // new PC value
} SlotResult deriving(Bits);

// The VLIW RISC-V Action Core Interface
interface RiscVActionCore#(type metaT, type paramT);
  interface Server#(Tuple2#(metaT, paramT), metaT) action_server;
  method Action loadProgram(Vector#(64, VLIWWord) program);
  method Action setVerbosity(int verbosity);
endinterface

module mkRiscVActionCore(RiscVActionCore#(metaT, paramT))
  provisos(Bits#(metaT, metaT_sz),
           Bits#(paramT, paramT_sz),
           FShow#(metaT),
           FShow#(paramT));

  `PRINT_DEBUG_MSG

  // Program memory: 64 VLIW words x 256 bits
  Vector#(64, Reg#(VLIWWord)) progMem <- replicateM(mkReg(replicate(0)));

  // Register file: 32 general-purpose 32-bit registers
  Vector#(32, Reg#(Bit#(32))) regFile <- replicateM(mkReg(0));

  // Metadata as flat bit vector
  Reg#(Bit#(metaT_sz)) metaBits <- mkReg(0);

  // Program counter (indexes VLIW words, not individual instructions)
  Reg#(Bit#(8)) pc <- mkReg(0);

  // Fetched VLIW word
  Reg#(VLIWWord) currentWord <- mkReg(replicate(0));

  // Processor state
  Reg#(ProcState) state <- mkReg(Idle);

  // I/O
  FIFOF#(Tuple2#(metaT, paramT)) inputFIFO <- mkFIFOF;
  FIFOF#(metaT) outputFIFO <- mkFIFOF;

  // --- Instruction decode helpers (pure functions) ---

  function Bit#(7)  iOpcode(Bit#(32) i) = i[6:0];
  function Bit#(5)  iRd(Bit#(32) i)     = i[11:7];
  function Bit#(3)  iFunct3(Bit#(32) i)  = i[14:12];
  function Bit#(5)  iRs1(Bit#(32) i)     = i[19:15];
  function Bit#(5)  iRs2(Bit#(32) i)     = i[24:20];
  function Bit#(7)  iFunct7(Bit#(32) i)  = i[31:25];

  function Bit#(32) iImmI(Bit#(32) i) = signExtend(i[31:20]);
  function Bit#(32) iImmS(Bit#(32) i) = signExtend({i[31:25], i[11:7]});
  function Bit#(32) iImmB(Bit#(32) i) = signExtend({i[31], i[7], i[30:25], i[11:8], 1'b0});
  function Bit#(32) iImmU(Bit#(32) i) = {i[31:12], 12'b0};
  function Bit#(32) iImmJ(Bit#(32) i) = signExtend({i[31], i[19:12], i[20], i[30:21], 1'b0});

  function Bool signedLT(Bit#(32) a, Bit#(32) b);
    Int#(32) sa = unpack(a); Int#(32) sb = unpack(b);
    return sa < sb;
  endfunction

  function Bit#(32) signedShiftRight(Bit#(32) a, Bit#(5) b);
    Int#(32) sa = unpack(a);
    return pack(sa >> b);
  endfunction

  // Read 32 bits from metaBits at a given bit offset (combinational)
  function Bit#(32) readMeta(Bit#(32) offset);
    return truncate(metaBits >> offset);
  endfunction

  // --- Per-slot execution (pure combinational function) ---
  // Returns the result of executing one 32-bit instruction.
  // All register reads are combinational; writes are collected.

  function SlotResult executeSlot(Bit#(32) inst);
    SlotResult res = SlotResult {
      writeReg: False, rd: 0, rdVal: 0,
      writeMeta: False, metaOffset: 0, metaVal: 0, metaWidth: 32,
      updatePC: False, newPC: 0
    };

    Bit#(7) opcode = iOpcode(inst);
    Bit#(5) rd     = iRd(inst);
    Bit#(3) funct3 = iFunct3(inst);
    Bit#(5) rs1    = iRs1(inst);
    Bit#(5) rs2    = iRs2(inst);
    Bit#(7) funct7 = iFunct7(inst);

    Bit#(32) v1 = (rs1 == 0) ? 0 : regFile[rs1];
    Bit#(32) v2 = (rs2 == 0) ? 0 : regFile[rs2];
    Bit#(32) result = 0;

    case (opcode)
      pack(OP): begin
        RiscVFunct3 f3 = unpack(funct3);
        case (f3)
          ADD_SUB: result = (funct7[5] == 0) ? v1 + v2 : v1 - v2;
          SLL:     result = v1 << v2[4:0];
          SLT:     result = signedLT(v1, v2) ? 1 : 0;
          SLTU:    result = (v1 < v2) ? 1 : 0;
          XOR:     result = v1 ^ v2;
          SRL_SRA: result = (funct7[5] == 0) ? v1 >> v2[4:0] : signedShiftRight(v1, v2[4:0]);
          OR:      result = v1 | v2;
          AND:     result = v1 & v2;
        endcase
        res.writeReg = (rd != 0);
        res.rd = rd;
        res.rdVal = result;
      end

      pack(OP_IMM): begin
        Bit#(32) imm = iImmI(inst);
        RiscVFunct3 f3 = unpack(funct3);
        case (f3)
          ADD_SUB: result = v1 + imm;
          SLL:     result = v1 << imm[4:0];
          SLT:     result = signedLT(v1, imm) ? 1 : 0;
          SLTU:    result = (v1 < imm) ? 1 : 0;
          XOR:     result = v1 ^ imm;
          SRL_SRA: result = (inst[30] == 0) ? v1 >> imm[4:0] : signedShiftRight(v1, imm[4:0]);
          OR:      result = v1 | imm;
          AND:     result = v1 & imm;
        endcase
        res.writeReg = (rd != 0);
        res.rd = rd;
        res.rdVal = result;
      end

      pack(LOAD): begin
        Bit#(32) addr = v1 + iImmI(inst);
        result = readMeta(addr << 3);
        res.writeReg = (rd != 0);
        res.rd = rd;
        res.rdVal = result;
      end

      pack(STORE): begin
        Bit#(32) addr = v1 + iImmS(inst);
        res.writeMeta = True;
        res.metaOffset = addr << 3;
        res.metaVal = v2;
        res.metaWidth = 32;
      end

      pack(BRANCH): begin
        Bool take = False;
        case (funct3)
          3'b000: take = (v1 == v2);
          3'b001: take = (v1 != v2);
          3'b100: take = signedLT(v1, v2);
          3'b101: take = !signedLT(v1, v2);
          3'b110: take = (v1 < v2);
          3'b111: take = (v1 >= v2);
          default: take = False;
        endcase
        if (take) begin
          res.updatePC = True;
          res.newPC = pc + truncate(iImmB(inst) >> 1);
        end
      end

      pack(JAL): begin
        if (rd != 0) begin
          res.writeReg = True;
          res.rd = rd;
          res.rdVal = zeroExtend(pc) + 1;
        end
        res.updatePC = True;
        res.newPC = pc + truncate(iImmJ(inst) >> 1);
      end

      pack(JALR): begin
        Bit#(32) target = (v1 + iImmI(inst)) & ~1;
        if (rd != 0) begin
          res.writeReg = True;
          res.rd = rd;
          res.rdVal = zeroExtend(pc) + 1;
        end
        res.updatePC = True;
        res.newPC = truncate(target >> 1);
      end

      pack(LUI): begin
        res.writeReg = (rd != 0);
        res.rd = rd;
        res.rdVal = iImmU(inst);
      end

      pack(AUIPC): begin
        res.writeReg = (rd != 0);
        res.rd = rd;
        res.rdVal = (zeroExtend(pc) << 1) + iImmU(inst);
      end

      pack(P4_EXT): begin
        P4ExtFunct3 p4op = unpack(funct3);
        case (p4op)
          EXT_FIELD: begin
            Bit#(5) width  = funct7[4:0];
            Bit#(5) offset = {funct7[6:5], rs2[2:0]};
            result = (v1 >> offset) & ((1 << width) - 1);
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = result;
          end

          INS_FIELD: begin
            Bit#(5) width  = funct7[4:0];
            Bit#(5) offset = {funct7[6:5], rs2[2:0]};
            Bit#(32) mask = ((1 << width) - 1) << offset;
            result = (v1 & ~mask) | ((v2 & ((1 << width) - 1)) << offset);
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = result;
          end

          ADD_HEADER: begin
            res.writeMeta = True;
            res.metaOffset = v1;
            res.metaVal = zeroExtend(headerForward);
            res.metaWidth = 3;
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = zeroExtend(headerForward);
          end

          REM_HEADER: begin
            res.writeMeta = True;
            res.metaOffset = v1;
            res.metaVal = zeroExtend(headerNotPresent);
            res.metaWidth = 3;
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = zeroExtend(headerNotPresent);
          end

          CHECKSUM: begin
            Bit#(33) sum = zeroExtend(v1) + zeroExtend(v2);
            result = truncate(sum) + zeroExtend(sum[32]);
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = result;
          end

          META_ACCESS: begin
            if (funct7[0] == 0) begin
              // Read
              result = readMeta(v1);
              res.writeReg = (rd != 0);
              res.rd = rd;
              res.rdVal = result;
            end else begin
              // Write
              res.writeMeta = True;
              res.metaOffset = v1;
              res.metaVal = v2;
              res.metaWidth = 32;
            end
          end

          default: begin
            // TBL_LOOKUP, PKT_MODIFY: reserved
            res.writeReg = (rd != 0);
            res.rd = rd;
            res.rdVal = v1;
          end
        endcase
      end

      default: begin
        // Unknown opcode or NOP (0x00000013) - do nothing
      end
    endcase

    return res;
  endfunction

  // --- Start execution ---
  rule startExecution if (state == Idle && inputFIFO.notEmpty);
    let input = inputFIFO.first;
    inputFIFO.deq;
    metaBits <= pack(tpl_1(input));
    for (Integer i = 0; i < 32; i = i + 1)
      regFile[i] <= 0;
    pc <= 0;
    state <= Fetch;
    dbprint(3, $format("VLIW: starting execution"));
  endrule

  // --- Fetch ---
  rule fetch if (state == Fetch);
    currentWord <= progMem[pc];
    state <= Execute;
    dbprint(3, $format("VLIW Fetch: PC=%d", pc));
  endrule

  // --- Execute all 8 slots in parallel ---
  rule execute if (state == Execute);
    VLIWWord word = currentWord;

    // Check for terminator (all-zero word)
    Bool allZero = True;
    for (Integer i = 0; i < numSlots; i = i + 1)
      if (word[i] != 0 && word[i] != rvNOP) allZero = False;

    if (allZero) begin
      state <= WriteBack;
      dbprint(3, $format("VLIW: terminator at PC=%d", pc));
    end else begin
      // Execute all 8 slots
      Vector#(NumSlots, SlotResult) results;
      for (Integer i = 0; i < numSlots; i = i + 1)
        results[i] = executeSlot(word[i]);

      // Apply register writes (compiler guarantees no conflicts)
      for (Integer i = 0; i < numSlots; i = i + 1) begin
        if (results[i].writeReg && results[i].rd != 0)
          regFile[results[i].rd] <= results[i].rdVal;
      end

      // Apply metadata writes: compute final metaBits combinationally
      Bit#(metaT_sz) newMeta = metaBits;
      for (Integer i = 0; i < numSlots; i = i + 1) begin
        if (results[i].writeMeta) begin
          Bit#(metaT_sz) mask;
          if (results[i].metaWidth == 3)
            mask = zeroExtend(3'b111) << results[i].metaOffset;
          else
            mask = zeroExtend(32'hFFFFFFFF) << results[i].metaOffset;
          Bit#(metaT_sz) val = zeroExtend(results[i].metaVal) << results[i].metaOffset;
          newMeta = (newMeta & ~mask) | (val & mask);
        end
      end
      metaBits <= newMeta;

      // PC update: check if any slot requested a branch/jump
      // Priority: lowest slot index wins (slot 0 is the branch slot by convention)
      Bool pcUpdated = False;
      for (Integer i = 0; i < numSlots; i = i + 1) begin
        if (results[i].updatePC && !pcUpdated) begin
          pc <= results[i].newPC;
          pcUpdated = True;
        end
      end
      if (!pcUpdated)
        pc <= pc + 1;

      state <= Fetch;
      dbprint(3, $format("VLIW Execute: PC=%d, 8 slots done", pc));
    end
  endrule

  // --- Write back ---
  rule writeBack if (state == WriteBack);
    metaT result = unpack(metaBits);
    outputFIFO.enq(result);
    state <= Idle;
    dbprint(3, $format("VLIW WriteBack complete"));
  endrule

  // --- Interface ---
  interface Server action_server;
    interface Put request;
      method Action put(Tuple2#(metaT, paramT) x);
        inputFIFO.enq(x);
      endmethod
    endinterface
    interface Get response;
      method ActionValue#(metaT) get();
        let x = outputFIFO.first;
        outputFIFO.deq;
        return x;
      endmethod
    endinterface
  endinterface

  method Action loadProgram(Vector#(64, VLIWWord) program);
    for (Integer i = 0; i < 64; i = i + 1)
      progMem[i] <= program[i];
    dbprint(2, $format("VLIW program loaded"));
  endmethod

  method Action setVerbosity(int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule

// Adapter: VLIW core -> Engine interface
module mkRiscVActionEngine#(Vector#(64, VLIWWord) program)(Engine#(depth, metaI, actI))
  provisos(Bits#(metaI, a__),
           Bits#(actI, b__),
           Add#(depth, 0, dep),
           FShow#(actI),
           FShow#(metaI));

  `PRINT_DEBUG_MSG

  RiscVActionCore#(metaI, actI) core <- mkRiscVActionCore();

  Reg#(Bool) initialized <- mkReg(False);
  rule doInit(!initialized);
    core.loadProgram(program);
    initialized <= True;
  endrule

  RX#(Tuple2#(metaI, actI)) meta_in <- mkRX;
  TX#(metaI) meta_out <- mkTX;

  mkConnection(meta_in.e, core.action_server.request);
  mkConnection(toPut(meta_out.e), core.action_server.response);

  interface prev_control_state = toServer(meta_in.e, meta_out.e);

  method Action set_verbosity(int verbosity);
    core.setVerbosity(verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
