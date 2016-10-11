#define ETHERTYPE_ARP 0x0806
#define ETHERTYPE_ICMP 0x1
#define ETHERTYPE_IPV4 0x0800
#define UDP_PROTOCOL 0x11
#define PAXOS_PROTOCOL_CORD 0x8887
#define PAXOS_PROTOCOL_ACPT 0x8888


#define PAXOS_1A 0
#define PAXOS_1B 1
#define PAXOS_2A 2
#define PAXOS_2B 3

#define MSGTYPE_SIZE 16
#define INST_SIZE 32
#define BALLOT_SIZE 16
#define ACPTID_SIZE 16
#define VALUE_SIZE 256
#define INST_COUNT 10


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
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
        src : 32;
        dst: 32;
    }
}

header_type arp_t {
    fields {
        hrd : 16;
        pro : 16;
        hln : 8;
        pln : 8;
        op  : 16;
        sha : 48;
        spa : 32;
        tha : 48;
        tpa : 32;
    }
}

header_type icmp_t {
    fields {
        icmptype : 8;
        code : 8;
        checksum : 16;
        Quench : 32;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

// Headers for Paxos

header_type paxos_t {
    fields {
        msgtype  : MSGTYPE_SIZE;
        inst   : INST_SIZE;
    }
}

header_type phase1a_t {
    fields {
        ballot : BALLOT_SIZE;
    }
}

header_type phase1b_t {
    fields {
        ballot   : BALLOT_SIZE;
        vballot  : BALLOT_SIZE;
        paxosval : VALUE_SIZE;
        acptid   : ACPTID_SIZE;
    }
}

header_type phase2a_t {
    fields {
        ballot   : BALLOT_SIZE;
        paxosval : VALUE_SIZE;
    }
}

header_type phase2b_t {
    fields {
        ballot   : BALLOT_SIZE;
        paxosval : VALUE_SIZE;
        acptid   : ACPTID_SIZE;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header arp_t arp;
header icmp_t icmp;
header udp_t udp;
header paxos_t paxos;
header phase1a_t paxos1a;
header phase1b_t paxos1b;
header phase2a_t paxos2a;
header phase2b_t paxos2b;


parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_ARP : parse_arp;
        ETHERTYPE_ICMP : parse_icmp;
        ETHERTYPE_IPV4 : parse_ipv4; 
        default : ingress;
    }
}

parser parse_icmp {
    extract(icmp);
    return ingress;
}

parser parse_arp {
    extract(arp);
    return ingress;
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        UDP_PROTOCOL : parse_udp;
        default : ingress;
    }
}

parser parse_udp {
    extract(udp);
    return select(udp.dstPort) {
        PAXOS_PROTOCOL_CORD : parse_paxos;
        PAXOS_PROTOCOL_ACPT : parse_paxos;
        default: ingress;
    }
}

parser parse_paxos {
    extract(paxos);
    return select(paxos.msgtype) {
        PAXOS_1A : parse_1a;
        PAXOS_1B : parse_1b;
        PAXOS_2A : parse_2a;
        PAXOS_2B : parse_2b;
        default : ingress;
    }
}

parser parse_1a {
    extract(paxos1a);
    return ingress;
}

parser parse_1b {
    extract(paxos1b);
    return ingress;
}

parser parse_2a {
    extract(paxos2a);
    return ingress;
}

parser parse_2b {
    extract(paxos2b);
    return ingress;
}

counter paxos_inst {
    type : packets;
    instance_count : 1;
    min_width : INST_SIZE;
}

header_type local_metadata_t {
    fields {
        ballot : BALLOT_SIZE;
    }
}

metadata local_metadata_t paxos_ballot;

register acceptor_id {
    width: ACPTID_SIZE;
    instance_count : 1; 
}

register ballots_register {
    width : BALLOT_SIZE;
    instance_count : INST_COUNT;
}

register vballots_register {
    width : BALLOT_SIZE;
    instance_count : INST_COUNT;
}

register values_register {
    width : VALUE_SIZE;
    instance_count : INST_COUNT;
}


action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table fwd_tbl {
    reads {
        standard_metadata.ingress_port : exact;
    }
    actions {
        forward;
    }
    size : 8;
}

action _no_op() {
}

action _drop() {
    drop();
}

action read_ballot() {
    register_read(paxos_ballot.ballot, ballots_register, paxos.inst); 
}

table ballot_tbl {
    actions { read_ballot; }
}

//action increase_seq() {
//    register_read(paxos.inst, instance_register, 0);
//    modify_field(paxos.inst, paxos.inst + 1);
//    register_write(instance_register, 0, paxos.inst);
//    modify_field(udp.checksum, 0);
//}

action handle_phase1a() {
    register_write(ballots_register, paxos.inst, paxos1a.ballot);
    remove_header(paxos1a);
    add_header(paxos1b);
	// modify_field(paxos1b.ballot, paxos1a.ballot);
    register_read(paxos1b.ballot, ballots_register, paxos.inst);
    register_read(paxos1b.vballot, vballots_register, paxos.inst);
    register_read(paxos1b.paxosval, values_register, paxos.inst);
    register_read(paxos1b.acptid, acceptor_id, 0);
    modify_field(udp.checksum, 0);
}

action handle_phase2a() {
    register_write(ballots_register, paxos.inst, paxos2a.ballot);
    register_write(vballots_register, paxos.inst, paxos2a.ballot);
    register_write(values_register, paxos.inst, paxos2a.paxosval);
    remove_header(paxos2a);
    add_header(paxos2b);
	// modify_field(paxos2b.ballot, paxos2a.ballot);
	// modify_field(paxos2b.paxosval, paxos2a.paxosval);
	register_read(paxos2b.ballot, ballots_register, paxos.inst);
    register_read(paxos2b.paxosval, values_register, paxos.inst);
    register_read(paxos2b.acptid, acceptor_id, 0);
    modify_field(udp.checksum, 0);
}


action reset_paxos() {

}

table drop_tbl {
    actions { _drop; }
}

table paxos1a_tbl {
    actions {
        handle_phase1a;
    }
    size : 1;
}

table paxos2a_tbl {
    actions {
        handle_phase2a;
    }
    size : 1;
}


control ingress {
    if (valid (ipv4))
        apply(fwd_tbl);
    if (valid (paxos))
        apply(ballot_tbl);
    if (valid (paxos1a)) {
        if (paxos_ballot.ballot <= paxos1a.ballot) {
            apply(paxos1a_tbl);
        } else {
            apply(drop_tbl);
        }
    }
    else if (valid (paxos2a)) {
        if (paxos_ballot.ballot <= paxos2a.ballot) {
            apply(paxos2a_tbl);
        }
    }

}
