THISDIR := $(realpath .)

LIBRARY = libfpgabackend.so

P4C_HOME ?=  $(THISDIR)/../../../p4c

CPPFLAGS = 

INCLUDES = \
 -I $(P4C_HOME)/build \
 -I $(P4C_HOME)

LDFLAGS = \
 -L $(P4C_HOME)/build \
 -lp4ctoolkit \
 -lfrontend \
 -lboost_system \
 -lboost_filesystem-mt \
 -lgmp \
 -lgmpxx \
 -lgc 

include ../Makefile.lib

