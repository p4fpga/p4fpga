P4PAXOS:=~/dev/p4paxos/p4src/


simple:
	python p4c-llvm.py tests/simple.p4
sonic:
	python p4c-llvm.py tests/sonic.p4
p4paxos:
	python p4c-llvm.py $(P4PAXOS)/paxos.p4

clean:
	rm *.pyc
