P4FILE=p4src/mdp.p4
CONNECTALFLAGS += --bsvpath=$(CURDIR)/lib
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += --bsvpath=generatedbsv
CPPFILES = $(P4FPGADIR)/cpp/main.cpp $(SONICDIR)/sw/lpcap.c app_init.cpp

run-thru:
	(cd bluesim; ./bin/ubuntu.exe -p ../${T} -r ${R} -n ${N})

include ../Makefile.common
BSVFILES += $(SONICDIR)/hw/bsv/DbgDefs.bsv
