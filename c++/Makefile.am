
bin_PROGRAMS += p4fpga/c++/libp4fpga/bin

p4fpga/libp4fpga/src_LDADD = libfrontend.a libp4ctoolkit.a

p4fpga/libp4fpga/src_SOURCES = \
	extensions/c++/libp4fpga/src/p4-c++/libp4fpga/src.cpp \
	extensions/c++/libp4fpga/include/backend.h \
	extensions/c++/libp4fpga/src/backend.cpp \
	extensions/c++/libp4fpga/include/codegen.h \
	extensions/c++/libp4fpga/src/codegen.cpp \
	extensions/c++/libp4fpgaincludesrc/string_utils.h \
	extensions/c++/libp4fpga/src/string_utils.cpp \
	extensions/c++/libp4fpga/include/ftype.h \
	extensions/c++/libp4fpga/src/ftype.cpp \
	extensions/c++/libp4fpga/include/fparser.h \
	extensions/c++/libp4fpga/src/fparser.cpp \
	extensions/c++/libp4fpga/src/fdeparser.cpp \
	extensions/c++/libp4fpga/include/fcontrol.h \
	extensions/c++/libp4fpga/src/fcontrol.cpp \
	extensions/c++/libp4fpga/src/fprogram.cpp \
	extensions/c++/libp4fpga/include/translator.h \
	extensions/c++/libp4fpga/src/translator.cpp \
	extensions/c++/libp4fpga/include/ftest.h \
	extensions/c++/libp4fpga/src/ftest.cpp \
	extensions/c++/libp4fpga/include/midend.h \
	extensions/c++/libp4fpga/src/midend.cpp

cpplint_FILES += $(p4c++/libp4fpga/src_SOURCES)

ir_DEF_FILES += $(srcdir)/extensions/c++/bluespec.def
#ir_SOURCES += extensions/c++/libp4fpga/src/bluespec.cpp
