#!/bin/bash
set -x
START=`grep "step 1" $1 | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
END=`grep "step 1" $1 | tail -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
LAT=`grep "runtime" $1 | grep "null" | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
echo $LAT
DIFF=$(($END-$START))
LATDIFF=$(($LAT-$START))
RATE=$(echo "100*128*8/$DIFF*10/4.0" | bc -l)
LATENCY=$(echo "$LATDIFF*4.0/20" | bc -l)
echo $1 "start="$START "end="$END "diff="$DIFF "rate="$RATE "lat="$LATENCY
