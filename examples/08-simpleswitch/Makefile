P4FILE=../../p4c/tests/simple_router.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=simple_router
CONNECTALFLAGS += -D TYPEDEF=StructGenerated

build:
	 p4fpga -o generatedbsv --p4-14 $(P4FILE)

#CONNECTALFLAGS += --bscflags="-fdir $(P4FPGADIR)/examples/multiproto/generatedbsv"
include ../Makefile.common
