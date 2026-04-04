# RISC-V Action Processor for P4FPGA

This extension adds a RISC-V based action processor to P4FPGA, making P4 actions more programmable and flexible while maintaining high performance.

## Overview

The RISC-V Action Processor replaces the fixed-function action implementation in P4FPGA with a programmable processor core specifically designed for packet processing. 

Key features:
- Lightweight RISC-V core with custom instructions for common packet operations
- P4 actions compiled to RISC-V assembly code
- Hardware acceleration for critical networking operations
- Compatible with existing P4FPGA pipeline architecture

## Architecture

The architecture consists of:

1. **RISC-V Action Core (RiscVActionCore.bsv)**
   - Implements a RISC-V CPU with custom packet processing extensions
   - Handles metadata/register mapping between P4 and processor state
   - Provides debug interfaces

2. **RISC-V Action Generator (RiscVActionGenerator.h/cpp)**
   - Translates P4 actions into RISC-V instructions
   - Supports standard arithmetic, logical operations, and custom P4 operations
   - Generates Bluespec code to instantiate the processor

3. **Action Engine Integration (action.cpp)**
   - Integrates the RISC-V processor into the P4FPGA pipeline
   - Supports both traditional and RISC-V based action implementations

## Custom RISC-V Instructions

The processor extends the standard RISC-V ISA with P4-specific instructions:

- `EXT_FIELD`: Extract bit fields from header values
- `INS_FIELD`: Insert bit fields into header values
- `ADD_HEADER`: Add a new header to a packet
- `REM_HEADER`: Remove a header from a packet
- `CHECKSUM`: Calculate checksums efficiently
- `TBL_LOOKUP`: Perform table lookups
- `PKT_MODIFY`: Modify packet data
- `META_ACCESS`: Access metadata fields

## Running Tests

### Bluespec Tests

To run the Bluespec simulator tests:

```bash
cd src/bsv/library/test
make
```

This will compile and run a series of tests that verify the RISC-V core operation with different types of actions.

### C++ Action Generator Tests

To run the P4-to-RISC-V code generator tests:

```bash
cd src/cpp/test
make run
```

This will compile and run tests that verify the RISC-V instruction generation from P4 actions.

## Demo Example

A demonstration P4 program is provided in `src/examples/riscv_demo/`. To compile it:

```bash
cd src/examples/riscv_demo
make
```

This generates Bluespec code using the RISC-V action processor for the following actions:

1. `update_counters`: Simple arithmetic operations
2. `complex_forward`: Conditional branching logic  
3. `calculate_custom_checksum`: Custom checksum calculation

## Performance and Tradeoffs

The RISC-V implementation offers key advantages:

- **Programmability**: Actions can be modified without requiring FPGA resynthesis
- **Flexibility**: Complex control flow is more easily expressed
- **Resource Efficiency**: Multiple actions share the same hardware

However, there are tradeoffs:

- **Latency**: Multi-cycle execution vs. single-cycle for simple actions
- **Throughput**: Sequential execution vs. fully pipelined operation

For critical applications, P4FPGA can still use the original fixed-function action implementation where maximum performance is required.

## Future Work

Planned enhancements:

1. Specialized instruction extensions for specific networking domains
2. Multi-core action processor for parallel action execution
3. Advanced compiler optimizations for P4-to-RISC-V code generation
4. Integration with runtime control plane for action program updates