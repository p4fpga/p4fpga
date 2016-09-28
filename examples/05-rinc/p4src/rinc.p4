/* Copyright 2013-present Barefoot Networks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "include/headers_tcp.p4"
#include "include/parser_tcp.p4"
#include "include/intrinsic.p4"
#define TH_FIN 1
#define TH_SYN 2
#define TH_RST 4
#define TH_PSH 8
#define TH_ACK 16
#define FLOW_MAP_SIZE 2    // use 2 for testing, change to 13 for 8192
#define ENTRIES 4 // change to 8192
#define TCP_PROTO 0x06 //TCP protocol 
#define IW 14600 //initiial window is 10 MSS
#define DUP_ACK_CNT_RETX 3


//////////////////// metadata needed for stats ///////////////////

header_type stats_metadata_t {
    fields {
	dummy : 32;
	dummy2: 32;
	flow_map_index : FLOW_MAP_SIZE; // flow's map index
	senderIP : 32; //sender's IP, server's IP, based on SYN 
	seqNo : 32;
	ackNo : 32;
	sample_rtt_seq : 32;
	rtt_samples : 32;
	//used for comparing flight size with mincwnd to see if incwnd needs to increase 
	mincwnd : 32;
	dupack : 32;
   }
}
metadata stats_metadata_t stats_metadata;
/////////////////////// hashing  //////////////////////////////////////
//test register
register check_map {
    width : FLOW_MAP_SIZE;
    instance_count : 2;
}

field_list l3_hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
}
field_list l3_hash_fields_reverse {
    ipv4.dstAddr;
    ipv4.srcAddr;
    ipv4.protocol;
    tcp.dstPort;
    tcp.srcPort;
}
field_list_calculation flow_map_hash {
    input {
        l3_hash_fields;
    }
    algorithm : crc32;
    output_width : FLOW_MAP_SIZE;
}
field_list_calculation flow_map_hash_reverse {
    input {
        l3_hash_fields_reverse;
    }
    algorithm : crc32;
    output_width : FLOW_MAP_SIZE;
}

action lookup_flow_map() {
    modify_field_with_hash_based_offset(stats_metadata.flow_map_index, 0, flow_map_hash, FLOW_MAP_SIZE);
    register_write(check_map, 0, stats_metadata.flow_map_index);
}

action lookup_flow_map_reverse() {
    modify_field_with_hash_based_offset(stats_metadata.flow_map_index, 0, flow_map_hash_reverse, FLOW_MAP_SIZE);
    register_write(check_map, 1, stats_metadata.flow_map_index);
}

table lookup{
	actions {
		lookup_flow_map;
	}
    size : 1;
}

table lookup_reverse{
	actions {
		lookup_flow_map_reverse;
	}
    size : 1;
}

///////////////////////////// initialization //////////////////////
register MSS {
    width : 16;
    instance_count : ENTRIES;
}
register wscale {
    width : 8;
    instance_count : ENTRIES;
}

register sendIP {
    width : 32;
    instance_count : ENTRIES;
}

action record_IP() {
	register_write(sendIP, stats_metadata.flow_map_index, ipv4.dstAddr);
	
    //register_read(stats_metadata.senderIP, sendIP, stats_metadata.flow_map_index);
    modify_field(stats_metadata.senderIP, ipv4.dstAddr);

	register_write(MSS, stats_metadata.flow_map_index, options_mss.MSS);
	register_write(wscale, stats_metadata.flow_map_index, options_wscale.wscale);
	//first time, record initial window (10 MSS) in mincwnd
	register_write(mincwnd, stats_metadata.flow_map_index, IW);
}

table init{
	actions {
		record_IP;
	}
    size : 1;
}

//////////// basic reading of stats before more processing  /////
action get_sender_IP(){
	register_read(stats_metadata.senderIP, sendIP, stats_metadata.flow_map_index);
	register_read(stats_metadata.seqNo, flow_last_seq_sent, stats_metadata.flow_map_index);
	register_read(stats_metadata.ackNo, flow_last_ack_rcvd, stats_metadata.flow_map_index);
	register_read(stats_metadata.sample_rtt_seq, flow_rtt_sample_seq, stats_metadata.flow_map_index);
	register_read(stats_metadata.rtt_samples, rtt_samples, stats_metadata.flow_map_index);
	register_read(stats_metadata.mincwnd, mincwnd, stats_metadata.flow_map_index);
	register_read(stats_metadata.dupack, flow_pkts_dup, stats_metadata.flow_map_index);
}
table direction{
	actions {
	get_sender_IP;
	}
}
///////////////////////// tracking per-flow stats //////////////////////

////// tracking cwnd and flight size
register mincwnd {
	width : 32;
	instance_count : ENTRIES;
}
register flight_size {
	width : 32;
	instance_count : ENTRIES;
}
//this is only called when last's flight size is larger than mincwnd, so store it in mincwnd
//new flight size is stored in dummy
//can add a new metadata for it too if this is confusing.
action increase_mincwnd(){
	register_write(mincwnd, stats_metadata.flow_map_index, stats_metadata.dummy);
}
table increase_cwnd{
	actions{
		increase_mincwnd;
	}
}
////
register flow_rwnd{
    width : 16;
    instance_count : ENTRIES;
}	
register flow_last_ack_rcvd {
    width : 32;
    instance_count : ENTRIES;
}
register flow_last_seq_sent {
    width : 32;
    instance_count : ENTRIES;
}
register flow_pkts_sent {
    width : 32;
    instance_count : ENTRIES;
}
register flow_pkts_rcvd {
    width : 32;
    instance_count : ENTRIES;
}
register flow_pkts_retx {
    width : 32;
    instance_count : ENTRIES;
}
register flow_pkts_dup {
    width : 32;
    instance_count : ENTRIES;
}
register ack_time{
	width: 32;
	instance_count : ENTRIES;
}
register app_reaction_time {
	width : 32;
	instance_count : ENTRIES;
}
action update_flow_sent() {
	//sent packets with new seq #
	register_read(stats_metadata.dummy, flow_pkts_sent, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(flow_pkts_sent, stats_metadata.flow_map_index, stats_metadata.dummy );
	//last sequence sent
	register_write(flow_last_seq_sent, stats_metadata.flow_map_index, tcp.seqNo);
	//app time = this time (send)- time of previous ack 
	//dummy = this time
	//dummy2 = time of last ack
	modify_field(stats_metadata.dummy, intrinsic_metadata.ingress_global_timestamp);
	register_read(stats_metadata.dummy2, ack_time, stats_metadata.flow_map_index);
	subtract_from_field(stats_metadata.dummy, stats_metadata.dummy2 ); //dummy = dummy - dummy2
	//store result into app_reaction time
	register_write(app_reaction_time, stats_metadata.flow_map_index, stats_metadata.dummy );
	//find the flight size and update it, flight size = last sent - last acked
	register_read(stats_metadata.dummy, flow_last_seq_sent, stats_metadata.flow_map_index);
	register_read(stats_metadata.dummy2, flow_last_ack_rcvd, stats_metadata.flow_map_index);
	subtract_from_field(stats_metadata.dummy, stats_metadata.dummy2);//dummy = flight size
	register_write(flight_size, stats_metadata.flow_map_index, stats_metadata.dummy);		
}
action update_flow_rcvd() {
	register_read(stats_metadata.dummy, flow_pkts_rcvd, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(flow_pkts_rcvd, stats_metadata.flow_map_index, stats_metadata.dummy );
	//reset duplicate ack counter due to new ack
	register_write(flow_last_ack_rcvd, stats_metadata.flow_map_index, tcp.ackNo);
	register_write(flow_pkts_dup, stats_metadata.flow_map_index, 0);
	register_write(flow_rwnd, stats_metadata.flow_map_index, tcp.window );
	register_write(ack_time,  stats_metadata.flow_map_index, intrinsic_metadata.ingress_global_timestamp);	
}
action update_flow_retx_3dupack() {
	//retx packets
	register_read(stats_metadata.dummy, flow_pkts_retx, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(flow_pkts_retx, stats_metadata.flow_map_index, stats_metadata.dummy );
	//remove samples
	register_write(flow_rtt_sample_seq,stats_metadata.flow_map_index,0);
	register_write(flow_rtt_sample_time,stats_metadata.flow_map_index,0);
	//CWND /= 2
	register_read(stats_metadata.dummy, mincwnd, stats_metadata.flow_map_index);
	modify_field(stats_metadata.dummy, stats_metadata.dummy>>1);
	register_write(mincwnd, stats_metadata.flow_map_index,stats_metadata.dummy );
	
}
action update_flow_retx_timeout() {
	//retx packets
	register_read(stats_metadata.dummy, flow_pkts_retx, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(flow_pkts_retx, stats_metadata.flow_map_index, stats_metadata.dummy );
	//remove samples
	register_write(flow_rtt_sample_seq,stats_metadata.flow_map_index,0);
	register_write(flow_rtt_sample_time,stats_metadata.flow_map_index,0);
	//CWND = IW
	register_write(mincwnd, stats_metadata.flow_map_index, IW);
	
}
action update_flow_dupack() {
	register_read(stats_metadata.dummy, flow_pkts_dup, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(flow_pkts_dup, stats_metadata.flow_map_index, stats_metadata.dummy );
}
table flow_sent {
	actions {  
		update_flow_sent;
	}
}
table flow_retx_3dupack {
	actions {
		update_flow_retx_3dupack;
	}
}
table flow_retx_timeout {
	actions {
		update_flow_retx_timeout;
	}
}
table flow_rcvd {
	actions {  
		update_flow_rcvd;
	}
}
table flow_dupack{
	actions{
		update_flow_dupack;
	}
}

///////////////// RTT sampling
register flow_srtt{
    width : 32;
    instance_count : ENTRIES;
}

register rtt_samples{
    width : 32;
    instance_count : ENTRIES;
}
/*
register samples{
	width : 32;
	instance_count : 50;
}

register flow_srttvar{
    width : 32;
    instance_count : ENTRIES;
}

register flow_rto{
}
register flow_mincwnd{
}

register flow_rtt_sample{
    width : 32;
    instance_count : ENTRIES;
}
*/
register flow_rtt_sample_seq{
    width : 32;
    instance_count : ENTRIES;
}
register flow_rtt_sample_time{
    width : 32;
    instance_count : ENTRIES;
}
action sample_new_rtt(){
	register_write(flow_rtt_sample_seq, stats_metadata.flow_map_index, tcp.seqNo);	
	//time in usec, time stamp of sent packet
	register_write(flow_rtt_sample_time, stats_metadata.flow_map_index, intrinsic_metadata.ingress_global_timestamp);
}
action use_sample_rtt(){
	register_read(stats_metadata.dummy, flow_rtt_sample_time , stats_metadata.flow_map_index);//contains the time stamp of sent pkt
	modify_field(stats_metadata.dummy2, intrinsic_metadata.ingress_global_timestamp);//contains the time stamp of this ack
	subtract_from_field(stats_metadata.dummy2,  stats_metadata.dummy);// dummy2 = R
	//register_write(flow_rtt_sample, stats_metadata.flow_map_index, stats_metadata.dummy2);
	//remove the used sample
	register_write(flow_rtt_sample_seq, stats_metadata.flow_map_index,0);
	//update SRTT : SRTT = 0.875*SRTT + 0.125*R
	register_read(stats_metadata.dummy, flow_srtt, stats_metadata.flow_map_index); //dummy = SRTT
	modify_field(stats_metadata.dummy, 7*stats_metadata.dummy+stats_metadata.dummy2);
	modify_field(stats_metadata.dummy, stats_metadata.dummy>>3);
	register_write(flow_srtt, stats_metadata.flow_map_index, stats_metadata.dummy);	
	//increment the rtt samples counter
	register_read(stats_metadata.dummy, rtt_samples, stats_metadata.flow_map_index);
	add_to_field(stats_metadata.dummy, 1);
	register_write(rtt_samples, stats_metadata.flow_map_index, stats_metadata.dummy );
}
//first sample : SRTT <- R , SRTTvar <- R/2, remove sample
action use_sample_rtt_first(){
	register_read(stats_metadata.dummy, flow_rtt_sample_time , stats_metadata.flow_map_index);//contains the time stamp of sent pkt
	modify_field(stats_metadata.dummy2, intrinsic_metadata.ingress_global_timestamp);//contains the time stamp of this ack
	subtract_from_field(stats_metadata.dummy2,  stats_metadata.dummy); //dummy2 now contains the new RTT sample: R
	//remove the used sample
	register_write(flow_rtt_sample_seq, stats_metadata.flow_map_index,0);
	//init SRTT
	register_write(flow_srtt, stats_metadata.flow_map_index, stats_metadata.dummy2);
	register_write(rtt_samples, stats_metadata.flow_map_index, 1);
	/*
	//init SRTTvar	
	set_metadata(stats_metadata.dummy2, stats_metadata.dummy2/2);
	register_write(flow_srttvar, stats_metadata.flow_map_index, stats_metadata.dummy2);
	*/
}
table sample_rtt_sent{
	actions{
		sample_new_rtt;
	}
}
table sample_rtt_rcvd{
	actions{
		use_sample_rtt;
	}
}
table first_rtt_sample{
	actions{
		use_sample_rtt_first;
	}
}
//////////////////// routing tables and action ///////////////////
action _drop() {
    drop();
}

