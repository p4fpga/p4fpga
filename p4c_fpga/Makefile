
ROOT_DIR=..
P4PAXOS:=~/dev/p4paxos/p4src/
PYPATH=PYTHONPATH=${ROOT_DIR}

simple:
	${PYPATH} python start.py -y -f tests/simple.p4
sonic:
	${PYPATH} python start.py -f tests/sonic.p4
p4paxos:
	${PYPATH} python start.py -f $(P4PAXOS)/paxos.p4
clean:
	rm *.pyc
