#!/bin/bash

# Prerequisite checker for building custom boot images

echo "========================================="
echo "Checking Prerequisites"
echo "========================================="
echo ""

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "❌ This must be run on a Linux system (RHEL 9 or compatible)"
    exit 1
fi

# Check for required commands
MISSING=0

echo "Checking required tools..."
echo ""

if command -v virt-builder &> /dev/null; then
    echo "✅ virt-builder: $(virt-builder --version | head -1)"
else
    echo "❌ virt-builder not found"
    echo "   Install: sudo dnf install libguestfs-tools-c"
    MISSING=1
fi

if command -v virt-customize &> /dev/null; then
    echo "✅ virt-customize: $(virt-customize --version | head -1)"
else
    echo "❌ virt-customize not found"
    echo "   Install: sudo dnf install libguestfs-tools-c"
    MISSING=1
fi

if command -v virt-sparsify &> /dev/null; then
    echo "✅ virt-sparsify: found"
else
    echo "❌ virt-sparsify not found"
    echo "   Install: sudo dnf install libguestfs-tools-c"
    MISSING=1
fi

if command -v qemu-img &> /dev/null; then
    echo "✅ qemu-img: $(qemu-img --version | head -1)"
else
    echo "❌ qemu-img not found"
    echo "   Install: sudo dnf install qemu-img"
    MISSING=1
fi

if command -v curl &> /dev/null; then
    echo "✅ curl: found"
else
    echo "❌ curl not found"
    echo "   Install: sudo dnf install curl"
    MISSING=1
fi

echo ""
echo "Checking permissions..."
echo ""

# Check if user is in libvirt group
if groups | grep -q libvirt; then
    echo "✅ User is in libvirt group"
else
    echo "⚠️  User not in libvirt group"
    echo "   This may cause permission issues"
    echo "   Fix: sudo usermod -a -G libvirt \$(whoami)"
    echo "        newgrp libvirt"
fi

# Check LIBGUESTFS_BACKEND
if [ -z "$LIBGUESTFS_BACKEND" ]; then
    echo "ℹ️  LIBGUESTFS_BACKEND not set (scripts will set it to 'direct')"
else
    echo "✅ LIBGUESTFS_BACKEND=$LIBGUESTFS_BACKEND"
fi

echo ""
echo "Checking disk space..."
echo ""

AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 10 ]; then
    echo "✅ Available disk space: ${AVAILABLE}GB"
else
    echo "⚠️  Low disk space: ${AVAILABLE}GB"
    echo "   Recommended: at least 10GB free"
fi

echo ""
echo "========================================="
if [ $MISSING -eq 0 ]; then
    echo "✅ All prerequisites met!"
    echo "========================================="
    echo ""
    echo "Ready to build. Run: ./build-from-cloud-image.sh"
else
    echo "❌ Missing prerequisites"
    echo "========================================="
    echo ""
    echo "Install missing packages with:"
    echo "  sudo dnf install libguestfs-tools-c qemu-img curl"
fi
echo ""
