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
  RISC-V Action Processor Core for P4FPGA

  A lightweight RISC-V core optimized for packet processing with custom
  extensions for P4 actions. Metadata is treated as a flat bit vector;
  the C++ code generator computes field offsets at compile time.
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

// RISC-V instruction types
typedef enum {
  R_TYPE,    // Register-Register operations
  I_TYPE,    // Immediate operations
  S_TYPE,    // Store operations
  B_TYPE,    // Branch operations
  U_TYPE,    // Upper immediate operations
  J_TYPE,    // Jump operations
  P4_TYPE    // Custom P4 operations
} InstructionType deriving(Bits, Eq, FShow);

// RISC-V standard opcodes
typedef enum {
  OP_IMM  = 7'b0010011,  // I-type ALU operations with immediate
  OP      = 7'b0110011,  // R-type ALU operations
  LOAD    = 7'b0000011,  // Load from metadata (byte-addressed)
  STORE   = 7'b0100011,  // Store to metadata (byte-addressed)
  BRANCH  = 7'b1100011,  // Branch operations
  LUI     = 7'b0110111,  // Load upper immediate
  AUIPC   = 7'b0010111,  // Add upper immediate to PC
  JAL     = 7'b1101111,  // Jump and link
  JALR    = 7'b1100111,  // Jump and link register
  P4_EXT  = 7'b1110011   // Custom P4 extensions
} RiscVOpcode deriving(Bits, Eq, FShow);

// RISC-V R-type function codes (funct3)
typedef enum {
  ADD_SUB = 3'b000,  // ADD or SUB based on funct7
  SLL     = 3'b001,  // Shift left logical
  SLT     = 3'b010,  // Set less than
  SLTU    = 3'b011,  // Set less than unsigned
  XOR     = 3'b100,  // Bitwise XOR
  SRL_SRA = 3'b101,  // Shift right logical or arithmetic based on funct7
  OR      = 3'b110,  // Bitwise OR
  AND     = 3'b111   // Bitwise AND
} RiscVFunct3 deriving(Bits, Eq, FShow);

// Custom P4 extension operations (using funct3 field)
typedef enum {
  EXT_FIELD   = 3'b000,  // Extract bit field from register
  INS_FIELD   = 3'b001,  // Insert bit field into register
  ADD_HEADER  = 3'b010,  // Set header state to Forward (valid)
  REM_HEADER  = 3'b011,  // Set header state to NotPresent (invalid)
  CHECKSUM    = 3'b100,  // One's complement addition
  TBL_LOOKUP  = 3'b101,  // Table lookup (reserved)
  PKT_MODIFY  = 3'b110,  // Packet modification (reserved)
  META_ACCESS = 3'b111   // Read/write metadata bit vector
} P4ExtFunct3 deriving(Bits, Eq, FShow);

// RISC-V Instruction format
typedef struct {
  Bit#(7)  opcode;
  Bit#(5)  rd;
  Bit#(3)  funct3;
  Bit#(5)  rs1;
  Bit#(5)  rs2;
  Bit#(7)  funct7;
} RiscVInstruction deriving(Bits, Eq, FShow);

// Instruction with immediate field views
typedef struct {
  Bit#(7)  opcode;
  Bit#(5)  rd;
  Bit#(3)  funct3;
  Bit#(5)  rs1;
  Bit#(12) imm;
} RiscVIInstruction deriving(Bits, Eq, FShow);

// Processor state
typedef enum {
  Fetch,
  Decode,
  Execute,
  WriteBack
} ProcState deriving(Bits, Eq, FShow);

// HeaderState encoding (matches P4FPGA StructDefines)
// NotPresent=0, Forward=1, Delete=2, Insert=3
typedef Bit#(3) HeaderState;

Bit#(3) headerNotPresent = 3'd0;
Bit#(3) headerForward    = 3'd1;

