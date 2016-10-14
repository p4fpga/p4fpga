//#define MAX_REG_INST 2097152
#define MAX_REG_INST 1048576

#define GOTTHARD_VALUE_BITS 1024

#define GOTTHARD_VALUE_LEN (GOTTHARD_VALUE_BITS / 8)
#define GOTTHARD_OP_HDR_LEN 5
#define GOTTHARD_OP_LEN (GOTTHARD_OP_HDR_LEN + GOTTHARD_VALUE_LEN)

#define GOTTHARD_PORT 9999

#define GOTTHARD_TYPE_REQ 0
#define GOTTHARD_TYPE_RES 1

#define GOTTHARD_STATUS_OK                  0
#define GOTTHARD_STATUS_ABORT               1
#define GOTTHARD_STATUS_OPTIMISTIC_ABORT    2
#define GOTTHARD_STATUS_BADREQ              3

#define GOTTHARD_OP_NOP     0
#define GOTTHARD_OP_READ    1
#define GOTTHARD_OP_WRITE   2
#define GOTTHARD_OP_VALUE   3
#define GOTTHARD_OP_UPDATE  4

#include "loop_tables.generated.p4"

#include "header.p4"
#include "parser.p4"

metadata intrinsic_metadata_t intrinsic_metadata;


action _nop () {
}


action do_direction_swap (udp_payload_size) { // return the packet to the sender
    // Save old dst IP and port in tmp variable
    req_meta.tmp_ipv4_dstAddr = ipv4.dstAddr;
    req_meta.tmp_udp_dstPort = udp.dstPort;

    ipv4.dstAddr = ipv4.srcAddr;
    ipv4.srcAddr = req_meta.tmp_ipv4_dstAddr;
    ipv4.totalLen = IPV4_HDR_LEN + UDP_HDR_LEN + udp_payload_size;

    udp.dstPort = udp.srcPort;
    udp.srcPort = req_meta.tmp_udp_dstPort;
    udp.length_ = UDP_HDR_LEN + udp_payload_size;
    udp.checksum = 0; // TODO: update the UDP checksum

    gotthard_hdr.from_switch = 1;
    gotthard_hdr.msg_type = GOTTHARD_TYPE_RES;
    gotthard_hdr.frag_cnt = 1;
    gotthard_hdr.frag_seq = 1;
}

register is_cached_register {
    width: 1;
    instance_count: MAX_REG_INST;
}
register value_register {
    width: GOTTHARD_VALUE_BITS;
    instance_count: MAX_REG_INST;
}

register is_opti_cached_register {
    width: 1;
    instance_count: MAX_REG_INST;
}
register opti_value_register {
    width: GOTTHARD_VALUE_BITS;
    instance_count: MAX_REG_INST;
}

metadata req_meta_t req_meta;


action do_reply_abort() {
    //gotthard_hdr.status = req_meta.has_opti_invalid_read == 1 ? GOTTHARD_STATUS_OPTIMISTIC_ABORT : GOTTHARD_STATUS_ABORT;
    do_direction_swap(GOTTHARD_HDR_LEN + (gotthard_hdr.op_cnt*GOTTHARD_OP_LEN));
}
action do_reply_ok() {
    gotthard_hdr.status = GOTTHARD_STATUS_OK;
    do_direction_swap(GOTTHARD_HDR_LEN + (gotthard_hdr.op_cnt*GOTTHARD_OP_LEN));
}
table t_reply_client {
    reads {
        req_meta.has_invalid_read: exact;
    }
    actions {
        do_reply_abort;
        do_reply_ok;
    }
    size: 2;
}



action _drop() {
    drop();
}

header_type routing_metadata_t {
    fields {
        bit<32> nhop_ipv4;
    }
}

metadata routing_metadata_t routing_metadata;


action set_nhop(nhop_ipv4, port) {
    routing_metadata.nhop_ipv4 = nhop_ipv4;
    standard_metadata.egress_spec = port;
    ipv4.ttl = ipv4.ttl - 1;
}

table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        set_nhop;
        _drop;
    }
    size: 1024;
}

action set_dmac(dmac) {
    ethernet.dstAddr = dmac;
}

table forward {
    reads {
        routing_metadata.nhop_ipv4 : exact;
    }
    actions {
        set_dmac;
        _drop;
    }
    size: 512;
}

action rewrite_mac(smac) {
    ethernet.srcAddr = smac;
}

table send_frame {
    reads {
        standard_metadata.egress_port: exact;
    }
    actions {
        rewrite_mac;
        _drop;
    }
    size: 256;
}


table t_req_fix {
    reads {
        gotthard_hdr.op_cnt: exact;
    }
    actions {
        _nop;
        do_req_fix0;
        do_req_fix1;
        do_req_fix2;
        do_req_fix3;
        do_req_fix4;
        do_req_fix5;
        do_req_fix6;
        do_req_fix7;
        do_req_fix8;
        do_req_fix9;
    }
    size: 11;
}


table t_req_pass1 {
    reads {
        gotthard_hdr.op_cnt: exact;
    }
    actions {
        _nop;
        do_check_op0;
        do_check_op1;
        do_check_op2;
        do_check_op3;
        do_check_op4;
        do_check_op5;
        do_check_op6;
        do_check_op7;
        do_check_op8;
        do_check_op9;
    }
    size: 11;
}

table t_opti_update {
    reads {
        gotthard_hdr.op_cnt: exact;
    }
    actions {
        _nop;
        do_opti_update0;
        do_opti_update1;
        do_opti_update2;
        do_opti_update3;
        do_opti_update4;
        do_opti_update5;
        do_opti_update6;
        do_opti_update7;
        do_opti_update8;
        do_opti_update9;
    }
    size: 11;
}


table t_store_update {
    reads {
        gotthard_hdr.op_cnt: exact;
    }
    actions {
        _nop;
        do_store_update0;
        do_store_update1;
        do_store_update2;
        do_store_update3;
        do_store_update4;
        do_store_update5;
        do_store_update6;
        do_store_update7;
        do_store_update8;
        do_store_update9;
    }
    size: 11;
}

control ingress {
    if (valid(ipv4)) {
        if (valid(gotthard_hdr)) {
            if (gotthard_hdr.msg_type == GOTTHARD_TYPE_REQ and
                gotthard_hdr.frag_cnt == 1
                ) {

                apply(t_req_pass1);

                if (req_meta.has_cache_miss == 0
                and
                    ((req_meta.has_invalid_read == 1 and
                    req_meta.read_cache_mode == 0)
                    or
                    (req_meta.read_cache_mode == 1 and
                    req_meta.r_cnt > 0 and
                    req_meta.w_cnt == 0 and
                    req_meta.rb_cnt ==0)
                    or
                    (req_meta.read_cache_mode == 0 and
                    req_meta.rb_cnt > 0 and
                    req_meta.r_cnt == 0 and
                    req_meta.w_cnt == 0))
                ) {
                    apply(t_req_fix);
                    apply(t_reply_client);
                }

                if (req_meta.w_cnt > 0 and
                    req_meta.has_cache_miss == 0 and
                    req_meta.has_invalid_read == 0) {
                    apply(t_opti_update);
                }
            }
            else if (gotthard_hdr.msg_type == GOTTHARD_TYPE_RES) {
                apply(t_store_update);
            }
        }

        apply(ipv4_lpm);
        apply(forward);
    }
}

control egress {
    apply(send_frame);
}
