#!/bin/bash
START=`grep "START" $1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
PARSER_END=`grep "send packet ingress" $1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
XMIT_END=`grep "outputQ 0 commit_packet" $1 | awk '{print $1}' | cut -d '(' -f 2 | cut -d ')' -f 1`
start=($START)
parse_end=($PARSER_END)
xmit_end=($XMIT_END)
length=${#start[@]}
total=0
for ((i=0; i!=length; i++)); do
	DIFF=$((${parse_end[i]} - ${start[i]}))
	echo $DIFF
	total=$((total+$DIFF))
done
average=$((total/length))

total2=0
for ((i=0; i!=length; i++)); do
	DIFF2=$((${xmit_end[i]} - ${start[i]}))
	echo $i $DIFF2
	total2=$((total2+$DIFF2))
done
average2=$((total2/length))

AVERAGE=$(echo "$average*4.0/10" | bc -l)
AVERAGE2=$(echo "$average2*4.0/10" | bc -l)
echo "parser average="$AVERAGE "end to end="$AVERAGE2
#echo $1 "start="$START "end="$END "diff="$DIFF "rate="$RATE
