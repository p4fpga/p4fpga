THISDIR := $(realpath .)

EXECUTABLE = run_all_tests

UNAME    := $(shell uname)

CPPFLAGS =

INCLUDES = \
	-isystem /opt/local/libcpp-software/include \
 	-I $(THISDIR)/../ext/include \

LDFLAGS = \
	-L $(THISDIR)/../ext/lib \
	-L /opt/local/libcpp-software/lib \
	-lgtest \

ifeq ($(UNAME), Linux)
LDFLAGS += \
	-Wl,-rpath,$(THISDIR)/../ext/lib \
	-Wl,-rpath,/opt/local/libcpp-software/lib 
endif

include ../Makefile.exe
