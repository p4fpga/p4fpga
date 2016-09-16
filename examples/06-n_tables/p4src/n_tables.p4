#define DLB_PROTOC0L 0x9999

header_type ethernet_t {
    fields {
        dl_dst : 48;
        dl_src : 48;
        dl_type : 16;
    }
}

header_type dpl_t {
    fields {
        _repeat : 8;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t eth;

parser parse_ethernet {
    extract(eth);
    return select(latest.dl_type) {
        DLB_PROTOC0L : parse_dpl;
        default : ingress;
    }
}

header dpl_t dpl;

parser parse_dpl {
    extract(dpl);
    return ingress;
}

action _drop() {
    drop();
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
}


action decrease_1() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_2() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_3() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_4() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_5() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_6() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_7() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_8() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_9() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_10() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_11() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_12() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_13() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_14() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

action decrease_15() {
    modify_field(dpl._repeat, dpl._repeat - 1);
}

#include "tables.p4"

control ingress {
    apply(forward_tbl);
    apply_dummy_tables();
}
