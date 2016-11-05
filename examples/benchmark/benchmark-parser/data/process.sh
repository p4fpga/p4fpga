#!/bin/bash

START=`grep "Parser State 01" $1 | head -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
END=`grep "Parser State 01" $1 | tail -n1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
DIFF=$(($END-$START))
RATE=$(echo "1000*256*8/$DIFF*10/4.0" | bc -l)
echo $1 "start="$START "end="$END "diff="$DIFF "rate="$RATE
