THISDIR := $(realpath .)

LIBRARY = libfpgabackend.so

P4C_HOME ?=  $(THISDIR)/../../../p4c

CPPFLAGS = 

INCLUDES = \
 -I $(P4C_HOME)/build \
 -I $(P4C_HOME)

LDFLAGS = \
 -L $(P4C_HOME)/build \
 -lgc \
 -lgmp \
 -lfrontend \
 -lp4ctoolkit

include ../Makefile.lib

