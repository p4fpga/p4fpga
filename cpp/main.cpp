/* Copyright (c) 2016 Cornell University
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

#include "MemServerIndication.h"
#include "MainIndication.h"
#include "MainRequest.h"
#include "GeneratedTypes.h"
#include "lutils.h"
#include "lpcap.h"
#include <pcap.h> 
#include <pthread.h>

#define DATA_WIDTH 128
#define MAXBYTES2CAPTURE 2048 
#define BUFFSIZE 4096
#define LINK_SPEED 10

static MainRequestProxy *device = 0;
char* pktbuf=NULL;
char* p=NULL;
int size = 0;
static bool tosend = false;

bool hwpktgen = false;

extern void app_init(MainRequestProxy* device);

void device_writePacketData(uint64_t* data, uint8_t* mask, int sop, int eop) {
    if (hwpktgen) {
      device->writePktGenData(data, mask, sop, eop);
    } else {
      device->writePacketData(data, mask, sop, eop);
    }
}

class MainIndication : public MainIndicationWrapper
{
public:
    virtual void read_version_rsp(uint32_t a) {
        fprintf(stderr, "version %x\n", a);
    }
    virtual void read_pktcap_perf_info_resp(PktCapRec a) {
        fprintf(stderr, "perf: pktcap data_bytes=%ld idle_cycle=%ld total_cycle=%ld\n", a.data_bytes, a.idle_cycles, a.total_cycles);
    }
    virtual void readPacketData(const uint64_t data, const uint8_t mask, const uint8_t sop, const uint8_t eop) {
        //fprintf(stderr, "Rdata %016lx, mask %02x, sop %x eop %x\n", data, mask, sop, eop);
        if (sop == 1) {
            pktbuf = (char *) malloc(4096);
            p = pktbuf;
        }
        memcpy(p, &data, 8);
        int bits = (mask * 01001001001ULL & 042104210421ULL) % 017;
        p += bits;
        size += bits;
        if (eop == 1) {
            tosend = true;
        }
    }
    MainIndication(unsigned int id): MainIndicationWrapper(id) {}
};

class MemServerIndication : public MemServerIndicationWrapper
{
public:
    virtual void error(uint32_t code, uint32_t sglId, uint64_t offset, uint64_t extra) {
        fprintf(stderr, "memServer Indication.error=%d\n", code);
    }
    virtual void addrResponse ( const uint64_t physAddr ) {
        fprintf(stderr, "phyaddr=%lx\n", physAddr);
    }
    virtual void reportStateDbg ( const DmaDbgRec rec ) {
        fprintf(stderr, "rec\n");
    }
    virtual void reportMemoryTraffic ( const uint64_t words ) {
        fprintf(stderr, "words %lx\n", words);
    }
    MemServerIndication(unsigned int id) : MemServerIndicationWrapper(id) {}
};

void usage (const char *program_name) {
    printf("%s: p4fpga tester\n"
     "usage: %s [OPTIONS] \n",
     program_name, program_name);
    printf("\nOther options:\n"
    " -p, --parser=FILE                pcap trace to run\n"
    " -I, --intf=interface             listen on interface\n"
    " -r, --rate=x                     packet generation rate\n"
    );
}

struct arg_info {
    double rate;
    uint64_t tracelen;
};

static void 
parse_options(int argc, char *argv[], char **pcap_file, char **intf, char **outf, struct arg_info* info) {
    int c, option_index;

    static struct option long_options [] = {
        {"help",                no_argument, 0, 'h'},
        {"pcap",                required_argument, 0, 'p'},
        {"intf",                required_argument, 0, 'I'},
        {"outf",                required_argument, 0, 'O'},
        {"pktgen-rate",         required_argument, 0, 'r'},
        {"pktgen-count",        required_argument, 0, 'n'},
        {0, 0, 0, 0}
    };

    static std::string short_options
        (long_options_to_short_options(long_options));

    for (;;) {
        c = getopt_long(argc, argv, short_options.c_str(), long_options, &option_index);

        if (c == -1)
            break;

        switch (c) {
            case 'h':
                usage(get_exe_name(argv[0]));
                break;
            case 'p':
                *pcap_file = optarg;
                break;
            case 'I':
                fprintf(stderr, "%s", optarg);
                *intf = optarg;
                break;
            case 'O':
                fprintf(stderr, "%s", optarg);
                *outf = optarg;
                break;
            case 'r':
                info->rate = strtod(optarg, NULL);
                break;
            case 'n':
                info->tracelen = strtol(optarg, NULL, 0);
                break;
            default:
                break;
        }
    }
}

/* processPacket(): Callback function called by pcap_loop() everytime a packet */
/* arrives to the network card. This function prints the captured raw data in  */
/* hexadecimal.                                                                */
void processPacket(u_char *arg, const struct pcap_pkthdr* pkthdr, const u_char * packet){ 
    int *counter = (int *)arg; 
    printf("Packet Count: %d\n", ++(*counter)); 
    printf("Received Packet Size: %d\n", pkthdr->len); 
    mem_copy(packet, pkthdr->len);
    return; 
} 

