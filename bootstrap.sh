#!/bin/bash

mydir=`dirname $0`
cd $mydir

mkdir -p p4c/extensions

pushd p4c/extensions
if [ ! -e p4fpga ]; then ln -sf ../../src p4fpga; fi
popd

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=DEBUG -DCMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_CXX_COMPILER=/usr/bin/g++ $*

