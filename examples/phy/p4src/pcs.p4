header_type sync_t {
	fields {
		syncbit : 2;
	}
}

header_type data_block_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type ctrl_block_t {
	fields {
		pcs_type : 8;
	}
}

header_type type_1e_t {
	fields {
		c0 : 7;
		c1 : 7;
		c2 : 7;
		c3 : 7;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_2d_t {
	fields {
		c0 : 7;
		c1 : 7;
		c2 : 7;
		c3 : 7;
		o4 : 4;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type type_33_t {
	fields {
		c0 : 7;
		c1 : 7;
		c2 : 7;
		c3 : 7;
		idle : 4;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type type_66_t {
	fields {
		d1 : 8;
		d2 : 8;
		d3 : 8;
		o0 : 4;
		idle : 4;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type type_55_t {
	fields {
		d1 : 8;
		d2 : 8;
		d3 : 8;
		o0 : 4;
		o4 : 4;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type type_78_t {
	fields {
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type type_4b_t {
	fields {
		d1 : 8;
		d2 : 8;
		d3 : 8;
		o0 : 4;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_87_t {
	fields {
		idle : 7;
		c1 : 7;
		c2 : 7;
		c3 : 7;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_99_t {
	fields {
		d0 : 8;
		idle : 6;
		c2 : 7;
		c3 : 7;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_aa_t {
	fields {
		d0 : 8;
		d1 : 8;
		idle : 5;
		c3 : 7;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_b4_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		idle : 4;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_cc_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		idle : 3;
		c5 : 7;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_d2_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		idle : 2;
		c6 : 7;
		c7 : 7;
	}
}

header_type type_e1_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		d5 : 8;
		idle : 1;
		c7 : 7;
	}
}

header_type type_ff_t {
	fields {
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		d5 : 8;
		d6 : 8;
	}
}

header_type metadata_t {
	fields {
		c0 : 7;
		c1 : 7;
		c2 : 7;
		c3 : 7;
		c4 : 7;
		c5 : 7;
		c6 : 7;
		c7 : 7;
		d0 : 8;
		d1 : 8;
		d2 : 8;
		d3 : 8;
		d4 : 8;
		d5 : 8;
		d6 : 8;
		d7 : 8;
	}
}

header_type xgmii_t {
	fields {
		ctrl0 : 1;
		data0 : 8;
		ctrl1 : 1;
		data1 : 8;
		ctrl2 : 1;
		data2 : 8;
		ctrl3 : 1;
		data3 : 8;
		ctrl4 : 1;
		data4 : 8;
		ctrl5 : 1;
		data5 : 8;
		ctrl6 : 1;
		data6 : 8;
		ctrl7 : 1;
		data7 : 8;
	}
}

header sync_t sync;
header data_block_t data_block;
header ctrl_block_t ctrl_block;
header type_1e_t type_1e;
header type_2d_t type_2d;
header type_33_t type_33;
header type_66_t type_66;
header type_55_t type_55;
header type_78_t type_78;
header type_4b_t type_4b;
header type_87_t type_87;
header type_99_t type_99;
header type_aa_t type_aa;
header type_b4_t type_b4;
header type_cc_t type_cc;
header type_d2_t type_d2;
header type_e1_t type_e1;
header type_ff_t type_ff;
header xgmii_t xgmii;
header metadata_t pcs_md;

parser start {
	extract(sync);
	return select (sync.syncbit) {
		0x01: parse_data_block;
		0x10: parse_ctrl_block;
	}
}

parser parse_data_block {
	extract(data_block);
	return ingress;
}

parser parse_ctrl_block {
	extract(ctrl_block);
	return select (latest.pcs_type) {
		0x1e: parse_1e;
		0x2d: parse_2d;
		0x33: parse_33;
		0x66: parse_66;
		0x55: parse_55;
		0x78: parse_78;
		0x4b: parse_4b;
		0x87: parse_87;
		0x99: parse_99;
		0xaa: parse_aa;
		0xb4: parse_b4;
		0xcc: parse_cc;
		0xd2: parse_d2;
		0xe1: parse_e1;
		0xff: parse_ff;
	}
}

parser parse_1e {
	extract(type_1e);
	set_metadata(pcs_md.c0, latest.c0);
	set_metadata(pcs_md.c1, latest.c1);
	set_metadata(pcs_md.c2, latest.c2);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_2d {
	extract(type_2d);
	set_metadata(pcs_md.c0, latest.c0);
	set_metadata(pcs_md.c1, latest.c1);
	set_metadata(pcs_md.c2, latest.c2);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	set_metadata(pcs_md.d7, latest.d7);
	return ingress;
}

parser parse_33 {
	extract(type_33);
	set_metadata(pcs_md.c0, latest.c0);
	set_metadata(pcs_md.c1, latest.c1);
	set_metadata(pcs_md.c2, latest.c2);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	set_metadata(pcs_md.d7, latest.d7);
	return ingress;
}

parser parse_66 {
	extract(type_66);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	set_metadata(pcs_md.d7, latest.d7);
	return ingress;
}

parser parse_55 {
	extract(type_55);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	set_metadata(pcs_md.d7, latest.d7);
	return ingress;
}

parser parse_78 {
	extract(type_78);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d4, latest.d4);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	set_metadata(pcs_md.d7, latest.d7);
	return ingress;
}

parser parse_4b {
	extract(type_4b);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_87 {
	extract(type_87);
	set_metadata(pcs_md.c1, latest.c1);
	set_metadata(pcs_md.c2, latest.c2);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_99 {
	extract(type_99);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.c2, latest.c2);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_aa {
	extract(type_aa);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.c3, latest.c3);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_b4 {
	extract(type_b4);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.c4, latest.c4);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_cc {
	extract(type_cc);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.c5, latest.c5);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_d2 {
	extract(type_d2);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d4, latest.d4);
	set_metadata(pcs_md.c6, latest.c6);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_e1 {
	extract(type_e1);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d4, latest.d4);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.c7, latest.c7);
	return ingress;
}

parser parse_ff {
	extract(type_ff);
	set_metadata(pcs_md.d0, latest.d0);
	set_metadata(pcs_md.d1, latest.d1);
	set_metadata(pcs_md.d2, latest.d2);
	set_metadata(pcs_md.d3, latest.d3);
	set_metadata(pcs_md.d4, latest.d4);
	set_metadata(pcs_md.d5, latest.d5);
	set_metadata(pcs_md.d6, latest.d6);
	return ingress;
}

action do_decode_1e () {
	remove_header(type_1e);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x7F);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, 0x7F);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, 0x7F);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, 0x7F);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0x7F);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, 0x7F);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, 0x7F);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, 0x7F);
	add_header(xgmii);
}

table decode_1e {
	actions {
		do_decode_1e;
	}
}

action do_decode_2d () {
	remove_header(type_2d);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x7F);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, 0x7F);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, 0x7F);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, 0x7F);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0x9C);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.d7);
	add_header(xgmii);
}

table decode_2d {
	actions {
		do_decode_2d;
	}
}

action do_decode_33 () {
	remove_header(type_33);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x7F);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, 0x7F);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, 0x7F);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, 0x7F);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0xFB);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.d7);
	add_header(xgmii);
}

