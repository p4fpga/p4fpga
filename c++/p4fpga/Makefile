THISDIR := $(realpath .)

EXECUTABLE = p4fpga

UNAME    := $(shell uname)

P4C_HOME ?=  $(THISDIR)/../../../p4c

CPPFLAGS = 

INCLUDES = \
 -I $(THISDIR)/../libp4fpga/include \
 -I $(P4C_HOME)/build \
 -I $(P4C_HOME)


LDFLAGS = \
 -L $(THISDIR)/../libp4fpga/bin \
 -L $(P4C_HOME)/build \
 -lfpgabackend \
 -lp4ctoolkit \
 -lfrontend \
 -lgmp \
 -lgmpxx \
 -lgc 

ifeq ($(UNAME), Linux)
LDFLAGS += \
        -Wl,-rpath,$(THISDIR)/../libp4fpga/bin \
        -Wl,-rpath,$(P4C_HOME)/build 
endif

include ../Makefile.exe

