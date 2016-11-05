#!/bin/bash
set -x
PKTSIZE=$2
NCHAN=$3
START=`grep "out =1" $1 | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
END=`grep "out =1" $1 | tail -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
#LAT=`grep "runtime" $1 | grep "null" | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
DIFF=$(($END-$START))
#LATDIFF=$(($LAT-$START))
RATE=$(echo "$NCHAN*1000*$PKTSIZE*8/$DIFF*10/4.0" | bc -l)
PPS=$(echo "$NCHAN*1000/$DIFF*10/4.0*1000000000" | bc -l)
#LATENCY=$(echo "$LATDIFF*4.0/20" | bc -l)
echo $1 "start="$START "end="$END "diff="$DIFF "rate="$RATE "pps="$PPS #"lat="$LATENCY
