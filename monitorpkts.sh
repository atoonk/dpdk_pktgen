#!/bin/bash

if [ "$1" != "" ]; then
	NIC=$1
else
    echo "Please provide the network interface you'd like to monitor."
    echo "example: $0 eth0"
    exit 1
fi
p=0
d=0
while sleep 1; do
r=$(netstat -i | grep $NIC | awk '{print $3,$5}' | grep -v statistics)
	p_now=$(echo $r | awk '{print $1}')
	d_now=$(echo $r |awk '{print $2}')

	if [ "$p" -gt "0" ]; then
		dropped=$((d_now - d))
		rx=$((p_now - p))
		perc_d=$(echo "scale=5;($dropped/$rx)*100" | bc -l)
		echo "pps: received: $rx    dropped: $dropped  $perc_d %"
	fi
	p=$p_now
	d=$d_now
done
