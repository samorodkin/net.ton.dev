#!/bin/bash

#
# Script counts and displays average duration time from node.log
# If not enough lines present, then it waits for log file to grow
# Note:
#   this is a very rough performance measurement, and for better results,
#   I suppose we should grep timings of only one type of operations.
#
# Example:
# - Display average from 100 measures
#   ./node_avg.sh 100
#
# Alternative one-liner for CLI:
#
#   tail -f $TON_WORK_DIR/node.log | egrep -o -m100 -E "duration:([0-9]+)\.[0-9]+ms" | grep -o -E "[0-9]+\.[0-9]+" | awk '{ total += $1; count++ } END { print total/count }'
#
# Tested on Ubuntu 18
#

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

# Use some existing log lines, otherwise it takes time to wait for the new lines to come.
tailLength=$(echo $1*3 | bc )

count=0
total=0 

for i in $( tail -n $tailLength -f $TON_WORK_DIR/node.log | egrep -o -m$1 -E "duration:([0-9]+)\.[0-9]+ms" | grep -o -E "[0-9]+\.[0-9]+" )
do 
    total=$(echo $total+$i | bc )
    ((count++))
done

echo "scale=2; $total / $count" | bc

