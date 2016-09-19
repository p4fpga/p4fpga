P4_PARTITION_FILE=n_tables5.p4
P4_SIMPLIFIED_FILE=n_tables5-Simplify_10_Evaluator.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += -m matchtable_model.cpp

CONNECTALFLAGS += --bsvpath=generatedbsv
CPPFILES = main.cpp $(SONICDIR)/sw/lpcap.c

build:
	p4fpga -o generatedbsv -v --top4 Evaluator -Tfcontrol:1,fparser:1 $(P4_PARTITION_FILE)
	p4fpga -o generatedbsv -Tfcontrol:1,fparser:1 $(P4_SIMPLIFIED_FILE)

compile:
	make build.bluesim -j8

include ../Makefile.common
BSVFILES += generatedbsv/ConnectalTypes.bsv
