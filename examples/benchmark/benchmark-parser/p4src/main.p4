#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_PTP 0x088F7

#define TCP_PROTOCOL 0x06
#define UDP_PROTOCOL 0x11
#define GENERIC_PROTOCOL 0x9091
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
header_type ptp_t {
    fields {
        transportSpecific : 4;
        messageType       : 4;
        reserved          : 4;
        versionPTP        : 4;
        messageLength     : 16;
        domainNumber      : 8;
        reserved2         : 8;
        flags             : 16;
        correction        : 64;
        reserved3         : 32;
        sourcePortIdentity: 80;
        sequenceId        : 16;
        ptpControl        : 8;
        logMessagePeriod  : 8;
        originTimestamp   : 80;
    }
}
parser start { return parse_ethernet; }
header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
	ETHERTYPE_PTP: parse_ptp;
	default : ingress;

    }
}
header ptp_t ptp;

parser parse_ptp {
    extract(ptp);
    return select(latest.reserved2) {
	1       : parse_header_0;
	default : ingress;

    }
}
header_type header_0_t {
    fields {
		field_0 : 16;

    }
}
header header_0_t header_0;

parser parse_header_0 {
    extract(header_0);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_1;

    }
}
header_type header_1_t {
    fields {
		field_0 : 16;

    }
}
header header_1_t header_1;

parser parse_header_1 {
    extract(header_1);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_2;

    }
}
header_type header_2_t {
    fields {
		field_0 : 16;

    }
}
header header_2_t header_2;

parser parse_header_2 {
    extract(header_2);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_3;

    }
}
header_type header_3_t {
    fields {
		field_0 : 16;

    }
}
header header_3_t header_3;

parser parse_header_3 {
    extract(header_3);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_4;

    }
}
header_type header_4_t {
    fields {
		field_0 : 16;

    }
}
header header_4_t header_4;

parser parse_header_4 {
    extract(header_4);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_5;

    }
}
header_type header_5_t {
    fields {
		field_0 : 16;

    }
}
header header_5_t header_5;

parser parse_header_5 {
    extract(header_5);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_6;

    }
}
header_type header_6_t {
    fields {
		field_0 : 16;

    }
}
header header_6_t header_6;

parser parse_header_6 {
    extract(header_6);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_7;

    }
}
header_type header_7_t {
    fields {
		field_0 : 16;

    }
}
header header_7_t header_7;

parser parse_header_7 {
    extract(header_7);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_8;

    }
}
header_type header_8_t {
    fields {
		field_0 : 16;

    }
}
header header_8_t header_8;

parser parse_header_8 {
    extract(header_8);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_9;

    }
}
header_type header_9_t {
    fields {
		field_0 : 16;

    }
}
header header_9_t header_9;

parser parse_header_9 {
    extract(header_9);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_10;

    }
}
header_type header_10_t {
    fields {
		field_0 : 16;

    }
}
header header_10_t header_10;

parser parse_header_10 {
    extract(header_10);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_11;

    }
}
header_type header_11_t {
    fields {
		field_0 : 16;

    }
}
header header_11_t header_11;

parser parse_header_11 {
    extract(header_11);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_12;

    }
}
header_type header_12_t {
    fields {
		field_0 : 16;

    }
}
header header_12_t header_12;

parser parse_header_12 {
    extract(header_12);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_13;

    }
}
header_type header_13_t {
    fields {
		field_0 : 16;

    }
}
header header_13_t header_13;

parser parse_header_13 {
    extract(header_13);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_14;

    }
}
header_type header_14_t {
    fields {
		field_0 : 16;

    }
}
header header_14_t header_14;

parser parse_header_14 {
    extract(header_14);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_15;

    }
}
header_type header_15_t {
    fields {
		field_0 : 16;

    }
}
header header_15_t header_15;

parser parse_header_15 {
    extract(header_15);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_16;

    }
}
header_type header_16_t {
    fields {
		field_0 : 16;

    }
}
header header_16_t header_16;

parser parse_header_16 {
    extract(header_16);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_17;

    }
}
header_type header_17_t {
    fields {
		field_0 : 16;

    }
}
header header_17_t header_17;

parser parse_header_17 {
    extract(header_17);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_18;

    }
}
header_type header_18_t {
    fields {
		field_0 : 16;

    }
}
header header_18_t header_18;

parser parse_header_18 {
    extract(header_18);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_19;

    }
}
header_type header_19_t {
    fields {
		field_0 : 16;

    }
}
header header_19_t header_19;

parser parse_header_19 {
    extract(header_19);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_20;

    }
}
header_type header_20_t {
    fields {
		field_0 : 16;

    }
}
header header_20_t header_20;

parser parse_header_20 {
    extract(header_20);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_21;

    }
}
header_type header_21_t {
    fields {
		field_0 : 16;

    }
}
header header_21_t header_21;

parser parse_header_21 {
    extract(header_21);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_22;

    }
}
header_type header_22_t {
    fields {
		field_0 : 16;

    }
}
header header_22_t header_22;

parser parse_header_22 {
    extract(header_22);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_23;

    }
}
header_type header_23_t {
    fields {
		field_0 : 16;

    }
}
header header_23_t header_23;

parser parse_header_23 {
    extract(header_23);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_24;

    }
}
header_type header_24_t {
    fields {
		field_0 : 16;

    }
}
header header_24_t header_24;

parser parse_header_24 {
    extract(header_24);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_25;

    }
}
header_type header_25_t {
    fields {
		field_0 : 16;

    }
}
header header_25_t header_25;

parser parse_header_25 {
    extract(header_25);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_26;

    }
}
header_type header_26_t {
    fields {
		field_0 : 16;

    }
}
header header_26_t header_26;

parser parse_header_26 {
    extract(header_26);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_27;

    }
}
header_type header_27_t {
    fields {
		field_0 : 16;

    }
}
header header_27_t header_27;

parser parse_header_27 {
    extract(header_27);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_28;

    }
}
header_type header_28_t {
    fields {
		field_0 : 16;

    }
}
header header_28_t header_28;

parser parse_header_28 {
    extract(header_28);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_29;

    }
}
header_type header_29_t {
    fields {
		field_0 : 16;

    }
}
header header_29_t header_29;

parser parse_header_29 {
    extract(header_29);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_30;

    }
}
header_type header_30_t {
    fields {
		field_0 : 16;

    }
}
header header_30_t header_30;

parser parse_header_30 {
    extract(header_30);
    return select(latest.field_0) {
	0       : ingress;
	default : parse_header_31;

    }
}
header_type header_31_t {
    fields {
		field_0 : 16;

    }
}
header header_31_t header_31;

parser parse_header_31 {
    extract(header_31);
    return select(latest.field_0) {
	default : ingress;

    }
}
action _drop() {
    drop();
}

action forward(_port) {
    modify_field(standard_metadata.egress_spec, _port);
}

table forward_table {
    reads {
        ethernet.dstAddr : exact;
    } actions {
        forward;
        _drop;
    }
    size : 4;
}
control ingress {
    apply(forward_table);
    
}