void *captureThread(void * pcapt) {
    pcap_t * pt;
    int count=0; 
    pt = (pcap_t *)pcapt;
    pcap_loop(pt, -1, processPacket, (u_char*)&count);
    /* should not be reached */
    pcap_close(pt);
    return NULL;
}

void *sendThread(void *pcapt) {
    pcap_t *pt;
    pt = (pcap_t *)pcapt;
    while (1) {
        if (tosend) {
            fprintf(stderr, "inject packet %d\n", size);
            pcap_inject(pt, pktbuf, size);
            tosend = false;
            size = 0;
        }
        usleep(100);
    }
    return NULL;
}

int main(int argc, char **argv)
{
    char *pcap_file=NULL;
    pcap_t *handle = NULL, *handle2=NULL; 
    struct arg_info arguments = {0.0, 0};
    pthread_t t_cap, t_snd;
    char errbuf[PCAP_ERRBUF_SIZE], *intf=NULL, *outf=NULL; 
    memset(errbuf,0,PCAP_ERRBUF_SIZE); 

    struct pcap_trace_info pcap_info = {0, 0};
    MainIndication echoindication(IfcNames_MainIndicationH2S);
    device = new MainRequestProxy(IfcNames_MainRequestS2H);

    parse_options(argc, argv, &pcap_file, &intf, &outf, &arguments);
    device->set_verbosity(1);
    device->read_version();

    // application specific call
    // e.g. insert table entries here.
    app_init(device);

    if (intf) {
        printf("Opening device %s\n", intf); 
        /* Open device in promiscuous mode */ 
        if ((handle = pcap_open_live(intf, MAXBYTES2CAPTURE, 0,  512, errbuf)) == NULL){
           fprintf(stderr, "ERROR: %s\n", errbuf);
           exit(1);
        }
        pthread_create(&t_cap, NULL, captureThread, (void*)handle);

        if (outf) {
            printf("Opening device %s\n", outf); 
            if ((handle2 = pcap_open_live(outf, MAXBYTES2CAPTURE, 0, 512, errbuf)) == NULL) {
                fprintf(stderr, "ERROR: %s\n", errbuf);
                exit(1);
            }
            pthread_create(&t_snd, NULL, sendThread, (void*)handle2);
        }

        pthread_join(t_cap, NULL);
        pthread_join(t_snd, NULL);
        /* Loop forever & call processPacket() for every received packet */
        //if (pcap_loop(pt, -1, processPacket, (u_char *)&count) == -1){
        //   fprintf(stderr, "ERROR: %s\n", pcap_geterr(pt) );
        //   exit(1);
        //}
    }

    if (arguments.rate && arguments.tracelen) {
        hwpktgen = true;
    }

    if (pcap_file) {
        fprintf(stderr, "Attempts to read pcap file %s\n", pcap_file);
        load_pcap_file(pcap_file, &pcap_info);
    }

    if (arguments.rate && arguments.tracelen) {
        fprintf(stderr, "%lx %llx\n", pcap_info.packet_count, pcap_info.byte_count);
        int idle = compute_idle(&pcap_info, arguments.rate, LINK_SPEED);
        fprintf(stderr, "IDLE=%d\n", idle);
        device->pktcap_start(arguments.tracelen);
        device->pktgen_start(arguments.tracelen, idle);
    }

    sleep(3);

    device->read_pktcap_perf_info();
    return 0;
}
