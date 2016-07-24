THISDIR := $(realpath .)

LIBRARY = libfpgabackend.so

P4C_HOME ?=  $(THISDIR)/../../../p4c

CPPFLAGS = 

INCLUDES = \
 -isystem /opt/local/libcpp-software/include \
 -I /usr/local/include \
 -I $(P4C_HOME)/build \
 -I $(P4C_HOME)


LDFLAGS = \
 -L /opt/local/libcpp-software/lib 

include ../Makefile.lib

