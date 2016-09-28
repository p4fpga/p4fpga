@pragma header_ordering ethernet ipv4 tcp options_mss options_sack options_ts options_nop options_wscale options_end

parser start {
    return parse_ethernet;
}

#define ETHERTYPE_IPV4 0x0800

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

#define IP_PROTOCOLS_TCP 6

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        IP_PROTOCOLS_TCP : parse_tcp;
        default: ingress;
    }
}

header tcp_t tcp;
/*
parser parse_tcp {
    extract(tcp);
    return ingress;
}
*/
//////////////////////////// TCP options /////////
header_type my_metadata_t {
    fields {
	parse_tcp_options_counter : 8;
    }
}
metadata my_metadata_t my_metadata;

parser parse_tcp {
    extract(tcp);
    set_metadata(my_metadata.parse_tcp_options_counter, tcp.dataOffset * 4 - 20);
    return select(latest.syn) {
    	1: parse_tcp_options; 
	default : ingress;
    }
}
 
parser parse_tcp_options {
	return select(my_metadata.parse_tcp_options_counter, current(0,8)) {
		0x0000 mask 0xff00 : ingress;
		0x0000 mask 0x00ff : parse_end;
		0x0001 mask 0x00ff : parse_nop;
		0x0002 mask 0x00ff : parse_mss;
		0x0003 mask 0x00ff : parse_wscale;
		0x0004 mask 0x00ff : parse_sack;
		0x0008 mask 0x00ff : parse_ts;		
	}
}
/////////////// end
header options_end_t options_end;
parser parse_end {
	extract(options_end);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-1);
	return parse_tcp_options;
}

/////////////// nop
header options_nop_t options_nop[3];
parser parse_nop {
	extract(options_nop[next]);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-1);
	return parse_tcp_options;
}
/////////////// MSS
header options_mss_t options_mss;
parser parse_mss {
	extract(options_mss);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-4);
	return parse_tcp_options;
}

/////////////// wscale
header options_wscale_t options_wscale;
parser parse_wscale {
	extract(options_wscale);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-3);
	return parse_tcp_options;
}

/////////////// SACK
header options_sack_t options_sack;
parser parse_sack {
	extract(options_sack);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-2);
	return parse_tcp_options;
}

//////////////// timestamp
header options_ts_t options_ts;
parser parse_ts {
	extract(options_ts);
	set_metadata(my_metadata.parse_tcp_options_counter, my_metadata.parse_tcp_options_counter-10);
	return parse_tcp_options;
}

