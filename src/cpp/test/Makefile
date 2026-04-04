# Makefile for RISC-V Action Generator tests

P4C_DIR = ../../../p4c
FPGA_DIR = ../..
SRCDIR = $(P4C_DIR)
GCOV_ROOT = $(SRCDIR)
GCOV = 1

#include $(SRCDIR)/backends/backends.mk

CPPFLAGS += -I$(srcdir)/frontends -I$(srcdir)/backends -I$(srcdir)/extensions -I$(FPGA_DIR)/cpp -I$(FPGA_DIR)/ir

GTEST_ROOT = $(P4C_DIR)/test/frameworks/gtest
GTEST_INC = -I$(GTEST_ROOT)/include
GTEST_LIB = $(GTEST_ROOT)/lib/libgtest.a

LIBS = $(GTEST_LIB) $(P4C_LIBRARIES) $(P4C_LIB_DEPS) $(FPGA_LIBRARIES) -lgmp -lpthread

TESTS = risc_v_action_generator_test

risc_v_action_generator_test_SOURCES = RiscVActionGeneratorTest.cpp
risc_v_action_generator_test_CPPFLAGS = $(CPPFLAGS)
risc_v_action_generator_test_LDADD = $(LIBS)

all: $(TESTS)

# Generic rule for building executable from sources
% : %.cpp
	$(CXX) $< $($(basename $@)_CPPFLAGS) $(CPPFLAGS) $($(basename $@)_LDADD) $(LIBS) -o $@

run: all
	for test in $(TESTS); do \
		./$$test; \
	done

clean:
	rm -f $(TESTS) *.o
