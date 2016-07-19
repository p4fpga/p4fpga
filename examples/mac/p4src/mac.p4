header_type avalon_st_t {
	fields {
		sop : 1;
		eop : 1;
		data : 64;
	}
}

header avalon_st_t avalon_st;

parser start {
	extract(avalon_st);
	return select (avalon_st.sop, avalon_st.eop) {
		'h1: parse_eop;
		'h2: parse_sop;
	}
}

control ingress {

}

control egress {

}
