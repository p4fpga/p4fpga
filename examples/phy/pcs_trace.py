#!/usr/bin/env python

from scapy.all import *
import sys
import argparse

class PCS(Packet):
    name = "PCS "
    fields_desc = [ BitField('sync', 0, 8),
                    XLongField('block', 0)]

def generate(trace):
    p = []
    for t in trace:
        sync, block = t.split(',')
        p.append(PCS(sync=int(sync, 2), block=long(block.strip(), 16)))
    #print p
    wrpcap('pcs.pcap', p)

def main():
    parser = argparse.ArgumentParser(description='PCS trace generator')
    parser.add_argument("-t", "--trace")

    args = parser.parse_args()

    with open(args.trace) as f:
        pcs_trace = f.readlines()
        generate(pcs_trace)

if __name__=='__main__':
    main()
