#-
# Copyright (c) 2013, 2014 Alexandre Joannou
# All rights reserved.
#
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
# ("CTSRD"), as part of the DARPA CRASH research programme.
#
# @BERI_LICENSE_HEADER_START@
#
# Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  BERI licenses this
# file to you under the BERI Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.beri-open-systems.org/legal/license-1-0.txt
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @BERI_LICENSE_HEADER_END@
#

CONNECTALDIR=/home/hwang/dev/connectal/bsv
QUARTUS_SIM_LIB=/usr/groups/ecad/altera/13.0sp1/quartus/eda/sim_lib/

TEST_BENCHs=Tb2

tests: tests_bluesim #tests_verilog

tests_bluesim: $(addprefix test_bluesim, $(TEST_BENCHs))

tests_verilog: $(addprefix test_verilog, $(TEST_BENCHs))

test_bluesim%: bluesim%
	simdir/$< > $@.out 2>&1

bluesim%: %.bsv mem_model.o
	mkdir -p bdir
	rm -f bdir/AsymmetricBRAM.bo
	bsc -D BSIM -bdir bdir $(CONNECTALDIR)/Pipe.bsv
	bsc -D BSIM -bdir bdir -I $(CONNECTALDIR) AsymmetricBRAM.bsv
	bsc -sim -bdir bdir -u $<
	mkdir -p simdir
	bsc -o simdir/$@ -sim -p bdir:simdir -simdir simdir -e mk$(basename $<) mem_model.o
	#dot -Tsvg *.dot -O
	#neato -Tsvg *.dot -O
	#twopi -Tsvg *.dot -O
	#circo -Tsvg *.dot -O

mem_model.o: mem_model.c
	echo "compiling $@"
	$(CC) -fPIC -c $< -o $@

test_verilog%: verilog%
	vsim -c -do "\
	force -freeze sim:/mk$(<:verilog%=%)/CLK 1 0, 0 {50 ps} -r 100;\
	force -freeze sim:/mk$(<:verilog%=%)/RST_N 0 0;\
	run 500ps;\
	force -freeze sim:/mk$(<:verilog%=%)/RST_N 1 0;\
	run 10ns;\
	" -L altera_mf -lib work_mk$(<:verilog%=%) mk$(<:verilog%=%) > $@.out
	sed -i '1,/# run 10ns/d;s/^..//' $@.out

verilog%: %.bsv altera_mf
	mkdir -p bdir
	rm -f bdir/AsymmetricBRAM.bo
	bsc -bdir bdir AsymmetricBRAM.bsv
	bsc -verilog -p +:bdir -bdir bdir -u $<
	bsc -o $@ -verilog -p ./altera_mf/:+ -e mk$(basename $<)

altera_mf:
	vlib altera_mf
	vlog -work altera_mf $(QUARTUS_SIM_LIB)/altera_mf.v

clean:
	rm -f Tb*.out
	rm -f vpi_*
	rm -f *.cxx *.h *.o *.ba *.bo *.so
	rm -rf bdir
	rm -rf simdir
	rm -f sim*
	rm -f verilog*
	rm -f *.dot *.svg
	rm -f test_*.out
	rm -f mkTb*.v
	rm -rf altera_mf
	rm -f vsim.wlf
	rm -rf work_mkTb*
	rm -f transcript

.PHONY: clean tests