// The RISC-V Action Core Interface
interface RiscVActionCore#(type metaT, type paramT);
  // Process an action with given metadata and parameters
  interface Server#(Tuple2#(metaT, paramT), metaT) action_server;

  // Load a new program (action)
  method Action loadProgram(Vector#(256, Bit#(32)) program);

  // Debug interface
  method Action setVerbosity(int verbosity);
endinterface

// Implementation of the RISC-V Action Core
module mkRiscVActionCore(RiscVActionCore#(metaT, paramT))
  provisos(Bits#(metaT, metaT_sz),
           Bits#(paramT, paramT_sz),
           FShow#(metaT),
           FShow#(paramT));

  `PRINT_DEBUG_MSG

  // Program memory (instruction storage) - 256 instructions
  BRAM_PORT#(Bit#(8), Bit#(32)) progMem <- mkBRAMCore1(256, False);

  // Register file - 32 general purpose registers
  Vector#(32, Reg#(Bit#(32))) regFile <- replicateM(mkReg(0));

  // Metadata as packed bit vector for field access
  Reg#(Bit#(metaT_sz)) metaBits <- mkReg(0);

  // Action parameters as packed bit vector
  Reg#(Bit#(paramT_sz)) paramBits <- mkReg(0);

  // Program counter
  Reg#(Bit#(8)) pc <- mkReg(0);

  // Current instruction
  Reg#(Bit#(32)) instruction <- mkReg(0);

  // Processor state
  Reg#(ProcState) state <- mkReg(Fetch);

  // Flag: core is running an action
  Reg#(Bool) running <- mkReg(False);

  // I/O FIFOs
  FIFOF#(Tuple2#(metaT, paramT)) inputFIFO <- mkFIFOF;
  FIFOF#(metaT) outputFIFO <- mkFIFOF;

  // Helper functions for instruction decoding
  function RiscVOpcode getOpcode(Bit#(32) inst);
    return unpack(inst[6:0]);
  endfunction

  function Bit#(5) getRd(Bit#(32) inst);
    return inst[11:7];
  endfunction

  function Bit#(3) getFunct3(Bit#(32) inst);
    return inst[14:12];
  endfunction

  function Bit#(5) getRs1(Bit#(32) inst);
    return inst[19:15];
  endfunction

  function Bit#(5) getRs2(Bit#(32) inst);
    return inst[24:20];
  endfunction

  function Bit#(7) getFunct7(Bit#(32) inst);
    return inst[31:25];
  endfunction

  // Immediate extraction functions
  function Bit#(32) getIImmediate(Bit#(32) inst);
    return signExtend(inst[31:20]);
  endfunction

  function Bit#(32) getSImmediate(Bit#(32) inst);
    return signExtend({inst[31:25], inst[11:7]});
  endfunction

  function Bit#(32) getBImmediate(Bit#(32) inst);
    return signExtend({inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
  endfunction

  function Bit#(32) getUImmediate(Bit#(32) inst);
    return {inst[31:12], 12'b0};
  endfunction

  function Bit#(32) getJImmediate(Bit#(32) inst);
    return signExtend({inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});
  endfunction

  // Read 32 bits from metaBits at a given bit offset
  function Bit#(32) readMetaBits(Bit#(32) bitOffset);
    return truncate(metaBits >> bitOffset);
  endfunction

  // Write 32 bits into metaBits at a given bit offset
  function Action writeMetaBits(Bit#(32) bitOffset, Bit#(32) value);
    action
      Bit#(metaT_sz) mask = zeroExtend(32'hFFFFFFFF) << bitOffset;
      metaBits <= (metaBits & ~mask) | (zeroExtend(value) << bitOffset);
    endaction
  endfunction

  // Write N bits into metaBits at a given bit offset
  function Action writeMetaBitsN(Bit#(32) bitOffset, Bit#(32) value, Integer nbits);
    action
      Bit#(metaT_sz) bitmask = (1 << fromInteger(nbits)) - 1;
      Bit#(metaT_sz) mask = bitmask << bitOffset;
      Bit#(metaT_sz) val = (zeroExtend(value) & bitmask) << bitOffset;
      metaBits <= (metaBits & ~mask) | val;
    endaction
  endfunction

  // Helper for signed comparison
  function Bool signedLT(Bit#(32) a, Bit#(32) b);
    Int#(32) sa = unpack(a);
    Int#(32) sb = unpack(b);
    return sa < sb;
  endfunction

  // Helper for arithmetic right shift
  function Bit#(32) signedShiftRight(Bit#(32) a, Bit#(32) b);
    Int#(32) sa = unpack(a);
    return pack(sa >> b);
  endfunction

  // Helper function for P4 custom operations
  function ActionValue#(Bit#(32)) executeP4Operation(Bit#(3) funct3, Bit#(5) rs1, Bit#(5) rs2, Bit#(7) funct7);
    actionvalue
      Bit#(32) rs1_val = (rs1 == 0) ? 0 : regFile[rs1];
      Bit#(32) rs2_val = (rs2 == 0) ? 0 : regFile[rs2];
      Bit#(32) result = 0;

      P4ExtFunct3 op = unpack(funct3);

      case (op)
        EXT_FIELD: begin
          // Extract bits from a register value
          // funct7 encodes: [4:0] = width, [6:5] = offset high bits
          // rs2 field encodes offset low bits
          Bit#(5) width = funct7[4:0];
          Bit#(5) offset = {funct7[6:5], rs2[2:0]};
          result = (rs1_val >> offset) & ((1 << width) - 1);
          dbprint(3, $format("P4 EXT_FIELD: rs1=%h, width=%d, offset=%d, result=%h", rs1_val, width, offset, result));
        end

        INS_FIELD: begin
          // Insert bits into a register value
          Bit#(5) width = funct7[4:0];
          Bit#(5) offset = {funct7[6:5], rs2[2:0]};
          Bit#(32) mask = ((1 << width) - 1) << offset;
          result = (rs1_val & ~mask) | ((rs2_val & ((1 << width) - 1)) << offset);
          dbprint(3, $format("P4 INS_FIELD: rs1=%h, rs2=%h, width=%d, offset=%d, result=%h",
                            rs1_val, rs2_val, width, offset, result));
        end

        ADD_HEADER: begin
          // Set header state to Forward at bit offset rs1_val
          writeMetaBitsN(rs1_val, zeroExtend(headerForward), 3);
          result = zeroExtend(headerForward);
          dbprint(3, $format("P4 ADD_HEADER at offset %d", rs1_val));
        end

        REM_HEADER: begin
          // Set header state to NotPresent at bit offset rs1_val
          writeMetaBitsN(rs1_val, zeroExtend(headerNotPresent), 3);
          result = zeroExtend(headerNotPresent);
          dbprint(3, $format("P4 REM_HEADER at offset %d", rs1_val));
        end

        CHECKSUM: begin
          // One's complement addition (internet checksum building block)
          Bit#(33) sum = zeroExtend(rs1_val) + zeroExtend(rs2_val);
          // Fold carry back into result
          result = truncate(sum) + zeroExtend(sum[32]);
          dbprint(3, $format("P4 CHECKSUM: %h + %h = %h", rs1_val, rs2_val, result));
        end

        TBL_LOOKUP: begin
          // Reserved for external table lookup interface
          dbprint(2, $format("P4 TBL_LOOKUP: not implemented, key=%h", rs1_val));
          result = rs1_val;
        end

        PKT_MODIFY: begin
          // Reserved for external packet buffer interface
          dbprint(2, $format("P4 PKT_MODIFY: not implemented"));
          result = rs1_val;
        end

        META_ACCESS: begin
          // Read/write metadata bit vector
          // funct7[0]: 0 = read, 1 = write
          // rs1_val: bit offset into metadata
          if (funct7[0] == 0) begin
            // Read 32 bits from metadata at bit offset
            result = readMetaBits(rs1_val);
            dbprint(3, $format("P4 META_READ: offset=%d, value=%h", rs1_val, result));
          end else begin
            // Write rs2_val to metadata at bit offset
            writeMetaBits(rs1_val, rs2_val);
            result = rs2_val;
            dbprint(3, $format("P4 META_WRITE: offset=%d, value=%h", rs1_val, rs2_val));
          end
        end
      endcase

      return result;
    endactionvalue
  endfunction

  // Start execution when input is available and core is idle
  rule startExecution if (inputFIFO.notEmpty && !running && state == Fetch);
    let input = inputFIFO.first;
    inputFIFO.deq;

    // Pack metadata and params into flat bit vectors
    metaBits <= pack(tpl_1(input));
    paramBits <= pack(tpl_2(input));

    // Load action parameters into low registers
    // The C++ generator emits metaRead instructions for fields it needs,
    // so we don't pre-load metadata fields here.
    // Action parameters are available via paramBits; the generator emits
    // LOAD instructions from param space if needed.

    running <= True;
    pc <= 0;

    // Clear register file
    for (Integer i = 0; i < 32; i = i + 1)
      regFile[i] <= 0;

    dbprint(3, $format("Starting execution"));
  endrule

  // Main execution FSM
  rule fetch if (state == Fetch && running);
    progMem.put(False, pc, ?);
    state <= Decode;
    dbprint(3, $format("Fetch: PC=%d", pc));
  endrule

  rule decode if (state == Decode && running);
    instruction <= progMem.read(pc);
    state <= Execute;
    dbprint(3, $format("Decode: reading instruction at PC=%d", pc));
  endrule

  rule execute if (state == Execute && running);
    let inst = instruction;
    RiscVOpcode opcode = getOpcode(inst);
    Bit#(5) rd = getRd(inst);
    Bit#(3) funct3 = getFunct3(inst);
    Bit#(5) rs1 = getRs1(inst);
    Bit#(5) rs2 = getRs2(inst);
    Bit#(7) funct7 = getFunct7(inst);

    Bit#(32) rs1_val = (rs1 == 0) ? 0 : regFile[rs1];
    Bit#(32) rs2_val = (rs2 == 0) ? 0 : regFile[rs2];
    Bit#(32) result = 0;
    Bool pcUpdated = False;

    // Check for program end (instruction all zeros = NOP terminator)
    if (inst == 0) begin
      state <= WriteBack;
    end else begin
      case (opcode)
        OP: begin
          // R-type instructions
          RiscVFunct3 alu_op = unpack(funct3);
          case (alu_op)
            ADD_SUB: begin
              if (funct7[5] == 0) result = rs1_val + rs2_val;
              else result = rs1_val - rs2_val;
            end
            SLL: result = rs1_val << (rs2_val[4:0]);
            SLT: result = (signedLT(rs1_val, rs2_val)) ? 1 : 0;
            SLTU: result = (rs1_val < rs2_val) ? 1 : 0;
            XOR: result = rs1_val ^ rs2_val;
            SRL_SRA: begin
              if (funct7[5] == 0) result = rs1_val >> (rs2_val[4:0]);
              else result = signedShiftRight(rs1_val, zeroExtend(rs2_val[4:0]));
            end
            OR: result = rs1_val | rs2_val;
            AND: result = rs1_val & rs2_val;
          endcase

          if (rd != 0) regFile[rd] <= result;
        end

        OP_IMM: begin
          // I-type ALU operations
          Bit#(32) imm = getIImmediate(inst);
          RiscVFunct3 alu_op = unpack(funct3);

          case (alu_op)
            ADD_SUB: result = rs1_val + imm;
            SLL: result = rs1_val << (imm[4:0]);
            SLT: result = (signedLT(rs1_val, imm)) ? 1 : 0;
            SLTU: result = (rs1_val < imm) ? 1 : 0;
            XOR: result = rs1_val ^ imm;
            SRL_SRA: begin
              if (inst[30] == 0) result = rs1_val >> (imm[4:0]);
              else result = signedShiftRight(rs1_val, zeroExtend(imm[4:0]));
            end
            OR: result = rs1_val | imm;
            AND: result = rs1_val & imm;
          endcase

          if (rd != 0) regFile[rd] <= result;
        end

        LOAD: begin
          // Load 32 bits from metadata at byte address (rs1 + imm)
          Bit#(32) byteAddr = rs1_val + getIImmediate(inst);
          Bit#(32) bitOffset = byteAddr << 3;  // byte to bit offset
          result = readMetaBits(bitOffset);
          if (rd != 0) regFile[rd] <= result;
          dbprint(3, $format("LOAD: addr=%h, bitOffset=%d, value=%h", byteAddr, bitOffset, result));
        end

        STORE: begin
          // Store 32 bits to metadata at byte address (rs1 + imm)
          Bit#(32) byteAddr = rs1_val + getSImmediate(inst);
          Bit#(32) bitOffset = byteAddr << 3;  // byte to bit offset
          writeMetaBits(bitOffset, rs2_val);
          dbprint(3, $format("STORE: addr=%h, bitOffset=%d, value=%h", byteAddr, bitOffset, rs2_val));
        end

        BRANCH: begin
          // Branch operations
          Bool take_branch = False;

          case (funct3)
            3'b000: take_branch = (rs1_val == rs2_val);            // BEQ
            3'b001: take_branch = (rs1_val != rs2_val);            // BNE
            3'b100: take_branch = signedLT(rs1_val, rs2_val);     // BLT
            3'b101: take_branch = !signedLT(rs1_val, rs2_val);    // BGE (>=)
            3'b110: take_branch = (rs1_val < rs2_val);             // BLTU
            3'b111: take_branch = (rs1_val >= rs2_val);            // BGEU
            default: take_branch = False;
          endcase

          if (take_branch) begin
            // Offset is in units of 2 bytes in real RISC-V, but our PC
            // increments by 1 per instruction, so divide by 2
            Bit#(32) offset = getBImmediate(inst);
            pc <= pc + truncate(offset >> 1);
            pcUpdated = True;
            dbprint(3, $format("BRANCH taken: PC=%d -> %d", pc, pc + truncate(offset >> 1)));
          end
        end

        JAL: begin
          if (rd != 0) regFile[rd] <= zeroExtend(pc) + 1;
          Bit#(32) offset = getJImmediate(inst);
          pc <= pc + truncate(offset >> 1);
          pcUpdated = True;
          dbprint(3, $format("JAL: PC=%d -> %d, rd=%d", pc, pc + truncate(offset >> 1), rd));
        end

        JALR: begin
          Bit#(32) target = (rs1_val + getIImmediate(inst)) & ~1;
          if (rd != 0) regFile[rd] <= zeroExtend(pc) + 1;
          pc <= truncate(target >> 1);
          pcUpdated = True;
          dbprint(3, $format("JALR: PC=%d -> %d", pc, target >> 1));
        end

        LUI: begin
          if (rd != 0) regFile[rd] <= getUImmediate(inst);
        end

        AUIPC: begin
          if (rd != 0) regFile[rd] <= (zeroExtend(pc) << 1) + getUImmediate(inst);
        end

        P4_EXT: begin
          let p4_result <- executeP4Operation(funct3, rs1, rs2, funct7);
          if (rd != 0) regFile[rd] <= p4_result;
        end

        default: begin
          dbprint(2, $format("Invalid opcode: %b", opcode));
        end
      endcase

      // Increment PC unless branch/jump already updated it
      if (!pcUpdated) begin
        pc <= pc + 1;
      end

      state <= Fetch;
    end
  endrule

  rule writeBack if (state == WriteBack && running);
    // Unpack modified metadata bits back to typed struct
    metaT result = unpack(metaBits);
    outputFIFO.enq(result);
    running <= False;
    pc <= 0;

    dbprint(3, $format("WriteBack complete"));
  endrule

  // Interface methods
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

  method Action loadProgram(Vector#(256, Bit#(32)) program);
    for (Integer i = 0; i < 256; i = i + 1) begin
      progMem.put(True, fromInteger(i), program[i]);
    end
    dbprint(2, $format("Program loaded"));
  endmethod

  method Action setVerbosity(int verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule

// Adapter module to make the RISC-V core compatible with the Engine interface
module mkRiscVActionEngine#(Vector#(256, Bit#(32)) program)(Engine#(depth, metaI, actI))
  provisos(Bits#(metaI, a__),
           Bits#(actI, b__),
           Add#(depth, 0, dep),
           FShow#(actI),
           FShow#(metaI));

  `PRINT_DEBUG_MSG

  // Instantiate the RISC-V Action Core
  RiscVActionCore#(metaI, actI) core <- mkRiscVActionCore();

  // Load the program into the core
  Reg#(Bool) initialized <- mkReg(False);
  rule initialize(!initialized);
    core.loadProgram(program);
    initialized <= True;
  endrule

  // RX/TX for metadata and actions
  RX#(Tuple2#(metaI, actI)) meta_in <- mkRX;
  TX#(metaI) meta_out <- mkTX;

  // Connect the core to the RX/TX interfaces
  mkConnection(meta_in.e, core.action_server.request);
  mkConnection(toPut(meta_out.e), core.action_server.response);

  // The Engine interface
  interface prev_control_state = toServer(meta_in.e, meta_out.e);

  method Action set_verbosity(int verbosity);
    core.setVerbosity(verbosity);
    cf_verbosity <= verbosity;
  endmethod
endmodule
