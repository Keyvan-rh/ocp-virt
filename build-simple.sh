#!/bin/bash
set -e

# Simplest possible build - no resize, just customize

IMAGE_NAME="centos-stream-9-httpd-custom"
OUTPUT_IMAGE="${IMAGE_NAME}.qcow2"
CLOUD_IMAGE_URL="https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
BASE_IMAGE="CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"

export LIBGUESTFS_BACKEND=direct

echo "========================================="
echo "Simple Build - No Resize"
echo "========================================="
echo ""

# Download if needed
if [ ! -f "$BASE_IMAGE" ]; then
    echo "Downloading CentOS Stream 9 Cloud Image..."
    curl -L -o "$BASE_IMAGE" "$CLOUD_IMAGE_URL"
fi

echo "Copying base image to $OUTPUT_IMAGE..."
cp "$BASE_IMAGE" "$OUTPUT_IMAGE"

echo ""
echo "Checking BEFORE customization..."
echo "Kernel: $(virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep vmlinuz | head -1 || echo 'NOT FOUND')"
echo "Initramfs: $(virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep initramfs | head -1 || echo 'NOT FOUND')"
echo "GRUB: $(virt-ls -a "$OUTPUT_IMAGE" /boot/grub2/ 2>/dev/null | grep grub.cfg || echo 'NOT FOUND')"

echo ""
echo "Customizing image (installing httpd only)..."
virt-customize -a "$OUTPUT_IMAGE" \
    --root-password password:redhat \
    --hostname centos-stream-9-httpd \
    --install httpd \
    --run-command 'systemctl enable httpd' \
    --write '/var/www/html/index.html:<!DOCTYPE html>
<html>
<head><title>CentOS Stream 9</title></head>
<body style="background:#000;color:#fff;text-align:center;padding:50px;font-family:Arial;">
<h1 style="color:#ee0000;font-size:3em;">CentOS Stream 9</h1>
<h2>Custom OpenShift Virtualization Boot Image</h2>
<p>Apache httpd is running</p>
</body>
</html>' \
    --run-command 'chown -R apache:apache /var/www/html'

echo ""
echo "Checking AFTER customization..."
echo "Kernel: $(virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep vmlinuz | head -1 || echo 'NOT FOUND')"
echo "Initramfs: $(virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep initramfs | head -1 || echo 'NOT FOUND')"
echo "GRUB: $(virt-ls -a "$OUTPUT_IMAGE" /boot/grub2/ 2>/dev/null | grep grub.cfg || echo 'NOT FOUND')"

echo ""
echo "Image info:"
qemu-img info "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Build Complete: $OUTPUT_IMAGE"
echo "========================================="
echo ""
echo "Run './verify-image.sh' to check bootability"
