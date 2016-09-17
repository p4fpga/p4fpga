P4FILE=simple_router.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += -m matchtable_model.cpp

CONNECTALFLAGS += --bsvpath=generatedbsv
CPPFILES = main.cpp $(SONICDIR)/sw/lpcap.c

build:
	p4fpga -o generatedbsv --p4-14 -v --top4 Evaluator -Tfcontrol:1,fparser:1 $(P4FILE)

compile:
	make build.bluesim -j8

include ../Makefile.common
BSVFILES += generatedbsv/APITypeDefGenerated.bsv
