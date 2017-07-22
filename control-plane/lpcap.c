#include "lpcap.h"

void device_writePacketData(uint64_t* data, uint8_t* mask, int sop, int eop);

//static struct write_pcap_desc* writeFiles[32];

void load_pcap_file(const char *filename, struct pcap_trace_info *info) {
    char errbuf[PCAP_ERRBUF_SIZE];
    const unsigned char *packet;
    pcap_t *pcap = NULL;
    struct pcap_pkthdr header;
    pcap = pcap_open_offline(filename, errbuf);
    if (pcap == NULL) {
        fprintf(stderr, "error reading pcap file: %s\n", errbuf);
        exit(-1);
    }
    while ((packet = pcap_next(pcap, &header)) != NULL) {
        fprintf(stderr, "packet %p len %d\n", packet, header.caplen);
        mem_copy(packet, header.caplen);
        info->byte_count += header.len;
        info->packet_count ++;
    }
}

//void open_pcap_dump_file(char* fn_p) {
//    pcap_t* pcap_desc = pcap_open_dead(1, 65535);
//    if (pcap_desc == NULL) {
//        fprintf(stderr, "pcap_open_dead: failed: \n");
//        exit(-1);
//    }
//    pcap_dumper_t* pdumper = pcap_dump_open(pcap_desc, fn_p);
//    if (pdumper == NULL) {
//        fprintf(stderr, "pcap_dump_open: failed:\n");
//        exit(-1);
//    }
//    struct write_pcap_desc *desc = calloc(1, sizeof(struct write_pcap_desc));
//    desc->pdesc = pcap_desc;
//    desc->pdumper = pdumper;
//    desc->packetLen = 0;
//    desc->queued = 0;
//    memset(&desc->packetHeader.ts, -1, 8);
//}

const char* get_exe_name(const char* argv0) {
    if (const char *last_slash = strrchr(argv0, '/')) {
        return last_slash + 1;
    }
    return argv0;
}

void mem_copy(const void *buff, int packet_size) {

    int i, sop, eop;
    uint64_t data[2];
    uint8_t mask[2];
    int numBeats;

    numBeats = packet_size / 8; // 16 bytes per beat for 128-bit datawidth;
    if (packet_size % 8) numBeats++;
    PRINT_INFO("nBeats=%d, packetSize=%d\n", numBeats, packet_size);
    for (i=0; i<numBeats; i++) {
        data[i%2] = *(static_cast<const uint64_t *>(buff) + i);
        if (packet_size > 8) {
            mask[i%2] = 0xff;
            packet_size -= 8; // 64-bit
        } else {
            mask[i%2] = ((1 << packet_size) - 1) & 0xff;
            packet_size = 0;
        }
        sop = (i/2 == 0);
        eop = (i/2 == (numBeats-1)/2);
        if (i%2) {
            device_writePacketData(data, mask, sop, eop);
            PRINT_INFO("%016lx %016lx %0x %0x %d %d\n", data[1], data[0], mask[1], mask[0], sop, eop);
        }

        // last beat, padding with zero
        if ((numBeats%2!=0) && (i==numBeats-1)) {
            sop = (i/2 == 0) ? 1 : 0;
            eop = 1;
            data[1] = 0;
            mask[1] = 0;
            device_writePacketData(data, mask, sop, eop);
            PRINT_INFO("%016lx %016lx %0x %0x %d %d\n", data[1], data[0], mask[1], mask[0], sop, eop);
        }
    }
}

/* from NOX */
std::string long_options_to_short_options(const struct option* options)
{
    std::string short_options;
    for (; options->name; options++) {
        const struct option* o = options;
        if (o->flag == NULL && o->val > 0 && o->val <= UCHAR_MAX) {
            short_options.push_back(o->val);
            if (o->has_arg == required_argument) {
                short_options.push_back(':');
            } else if (o->has_arg == optional_argument) {
                short_options.append("::");
            }
        }
    }
    return short_options;
}

/* compute idle character in bytes (round to closest 16) */
int
compute_idle (const struct pcap_trace_info *info, double rate, double link_speed) {

    double idle_count = (link_speed - rate) * info->byte_count / rate;
    int idle = idle_count / info->packet_count;
    int average_packet_len = info->byte_count / info->packet_count;
    PRINT_INFO("idle = %d, link_speed=%f, rate=%f, average packet len = %d\n", idle, link_speed, rate, average_packet_len);
    return idle;
}

