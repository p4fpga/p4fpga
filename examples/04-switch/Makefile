P4FILE=~/dev/p4c/testdata/p4_14_samples/switch_20160512/switch.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=fabric
CONNECTALFLAGS += -D TYPEDEF=StructDefines

build:
	p4fpga -v --top4 Evaluator --p4-14 -Ttable:1,action:1,fcontrol:1,fparser:1,fprogram:1 $(P4FILE) -o generatedbsv

include ../Makefile.common
