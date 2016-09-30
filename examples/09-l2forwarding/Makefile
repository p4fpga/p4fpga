P4FILE=p4src/l2forwarding.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += --bsvpath=generatedbsv
CONNECTALFLAGS += -m matchtable_model.cpp
CPPFILES = $(P4FPGADIR)/cpp/main.cpp $(SONICDIR)/sw/lpcap.c app_init.cpp

build:
	p4fpga -o generatedbsv --p4-14 -v --top4 Evaluator -Tfcontrol:1,fparser:1 $(P4FILE)

compile:
	make build.bluesim -j8

include ../Makefile.common
BSVFILES += generatedbsv/ConnectalTypes.bsv
BSVFILES+=$(SONICDIR)/hw/bsv/DbgDefs.bsv
