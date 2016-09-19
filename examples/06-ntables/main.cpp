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

static MainRequestProxy *device = 0;
char* pktbuf=NULL;
char* p=NULL;
int size = 0;
static bool tosend = false;

void device_writePacketData(uint64_t* data, uint8_t* mask, int sop, int eop) {
    device->writePacketData(data, mask, sop, eop);
}

class MainIndication : public MainIndicationWrapper
{
public:
    virtual void read_version_rsp(uint32_t a) {
        fprintf(stderr, "version %x\n", a);
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
    );
}

static void 
parse_options(int argc, char *argv[], char **pcap_file, char **intf, char **outf, struct arg_info* info) {
    int c, option_index;

    static struct option long_options [] = {
        {"help",                no_argument, 0, 'h'},
        {"pcap",                required_argument, 0, 'p'},
        {"intf",                required_argument, 0, 'I'},
        {"outf",                required_argument, 0, 'O'},
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

#define DUMMY_TABLE_ADD_ENTRY(id) \
    ApplyDummyTablesDummy##id##ReqT dummy##id##_key = {0x45}; \
    ApplyDummyTablesDummy##id##RspT dummy##id##_act = {1}; \
    device->apply_dummy_tables_dummy_##id##_add_entry(dummy##id##_key, dummy##id##_act);

int main(int argc, char **argv)
{
    char *pcap_file=NULL;
    pcap_t *handle = NULL, *handle2=NULL; 
    pthread_t t_cap, t_snd;
    char errbuf[PCAP_ERRBUF_SIZE], *intf=NULL, *outf=NULL; 
    memset(errbuf,0,PCAP_ERRBUF_SIZE); 

    struct pcap_trace_info pcap_info = {0, 0};
    MainIndication echoindication(IfcNames_MainIndicationH2S);
    device = new MainRequestProxy(IfcNames_MainRequestS2H);

    parse_options(argc, argv, &pcap_file, &intf, &outf, 0);
    device->set_verbosity(6);
    device->read_version();

    ForwardTblReqT key = {0x0001005E002002};
    ForwardTblRspT action = {1, 1};
    device->forward_tbl_add_entry(key, action);

    DUMMY_TABLE_ADD_ENTRY(1);
    DUMMY_TABLE_ADD_ENTRY(2);
    DUMMY_TABLE_ADD_ENTRY(3);
    DUMMY_TABLE_ADD_ENTRY(4);
    DUMMY_TABLE_ADD_ENTRY(5);
    DUMMY_TABLE_ADD_ENTRY(6);
    DUMMY_TABLE_ADD_ENTRY(7);
    DUMMY_TABLE_ADD_ENTRY(8);
    DUMMY_TABLE_ADD_ENTRY(9);
    DUMMY_TABLE_ADD_ENTRY(10);
    DUMMY_TABLE_ADD_ENTRY(11);
    DUMMY_TABLE_ADD_ENTRY(12);
    DUMMY_TABLE_ADD_ENTRY(13);
    DUMMY_TABLE_ADD_ENTRY(14);
    DUMMY_TABLE_ADD_ENTRY(15);

    //device->forward_tbl_add_entry(0x003417eb96bf1c,0x200);
    //device->forward_tbl_add_entry(0x003417eb96bf1c,0x200);

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

    if (pcap_file) {
        fprintf(stderr, "Attempts to read pcap file %s\n", pcap_file);
        load_pcap_file(pcap_file, &pcap_info);
    }

    sleep(3);
    return 0;
}