header_type routing_metadata_t {
    fields {
        nhop_ipv4 : 32;
    }
}

metadata routing_metadata_t routing_metadata;

action set_nhop(nhop_ipv4, port) {
    modify_field(routing_metadata.nhop_ipv4, nhop_ipv4);
    modify_field(standard_metadata.egress_spec, port);
    add_to_field(ipv4.ttl, -1);
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
    modify_field(ethernet.dstAddr, dmac);
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
    modify_field(ethernet.srcAddr, smac);
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
/////////////////// debug ///////////////////////////
register srcIP{
	width : 32;
	instance_count : ENTRIES;
}
register dstIP{
	width : 32;
	instance_count : ENTRIES;
}
register metaIP{
	width : 32;
	instance_count : ENTRIES;
}	
action save_source_IP() {
	register_write(srcIP, stats_metadata.flow_map_index, ipv4.srcAddr);
	register_write(dstIP, stats_metadata.flow_map_index, ipv4.dstAddr);
	register_write(metaIP, stats_metadata.flow_map_index, stats_metadata.senderIP);
}
table debug {
	actions{
		save_source_IP;	
	}
}

/////////////////// control  ///////////////////////
control ingress {
	if ( ipv4.protocol == TCP_PROTO) {
		if( ipv4.srcAddr > ipv4.dstAddr ) {
			apply(lookup);
		}else{
			apply(lookup_reverse);
		}
		//first pkt
		if ( (tcp.syn == 1) and (tcp.ack == 0) ) {
			apply(init);
		} 
		else{
			//update based on direction :read previous stats 
			apply(direction);
		}
		//
		if (ipv4.srcAddr == stats_metadata.senderIP){
			
			if( tcp.seqNo > stats_metadata.seqNo )
			{
				apply(flow_sent);
				if(stats_metadata.sample_rtt_seq == 0){
					//no sample, new tx
					apply(sample_rtt_sent);
				}
				//at the end of "update_flow_sent" action in table "flow_sent", new flight size is stored into "dummy"
				if(stats_metadata.dummy > stats_metadata.mincwnd)//growth in flight size
				{
					apply(increase_cwnd);
				}
								
			}else{
				if(stats_metadata.dupack == DUP_ACK_CNT_RETX) {
					apply(flow_retx_3dupack);
				}
				else {
					apply(flow_retx_timeout);
				}
			}
			
		}
		else if(ipv4.dstAddr == stats_metadata.senderIP ) {
			if( tcp.ackNo > stats_metadata.ackNo ){
				//new ack
				apply(flow_rcvd);
				if( tcp.ackNo >= stats_metadata.sample_rtt_seq and stats_metadata.sample_rtt_seq>0){
					if(stats_metadata.rtt_samples ==0){
					apply(first_rtt_sample);
					}else{
					apply(sample_rtt_rcvd);
					}
				}
				
			}else{
			//dup ack
				apply(flow_dupack);
			}	
			
		}
		else{
			apply(debug);
		}
		
	}
	apply(ipv4_lpm);
        apply(forward);
}

control egress {
    /*if(tcp.syn == 1) {
    	apply(format_options); 
    }*/
    apply(send_frame);
}
