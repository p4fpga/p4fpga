#!/usr/bin/make -f

SONIC=/home/hwang/dev/sonic-lite/hw/bsv
BSC=bsc
BSCFLAGS_V = -show-module-use -cross-info
BSCFLAGS_C = -p ../../:$(SONIC):+
# BSCFLAGS=-cross-info

VSIM=iverilog

SOURCES= Tb.bsv ../../XBar.bsv

.PHONY: help
help:
	@echo "Useful targets:"
	@echo "  mkTb.v           - compile to Verilog"
	@echo "  mkTb_v           - build iVerilog executabe"
	@echo "  runv             - build and run iVerilog executable"
	@echo "  mkTb_c           - build Bluesim executabe"
	@echo "  runc             - build and run Bluesim executable"
	@echo "  clean            - remove output and temporary files"

# ----------------------------------------------------------------
# Bluesim

mkTb.ba: $(SOURCES)
	$(BSC) $(BSCFLAGS_C) -sim -u Tb.bsv

mkTb_c: mkTb.ba
	$(BSC) -sim -e mkTb -o mkTb_c -u mkTb.ba

.PHONY: runc
runc: mkTb_c
	./mkTb_c

# ----------------------------------------------------------------
# compile to Verilog

mkTb.v: $(SOURCES)
	$(BSC) $(BSCFLAGS_V) -verilog -u  Tb.bsv

mkTb_v: mkTb.v
	$(BSC) -verilog -e mkTb -vsim $(VSIM) -o $@ $+

# invoke iverilog directly and link with main.v, and run it
.PHONY: runv
runv: mkTb_v
	./mkTb_v +bscvcd

# ----------------------------------------------------------------
# Synth

mkXBar4.v: $(SOURCES)
	$(BSC) $(BSCFLAGS_V) -verilog -u  Synth.bsv

mkXBar8.v: $(SOURCES)
	$(BSC) $(BSCFLAGS_V) -verilog -u  Synth.bsv

.PHONY: synth
synth: mkXBar4.v mkXBar8.v

# ----------------------------------------------------------------

.PHONY: clean
clean:
	rm -f *.bi *.bo  *.vcd *~  mk*.h  mk*.o  mk*.c  *.cdf  *.use  mk*.info  dump.* schedule.* *.ba mk*.cxx

.PHONY: realclean
realclean:
	make clean
	rm -r -f   mk*.v  mkTb_v  mkTb_c nWaveLog  vfastLog  debussy.rc
