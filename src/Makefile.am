
bin_PROGRAMS += p4fpga

p4fpga_LDFLAGS = -lboost_system -lboost_filesystem#-mt

p4fpga_LDADD = libfrontend.a libp4ctoolkit.a 

p4fpga_CPPFLAGS = -I$(srcdir)/extensions/c++/libp4fpga/include

p4fpga_SOURCES = \
	extensions/c++/p4fpga/src/p4-fpga.cpp \
	extensions/c++/libp4fpga/src/analyzer.cpp \
	extensions/c++/libp4fpga/src/backend.cpp \
	extensions/c++/libp4fpga/src/codegeninspector.cpp \
	extensions/c++/libp4fpga/src/string_utils.cpp \
	extensions/c++/libp4fpga/src/ftype.cpp \
	extensions/c++/libp4fpga/src/fparser.cpp \
	extensions/c++/libp4fpga/src/fstruct.cpp \
	extensions/c++/libp4fpga/src/funion.cpp \
	extensions/c++/libp4fpga/src/fdeparser.cpp \
	extensions/c++/libp4fpga/src/fcontrol.cpp \
	extensions/c++/libp4fpga/src/program.cpp \
	extensions/c++/libp4fpga/src/translator.cpp \
	extensions/c++/libp4fpga/src/ftest.cpp \
	extensions/c++/libp4fpga/src/midend.cpp \
	extensions/c++/libp4fpga/src/partition.cpp \
	extensions/c++/libp4fpga/src/profile.cpp \
	extensions/c++/libp4fpga/src/metadata-analysis.cpp \
	extensions/c++/libp4fpga/src/table.cpp \
	extensions/c++/libp4fpga/src/action.cpp

cpplint_FILES += $(p4fpga_SOURCES)

ir_DEF_FILES += $(srcdir)/extensions/c++/bluespec.def
#ir_SOURCES += extensions/c++/libp4fpga/src/bluespec.cpp
