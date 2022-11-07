#!/bin/bash

export DPDK_VER=20.02
export PKTGEN_VER=20.02.0
export PCI_IF="0000:1a:00.3"


if [ `whoami` != 'root' ]; then
    echo "Please run this as root..., don't worry about it..."
    exit 1
fi

echo "updating fstab"
r=`grep hugetlbfs /etc/fstab`
if [ $? -eq 1 ]; then
echo "huge        /mnt/huge   hugetlbfs defaults      0   0" >> /etc/fstab
fi

if [ ! -d /mnt/huge ]; then
mkdir /mnt/huge
chmod 777 /mnt/huge/
fi


echo "Updating sysctl"
r=`grep nr_hugepages /etc/sysctl.conf`
if [ $? -eq 1 ]; then
    echo "vm.nr_hugepages=256" >> /etc/sysctl.conf
    # also make sure it is live on this run, in case fstab has been already updated
    sysctl -w vm.nr_hugepages=256
fi

echo "checking for iommu in GRUB"
r=`grep iommu=pt /etc/default/grub`
if [ $? -eq 1 ]; then
echo "iommu is missing from grub"
echo "please edit /etc/default/grub and make to append the below to GRUB_CMDLINE_LINUX"
echo "default_hugepagesz=1G hugepagesz=1G hugepages=8 iommu=pt intel_iommu=on pci=assign-busses"
echo 'example: GRUB_CMDLINE_LINUX="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1 default_hugepagesz=1G hugepagesz=1G hugepages=8 iommu=pt intel_iommu=on pci=assign-busses"'
echo "after that run: update-grub && reboot"
echo "this will reboot your machine!"
echo "other things you may want to add are:"
echo "maxcpus=32"
echo "isolcpus=3-31"
exit 1
fi

r=`grep intel_iommu=on /etc/default/grub`
if [ $? -eq 1 ]; then
echo "iommu is missing from grub"
echo "please edit /etc/default/grub and make to append the below to GRUB_CMDLINE_LINUX"
echo "default_hugepagesz=1G hugepagesz=1G hugepages=8 iommu=pt intel_iommu=on pci=assign-busses"

echo 'example: GRUB_CMDLINE_LINUX="console=tty0 console=ttyS1,115200n8 biosdevname=0 net.ifnames=1 default_hugepagesz=1G hugepagesz=1G hugepages=8 iommu=pt intel_iommu=on pci=assign-busses"'
echo "after that run: update-grub && reboot"
echo "this will reboot your machine!"
exit 1
fi

echo "Going into /opt ..."
cd /opt

echo "Installing packages..."
apt-get -y update
apt-get -y upgrade
apt-get -y install python2.7
apt-get -y install build-essential ninja-build meson cmake
apt-get -y install libnuma-dev
apt-get -y install pciutils
apt-get -y install libpcap-dev
apt-get -y install liblua5.3-dev
apt-get -y install python3-pyelftools
apt -y install libelf-dev
apt-get -y install linux-headers-`uname -r` || apt -y install  linux-headers-generic

echo "Setting env..."
export RTE_TARGET=x86_64-native-linuxapp-gcc
export RTE_SDK=/opt/dpdk-$DPDK_VER
ln -s /usr/bin/python2.7 /usr/bin/python

echo "Downloading DPDK..."
if [ ! -f /opt/dpdk-$DPDK_VER.tar.xz ]; then
    wget https://fast.dpdk.org/rel/dpdk-$DPDK_VER.tar.xz
fi

echo "Unpacking DPDK..."
rm -rf dpdk-$DPDK_VER/
tar xvf dpdk-$DPDK_VER.tar.xz

echo "Installing DPDK..."
cd dpdk-$DPDK_VER
make config T=x86_64-native-linuxapp-gcc CONFIG_RTE_EAL_IGB_UIO=y
make install T=x86_64-native-linuxapp-gcc DESTDIR=install CONFIG_RTE_EAL_IGB_UIO=y

cd ..

echo "Downloading pktgen..."
if [ ! -f /opt/pktgen-$PKTGEN_VER.tar.gz ]; then
    wget http://dpdk.org/browse/apps/pktgen-dpdk/snapshot/pktgen-$PKTGEN_VER.tar.gz
fi

echo "Unpacking pktgen..."
rm -rf pktgen-$PKTGEN_VER/
tar xvf pktgen-$PKTGEN_VER.tar.gz

echo "Installing DPDK..."
cd pktgen-$PKTGEN_VER
make

echo "binding dpdk interface $PCI_IF"
modprobe uio
insmod /opt/dpdk-$DPDK_VER/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko
modprobe vfio-pci
modprobe uio_pci_generic
dpdkdevbind=/opt/dpdk-$DPDK_VER/usertools/dpdk-devbind.py
$dpdkdevbind --force -u $PCI_IF
$dpdkdevbind -b igb_uio $PCI_IF
$dpdkdevbind -s

echo "To run pktgen:"
echo  '/opt/pktgen-$PKTGEN_VER/app/x86_64-native-linuxapp-gcc/pktgen  -- -T -P -m "2.[0]"'
echo  '/opt/pktgen-$PKTGEN_VER/app/x86_64-native-linuxapp-gcc/pktgen  -- -T -P -m  "2/4:6/8.[0]"'

echo "
example commands:
set 0 dst mac  e4:43:4b:53:51:83
set 0 rate 1
set 0 size 128
start 0
stop 0
"
