P4FILE=p4src/acceptor.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=acceptor
CONNECTALFLAGS += -D TYPEDEF=StructDefines

build:
	p4fpga -o generatedbsv --p4-14 -Tfcontrol:1,action:1,funion:1 -v --top4 Evaluator $(P4FILE)

###########################################
# Default Rules
###########################################
include ../Makefile.common
