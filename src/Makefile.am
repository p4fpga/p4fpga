p4fpga_LDFLAGS = -lboost_system -lboost_filesystem

p4fpga_CPPFLAGS = -I$(srcdir)/%reldir%/include

p4fpga_SOURCES = \
	%reldir%/src/p4-fpga.cpp \
	%reldir%/src/analyzer.cpp \
	%reldir%/src/backend.cpp \
	%reldir%/src/string_utils.cpp \
	%reldir%/src/type.cpp \
	%reldir%/src/parser.cpp \
	%reldir%/src/struct.cpp \
	%reldir%/src/union.cpp \
	%reldir%/src/deparser.cpp \
	%reldir%/src/control.cpp \
	%reldir%/src/program.cpp \
	%reldir%/src/midend.cpp \
	%reldir%/src/table.cpp \
	%reldir%/src/action.cpp

cpplint_FILES += $(p4fpga_SOURCES)

ir_DEF_FILES += \
	$(srcdir)/%reldir%/bluespec.def

bin_PROGRAMS += p4fpga

p4fpga_LDADD = libfrontend.la libp4ctoolkit.a
