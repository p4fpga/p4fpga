
### Generated Bluespec Organization

**Main.bsv** : contains top level module for connectal framework.
- Runtime.bsv
- Program.bsv

**Runtime.bsv** : contains runtime environment for p4 program
- PHY + MAC
- Stream Arbitration (maybe part of program.bsv)
- Shared memory (optional)
- Stream Demultiplexer (maybe part of program.bsv)

**Program.bsv** : contains p4 program according to architecture specification in arch.p4
- Parser.bsv
- Deparser.bsv
- Control.bsv
- Table.bsv
- Action.bsv

**Parser.bsv** : contains parser implementation
- parser is usually instantiated on a per-port basis, to ensure scalability
- current implementation uses 128-bit datapath width @ 250 MHz

**Deparser.bsv** : contains deparser implementation
- current implementation uses 128-bit datpath width @ 250 MHz

**Control.bsv** : contains control flow and pipeline implementation
- instantiate p4 table and action engine
- connect table and action engine according to control flow

**Table.bsv** :
- per P4 table instance
- include simulation model for match table

**Action.bsv** :
- per P4 action instance
- include ALU / Bluespec operator / DSP-based action engine


### Compiler Organization 

**main.cpp** :
- generate Main.bsv
- Main(runtime, program)

**runtime.cpp** :
- generate Runtime.bsv
- Runtime()

**program.cpp** :
- generate Program.bsv
- Program(arch, runtime)

**pipeline.cpp** :
- generate Pipeline.bsv based on arch.p4
- arch specifies sequence of parser, deparser and control blocks
- v1model : parser -> ingress -> egress -> deparser

**control.cpp** :
- generate Control.bsv
- Control.bsv contain Ingress and Egress
- Ingress/Egress implement control flow for tables and actions
- Table/action can be empty to evaluate cost of pipeline.

**table.cpp** :
- implement p4 table (bcam, tcam)

**action.cpp** :
- implement p4 action
- dsp optimizes arithmetic and logic operations
- bluespec operator implement boolean operations
