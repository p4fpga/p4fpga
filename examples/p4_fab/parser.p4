/*
Author: Ke Wang
June 9th, 2016

*/
#ifndef _PARSER_P4_
#define _PARSER_P4_


parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800
#define FAB_PORT 0x55f0

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

#define IP_PROTOCOLS_UDP 17

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IP_PROTOCOLS_UDP : parse_udp;
        default: ingress;
    }
}

header udp_t udp;

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        FAB_PORT : parse_fab;
        default: ingress;
    }
}

header fab_t fab;

parser parse_fab {
    extract(fab);
    return ingress;
}

#endif