table decode_33 {
	actions {
		do_decode_33;
	}
}

action do_decode_66 () {
	remove_header(type_66);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x9C);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0xFB);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.d7);
	add_header(xgmii);
}

table decode_66 {
	actions {
		do_decode_66;
	}
}

action do_decode_55 () {
	remove_header(type_55);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x9C);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0x9C);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.d7);
	add_header(xgmii);
}

table decode_55 {
	actions {
		do_decode_55;
	}
}

action do_decode_78 () {
	remove_header(type_78);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0xFB);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.d4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.d7);
	add_header(xgmii);
}

table decode_78 {
	actions {
		do_decode_78;
	}
}

action do_decode_4b () {
	remove_header(type_4b);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0x9C);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.c4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_4b {
	actions {
		do_decode_4b;
	}
}

action do_decode_87 () {
	remove_header(type_87);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, 0xfd);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.c1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.c2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.c3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.c4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_87 {
	actions {
		do_decode_87;
	}
}

action do_decode_99 () {
	remove_header(type_99);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, 0xfd);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.c2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.c3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.c4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_99 {
	actions {
		do_decode_99;
	}
}

action do_decode_aa () {
	remove_header(type_aa);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, 0xfd);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.c3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.c4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_aa {
	actions {
		do_decode_aa;
	}
}

