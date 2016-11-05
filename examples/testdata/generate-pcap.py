#!/user/bin/python

import argparse
import collections
import logging
import os
import random
import sys

logging.getLogger("scapy").setLevel(1)

from scapy.all import *

parser = argparse.ArgumentParser(description="Test packet generator")
parser.add_argument('--out-dir', help="Output path", type=str, action='store', default=os.getcwd())
args = parser.parse_args()

all_pkts = collections.OrderedDict()

def gen_udp_pkts():
    # ETH|VLAN|VLAN|IP|UDP
    all_pkts['vlan2-udp'] = Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                           Dot1Q(vlan=3393) / Dot1Q(vlan=2000) / IP(src="10.0.0.1", dst="10.0.0.2") /   \
                           UDP(sport=6000, dport=6639)

    # ETH|VLAN|IP|UDP
    all_pkts['vlan-udp'] = Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                           Dot1Q(vlan=3393) / IP(src="10.0.0.1", dst="10.0.0.2") /   \
                           UDP(sport=6000, dport=20000)

    # ETH|VLAN|IP|UDP
    all_pkts['udp-small'] = Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                           IP(src="10.0.0.1", dst="10.0.0.2") /   \
                           UDP(sport=6000, dport=20000)
    # ETH|VLAN|IP|UDP|PAYLOAD
    data = bytearray(os.urandom(1000))
    all_pkts['udp-large'] = Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                            IP(src="10.0.0.1", dst="10.0.0.2") /   \
                            UDP(sport=6000, dport=20000) / Raw(str(data))

    data = bytearray(os.urandom(500))
    all_pkts['udp-mid'] = Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                            IP(src="10.0.0.1", dst="10.0.0.2") /   \
                            UDP(sport=6000, dport=20000) / Raw(str(data))

    # ETH|VLAN|IP|UDP
    sweep_small = PacketList()
    for i in range(8):
        sweep_small.append(Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                           IP(src="10.0.0.12", dst="10.0.0.{}".format(i)) /   \
                           UDP(sport=6000, dport=20000))
    all_pkts['udp-sweep-small'] = sweep_small

    # ETH|IP|UDP|PAYLOAD X 10
    udp_10 = PacketList()
    for i in range(10):
        data = bytearray(os.urandom(random.randint(1,100)))
        udp_10.append(Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-burst'] = udp_10

    vlan_10 = PacketList()
    for i in range(10):
        data = bytearray(os.urandom(random.randint(1,100)))
        vlan_10.append(Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                Dot1Q(vlan=3393) / IP(src="10.0.0.1", dst="10.0.0.2") /   \
                UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['vlan-burst'] = vlan_10

    # ETH|IP|UDP|PAYLOAD X 10
    udp_5 = PacketList()
    for i in range(5):
        data = bytearray(os.urandom(random.randint(1,100)))
        udp_5.append(Ether(src="34:17:eb:96:bf:1b", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-burst-5'] = udp_5

    udp_10 = PacketList()
    for i in range(10):
        data = bytearray(os.urandom(10))
        udp_10.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-burst-10'] = udp_10

    udp_128b = PacketList()
    data = bytearray(os.urandom(87))
    udp_128b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-128b'] = udp_128b

    udp_256b = PacketList()
    data = bytearray(os.urandom(215))
    udp_256b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-256b'] = udp_256b

    udp_512b = PacketList()
    data = bytearray(os.urandom(471))
    udp_512b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-512b'] = udp_512b

    udp_1024b = PacketList()
    data = bytearray(os.urandom(983))
    udp_1024b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-1024b'] = udp_1024b

    udp_1516b = PacketList()
    data = bytearray(os.urandom(1475))
    udp_1516b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-1516b'] = udp_1516b

    udp_64b = PacketList()
    data = bytearray(os.urandom(22))
    udp_64b.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-64b'] = udp_64b

    udp_65 = PacketList()
    data = bytearray(os.urandom(23))
    udp_65.append(Ether(src="00:00:00:00:00:01", dst="34:17:eb:96:bf:1c") / \
                 IP(src="10.0.0.1", dst="10.0.0.2") /   \
                 UDP(sport=6000, dport=20000) / Raw(str(data)))
    all_pkts['udp-65'] = udp_65


def main():
    gen_udp_pkts()

    with open("packet.mk", "w") as f:
        f.write("TEST_PACKET=")
        for packet in all_pkts.keys():
            f.write(" "+packet)

    for k, v in all_pkts.iteritems():
        wrpcap('%s.pcap' % k, v)

if __name__ == '__main__':
    main()
