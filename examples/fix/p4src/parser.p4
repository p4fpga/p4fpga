#define ETHERTYPE_IPV4 0x0800
#define UDP_PROTOCOL 0x11

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4; 
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type mdp_packet_t {
	fields {
		msgSeqNum : 32;
		sendingTime : 64;
	}
}

header_type mdp_message_t {
	fields {
		msgSize : 16;
	}
}

header_type mdp_sbe_t {
	fields {
		blockLength : 16;
		templateID : 16;
		schemaID : 16;
		version : 16;
	}
}

header_type event_metadata_t {
	fields {
		group_size : 16;
	}
}

header_type MDIncrementalRefreshBook32 {
	fields {
		transactTime : 64;
		matchEventIndicator : 16;
		blockLength: 16;
		NoMDEntries: 16;
	}
}

header_type MDIncrementalRefreshBook32Group {
	fields {
		MDEntryPx : 64;
		MDEntrySize : 32;
		SecurityID : 32;
		RptReq : 32;
		NumberOfOrders : 32;
		MDPriceLevel : 8;
		MDUpdateAction : 8;
		MDEntryType : 8;
		padding : 40;
	}
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header udp_t udp;
header mdp_packet_t mdp;
header mdp_message_t mdp_msg;
header mdp_sbe_t mdp_sbe;
header MDIncrementalRefreshBook32 mdp_refreshbook;
header MDIncrementalRefreshBook32Group group[10];
metadata event_metadata_t event_metadata;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4; 
        default : ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.protocol) {
        UDP_PROTOCOL : parse_udp;
        default : ingress;
    }
}

parser parse_udp {
    extract(udp);
    return select(udp.dstPort) {
        default: parse_mdp;
    }
}

parser parse_mdp {
	extract(mdp);
	extract(mdp_msg);
	extract(mdp_sbe);
	extract(mdp_refreshbook);
	set_metadata(event_metadata.group_size, mdp_refreshbook.NoMDEntries);
	return select(event_metadata.group_size) {
		0: ingress;
		default: parse_mdp_group;
	}
}

parser parse_mdp_group {
	extract(group[next]);
	set_metadata(event_metadata.group_size, event_metadata.group_size - 1);
	return select(event_metadata.group_size) {
		0: ingress;
		default: parse_mdp_group;
	}
}
