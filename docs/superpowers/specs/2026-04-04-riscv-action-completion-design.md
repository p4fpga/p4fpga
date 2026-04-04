# RISC-V Action Processor Completion Design

## Problem

The RISC-V action processor has a working RV32I core and instruction encoding infrastructure, but the P4-specific custom instructions are stubbed and the C++ code generator lacks field mapping. This makes the processor unusable for actual P4 actions.

## Scope

Complete the RISC-V action processor so that P4 actions compile to RISC-V programs that correctly read metadata fields, compute new values, and write results back.

**In scope:**
- META_ACCESS: read/write 32-bit words from packed metadata
- ADD_HEADER / REM_HEADER: toggle header validity in metadata
- CHECKSUM: one's complement internet checksum
- LOAD/STORE: byte-addressable metadata access
- C++ generator: field offset computation, if/else to branches, field mapping
- CMake integration: wire new files into the build
- Tests: validate metadata round-trip

**Deferred:**
- TBL_LOOKUP / PKT_MODIFY (need external FIFO interfaces to match tables / packet buffers)
- Multi-core RISC-V
- Runtime program loading from control plane
- Register spilling for actions using >30 fields

## Design

### Metadata Access Model

MetadataT is a generated Bluespec struct. The core treats it as a flat bit vector via `pack()`/`unpack()`. The C++ generator computes byte offsets for each field at compile time.

```
metadataReg (packed bits)
  [0..31]     field_0 (e.g., standard_metadata.ingress_port)
  [32..63]    field_1 (e.g., hdr.ethernet.dstAddr[31:0])
  ...
```

The core maintains a `Reg#(Bit#(metaT_sz)) metaBits` register. On `startExecution`, it packs input metadata into this register. On `writeBack`, it unpacks and outputs.

### BSV Core Changes

#### META_ACCESS (funct3 = 3'b111)

Encoding: `P4_EXT rd, funct3=META_ACCESS, rs1=fieldOffset, rs2=srcReg, funct7`
- `funct7[0] == 0`: **Read** - Extract 32 bits from `metaBits` starting at bit offset `rs1_val`, store in `rd`
- `funct7[0] == 1`: **Write** - Insert `rs2_val` (32 bits) into `metaBits` at bit offset `rs1_val`

The offset is in **bits**, passed as a register value. The C++ generator loads the offset into a register via `addi` before issuing META_ACCESS.

Implementation:
```bsv
META_ACCESS: begin
  Bit#(32) offset = rs1_val;
  if (funct7[0] == 0) begin
    // Read: extract 32 bits at offset
    result = truncate(metaBits >> offset);
  end else begin
    // Write: insert rs2_val at offset
    Bit#(metaT_sz) mask = zeroExtend(32'hFFFFFFFF) << offset;
    metaBits <= (metaBits & ~mask) | (zeroExtend(rs2_val) << offset);
    result = rs2_val;
  end
end
```

#### ADD_HEADER / REM_HEADER (funct3 = 3'b010 / 3'b011)

Headers in P4FPGA use `HeaderState` (3-bit enum: NotPresent=0, Forward=1, Delete=2, Insert=3). The header state lives at a known bit offset in the packed metadata.

- `ADD_HEADER rd, rs1, rs2`: Set header state at bit offset `rs1_val` to `Forward` (1). `result = 1`.
- `REM_HEADER rd, rs1, rs2`: Set header state at bit offset `rs1_val` to `NotPresent` (0). `result = 0`.

Implementation writes 3 bits at the given offset in `metaBits`, same shift/mask pattern as META_ACCESS but with a 3-bit width.

#### CHECKSUM (funct3 = 3'b100)

One's complement addition (internet checksum building block):
```bsv
CHECKSUM: begin
  Bit#(33) sum = zeroExtend(rs1_val) + zeroExtend(rs2_val);
  // Fold carry back
  result = truncate(sum) + zeroExtend(sum[32]);
end
```

To compute a full header checksum, the C++ generator emits a sequence: load each 16-bit field, accumulate with CHECKSUM, then complement.

#### LOAD / STORE

Repurposed for metadata byte access (complementary to META_ACCESS for smaller granularity):

- `LOAD rd, offset(rs1)`: Read 4 bytes from metaBits at byte address `(rs1_val + offset)`
- `STORE rs2, offset(rs1)`: Write 4 bytes to metaBits at byte address `(rs1_val + offset)`

Byte address is converted to bit offset by `<< 3`. Uses same shift/mask on `metaBits`.

#### startExecution / writeBack

```bsv
rule startExecution if (inputFIFO.notEmpty && pc == 0 && state == Fetch);
  let input = inputFIFO.first;
  inputFIFO.deq;
  metadataReg <= tpl_1(input);
  paramReg <= tpl_2(input);
  metaBits <= pack(tpl_1(input));  // Pack metadata to flat bits
  // Action parameters go into registers r1..rN
  // (C++ generator emits metaRead instructions for fields it needs)
endrule

rule writeBack if (state == WriteBack);
  metaT result = unpack(metaBits);  // Unpack modified bits back to struct
  outputFIFO.enq(result);
  state <= Fetch;
  pc <= 0;
endrule
```

