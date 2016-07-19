DPL_BENCHMARK=../../submodules/dpl-benchmark/
P4FILE=$(DPL_BENCHMARK)/l2forwarding/p4src/l2forwarding.p4
CONNECTALFLAGS += -D PARSER=parser
CONNECTALFLAGS += -D DEPARSER=l2forwarding
CONNECTALFLAGS += -D MATCHTABLE=l2forwarding
CONNECTALFLAGS += -D TYPEDEF=l2forwarding
include ../Makefile.common
