header_type ethernet_t {
    fields {
        bit<48> dstAddr;
        bit<48> srcAddr;
        bit<16> etherType;
    }
}

#define IPV4_HDR_LEN 20
header_type ipv4_t {
    fields {
        bit<4> version;
        bit<4> ihl;
        bit<8> diffserv;
        bit<16> totalLen;
        bit<16> identification;
        bit<3> flags;
        bit<13> fragOffset;
        bit<8> ttl;
        bit<8> protocol;
        bit<16> hdrChecksum;
        bit<32> srcAddr;
        bit<32> dstAddr;
    }
}

#define UDP_HDR_LEN 8
header_type udp_t {
    fields {
        bit<16> srcPort;
        bit<16> dstPort;
        bit<16> length_;
        bit<16> checksum;
    }
}

#define GOTTHARD_HDR_LEN 13
header_type gotthard_hdr_t {
    fields {
        bit<1> msg_type;
        bit<1> from_switch;
        bit<6> unused_flags;
        bit<32> cl_id;
        bit<32> req_id;
        bit<8> frag_seq;
        bit<8> frag_cnt;
        bit<8> status;
        bit<16> op_cnt;
    }
}

header_type gotthard_op_t {
    fields {
        bit<8> op_type;
        bit<32> key;
        bit<GOTTHARD_VALUE_BITS> value;
    }
}

header_type op_parse_meta_t {
    fields {
        bit<8> remaining_cnt;
    }
}

header_type req_meta_t {
    fields {
        bit<8> r_cnt;
        bit<8> w_cnt;
        bit<8> rb_cnt;
        bit<1> has_cache_miss;
        bit<1> has_invalid_read;
        bit<1> has_opti_invalid_read;

        bit<1> read_cache_mode;

        // tmp variables for doing swaps:
        bit<32> tmp_ipv4_dstAddr;
        bit<16> tmp_udp_dstPort;
    }
}

header_type intrinsic_metadata_t {
    fields {
        bit<4> mcast_grp;
        bit<4> egress_rid;
        bit<16> mcast_hash;
        bit<32> lf_field_list;
        bit<16> resubmit_flag;
    }
}
