set (P4FPGA_BACKEND_SRCS
    cpp/action.cpp
    cpp/analyzer.cpp
    cpp/backend.cpp
    cpp/control.cpp
    cpp/deparser.cpp
    cpp/midend.cpp
    cpp/parser.cpp
    cpp/program.cpp
    cpp/string_utils.cpp
    cpp/struct.cpp
    cpp/table.cpp
    cpp/target.cpp
    cpp/type.cpp
    cpp/union.cpp
)

set (P4FPGA_BACKEND_HDRS
    cpp/action.h
    cpp/analyzer.h
    cpp/ast.h
    cpp/backend.h
    cpp/bsvprogram.h
    cpp/codegeninspector.h
    cpp/control.h
    cpp/deparser.h
    cpp/midend.h
    cpp/options.h
    cpp/parser.h
    cpp/program.h
    cpp/string_utils.h
    cpp/struct.h
    cpp/table.h
    cpp/type.h
    cpp/union.h
    cpp/vector_utils.h
)

set (P4FPGA_IR_DEF_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/ir/p4fpga.def
    )

set (IR_DEF_FILES ${IR_DEF_FILES} ${P4FPGA_IR_DEF_FILES} PARENT_SCOPE)

set (P4FPGA_SOURCES
    ${P4FPGA_BACKEND_SRCS}
    )

set (P4C_P4FPGA_SRCS
    cpp/p4-fpga.cpp
)

add_library(p4fpga_backend ${P4FPGA_SOURCES})
add_dependencies(p4fpga_backend genIR)

find_package(Boost REQUIRED COMPONENTS system filesystem)
include_directories(${Boost_INCLUDE_DIRS})

add_executable(p4c-p4fpga ${P4C_P4FPGA_SRCS})
target_link_libraries (p4c-p4fpga p4fpga_backend ${P4C_LIBRARIES} ${P4C_LIB_DEPS} ${Boost_SYSTEM_LIBRARY} ${Boost_FILESYSTEM_LIBRARY})
