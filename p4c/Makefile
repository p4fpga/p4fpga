
ROOT_DIR=~/dev/p4fpga/pif_ir
P4PAXOS:=~/dev/p4paxos/p4src
PYPATH=PYTHONPATH=${ROOT_DIR}

simple:
	${PYPATH} python start.py -y -f tests/simple.p4
	${PYPATH} python bsvgen.py -y tests/simple.yml -o tests/simple.bsv

sonic:
	${PYPATH} python start.py -y -f tests/sonic.p4

p4paxos:
	${PYPATH} python start.py -y -f $(P4PAXOS)/paxos.p4
	${PYPATH} python bsvgen.py -y $(P4PAXOS)/paxos.yml -o $(P4PAXOS)/paxos.bsv

unit-test:
	${PYPATH} python start.py -y -f tests/golden_reference.p4
	${PYPATH} python bsvgen.py -y tests/golden_reference.yml -o tests/golden_reference.bsv

p4:
	python p4c-llvm.py $(P4PAXOS)/paxos.p4

caans:
	${PYPATH} python start.py -y -f tests/caans.p4
	${PYPATH} python bsvgen.py -y tests/caans.yml -o tests/caans.bsv

route:
	${PYPATH} python start.py -y -f tests/basic_routing.p4
	${PYPATH} python bsvgen.py -y tests/basic_routing.yml -o tests/basic_routing.bsv

clean:
	rm *.pyc

doc:
	doxygen Doxyfile
