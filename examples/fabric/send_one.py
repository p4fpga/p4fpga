#!/usr/bin/env python

from scapy.all import *
import sys
import argparse

class Fabric(Packet):
    name = "Fabric "
    fields_desc = [
        BitField('packetType', 0, 3),
        BitField('headerVersion', 0, 2),
        BitField('packetVersion', 0, 2),
        BitField('pad1', 0, 1),
        BitField('fabricColor', 0, 3),
        BitField('fabricQos', 0, 5),
        ByteField('dstDevice', 0),
        ShortField('dstPortOrGroup', 0)]

class FabricUnicast(Packet):
    name = "Fabric Unicast"
    fields_desc = [
        BitField('routed', 0, 1),
        BitField('outerRouted', 0, 1),
        BitField('tunnelTerminate', 0, 1),
        BitField('ingressTunnelType', 0, 5),
        ShortField('nexthopIndex', 0)]

class FabricMulticast(Packet):
    name = "Fabric Multicast"
    fields_desc = [
        BitField('routed', 0, 1),
        BitField('outerRouted', 0, 1),
        BitField('tunnelTerminate', 0, 1),
        BitField('ingressTunnelType', 0, 5),
        ShortField('ingressIfIndex', 0),
        ShortField('ingressBd', 0),
        ShortField('mcastGrp', 0)]

class FabricMirror(Packet):
    name = "Fabric Mirror"
    fields_desc = [
        ShortField('rewriteIndex', 0),
        BitField('egressPort', 0, 10),
        BitField('egressQueue', 0, 5),
        BitField('pad', 0, 1)]

def generate(args):
    p0 = Ether(src="00:00:00:00:00:01", dst="00:00:00:00:00:02", type=0x900) / \
        Fabric(packetType=1, headerVersion=2, packetVersion=3, fabricColor=3,
               fabricQos=4, dstDevice = 5, dstPortOrGroup=6) / \
        FabricUnicast(routed=1, outerRouted=1, tunnelTerminate=1, ingressTunnelType=5)
    p1 = Ether(src="00:00:00:00:00:01", dst="00:00:00:00:00:02", type=0x900) / \
        Fabric(packetType=1, headerVersion=2, packetVersion=3, fabricColor=3,
               fabricQos=4, dstDevice = 5, dstPortOrGroup=6) / \
        FabricMulticast(routed=1, outerRouted=1, tunnelTerminate=1, ingressTunnelType=5,
                      ingressIfIndex=0, ingressBd=2)
    wrpcap('fabric.pcap', [p0, p1])

def main():
    parser = argparse.ArgumentParser(description='MPLS label generator')
    parser.add_argument("-i", "--interface", default='veth2', help="bind to specified interface")

    args = parser.parse_args()

    generate(args)

if __name__=='__main__':
    main()
