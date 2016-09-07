DPL_BENCHMARK=../../submodules/dpl-benchmark/
P4FILE=$(DPL_BENCHMARK)/n_tables/p4src/n_tables.p4
CONNECTALFLAGS += -D PARSER=n_tables
CONNECTALFLAGS += -D DEPARSER=n_tables
CONNECTALFLAGS += -D MATCHTABLE=n_tables
CONNECTALFLAGS += -D TYPEDEF=n_tables
include ../Makefile.common
