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
action _nop() {

}
action mod_headers() {
	modify_field(ipv4.diffserv, 0);
	modify_field(ipv4.identification, 1);
	modify_field(ipv4.ttl, 2);
	modify_field(ipv4.hdrChecksum, 3);
	modify_field(udp.srcPort, 4);
	modify_field(udp.checksum, 5);
	modify_field(ipv4.diffserv, 6);
	modify_field(ipv4.identification, 7);
	modify_field(ipv4.ttl, 8);
	modify_field(ipv4.hdrChecksum, 9);
	modify_field(udp.srcPort, 10);
	modify_field(udp.checksum, 11);
	modify_field(ipv4.diffserv, 12);
	modify_field(ipv4.identification, 13);
	modify_field(ipv4.ttl, 14);
	modify_field(ipv4.hdrChecksum, 15);
	modify_field(udp.srcPort, 16);
	modify_field(udp.checksum, 17);
	modify_field(ipv4.diffserv, 18);
	modify_field(ipv4.identification, 19);
	modify_field(ipv4.ttl, 20);
	modify_field(ipv4.hdrChecksum, 21);
	modify_field(udp.srcPort, 22);
	modify_field(udp.checksum, 23);
	modify_field(ipv4.diffserv, 24);
	modify_field(ipv4.identification, 25);
	modify_field(ipv4.ttl, 26);
	modify_field(ipv4.hdrChecksum, 27);
	modify_field(udp.srcPort, 28);
	modify_field(udp.checksum, 29);
	modify_field(ipv4.diffserv, 30);
	modify_field(ipv4.identification, 31);
	modify_field(ipv4.ttl, 32);
	modify_field(ipv4.hdrChecksum, 33);
	modify_field(udp.srcPort, 34);
	modify_field(udp.checksum, 35);
	modify_field(ipv4.diffserv, 36);
	modify_field(ipv4.identification, 37);
	modify_field(ipv4.ttl, 38);
	modify_field(ipv4.hdrChecksum, 39);
	modify_field(udp.srcPort, 40);
	modify_field(udp.checksum, 41);
	modify_field(ipv4.diffserv, 42);
	modify_field(ipv4.identification, 43);
	modify_field(ipv4.ttl, 44);
	modify_field(ipv4.hdrChecksum, 45);
	modify_field(udp.srcPort, 46);
	modify_field(udp.checksum, 47);
	modify_field(ipv4.diffserv, 48);
	modify_field(ipv4.identification, 49);
	modify_field(ipv4.ttl, 50);
	modify_field(ipv4.hdrChecksum, 51);
	modify_field(udp.srcPort, 52);
	modify_field(udp.checksum, 53);
	modify_field(ipv4.diffserv, 54);
	modify_field(ipv4.identification, 55);
	modify_field(ipv4.ttl, 56);
	modify_field(ipv4.hdrChecksum, 57);
	modify_field(udp.srcPort, 58);
	modify_field(udp.checksum, 59);
	modify_field(ipv4.diffserv, 60);
	modify_field(ipv4.identification, 61);
	modify_field(ipv4.ttl, 62);
	modify_field(ipv4.hdrChecksum, 63);
	modify_field(udp.srcPort, 64);
	modify_field(udp.checksum, 65);
	modify_field(ipv4.diffserv, 66);
	modify_field(ipv4.identification, 67);
	modify_field(ipv4.ttl, 68);
	modify_field(ipv4.hdrChecksum, 69);
	modify_field(udp.srcPort, 70);
	modify_field(udp.checksum, 71);
	modify_field(ipv4.diffserv, 72);
	modify_field(ipv4.identification, 73);
	modify_field(ipv4.ttl, 74);
	modify_field(ipv4.hdrChecksum, 75);
	modify_field(udp.srcPort, 76);
	modify_field(udp.checksum, 77);
	modify_field(ipv4.diffserv, 78);
	modify_field(ipv4.identification, 79);
	modify_field(ipv4.ttl, 80);
	modify_field(ipv4.hdrChecksum, 81);
	modify_field(udp.srcPort, 82);
	modify_field(udp.checksum, 83);
	modify_field(ipv4.diffserv, 84);
	modify_field(ipv4.identification, 85);
	modify_field(ipv4.ttl, 86);
	modify_field(ipv4.hdrChecksum, 87);
	modify_field(udp.srcPort, 88);
	modify_field(udp.checksum, 89);
	modify_field(ipv4.diffserv, 90);
	modify_field(ipv4.identification, 91);
	modify_field(ipv4.ttl, 92);
	modify_field(ipv4.hdrChecksum, 93);
	modify_field(udp.srcPort, 94);
	modify_field(udp.checksum, 95);
	modify_field(ipv4.diffserv, 96);
	modify_field(ipv4.identification, 97);
	modify_field(ipv4.ttl, 98);
	modify_field(ipv4.hdrChecksum, 99);
	modify_field(udp.srcPort, 100);
	modify_field(udp.checksum, 101);
	modify_field(ipv4.diffserv, 102);
	modify_field(ipv4.identification, 103);
	modify_field(ipv4.ttl, 104);
	modify_field(ipv4.hdrChecksum, 105);
	modify_field(udp.srcPort, 106);
	modify_field(udp.checksum, 107);
	modify_field(ipv4.diffserv, 108);
	modify_field(ipv4.identification, 109);
	modify_field(ipv4.ttl, 110);
	modify_field(ipv4.hdrChecksum, 111);
	modify_field(udp.srcPort, 112);
	modify_field(udp.checksum, 113);
	modify_field(ipv4.diffserv, 114);
	modify_field(ipv4.identification, 115);
	modify_field(ipv4.ttl, 116);
	modify_field(ipv4.hdrChecksum, 117);
	modify_field(udp.srcPort, 118);
	modify_field(udp.checksum, 119);
	modify_field(ipv4.diffserv, 120);
	modify_field(ipv4.identification, 121);
	modify_field(ipv4.ttl, 122);
	modify_field(ipv4.hdrChecksum, 123);
	modify_field(udp.srcPort, 124);
	modify_field(udp.checksum, 125);
	modify_field(ipv4.diffserv, 126);
	modify_field(ipv4.identification, 127);

}
table test_tbl {
    reads {
        udp.dstPort : exact;
    } actions {
        		_nop;
		mod_headers;
    }
    size : 4;
}
control ingress {
    apply(forward_table);
    apply(test_tbl);

}
