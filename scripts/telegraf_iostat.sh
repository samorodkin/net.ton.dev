#!/bin/bash
#
# This script outputs iostat for specified disk, for usage with telegraf monitoring.
#
# Written by Dmitry Summit for Free TON contest.
#

# nvme0n1  r/s     rkB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wkB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dkB/s   drqm/s  %drqm d_await dareq-sz  aqu-sz  %util

while read -r device rs rkBs rrqms rrqm r_await rareq_sz ws wkBs wrqms wrqm w_await wareq_sz ds dkBs drqms drqm d_await dareq_sz aqu_sz util; do
#read_queued_sec write_queued_sec read_completed_sec write_completed_sec read_kbytes_sec write_kbytes_sec avg_sector_size avg_queue_len await_ms read_await_ms write_await_ms svctime_ms util_pct; do
ds=$(awk "BEGIN {print ($rs + $ws)/1000 }")
dkBs=$(awk "BEGIN {print $rkBs + $wkBs}")
    [ ! -z "$device" ] && echo "exec_iostat,device=$device rs=$rs,rkBs=$rkBs,rrqms=$rrqms,rrqm=$rrqm,r_await=$r_await,rareq-sz=$rareq_sz,ws=$ws,wkBs=$wkBs,wrqms=$wrqms,wrqm=$wrqm,w_await=$w_await,wareq_sz=$wareq_sz,ds=$ds,dkBs=$dkBs,drqms=$drqms,drqm=$drqm,d_await=$d_await,dareq_sz=$dareq_sz,aqu_sz=$aqu_sz,util=$util"
#read_queued_sec=$read_queued_sec,write_queued_sec=$write_queued_sec,read_completed_sec=$read_completed_sec,write_completed_sec=$write_completed_sec,read_kbytes_sec=$read_kbytes_sec,write_kbytes_sec=$write_kbytes_sec,avg_sector_size=$avg_sector_size,avg_queue_len=$avg_queue_len,await_ms=$await_ms,read_await_ms=$read_await_ms,write_await_ms=$write_await_ms,svctime_ms=$svctime_ms,util_pct=$util_pct"
#done < <(iostat -d nvme0n1 1 1 |  tail -n +4)
done < <(iostat -d nvme0n1 -xyk 1 1 | tail -n3 | head -n1)
exit 0
