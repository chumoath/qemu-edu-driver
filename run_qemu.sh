#!/bin/bash

function net_config()
{
	ip tuntap add tap0 mode tap group 0
	ip link set dev tap0 up
	ip addr add 192.168.33.1/24 dev tap0
	iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.33.0/24
	echo 1 > /proc/sys/net/ipv4/ip_forward
	iptables -P FORWARD ACCEPT
}

function run_qemu()
{
	qemu-system-aarch64 -M virt,gic-version=3 -m 16G -cpu cortex-a72 -smp 4 \
	  -kernel Image -append "console=ttyAMA0 nokaslr root=/dev/vda rw" \
	  -device e1000e,netdev=tap0 -netdev tap,id=tap0,ifname=tap0,script=no,downscript=no \
	  -monitor none -drive format=raw,file=ubuntu22_arm64.img \
	  -serial telnet::55555,server,nowait,nodelay -device edu,dma_mask=0xffffffffffffffff -s
}

net_config
run_qemu
