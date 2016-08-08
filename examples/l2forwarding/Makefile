DPL_BENCHMARK=../../submodules/dpl-benchmark/
P4FILE=$(DPL_BENCHMARK)/l2forwarding/p4src/l2forwarding.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=l2forwarding
CONNECTALFLAGS += -D TYPEDEF=StructGenerated
CONNECTALFLAGS += --bscflags="-fdir $(P4FPGADIR)/examples/l2forwarding/generatedbsv"

########################################################
# NFSUME SUPPORT
########################################################
ifeq ($(BOARD), nfsume)
AUTOTOP = --interface pins:MemoryTest.pins
PIN_TYPE = NfsumePins
PIN_TYPE_INCLUDE = NfsumePins
PIN_BINDINGS ?= LED:LED SFP:SFP SFPA:SFPA SFPB:SFPB SFPC:SFPC SFPD:SFPD
PINOUT_FILE = $(SONICDIR)/boards/nfsume.json
CONNECTALFLAGS += -D XILINX_SYS_CLK
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/ten_gig_eth_mac_0/ten_gig_eth_mac_0.xci
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/ten_gig_eth_pcs_pma_shared/ten_gig_eth_pcs_pma_shared.xci
CONNECTALFLAGS += --xci=$(IPDIR)/$(BOARD)/ten_gig_eth_pcs_pma_non_shared/ten_gig_eth_pcs_pma_non_shared.xci
CONNECTALFLAGS += --constraint=timing_constraints.xdc --implconstraint=timing_constraints.xdc
prebuild::
	(cd $(BOARD); BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) vivado -notrace -mode batch -source $(SONICDIR)/hw/scripts/generate-mac.tcl)
	(cd $(BOARD); BUILDCACHE_CACHEDIR=$(BUILDCACHE_CACHEDIR) $(BUILDCACHE) vivado -notrace -mode batch -source $(SONICDIR)/hw/scripts/connectal-synth-phy.tcl)
endif

include ../Makefile.common
