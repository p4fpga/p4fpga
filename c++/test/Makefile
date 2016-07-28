THISDIR := $(realpath .)

EXECUTABLE = run_all_tests

UNAME    := $(shell uname)

CPPFLAGS =

INCLUDES = \
 -I $(THISDIR)/../libp4fpga/include \
 -I $(P4C_HOME)/build \
 -I $(THISDIR)/../ext/include \
 -I $(P4C_HOME) 

LDFLAGS = \
 -L $(THISDIR)/../ext/lib \
 -L $(THISDIR)/../libp4fpga/bin \
 -L $(P4C_HOME)/build \
 -lgtest \
 -lfpgabackend \
 -lp4ctoolkit \
 -lfrontend \
 -lgmp \
 -lgmpxx \
 -lgc 

ifeq ($(UNAME), Linux)
LDFLAGS += \
	-Wl,-rpath,$(THISDIR)/../ext/lib \
        -Wl,-rpath,$(THISDIR)/../libp4fpga/bin \
        -Wl,-rpath,$(P4C_HOME)/build 
endif

include ../Makefile.exe
