#include <core.p4>
#include <v1model.p4>

header dpl_t {
    bit<8> repeat;
}

header ethernet_t {
    bit<48> dl_dst;
    bit<48> dl_src;
    bit<16> dl_type;
}

struct metadata {
}

struct headers {
    @name("dpl") 
    dpl_t      dpl;
    @name("eth") 
    ethernet_t eth;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_dpl") state parse_dpl {
        packet.extract<dpl_t>(hdr.dpl);
        transition accept;
    }
    @name("parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.eth);
        transition select(hdr.eth.dl_type) {
            16w0x9999: parse_dpl;
            default: accept;
        }
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    headers hdr_0;
    metadata meta_0;
    standard_metadata_t standard_metadata_0;
    action NoAction_1() {
    }
    action NoAction_2() {
    }
    action NoAction_3() {
    }
    action NoAction_4() {
    }
    action NoAction_5() {
    }
    action NoAction_6() {
    }
    action NoAction_7() {
    }
    action NoAction_8() {
    }
    action NoAction_9() {
    }
    action NoAction_10() {
    }
    action NoAction_11() {
    }
    action NoAction_12() {
    }
    action NoAction_13() {
    }
    action NoAction_14() {
    }
    action NoAction_15() {
    }
    action NoAction_16() {
    }
    @name("forward") action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name("_drop") action _drop() {
        mark_to_drop();
    }
    @name("forward_tbl") table forward_tbl_0() {
        actions = {
            forward();
            _drop();
            NoAction_1();
        }
        key = {
            hdr.eth.dl_dst: exact;
        }
        size = 1024;
        default_action = NoAction_1();
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_0() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_1() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_2() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_3() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_4() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_5() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_6() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_7() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_8() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_9() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_10() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_11() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_12() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_13() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.decrease") action apply_dummy_tables_decrease_14() {
        hdr_0.dpl.repeat = hdr_0.dpl.repeat + 8w255;
    }
    @name("apply_dummy_tables.dummy_1") table apply_dummy_tables_dummy() {
        actions = {
            apply_dummy_tables_decrease_0();
            NoAction_2();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_2();
    }
    @name("apply_dummy_tables.dummy_10") table apply_dummy_tables_dummy_0() {
        actions = {
            apply_dummy_tables_decrease_1();
            NoAction_3();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_3();
    }
    @name("apply_dummy_tables.dummy_11") table apply_dummy_tables_dummy_1() {
        actions = {
            apply_dummy_tables_decrease_2();
            NoAction_4();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_4();
    }
    @name("apply_dummy_tables.dummy_12") table apply_dummy_tables_dummy_2() {
        actions = {
            apply_dummy_tables_decrease_3();
            NoAction_5();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_5();
    }
    @name("apply_dummy_tables.dummy_13") table apply_dummy_tables_dummy_3() {
        actions = {
            apply_dummy_tables_decrease_4();
            NoAction_6();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_6();
    }
    @name("apply_dummy_tables.dummy_14") table apply_dummy_tables_dummy_4() {
        actions = {
            apply_dummy_tables_decrease_5();
            NoAction_7();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_7();
    }
    @name("apply_dummy_tables.dummy_15") table apply_dummy_tables_dummy_5() {
        actions = {
            apply_dummy_tables_decrease_6();
            NoAction_8();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_8();
    }
    @name("apply_dummy_tables.dummy_2") table apply_dummy_tables_dummy_6() {
        actions = {
            apply_dummy_tables_decrease_7();
            NoAction_9();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_9();
    }
    @name("apply_dummy_tables.dummy_3") table apply_dummy_tables_dummy_7() {
        actions = {
            apply_dummy_tables_decrease_8();
            NoAction_10();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_10();
    }
    @name("apply_dummy_tables.dummy_4") table apply_dummy_tables_dummy_8() {
        actions = {
            apply_dummy_tables_decrease_9();
            NoAction_11();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_11();
    }
    @name("apply_dummy_tables.dummy_5") table apply_dummy_tables_dummy_9() {
        actions = {
            apply_dummy_tables_decrease_10();
            NoAction_12();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_12();
    }
    @name("apply_dummy_tables.dummy_6") table apply_dummy_tables_dummy_10() {
        actions = {
            apply_dummy_tables_decrease_11();
            NoAction_13();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_13();
    }
    @name("apply_dummy_tables.dummy_7") table apply_dummy_tables_dummy_11() {
        actions = {
            apply_dummy_tables_decrease_12();
            NoAction_14();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_14();
    }
    @name("apply_dummy_tables.dummy_8") table apply_dummy_tables_dummy_12() {
        actions = {
            apply_dummy_tables_decrease_13();
            NoAction_15();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_15();
    }
    @name("apply_dummy_tables.dummy_9") table apply_dummy_tables_dummy_13() {
        actions = {
            apply_dummy_tables_decrease_14();
            NoAction_16();
        }
        key = {
            hdr_0.dpl.repeat: exact;
        }
        size = 4;
        default_action = NoAction_16();
    }
    apply {
        hdr_0 = hdr;
        meta_0 = meta;
        standard_metadata_0 = standard_metadata;
        if (hdr_0.dpl.repeat > 8w0) 
            apply_dummy_tables_dummy_0.apply();
        if (hdr_0.dpl.repeat > 8w0) 
            apply_dummy_tables_dummy_1.apply();
        if (hdr_0.dpl.repeat > 8w0) 
            apply_dummy_tables_dummy_2.apply();
        if (hdr_0.dpl.repeat > 8w0) 
            apply_dummy_tables_dummy_3.apply();
        if (hdr_0.dpl.repeat > 8w0) 
            apply_dummy_tables_dummy_4.apply();
        hdr = hdr_0;
        meta = meta_0;
        standard_metadata = standard_metadata_0;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr, inout metadata meta) {
    apply {
        packet.emit<ethernet_t>(hdr.eth);
        packet.emit<dpl_t>(hdr.dpl);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
