#!/bin/bash

# Verify the built image is bootable and properly configured

IMAGE="centos-stream-9-httpd-custom.qcow2"

if [ ! -f "$IMAGE" ]; then
    echo "Error: $IMAGE not found!"
    echo "Please run ./build-custom-rhel9.sh first"
    exit 1
fi

echo "========================================="
echo "Verifying Image: $IMAGE"
echo "========================================="
echo ""

echo "1. Image Information:"
echo "-------------------"
qemu-img info "$IMAGE"
echo ""

echo "2. Checking for bootloader:"
echo "-------------------"

# List what's actually in /boot/grub2/
echo "DEBUG: Listing /boot/grub2/ contents:"
virt-ls -a "$IMAGE" /boot/grub2/ 2>&1 | head -10

echo ""
echo "DEBUG: Listing /boot/ contents:"
virt-ls -a "$IMAGE" /boot/ 2>&1 | head -20

echo ""
if virt-ls -a "$IMAGE" /boot/grub2/ 2>/dev/null | grep -q grub.cfg; then
    echo "✅ GRUB2 configuration found: /boot/grub2/grub.cfg"
else
    echo "❌ GRUB2 configuration NOT found!"
    echo "   Files in /boot/grub2/: $(virt-ls -a "$IMAGE" /boot/grub2/ 2>/dev/null | tr '\n' ' ')"
fi

if virt-ls -a "$IMAGE" /boot/ 2>/dev/null | grep -q vmlinuz; then
    KERNEL=$(virt-ls -a "$IMAGE" /boot/ | grep vmlinuz | head -1)
    echo "✅ Kernel found: /boot/$KERNEL"
else
    echo "❌ Kernel NOT found!"
    echo "   Files in /boot/: $(virt-ls -a "$IMAGE" /boot/ 2>/dev/null | tr '\n' ' ')"
fi

if virt-ls -a "$IMAGE" /boot/ 2>/dev/null | grep -q initramfs; then
    INITRAMFS=$(virt-ls -a "$IMAGE" /boot/ | grep initramfs | head -1)
    echo "✅ Initramfs found: /boot/$INITRAMFS"
else
    echo "❌ Initramfs NOT found!"
    echo "   Files in /boot/: $(virt-ls -a "$IMAGE" /boot/ 2>/dev/null | tr '\n' ' ')"
fi
echo ""

echo "3. Checking installed packages:"
echo "-------------------"
PACKAGES="httpd qemu-guest-agent cloud-init firewalld"
for pkg in $PACKAGES; do
    if virt-inspector -a "$IMAGE" 2>/dev/null | grep -q "$pkg"; then
        echo "✅ $pkg installed"
    else
        # Fallback check
        if virt-ls -a "$IMAGE" /etc/systemd/system/multi-user.target.wants/ 2>/dev/null | grep -q "$pkg"; then
            echo "✅ $pkg service enabled"
        else
            echo "⚠️  $pkg - cannot verify"
        fi
    fi
done
echo ""

echo "4. Checking web content:"
echo "-------------------"
if virt-cat -a "$IMAGE" /var/www/html/index.html >/dev/null 2>&1; then
    echo "✅ Web page found: /var/www/html/index.html"
    echo "   Preview (first 5 lines):"
    virt-cat -a "$IMAGE" /var/www/html/index.html | head -5 | sed 's/^/   /'
else
    echo "❌ Web page NOT found!"
fi
echo ""

echo "5. Boot partition check:"
echo "-------------------"
virt-filesystems -a "$IMAGE" --long --parts --blkdevs
echo ""

echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "If bootloader is missing, the image may not boot."
echo "To test boot locally:"
echo "  qemu-system-x86_64 -m 2048 -hda $IMAGE -boot c"
echo ""
