#!/bin/bash

PROG="main"

source ../env.sh

set -m
$P4C_BM_SCRIPT p4src/$PROG.p4 --json $PROG.json

if [ $? -ne 0 ]; then
echo "p4 compilation failed"
exit 1
fi

SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py

sudo echo "sudo" > /dev/null
sudo $SWITCH_PATH >/dev/null 2>&1
sudo $SWITCH_PATH $PROG.json \
    -i 1@veth2 -i 2@veth4 --log-console --pcap &

sleep 2
echo "**************************************"
echo "Sending commands to switch through CLI"
echo "**************************************"
$CLI_PATH --json $PROG.json < commands.txt
echo "READY!!!"
fg