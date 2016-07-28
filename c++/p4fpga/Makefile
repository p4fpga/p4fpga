THISDIR := $(realpath .)

EXECUTABLE = p4fpga

P4C_HOME ?=  $(THISDIR)/../../../p4c

CPPFLAGS = 

INCLUDES = \
 -I /usr/local/include \
 -I $(THISDIR)/../libp4fpga/include \
 -I $(P4C_HOME)/build \
 -I $(P4C_HOME)


LDFLAGS = \
 -L $(THISDIR)/../libp4fpga/bin \
 -L $(P4C_HOME)/build 

include ../Makefile.exe

