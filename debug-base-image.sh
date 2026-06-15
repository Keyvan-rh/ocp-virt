#!/bin/bash

# Debug script to check what's in the base cloud image

export LIBGUESTFS_BACKEND=direct

BASE_IMAGE="CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"

if [ ! -f "$BASE_IMAGE" ]; then
    echo "Base image not found. Downloading..."
    curl -L -o "$BASE_IMAGE" "https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
fi

echo "========================================="
echo "Checking BASE Cloud Image"
echo "========================================="
echo ""

echo "Image info:"
qemu-img info "$BASE_IMAGE"

echo ""
echo "========================================="
echo "Filesystems in the image:"
echo "========================================="
virt-filesystems -a "$BASE_IMAGE" --all --long

echo ""
echo "========================================="
echo "Partitions:"
echo "========================================="
virt-filesystems -a "$BASE_IMAGE" --partitions --long

echo ""
echo "========================================="
echo "What's in /boot/ directory:"
echo "========================================="
virt-ls -a "$BASE_IMAGE" -l /boot/ || echo "Could not list /boot/"

echo ""
echo "========================================="
echo "What's in /boot/grub2/ directory:"
echo "========================================="
virt-ls -a "$BASE_IMAGE" -l /boot/grub2/ || echo "Could not list /boot/grub2/"

echo ""
echo "========================================="
echo "Checking for kernel:"
echo "========================================="
virt-ls -a "$BASE_IMAGE" /boot/ | grep vmlinuz || echo "No kernel found"

echo ""
echo "========================================="
echo "Checking for initramfs:"
echo "========================================="
virt-ls -a "$BASE_IMAGE" /boot/ | grep initramfs || echo "No initramfs found"

echo ""
echo "========================================="
echo "Checking for grub.cfg:"
echo "========================================="
virt-ls -a "$BASE_IMAGE" /boot/grub2/ | grep grub.cfg || echo "No grub.cfg found"

echo ""
echo "========================================="
echo "Installed kernel packages:"
echo "========================================="
virt-inspector -a "$BASE_IMAGE" 2>/dev/null | grep -A5 "<name>kernel</name>" || echo "Could not inspect packages"

echo ""
echo "========================================="
echo "Analysis Complete"
echo "========================================="
