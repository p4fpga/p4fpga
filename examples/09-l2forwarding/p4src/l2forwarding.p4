
header_type ethernet_t {
    fields {
        dl_dst : 48;
        dl_src : 48;
        dl_type : 16;
    }
}


parser start {
    return parse_ethernet;
}

header ethernet_t eth;

parser parse_ethernet {
    extract(eth);
    return ingress;
}

action _drop() {
    drop();
}

action _nop() {

}

action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table forward_tbl {
    reads {
        eth.dl_dst : exact;
    } actions {
        forward;
        _drop;
    }
    size : 1024;
}
control ingress {
    apply(forward_tbl);
}