P4FILE=p4src/switch.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=fabric
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += --bsvpath=generatedbsv

build:
	p4fpga -v --top4 Evaluator --p4-14 -Tfcontrol:1,fprogram:1 $(P4FILE) -o generatedbsv

include ../Makefile.common
BSVFILES += generatedbsv/ConnectalTypeGenerated.bsv
