
###########################################
# Environment
###########################################
ifeq ($(DEV_ROOT), )
    $(error DEV_ROOT not define)
endif

CONNECTALDIR?=$(DEV_ROOT)/connectal
SONICDIR?=$(DEV_ROOT)/sonic-lite
P4EXAMPLEDIR=$(SONICDIR)/p4
P4FPGADIR?=$(DEV_ROOT)/p4fpga
BIRDIR?=$(DEV_ROOT)/p4fpga/pif_ir
OFTESTDIR?=$(DEV_ROOT)/p4fpga/pif_ir/submodules/oftest/src/python
PYPATH?=PYTHONPATH=${BIRDIR}:${OFTESTDIR}

###########################################
# Connectal Support
###########################################
S2H_INTERFACES=MainRequest:Main.request
H2S_INTERFACES=Main:MainIndication,MemServerIndication
BSVFILES=Main.bsv MainAPI.bsv MainDefs.bsv
CPPFILES=main.cpp
CPPFILES += $(SONICDIR)/sw/lpcap.c
CONNECTALFLAGS += -I $(SONICDIR)/sw/
#CONNECTALFLAGS += --bsvpath=$(P4EXAMPLEDIR)/bsv/
CONNECTALFLAGS += --bsvpath=$(P4EXAMPLEDIR)/bsv/AsymmetricBRAM
CONNECTALFLAGS += --bsvpath=$(P4EXAMPLEDIR)/bsv/Bcam
CONNECTALFLAGS += --bsvpath=$(SONICDIR)/hw/bsv
CONNECTALFLAGS += --bsvpath=$(SONICDIR)/hw/generated
CONNECTALFLAGS += -D NicVersion=$(shell printf "%d" 0x`git rev-parse --short=8 HEAD`)
CONNECTALFLAGS += -D DataBusWidth=128
CONNECTALFLAGS += -D IMPORT_HOSTIF
CONNECTALFLAGS += -D BYTE_ENABLES
CONNECTALFLAGS += --bscflags="-show-range-conflict +RTS -K46777216 -RTS -demote-errors G0066:G0045 -suppress-warnings G0046:G0020:G0023:S0015:S0080:S0039 -steps-max-intervals 20"
CONNECTALFLAGS += -m $(P4EXAMPLEDIR)/bsv/AsymmetricBRAM/mem_model.c
CONNECTALFLAGS += -m matchtable_model.cpp
CONNECTALFLAGS += --nocache
CONNECTALFLAGS += --cxxflags=-std=c++11
BURST_LEN_SIZE=12

###########################################
# P4FPGA
###########################################

P4FILE=simple.p4
CONNECTALFLAGS += -D PARSER=Simple
#CONNECTALFLAGS += -D MATCHTABLE=MatchTableSim

ALL: codegen simgen

codegen: $(P4FILE)
	${PYPATH} python ${P4FPGADIR}/p4c/start.py -y -f ${P4FILE}
	${PYPATH} python ${P4FPGADIR}/p4c/bsvgen.py -y $(P4FILE:p4=yml) -o $(P4FILE:p4=bsv)

simgen: codegen
	make build.bluesim

run:
	(cd bluesim; ./bin/ubuntu.exe -p ../${T})

runyml:
	sudo ${PYPATH} python ${BIRDIR}/pif_ir/examples/bir/start.py simple.yml

bitgen: codegen
	make build.nfsume

clean:
	rm *.yml *.json
###########################################
# Default Rules
###########################################
include $(CONNECTALDIR)/Makefile.connectal
