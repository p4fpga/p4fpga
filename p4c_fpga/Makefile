
ROOT_DIR=..
P4PAXOS:=~/p4paxos/p4src
PYPATH=PYTHONPATH=${ROOT_DIR}

simple:
	${PYPATH} python start.py -y -f tests/simple.p4
	${PYPATH} python bsvgen.py -y tests/simple.yml -o tests/simple.bsv

sonic:
	${PYPATH} python start.py -y -f tests/sonic.p4

p4paxos:
	${PYPATH} python start.py -y -f $(P4PAXOS)/paxos.p4
#	${PYPATH} python bsvgen.py -y $(P4PAXOS)/paxos.yml -o $(P4PAXOS)/paxos.bsv

p4:
	python p4c-llvm.py $(P4PAXOS)/paxos.p4

clean:
	rm *.pyc
