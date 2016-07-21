
bin_PROGRAMS += p4fpga
p4fpga_LDADD = libfrontend.a libp4ctoolkit.a

p4fpga_SOURCES = \
	extensions/fpga/p4-fpga.cpp \
	extensions/fpga/backend.h \
	extensions/fpga/backend.cpp \
	extensions/fpga/codegen.h \
	extensions/fpga/codegen.cpp \
	extensions/fpga/string_utils.h \
	extensions/fpga/string_utils.cpp \
	extensions/fpga/ftype.h \
	extensions/fpga/ftype.cpp \
	extensions/fpga/fparser.h \
	extensions/fpga/fparser.cpp \
	extensions/fpga/fdeparser.cpp \
	extensions/fpga/fcontrol.h \
	extensions/fpga/fcontrol.cpp \
	extensions/fpga/fprogram.cpp \
	extensions/fpga/translator.h \
	extensions/fpga/translator.cpp \
	extensions/fpga/ftest.h \
	extensions/fpga/ftest.cpp \
	extensions/fpga/midend.h \
	extensions/fpga/midend.cpp

cpplint_FILES += $(p4fpga_SOURCES)

ir_DEF_FILES += $(srcdir)/extensions/fpga/bluespec.def
#ir_SOURCES += extensions/fpga/bluespec.cpp
