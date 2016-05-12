
###########################################
# Environment
###########################################
ifeq ($(DEV_ROOT), )
    $(error DEV_ROOT not define)
endif

CONNECTALDIR?=$(DEV_ROOT)/connectal
SONICDIR?=$(DEV_ROOT)/sonic-lite
P4FPGADIR?=$(DEV_ROOT)/p4fpga
BIRDIR?=$(DEV_ROOT)/p4fpga/pif_ir
PYPATH?=PYTHONPATH=${BIRDIR}

###########################################
# Connectal Support
###########################################
S2H_INTERFACES=MainRequest:Main.request
H2S_INTERFACES=Main:MainIndication
BSVFILES=Main.bsv MainAPI.bsv
CPPFILES=main.cpp
CPPFILES += $(SONICDIR)/sw/lpcap.c
CONNECTALFLAGS += -D NicVersion=$(shell printf "%d" 0x`git rev-parse --short=8 HEAD`)

###########################################
# P4FPGA
###########################################

P4FILE=simple.p4

ALL: codegen simgen bitgen

codegen: $(P4FILE)
	${PYPATH} python ${P4FPGADIR}/p4c/start.py -y -f ${P4FILE}
	${PYPATH} python ${P4FPGADIR}/p4c/bsvgen.py -y $(P4FILE:p4=yml) -o $(P4FILE:p4=bsv)

simgen: codegen
	make build.verilator

bitgen: codegen
	make build.nfsume

###########################################
# Default Rules
###########################################
include $(CONNECTALDIR)/Makefile.connectal
