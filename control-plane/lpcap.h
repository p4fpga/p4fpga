#ifndef _SONIC_PCAP_H_
#define _SONIC_PCAP_H_

#include <assert.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdio.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <getopt.h>
#include <errno.h>
#include <cstring>
#include <stdint.h>
#include <pcap.h>

#include "lutils.h"

//#define MAX_PKTSIZE (17 * 1024)

struct pcap_trace_info {
    unsigned long packet_count;
    unsigned long long byte_count;
};

//struct write_pcap_desc {
//  pcap_t              *pdesc;
//  pcap_dumper_t       *pdumper;
//  struct pcap_pkthdr  packetHeader;
//  unsigned            packetLen;
//  unsigned            queued;
//  u_char              cap_data[MAX_PKTSIZE];
//};

/* mem_copy must be provided by each test */
void mem_copy(const void *buff, int length);
void load_pcap_file(const char *filename, struct pcap_trace_info *);
void inject_pcap_file(const void *buff);
const char* get_exe_name(const char* argv0);
int compute_idle (const struct pcap_trace_info *info, double rate, double link_speed);

#endif
