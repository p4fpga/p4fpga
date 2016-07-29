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

#define DATA_WIDTH 128
#define MAXBYTES2CAPTURE 2048 

static MainRequestProxy *device = 0;

void device_writePacketData(uint64_t* data, uint8_t* mask, int sop, int eop) {
    device->writePacketData(data, mask, sop, eop);
}

class MainIndication : public MainIndicationWrapper
{
public:
    virtual void read_version_rsp(uint32_t a) {
        fprintf(stderr, "version %x\n", a);
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
parse_options(int argc, char *argv[], char **pcap_file, char **intf, struct arg_info* info) {
    int c, option_index;

    static struct option long_options [] = {
        {"help",                no_argument, 0, 'h'},
        {"pcap",                required_argument, 0, 'p'},
        {"intf",                required_argument, 0, 'I'},
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

int main(int argc, char **argv)
{
    char *pcap_file=NULL;
    int count=0; 
    pcap_t *descr = NULL; 
    char errbuf[PCAP_ERRBUF_SIZE], *intf=NULL; 
    memset(errbuf,0,PCAP_ERRBUF_SIZE); 

    struct pcap_trace_info pcap_info = {0, 0};
    MainIndication echoindication(IfcNames_MainIndicationH2S);
    device = new MainRequestProxy(IfcNames_MainRequestS2H);

    parse_options(argc, argv, &pcap_file, &intf, 0);
    device->set_verbosity(4);
    device->read_version();

    if (intf) {
        printf("Opening device %s\n", intf); 
        /* Open device in promiscuous mode */ 
        if ((descr = pcap_open_live(intf, MAXBYTES2CAPTURE, 1,  512, errbuf)) == NULL){
           fprintf(stderr, "ERROR: %s\n", errbuf);
           exit(1);
        }

        /* Loop forever & call processPacket() for every received packet*/ 
        if (pcap_loop(descr, -1, processPacket, (u_char *)&count) == -1){
           fprintf(stderr, "ERROR: %s\n", pcap_geterr(descr) );
           exit(1);
        }
    }

    if (pcap_file) {
        fprintf(stderr, "Attempts to read pcap file %s\n", pcap_file);
        load_pcap_file(pcap_file, &pcap_info);
    }

    return 0;
}
