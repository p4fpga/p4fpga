
P4PAXOS:=~/dev/p4paxos/p4src

objects:=$(wildcard tests/*.p4)

%:
	python bsvgen.py tests/$@.p4;

clean:
	rm *.pyc

doc:
	doxygen Doxyfile
