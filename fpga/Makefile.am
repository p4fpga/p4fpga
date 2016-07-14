
bin_PROGRAMS += p4fpga
p4fpga_LDADD = libfrontend.a libp4ctoolkit.a

p4fpga_SOURCES = \
	extensions/fpga/p4-fpga.cpp \
	extensions/fpga/fbackend.h \
	extensions/fpga/fbackend.cpp \
	extensions/fpga/fparser.cpp \
	extensions/fpga/fdeparser.cpp \
	extensions/fpga/fcontrol.cpp \
	extensions/fpga/fprogram.cpp \
	extensions/fpga/midend.h \
	extensions/fpga/midend.cpp

cpplint_FILES += $(p4fpga_SOURCES)
