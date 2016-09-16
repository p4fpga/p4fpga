P4FILE=../../p4c/tests/07-MultiProtocol.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D TYPEDEF=StructDefines

build:
	p4fpga --p4-14 -o generatedbsv $(P4FILE)
include ../Makefile.common
