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
		field_1 : 16;
		field_2 : 16;
		field_3 : 16;
		field_4 : 16;
		field_5 : 16;
		field_6 : 16;
		field_7 : 16;
		field_8 : 16;
		field_9 : 16;
		field_10: 16;
		field_11: 16;
		field_12: 16;
		field_13: 16;
		field_14: 16;
		field_15: 16;

    }
}
header header_0_t header_0;

parser parse_header_0 {
    extract(header_0);
    return select(latest.field_0) {
	default : ingress;

    }
}
action mod_headers() {
	modify_field(header_0.field_0, 1);
	modify_field(header_0.field_1, 1);
	modify_field(header_0.field_2, 1);
	modify_field(header_0.field_3, 1);
	modify_field(header_0.field_4, 1);
	modify_field(header_0.field_5, 1);
	modify_field(header_0.field_6, 1);
	modify_field(header_0.field_7, 1);
	modify_field(header_0.field_8, 1);
	modify_field(header_0.field_9, 1);
	modify_field(header_0.field_10, 1);
	modify_field(header_0.field_11, 1);
	modify_field(header_0.field_12, 1);
	modify_field(header_0.field_13, 1);
	modify_field(header_0.field_14, 1);
	modify_field(header_0.field_15, 1);

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
table test_tbl {
    actions {
		mod_headers;
    }
    size : 1;
}
control ingress {
    apply(forward_table);
    apply(test_tbl);

}
