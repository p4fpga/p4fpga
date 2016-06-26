#!/usr/bin/env python

import random
from scapy.all import *

udps = [UDP(sport=0x2222, dport=0x2222),
        UDP(sport=0x3333, dport=0x3333),
        UDP(sport=0x4444, dport=0x4444),
        UDP(sport=0x5555, dport=0x5555)]

pkts = []
for _ in range(10):
    pkts.append(Ether() / IP() / random.choice(udps))

sendp(pkts, iface='veth1')
