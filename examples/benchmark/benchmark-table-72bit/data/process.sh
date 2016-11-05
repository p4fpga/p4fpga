#!/bin/bash
set -x
START=`grep "START" $1 | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
END=`grep "START" $1 | tail -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
DIFF=$(($END-$START))
RATE=$(echo "100*128*8/$DIFF*10/4.0" | bc -l)
echo $1 "start="$START "end="$END "diff="$DIFF "rate="$RATE
