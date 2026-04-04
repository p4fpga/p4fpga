# Makefile for RISC-V Action Processor tests

CONNECTALDIR?=$(HOME)/p4fpga/connectal
BSVPATH = ../../library:../../datapath:../../infra

BSC=bsc
BSCFLAGS=-p +:$(CONNECTALDIR)/bsv:$(BSVPATH)
BSCFLAGS+= -keep-fires -aggressive-conditions
BSCFLAGS+= -steps-max-intervals 20
BSCFLAGS+= +RTS -K256M -RTS
BSCFLAGS+= -show-schedule -show-compiles
BSCFLAGS+= -suppress-warnings T0127
BSCFLAGS+= -D SIMULATION
BSCFLAGS+= -opt-undetermined-vals -unspecified-to X

all: bluesim

riscv_action_test.bluesim: RiscVActionTest.bsv
	mkdir -p build
	$(BSC) $(BSCFLAGS) -sim -g mkRiscVActionTestSim -u RiscVActionTest.bsv
	$(BSC) $(BSCFLAGS) -sim -e mkRiscVActionTestSim -o build/riscv_action_test

bluesim: riscv_action_test.bluesim
	cd build && ./riscv_action_test

clean:
	rm -rf build *_sim *.bo *.ba