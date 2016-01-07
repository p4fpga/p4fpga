/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ingress_metadata_t {
    fields {
        vrf : 16;                   /* VRF */
        bd : 16;                     /* ingress BD */
        nexthop_index : 16;                    /* final next hop index */
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

metadata ingress_metadata_t ingress_metadata;

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

action action_0(){
    no_op();
}

action action_1() {
    no_op();
}

table table_0 {
   reads {
      ethernet.etherType : exact;
   }
   actions {
      action_0;
   }
}

table table_1 {
    reads {
        ingress_metadata.bd : exact;
    }
    actions {
        action_1;
    }
}

control ingress {
    apply(table_0);
//    apply(table_1);
}
