
ROOT_DIR=~/dev/p4fpga/pif_ir
P4PAXOS:=~/dev/p4paxos/p4src
PYPATH=PYTHONPATH=${ROOT_DIR}

objects:=$(wildcard tests/*.p4)

%:
	python bsvgen.py -o build/$@.bsv tests/$@.p4;

clean:
	rm *.pyc

doc:
	doxygen Doxyfile
