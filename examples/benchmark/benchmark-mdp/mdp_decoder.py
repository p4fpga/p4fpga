#!/usr/bin/env python

"""
Parse a pcap file containing CME MDP3 market data based on a SBE xml schema file.
"""

import sys
import os.path
from struct import unpack_from
from datetime import datetime
from sbedecoder import SBESchema
from sbedecoder import SBEMessageFactory
from sbedecoder import SBEParser
import gzip
import dpkt


def parse_mdp3_packet(mdp_parser, ts, data, skip_fields):
    timestamp = datetime.fromtimestamp(ts)
    # parse the packet header: http://www.cmegroup.com/confluence/display/EPICSANDBOX/MDP+3.0+-+Binary+Packet+Header
    sequence_number = unpack_from("<i", data, offset=0)[0]
    sending_time = unpack_from("<Q", data, offset=4)[0]
    print(':packet - timestamp: {} sequence_number: {} sending_time: {} '.format(
        timestamp, sequence_number, sending_time))
    for mdp_message in mdp_parser.parse(data, offset=12):
        message_fields = ''
        for field in mdp_message.fields:
            if field.name not in skip_fields:
                message_fields += ' ' + str(field)
        print('::{} - {}'.format(mdp_message, message_fields))
        for iterator in mdp_message.iterators:
            print(':::{} - num_groups: {}'.format(iterator.name, iterator.num_groups))
            for index, group in enumerate(iterator):
                group_fields = ''
                for group_field in group.fields:
                    group_fields += str(group_field) + ' '
                print('::::{}'.format(group_fields))


def process_file(args, pcap_filename):
    # Read in the schema xml as a dictionary and construct the various schema objects
    mdp_schema = SBESchema()
    mdp_schema.parse(args.schema)
    msg_factory = SBEMessageFactory(mdp_schema)
    mdp_parser = SBEParser(msg_factory)

    skip_fields = set(args.skip_fields.split(','))

    with gzip.open(pcap_filename, 'rb') if pcap_filename.endswith('.gz') else open(pcap_filename, 'rb') as pcap:
        pcap_reader = dpkt.pcap.Reader(pcap)
        packet_number = 0
        for ts, packet in pcap_reader:
            packet_number += 1
            ethernet = dpkt.ethernet.Ethernet(packet)
            if ethernet.type == dpkt.ethernet.ETH_TYPE_IP:
                ip = ethernet.data
                if ip.p == dpkt.ip.IP_PROTO_UDP:
                    udp = ip.data
                    try:
                        parse_mdp3_packet(mdp_parser, ts, udp.data, skip_fields)
                    except Exception:
                        print('could not parse packet number {}'.format(packet_number))


def process_command_line():
    from argparse import ArgumentParser

    parser = ArgumentParser(
        description="Parse a pcap file containing CME MDP3 market data based on a SBE xml schema file.",
        version="0.1")

    parser.add_argument("pcapfile",
        help="Name of the pcap file to process")

    parser.add_argument("-s", "--schema", default='templates_FixBinary.xml',
        help="Name of the SBE schema xml file")

    default_skip_fields = 'message_size,block_length,template_id,schema_id,version'

    parser.add_argument("-f", "--skip-fields", default=default_skip_fields,
        help="Don't print these message fields (default={})".format(default_skip_fields))

    args = parser.parse_args()

    # check number of arguments, verify values, etc.:
    if not os.path.isfile(args.schema):
        parser.error("sbe schema xml file '{}' not found".format(args.schema))

    return args


def main(argv=None):
    args = process_command_line()
    process_file(args, args.pcapfile)
    return 0  # success


if __name__ == '__main__':
    status = main()
    sys.exit(status)
