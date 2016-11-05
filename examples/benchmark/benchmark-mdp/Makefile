P4FILE=p4src/mdp.p4

CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/library
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/datapath
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/infra

CONNECTALFLAGS += --bsvpath=$(CURDIR)/lib
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += --bsvpath=generatedbsv
#CONNECTALFLAGS += -m matchtable_model.cpp
CONNECTALFLAGS += -D NUM_RXCHAN=4
CONNECTALFLAGS += -D NUM_TXCHAN=4
CONNECTALFLAGS += -D NUM_HOSTCHAN=1
CONNECTALFLAGS += -D NUM_METAGEN=1
CONNECTALFLAGS += -D NUM_PKTGEN=4
CONNECTALFLAGS += -D STREAM
CONNECTALFLAGS += -D MDP
CONNECTALFLAGS += --bscflags="-fdir $(CURDIR)"

CPPFILES = $(P4FPGADIR)/cpp/main.cpp $(P4FPGADIR)/cpp/lpcap.c app_init.cpp
BSVFILES = $(P4FPGADIR)/bsv/infra/Main.bsv $(P4FPGADIR)/bsv/infra/MainAPI.bsv
BSVFILES += generatedbsv/ConnectalTypes.bsv
BSVFILES += $(P4FPGADIR)/bsv/library/DbgDefs.bsv


run-thru:
	(cd bluesim; ./bin/ubuntu.exe -p ../${T} -r ${R} -n ${N})

include ../../Makefile.common
#BSVFILES += $(SONICDIR)/hw/bsv/DbgDefs.bsv