action do_decode_b4 () {
	remove_header(type_b4);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, 0xfd);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.c4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_b4 {
	actions {
		do_decode_b4;
	}
}

action do_decode_cc () {
	remove_header(type_cc);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, 0xfd);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.c5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_cc {
	actions {
		do_decode_cc;
	}
}

action do_decode_d2 () {
	remove_header(type_d2);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.d4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, 0xfd);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.c6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_d2 {
	actions {
		do_decode_d2;
	}
}

action do_decode_e1 () {
	remove_header(type_e1);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.d4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, 0xfd);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, pcs_md.c7);
	add_header(xgmii);
}

table decode_e1 {
	actions {
		do_decode_e1;
	}
}

action do_decode_ff () {
	remove_header(type_ff);
	modify_field(xgmii.ctrl0, 1);
	modify_field(xgmii.data0, pcs_md.d0);
	modify_field(xgmii.ctrl1, 1);
	modify_field(xgmii.data1, pcs_md.d1);
	modify_field(xgmii.ctrl2, 1);
	modify_field(xgmii.data2, pcs_md.d2);
	modify_field(xgmii.ctrl3, 1);
	modify_field(xgmii.data3, pcs_md.d3);
	modify_field(xgmii.ctrl4, 1);
	modify_field(xgmii.data4, pcs_md.d4);
	modify_field(xgmii.ctrl5, 1);
	modify_field(xgmii.data5, pcs_md.d5);
	modify_field(xgmii.ctrl6, 1);
	modify_field(xgmii.data6, pcs_md.d6);
	modify_field(xgmii.ctrl7, 1);
	modify_field(xgmii.data7, 0xfd);
	add_header(xgmii);
}

table decode_ff {
	actions {
		do_decode_ff;
	}
}

action _nop () {
}

table forward {
	actions {
		_nop;
	}
}

control ingress {
	if (ctrl_block.pcs_type == 0x1e) {
		apply(decode_1e);
	} else if (ctrl_block.pcs_type == 0x2d) {
		apply(decode_2d);
	} else if (ctrl_block.pcs_type == 0x33) {
		apply(decode_33);
	} else if (ctrl_block.pcs_type == 0x66) {
		apply(decode_66);
	} else if (ctrl_block.pcs_type == 0x55) {
		apply(decode_55);
	} else if (ctrl_block.pcs_type == 0x78) {
		apply(decode_78);
	} else if (ctrl_block.pcs_type == 0x4b) {
		apply(decode_4b);
	} else if (ctrl_block.pcs_type == 0x87) {
		apply(decode_87);
	} else if (ctrl_block.pcs_type == 0x99) {
		apply(decode_99);
	} else if (ctrl_block.pcs_type == 0xaa) {
		apply(decode_aa);
	} else if (ctrl_block.pcs_type == 0xb4) {
		apply(decode_b4);
	} else if (ctrl_block.pcs_type == 0xcc) {
		apply(decode_cc);
	} else if (ctrl_block.pcs_type == 0xd2) {
		apply(decode_d2);
	} else if (ctrl_block.pcs_type == 0xe1) {
		apply(decode_e1);
	} else if (ctrl_block.pcs_type == 0xff) {
		apply(decode_ff);
	} else {
		apply(forward);
	}
}

control egress {
}
