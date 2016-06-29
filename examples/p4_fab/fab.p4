#include "headers.p4"
#include "parser.p4"

#define INST_NUM 8

header_type intrinsic_metadata_t {
    fields {
        mcast_grp : 4;
        egress_rid : 4;
        mcast_hash : 16;
        lf_field_list: 32;
    }
}

metadata intrinsic_metadata_t intrinsic_metadata;

header_type ingress_metadata_t { 
    fields {
        accept_count : 8;
        commit_inst : 32;
        curr_inst : 32;
        inst_index : 16;
        committed : 8;
        next_count : 8;
        temporary : 32;
    }
}

metadata ingress_metadata_t ingress_data;

register instance_register {
    width : 32;
    instance_count : 1;
}

register committed_inst {
    width : 32;
    instance_count : 1;
}

register accept_count {
    width : 8;
    instance_count : INST_NUM;
}


//  This function read num_inst stored in the register and copy it to
//  the current packet. Then it increased the num_inst by 1, and write
//  it back to the register
action increase_instance() {
    register_read(fab.inst, instance_register, 0);
    add_to_field(fab.inst, 1);
    register_write(instance_register, 0, fab.inst);
    modify_field(fab.msgtype, 1);

    //  Update the count associated with this instance
    modify_field(ingress_data.inst_index, fab.inst & (INST_NUM-1));
    register_write(accept_count, ingress_data.inst_index, 1);
}

action read_accept() {
    modify_field(ingress_data.inst_index, fab.inst & (INST_NUM-1));
    register_read(ingress_data.accept_count, accept_count, ingress_data.inst_index);
}

table read_accept_table {
    actions { read_accept; }
    size : 1;
}

table read_accept_table_query {
    actions { read_accept; }
    size : 1;
}

//  This function increases the accept count for a given instance upon receiving
//  accept messages.
action increase_accept() {
    modify_field(ingress_data.inst_index, fab.inst & (INST_NUM-1));
    add_to_field(ingress_data.accept_count, 1);
    register_write(accept_count, ingress_data.inst_index, ingress_data.accept_count);
    //  Effectively drop the packet by changing destination IP address to a non-existent address
    modify_field(ipv4.dstAddr, 0);
}

action update_committed_inst() {
    add_to_field(ingress_data.commit_inst, 1);
    register_write(committed_inst, 0, ingress_data.commit_inst);
}

table update_commit_table {
    actions { update_committed_inst; }
    size : 1;
}

table update_commit_table_aftercommit {
    actions { update_committed_inst; }
    size : 1;
}

table update_commit_table_afternoop {
    actions { update_committed_inst; }
    size : 1;
}

//  This function broadcasts a commit message once the switch receives enough accept
//  messages for a given instance number.
action broadcast_commit() {
    modify_field(ingress_data.inst_index, fab.inst % (INST_NUM));
    //  Modify the count for this instance to be 255 to indicate it has been committed
    //  This value is set as the largest count value representable.
    register_write(accept_count, ingress_data.inst_index, 255);
    modify_field(fab.msgtype, 3);
    modify_field(fab.replica, 0);
    //  Now update the committed_inst register if applicable
    modify_field(ingress_data.committed, 1);
}

action broadcast_noop() {
    modify_field(ingress_data.inst_index, fab.inst & (INST_NUM-1));
    //  Modify the count for this instance to be 254 to indicate it has been committed
    //  a special noop
    register_write(accept_count, ingress_data.inst_index, 254);
    //  Message type 5 indicates a special noop broadcast message
    modify_field(fab.msgtype, 5);
    modify_field(ingress_data.committed, 1);
}

action resend_commit() {

}

action resend_noop() {
    modify_field(ipv4.dstAddr, 0);
}

table sequencer_table {
    actions { increase_instance; }
    size : 1;
}

action _drop() {
    modify_field(ipv4.dstAddr, 0);
    drop();
}

table drop_table {
    actions { _drop; }
    size : 1;
}

table flow_control_drop {
    actions { _drop; }
    size : 1;
}

table old_accept_drop {
    actions { _drop; }
    size : 1;
}

table outdate_query_drop {
    actions { _drop; }
    size : 1;
}


action mcast() {
    modify_field(intrinsic_metadata.mcast_grp, (fab.inst % 4 + 1));
}

action bcast() {
    modify_field(intrinsic_metadata.mcast_grp, 5);
}


action forward(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table accept_table {
    reads {
        ingress_data.accept_count : exact;
    }
    actions {
        increase_accept; broadcast_commit; _drop;
    }
    size : 3;
}

table reply_query_table {
    reads {
        ingress_data.accept_count : exact;
    }
    actions {
        resend_commit; broadcast_noop; resend_noop; _drop;
    }
}


table fwd_table {
    reads {
        ipv4.dstAddr : exact;
        ingress_data.committed : exact;
    }
    actions {
        mcast; forward; bcast; _drop;
    }
    size : 16;
}

action read_register() {
    register_read(ingress_data.curr_inst, instance_register, 0);
    register_read(ingress_data.commit_inst, committed_inst, 0);
}

action read_next_count() {
    modify_field(ingress_data.next_count, ingress_data.commit_inst + 1);
    modify_field(ingress_data.temporary, ingress_data.next_count % (INST_NUM));
    register_read(ingress_data.next_count, accept_count, ingress_data.temporary);
}

table read_reg_table {
    actions { read_register; }
    size : 1;
}

table read_nextcount_table {
    actions { read_next_count; }
    size : 1;
}

table read_nextcount_table_aftercommit {
    actions { read_next_count; }
    size : 1;
}

table read_nextcount_table_afternoop {
    actions { read_next_count; }
    size : 1;
}

control ingress {
    if(valid(fab)) {
        apply(read_reg_table);
        if(fab.msgtype==0) {
            apply(read_nextcount_table);
            if(ingress_data.commit_inst < ingress_data.curr_inst) {
                //  First update commmitted_inst if applicable
                if((ingress_data.next_count == 255) or (ingress_data.next_count == 254)) {
                    apply(update_commit_table);
                }
            }
            if(ingress_data.curr_inst >= ingress_data.commit_inst + INST_NUM) {
                apply(flow_control_drop);
            }
            else {
                apply(sequencer_table);
            }
        }
        if(fab.msgtype==2) {
            if((fab.inst <= ingress_data.commit_inst) or (fab.inst > ingress_data.curr_inst)) {
                apply(old_accept_drop);
            }
            else {
                apply(read_accept_table);
                apply(accept_table);
                if(ingress_data.committed == 1) {
                    //  A commit message has been broadcast
                    apply(read_nextcount_table_aftercommit);
                    if(ingress_data.next_count == 255) {
                        apply(update_commit_table_aftercommit);
                    }
                }
            }
        }
        if(fab.msgtype==4) {
            //  This is sent by a replica for query of a missing commit msg. If the server has the committed record, 
            //  reply with commit, otherwise broadcast a special no-op
            if(fab.inst <= ingress_data.commit_inst) {
                //  outdated query
                apply(outdate_query_drop);
            }
            else {
                apply(read_accept_table_query);
                apply(reply_query_table);
                if(ingress_data.committed == 1) {
                    //  A noop message has been broadcast
                    apply(read_nextcount_table_afternoop);
                    if((ingress_data.next_count == 255) or (ingress_data.next_count == 254)) {
                        apply(update_commit_table_afternoop);
                    }
                }
            }
        }
        apply(fwd_table);
    }
    else {
        apply(drop_table);
    }
}

control egress {
}