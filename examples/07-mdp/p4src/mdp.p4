#include "parser.p4"

//action lookup_map () {
//	modify_field(meta.hash, bloom_hash);
//}
//
//table bloomhash {
//	actions {
//		bloomfilter;
//	}
//}
//
//table filter {
//	read {
//		meta.filter: exact;
//	}
//	action {
//		nop;
//		drop;
//	}
//}

control ingress {
//	apply(filter);
//	if (meta.filter) {
//		apply(forward);
//	} else {
//		apply(drop);
//	}
}
