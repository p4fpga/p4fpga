#define ETHERTYPE_IPV4 0x0800

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
header ethernet_t ethernet;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4; 
        default : ingress;
    }
}
header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}
header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        TCP_PROTOCOL : parse_tcp;
        UDP_PROTOCOL : parse_udp;
        default : ingress;
    }
}
header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}
header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    return ingress;
}
header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}
header udp_t udp;

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
	37009   : parse_header_0;
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
