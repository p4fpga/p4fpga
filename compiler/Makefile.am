
bin_PROGRAMS += p4fpga

p4fpga_LDFLAGS = -lboost_system -lboost_filesystem#-mt

p4fpga_LDADD = libfrontend.a libp4ctoolkit.a 

p4fpga_CPPFLAGS = -I$(srcdir)/extensions/c++/include

p4fpga_SOURCES = \
	extensions/c++/src/p4-fpga.cpp \
	extensions/c++/src/analyzer.cpp \
	extensions/c++/src/backend.cpp \
	extensions/c++/src/string_utils.cpp \
	extensions/c++/src/ftype.cpp \
	extensions/c++/src/fparser.cpp \
	extensions/c++/src/fstruct.cpp \
	extensions/c++/src/funion.cpp \
	extensions/c++/src/fdeparser.cpp \
	extensions/c++/src/fcontrol.cpp \
	extensions/c++/src/program.cpp \
	extensions/c++/src/translator.cpp \
	extensions/c++/src/ftest.cpp \
	extensions/c++/src/midend.cpp \
	extensions/c++/src/partition.cpp \
	extensions/c++/src/profile.cpp \
	extensions/c++/src/metadata-analysis.cpp \
	extensions/c++/src/table.cpp \
	extensions/c++/src/action.cpp

cpplint_FILES += $(p4fpga_SOURCES)

ir_DEF_FILES += $(srcdir)/extensions/c++/bluespec.def
#ir_SOURCES += extensions/c++/libp4fpga/src/bluespec.cpp
