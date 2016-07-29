#!/usr/bin/env python

from scapy.all import *
import sys
import argparse
import gzip
import dpkt

def generate(args, pcap_filename):
    with gzip.open(pcap_filename, 'rb') if pcap_filename.endswith('.gz') else open(pcap_filename, 'rb') as pcap:
        pcap_reader = dpkt.pcap.Reader(pcap)
        packet_number = 0
        for ts, p in pcap_reader:
            packet_number += 1
            sendp(p, iface = args.interface)

def main():
    parser = argparse.ArgumentParser(description='FIX message generator')
    parser.add_argument("-i", "--interface", default='veth4', help="bind to specified interface")
    parser.add_argument("pcapfile", help="Name of the pcap file to process")
    args = parser.parse_args()

    generate(args, args.pcapfile)

if __name__=='__main__':
    main()
