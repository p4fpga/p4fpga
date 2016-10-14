parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
    }
}

header ipv4_t ipv4;

field_list ipv4_checksum_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_checksum {
    input {
        ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field ipv4.hdrChecksum  {
    verify ipv4_checksum;
    update ipv4_checksum;
}

#define IPTYPE_UDP 0x11

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IPTYPE_UDP: parse_udp;
        default: ingress;
    }
}


header udp_t udp;

parser parse_udp {
    extract(udp);
    return parse_gotthard;
}

header gotthard_hdr_t gotthard_hdr;
header gotthard_op_t gotthard_op[GOTTHARD_MAX_OP];

header op_parse_meta_t parse_meta;

parser parse_op {
    extract(gotthard_op[next]);
    set_metadata(parse_meta.remaining_cnt, parse_meta.remaining_cnt - 1);
    return select(parse_meta.remaining_cnt) {
        0: ingress;
        default: parse_op;
    }
}

parser parse_gotthard {
    extract(gotthard_hdr);
    set_metadata(parse_meta.remaining_cnt, gotthard_hdr.op_cnt);
    return select(parse_meta.remaining_cnt) {
        0: ingress;
        default: parse_op;
    }
}
