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
	# qemu-xhci: CONFIG_USB_XHCI_HCD CONFIG_USB_XHCI_PCI
	# minicom -D /dev/pts/11
	#gdbserver :2345 qemu-system-aarch64 -M virt,gic-version=3 -m 16G -cpu cortex-a72 -smp 4 \
	qemu-system-aarch64 -M virt,gic-version=3 -m 16G -cpu cortex-a72 -smp 4 \
	  -kernel Image -append "console=ttyAMA0 nokaslr root=/dev/vda rw video=Virtual-1:1920x1080@60me" \
	  -device pcie-root-port,bus=pcie.0,id=seat1,addr=1.0,chassis=1,slot=0 \
	  -device pcie-root-port,bus=pcie.0,id=seat2,addr=2.0,chassis=2,slot=0 \
	  -device pcie-root-port,bus=pcie.0,id=seat3,addr=3.0,chassis=3,slot=0 \
	  -device pcie-root-port,bus=pcie.0,id=seat4,addr=4.0,chassis=4,slot=0 \
	  -device pcie-root-port,bus=pcie.0,id=seat0,addr=5.0,chassis=5,slot=0 \
	  -device virtio-gpu-pci,bus=seat0 \
	  -device qemu-xhci,bus=seat1 \
	  -device edu,dma_mask=0xffffffffffffffff,bus=seat2 \
	  -device e1000e,netdev=tap0,bus=seat3 -netdev tap,id=tap0,ifname=tap0,script=no,downscript=no \
	  -device virtio-blk-pci,drive=rootfs,bus=seat4 -blockdev driver=file,node-name=rootfs,filename=ubuntu22_arm64.img \
	  -device usb-mouse -device usb-kbd -device usb-tablet  -chardev pty,id=pty_serial -device usb-serial,chardev=pty_serial \
	  -monitor none -serial stdio -s
}

net_config
run_qemu
