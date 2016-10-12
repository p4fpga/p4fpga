P4FILE=p4src/simple_router.p4

CONNECTALDIR?=$(DEV_ROOT)/connectal
P4FPGADIR?=$(DEV_ROOT)/p4fpga

CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/library
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/datapath
CONNECTALFLAGS += --bsvpath=$(P4FPGADIR)/bsv/infra
#CONNECTALFLAGS += --bsvpath=generatedbsv

CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines
CONNECTALFLAGS += -m matchtable_model.cpp
CONNECTALFLAGS += -D NUM_RXCHAN=1
CONNECTALFLAGS += -D NUM_TXCHAN=1
CONNECTALFLAGS += -D NUM_HOSTCHAN=1
CONNECTALFLAGS += -D STREAM

CPPFILES = $(P4FPGADIR)/cpp/main.cpp $(P4FPGADIR)/cpp/lpcap.c app_init.cpp

build:
	p4fpga -o generatedbsv --p4-14 -v -Tdeparser:1,action:1 $(P4FILE)

include ../Makefile.common
BSVFILES+=generatedbsv/ConnectalTypes.bsv
BSVFILES+=$(P4FPGADIR)/bsv/library/DbgDefs.bsv
