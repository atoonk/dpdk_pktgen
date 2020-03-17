Also see:
https://github.com/github/glb-director/blob/master/docs/setup/known-compatible-dpdk.md

# Enable SRIOV
```
echo 1 > /sys/class/net/eno1/device/sriov_numvfs
cat /sys/class/net/eno1/device/sriov_numvfs

ip link set eno1 vf 0 spoofchk off
ip link set eno1 vf 0 trust on
ethtool --features eno1 ntuple on

```
After you create the VF, identify the new interface like this:, in this case it's em1_0
You can also check ```dmesg -T```
```
root@ewr1-x1:~# lshw -businfo -class network
Bus info          Device     Class          Description
=======================================================
pci@0000:02:00.0  eno1       network        Ethernet Controller X710 for 10GbE backplane
pci@0000:02:00.1  em2        network        Ethernet Controller X710 for 10GbE backplane
pci@0000:03:02.0  em1_0      network        Illegal Vendor ID
                  bond0      network        Ethernet interface
```
bring it up if you'd like ``` ip link set em1_0 up ```

# flow bifurcation
Add rule to send to queue 0, which when you have VF SRIOV, will be VF0
note, you can add order with loc key word
```
ethtool --config-ntuple eno1 flow-type udp4 dst-port 80  action  0x100000000
Added rule with ID 7679
```

check with
```
root@ewr1-x1:~# ethtool -n  eno1
8 RX rings available
Total 1 rules

Filter: 5
	Rule Type: UDP over IPv4
	Src IP addr: 0.0.0.0 mask: 255.255.255.255
	Dest IP addr: 0.0.0.0 mask: 255.255.255.255
	TOS: 0x0 mask: 0xff
	Src port: 0 mask: 0xffff
	Dest port: 80 mask: 0x0
	Action: Direct to VF 0 queue 0
  ```
  
  To add a drop key:
  ```
  ethtool --config-ntuple eno1 flow-type udp4 dst-port 80  action -1 loc 5
  ```
  
  To delete
  ```
  ethtool --config-ntuple eno1 delete 5
  ```
