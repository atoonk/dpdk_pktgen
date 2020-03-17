# DPDK Pktgen

## starting

```
/opt/pktgen-20.02.0/app/x86_64-native-linuxapp-gcc/pktgen  -- -T -P -m "2.[0]" -f pktgen.pkt
```
This means we use CPU core 2 for port 0. ``` -f pktgen.pkt ``` means we have a few set commands in pktgen.pkt
start with an example file that looks like this:
```
root@ewr1-x1:~# cat pktgen.pkt
stop 0
set 0 rate 0.1
set 0 ttl 10
set 0 proto udp
set 0 dport 81
set 0 dst mac 44:ec:ce:c1:a8:20
set 0 src mac 00:52:44:11:22:33
set 0 dst ip 10.99.204.8
set 0 src ip 10.99.204.3/30
set 0 size 64
```

Note: you need to run ```start 0``` after this to start

See this link for all set options
https://pktgen-dpdk.readthedocs.io/en/latest/commands.html#runtime-options-and-commands

see this link for all pktgen cli option (i.e. core assignments, etc as defined with -m)
https://pktgen-dpdk.readthedocs.io/en/latest/usage_pktgen.html

## Pages
1. page main 
```
Pktgen:/> page main
```
This is the start up page and will show you the current througput, ports, etc.


2. page range 
```
Pktgen:/> page range
```
This will show you the ranges you set up.
Ranges are used for when you want Pktgen to use a range of IPs, Ports, pkt sizes, etc.
Note: that after you change the range settings, you will need to stop and start the test

```
Pktgen:/> stop 0
Pktgen:/> start 0
```

Also know you need to enable and disable range if you'd like to use it.
By default you don't use range

```
Pktgen:/> enable 0 range
```


## Traffic patterns
Traffic patterns can be set with ranges.
Remember to enable ranges (not default)

```
Pktgen:/> enable 0 range
```

You need to stop and start after range changes
```
stop 0
start 0
```

Set dst port range
```
Pktgen:/> range 0 src port start 4000
Pktgen:/> range 0 src port min 4000
Pktgen:/> range 0 src port max 5000
Pktgen:/> range 0 src port inc 1
```
Start, minimum, maximum, increment

Set to UDP
```
Pktgen:/> range 0 proto udp
```

Set dst mac
```
Pktgen:/> range 0 dst mac start 44:ec:ce:c1:a8:20
```

set src and dst ip
```
Pktgen:/> range 0 src ip start 10.99.204.4
Pktgen:/> range 0 dst ip start 10.99.204.1
```

```
stop 0
set 0 rate 0.1
range 0 ttl start 10
range 0 dst mac start 44:ec:ce:c1:a8:20
range 0 proto udp
range 0 src port start 4000
range 0 src port inc 0
range 0 src port max 4000
range 0 dst port start 4000
range 0 dst port min 4000
range 0 dst port max 4000
range 0 dst port inc 0
range 0 dst ip start 10.99.204.8
range 0 dst ip inc 0
range 0 dst mac start 44:ec:ce:c1:a8:20
range 0 src ip start 10.99.204.3
range 0 src ip inc 0
range 0 size start 64
range 0 size inc 0

```
## Read from pcap

Download for example an imix file:
```
wget https://github.com/cisco-system-traffic-generator/trex-core/raw/master/scripts/exp/imix.pcap
```
```
tshark -r imix.pcap -V | grep 'Frame Length'| sort | uniq -c | sort -n
Running as user "root" and group "root". This could be dangerous.
      9     Frame Length: 1514 bytes (12112 bits)
     33     Frame Length: 590 bytes (4720 bits)
     58     Frame Length: 60 bytes (480 bits)
 ```
 See: https://en.wikipedia.org/wiki/Internet_Mix
 
| Packet size (incl. IP header)	| Packets	Distribution (in packets)	 |
| ------------- |:-------------:|
|40	|	58.333333%	|
|576	|	33.333333%	|
|1500	|	8.333333%	|
     
Then rewrite all field to what you need it to be 
In this case i'm setting the src and dst mac. And need to rewrite the dst IP to the target host 48.0.0.0/8 > 10.99.204.8/32/
Also randomizing source IPS 16.0.0.0/8 > 10.10.0.0/16
```
tcprewrite \
  --enet-dmac=44:ec:ce:c1:a8:20 \
  --enet-smac=00:52:44:11:22:33 \
  --pnat=16.0.0.0/8:10.10.0.0/16,48.0.0.0/8:10.99.204.8/32 \
  --infile=imix.pcap \
  --outfile=output.pcap
  ```

check result with ```tcpdump -e -n -r output.pcap```

  Then start pktgen with the pcap
  ```
  /opt/pktgen-20.02.0/app/x86_64-native-linuxapp-gcc/pktgen  -- -T -P -m "2.[0]" -s 0:output.pcap
  ```

Then do this:
```
enable 0 pcap
set 0 rate 0.1
start 0
```

Also check ``` page pcap``` not sure why the ips look different in that screen..
