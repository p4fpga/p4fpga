#include "headers.p4"
#include "parser.p4"

action nop() {}

table drop {
	actions {
		nop;
	}
}

control ingress {
	apply(drop);
}

control egress {

}
