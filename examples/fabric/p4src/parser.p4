
#define ETHERTYPE_BF_FABRIC    0x9000
#define ETHERTYPE_IPV4         0x0800

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_BF_FABRIC : parse_fabric_header;
        ETHERTYPE_IPV4 : parse_ipv4;
    }
}

header fabric_header_t                  fabric_header;
header fabric_header_unicast_t          fabric_header_unicast;
header fabric_header_multicast_t        fabric_header_multicast;
header fabric_header_mirror_t           fabric_header_mirror;
header fabric_header_cpu_t              fabric_header_cpu;
header fabric_payload_header_t          fabric_payload_header;

parser parse_fabric_header {
    extract(fabric_header);
    return select(latest.packetType) {
        FABRIC_HEADER_TYPE_UNICAST : parse_fabric_header_unicast;
        FABRIC_HEADER_TYPE_MULTICAST : parse_fabric_header_multicast;
        FABRIC_HEADER_TYPE_MIRROR : parse_fabric_header_mirror;
        FABRIC_HEADER_TYPE_CPU : parse_fabric_header_cpu;
        default : ingress;
    }
}

parser parse_fabric_header_unicast {
    extract(fabric_header_unicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_multicast {
    extract(fabric_header_multicast);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_mirror {
    extract(fabric_header_mirror);
    return parse_fabric_payload_header;
}

parser parse_fabric_header_cpu {
    extract(fabric_header_cpu);
    return parse_fabric_payload_header;
}

parser parse_fabric_payload_header {
    extract(fabric_payload_header);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
    }
}

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        default: ingress;
    }
}

