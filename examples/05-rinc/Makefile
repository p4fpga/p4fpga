P4FILE=p4src/rinc.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=rinc
CONNECTALFLAGS += -D TYPEDEF=StructGenerated

build:
	p4fpga -v --top4 Evaluator --p4-14 -Tfcontrol:1,fprogram:1 $(P4FILE) -o generatedbsv

include ../Makefile.common
