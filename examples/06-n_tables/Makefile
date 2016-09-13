DPL_BENCHMARK=../../submodules/dpl-benchmark/
P4FILE=$(DPL_BENCHMARK)/n_tables/p4src/n_tables.p4
#P4FILE=$(DPL_BENCHMARK)/n_tables/p4src/main.p4
CONNECTALFLAGS += -D PARSER=Parser
CONNECTALFLAGS += -D DEPARSER=Deparser
CONNECTALFLAGS += -D MATCHTABLE=Control
CONNECTALFLAGS += -D TYPEDEF=StructDefines

build:
	p4fpga -o generatedbsv --p4-14 -v --top4 Evaluator -Tfcontrol:1,analyzer:1,action:1 $(P4FILE)

include ../Makefile.common