### C++ Generator Changes

#### Field Offset Map

Add a `buildFieldOffsetMap()` method that walks the MetadataT struct and computes bit offsets:

```cpp
struct FieldInfo {
    uint32_t bitOffset;
    uint32_t bitWidth;
    cstring fullPath;  // e.g., "hdr.ethernet.dstAddr"
};

std::map<cstring, FieldInfo> fieldOffsets;
```

The map is built by recursively walking `IR::Type_Struct` fields, accumulating bit offsets. This uses the same layout that Bluespec `pack()` uses (MSB-first, field order).

#### Field Access (generateFieldAccess)

Replace the placeholder `fieldId = 1` with actual offset lookup:

```cpp
void generateFieldAccess(const IR::Member* member) {
    cstring fieldPath = buildFieldPath(member);  // e.g., "hdr.ipv4.ttl"
    auto it = fieldOffsets.find(fieldPath);
    // Load bit offset into a register
    uint8_t offsetReg = allocateRegister();
    generateConstant(it->second.bitOffset, offsetReg);
    // META_ACCESS read
    uint8_t destReg = getRegister(member);
    instructions.push_back(RiscVInstr::encodeP4Ext(
        destReg, RiscVInstr::META_ACCESS, offsetReg, 0, 0));
}
```

#### Field Write (in AssignmentStatement)

When the left side is a metadata field:
```cpp
cstring fieldPath = buildFieldPath(member);
uint8_t offsetReg = allocateRegister();
generateConstant(fieldOffsets[fieldPath].bitOffset, offsetReg);
instructions.push_back(RiscVInstr::encodeP4Ext(
    0, RiscVInstr::META_ACCESS, offsetReg, valueReg, 1));  // funct7[0]=1 for write
```

#### If/Else to Branches

```cpp
bool preorder(const IR::IfStatement* stmt) {
    // 1. Evaluate condition into a register
    visit(stmt->condition);
    uint8_t condReg = getRegister(stmt->condition);

    // 2. Emit BEQ condReg, x0, else_label (branch if false)
    size_t branchIdx = instructions.size();
    instructions.push_back(0);  // placeholder

    // 3. Emit true body
    visit(stmt->ifTrue);
    size_t jumpIdx = instructions.size();
    if (stmt->ifFalse) {
        instructions.push_back(0);  // placeholder for jump over else
    }

    // 4. Patch branch offset
    int16_t elseOffset = (instructions.size() - branchIdx);
    instructions[branchIdx] = RiscVInstr::beq(condReg, 0, elseOffset);

    // 5. Emit else body
    if (stmt->ifFalse) {
        visit(stmt->ifFalse);
        int16_t endOffset = (instructions.size() - jumpIdx);
        instructions[jumpIdx] = RiscVInstr::jal(0, endOffset);
    }

    return false;
}
```

Note: offsets are in instruction count (each = 1 PC increment), matching the core's `pc <= pc + 1` per instruction.

#### Comparison Operations

Fix the Neq implementation (currently broken):
```cpp
// Equ: XOR then SLTIU 1
// Neq: XOR then SLTU x0, temp (sets 1 if temp != 0)
```

Replace with: XOR → SLTU(rd, x0, temp) which correctly sets rd=1 when temp>0.

### CMake Integration

Add `RiscVActionGenerator.cpp` to `src/CMakeLists.txt`:
```cmake
set (P4FPGA_BACKEND_SRCS
    ...
    cpp/RiscVActionGenerator.cpp
)
set (P4FPGA_BACKEND_HDRS
    ...
    cpp/RiscVActionGenerator.h
)
```

### Test Plan

1. **BSV unit test**: Update `RiscVActionTest.bsv` to verify META_ACCESS read/write round-trip, ADD_HEADER/REM_HEADER state changes, CHECKSUM fold-carry, LOAD/STORE byte access
2. **C++ unit test**: Update `RiscVActionGeneratorTest.cpp` to validate generated instruction sequences (check field offsets, branch offsets, instruction encodings)
3. **Integration**: The existing `sample.p4` demo should compile through the updated generator and produce correct RISC-V programs

## File Changes

| File | Change |
|------|--------|
| `src/bsv/library/RiscVActionCore.bsv` | Add metaBits register, implement META_ACCESS/ADD_HEADER/REM_HEADER/CHECKSUM/LOAD/STORE, fix startExecution/writeBack |
| `src/cpp/RiscVActionGenerator.h` | Add FieldInfo, fieldOffsets map, buildFieldOffsetMap(), if/else handler |
| `src/cpp/RiscVActionGenerator.cpp` | Implement field offset computation, field access/write, if/else→branch, fix Neq |
| `src/CMakeLists.txt` | Add RiscVActionGenerator.cpp/.h to build |
| `src/bsv/library/test/RiscVActionTest.bsv` | Add META_ACCESS round-trip, header state, checksum tests |
| `src/cpp/test/RiscVActionGeneratorTest.cpp` | Add instruction sequence validation tests |
