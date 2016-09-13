P4FILE=../../p4c/tests/simple_router.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=simple_router
CONNECTALFLAGS += -D TYPEDEF=StructDefines

build:
	#p4fpga -o generatedbsv --p4-14 -v -Tdeparser:1,action:1 $(P4FILE)
	make build.bluesim

#CONNECTALFLAGS += --bscflags="-fdir $(P4FPGADIR)/examples/multiproto/generatedbsv"
include ../Makefile.common
