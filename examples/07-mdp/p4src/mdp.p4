#include "parser.p4"

action dedup () {
	modify_field(mdp.msgSeqNum, 0);
}

table tbl_bloomfilter {
	actions {
		dedup;
	}
}

action drop() {
}

action forward() {
}

table tbl_forward {
	actions {
		forward;
	}
}

table tbl_drop {
	actions {
		drop;
	}
}

control ingress {
	apply(tbl_bloomfilter);
	if (dedup.notPresent == 1) {
		apply(tbl_forward);
	} else {
		apply(tbl_drop);
	}
}
