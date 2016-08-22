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

header_type dedup_t {
   fields {
      notPresent : 1;
   }
}

header_type mdIncrementalRefreshBook32 {
	fields {
		transactTime : 64;
		matchEventIndicator : 16;
		blockLength: 16;
		noMDEntries: 16;
	}
}

header_type mdIncrementalRefreshBook32Group {
	fields {
		mdEntryPx : 64;
		mdEntrySize : 32;
		securityID : 32;
		rptReq : 32;
		numberOfOrders : 32;
		mdPriceLevel : 8;
		mdUpdateAction : 8;
		mdEntryType : 8;
		padding : 40;
	}
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header udp_t udp;
header mdp_packet_t mdp;
header mdp_message_t mdp_msg;
header mdp_sbe_t mdp_sbe;
header mdIncrementalRefreshBook32 mdp_refreshbook;
header mdIncrementalRefreshBook32Group group[10];
metadata event_metadata_t event_metadata;
metadata dedup_t dedup;

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
		15311: parse_mdp;
		14311: parse_mdp;
        default: ingress;
    }
}

parser parse_mdp {
	extract(mdp);
	return parse_mdp_msg;
}	

parser parse_mdp_msg {
	extract(mdp_msg);
	return parse_mdp_sbe;
}

parser parse_mdp_sbe {
	extract(mdp_sbe);
	return parse_mdp_refreshbook;
}

parser parse_mdp_refreshbook {
	extract(mdp_refreshbook);
	set_metadata(event_metadata.group_size, mdp_refreshbook.noMDEntries);
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

