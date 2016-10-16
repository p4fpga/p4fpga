P4FILE=p4src/simple_router.p4

CONNECTALDIR?=$(DEV_ROOT)/connectal
SONICDIR?=$(DEV_ROOT)/sonic-lite
P4EXAMPLEDIR=$(SONICDIR)/p4
P4FPGADIR?=$(DEV_ROOT)/p4fpga

CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/library
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/datapath
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/infra

CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += -m matchtable_model.cpp
CONNECTALFLAGS += -D NUM_RXCHAN=4
CONNECTALFLAGS += -D NUM_TXCHAN=4
CONNECTALFLAGS += -D NUM_HOSTCHAN=1
CONNECTALFLAGS += -D STREAM
#CONNECTALFLAGS += -D MEMORY

#CONNECTALFLAGS += --bsvpath=generatedbsv
CPPFILES = $(P4FPGADIR)/cpp/main.cpp $(SONICDIR)/sw/lpcap.c app_init.cpp

build:
	p4fpga -o generatedbsv --p4-14 -v --top4 Evaluator -Tfparser:1,fstruct:1,fcontrol:1,program:1 $(P4FILE)

run-thru:
	(cd bluesim; ./bin/ubuntu.exe -p ../${T} -r ${R} -n ${N})

include ../Makefile.common
BSVFILES+=generatedbsv/ConnectalTypes.bsv
BSVFILES+=$(P4FPGADIR)/bsv/library/DbgDefs.bsv

