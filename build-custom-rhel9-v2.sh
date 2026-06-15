#!/bin/bash
set -e

# Custom CentOS Stream 9 Image Builder - Step by Step Approach
# This version builds in stages to ensure bootloader is properly installed

IMAGE_NAME="centos-stream-9-httpd-custom"
IMAGE_VERSION="1.0"
OUTPUT_IMAGE="${IMAGE_NAME}.qcow2"
TEMP_IMAGE="${IMAGE_NAME}-temp.qcow2"

# Fix libguestfs permissions issue
export LIBGUESTFS_BACKEND=direct

echo "========================================="
echo "Building Custom CentOS Stream 9 Image"
echo "Step-by-Step Approach"
echo "========================================="
echo ""

# Clean up any old images
rm -f "$OUTPUT_IMAGE" "$TEMP_IMAGE"

echo "Step 1: Download base CentOS Stream 9 image"
echo "-------------------------------------------"
virt-builder centosstream-9 \
    --format qcow2 \
    --size 30G \
    --output "$TEMP_IMAGE"

echo ""
echo "Step 2: Check what's in the base image"
echo "---------------------------------------"
echo "Checking for kernel..."
virt-ls -a "$TEMP_IMAGE" /boot/ || echo "Boot directory contents unclear"
echo ""
echo "Checking for grub..."
virt-ls -a "$TEMP_IMAGE" /boot/grub2/ 2>/dev/null || echo "No GRUB2 directory yet"
echo ""

echo "Step 3: Install kernel and bootloader"
echo "--------------------------------------"
virt-customize -a "$TEMP_IMAGE" \
    --root-password password:redhat \
    --hostname centos-stream-9-httpd \
    --run-command 'dnf clean all' \
    --run-command 'dnf install -y kernel grub2 grub2-tools grub2-efi-x64 shim-x64' \
    --run-command 'echo "Kernel installed, listing kernels:"' \
    --run-command 'rpm -qa | grep kernel' \
    --run-command 'echo "Generating initramfs..."' \
    --run-command 'KVER=$(rpm -q kernel --qf "%{VERSION}-%{RELEASE}.%{ARCH}\n" | tail -1); echo "Kernel version: $KVER"; dracut --force --kver $KVER' \
    --run-command 'ls -la /boot/' \
    --run-command 'echo "Configuring GRUB2..."' \
    --run-command 'grub2-mkconfig -o /boot/grub2/grub.cfg' \
    --run-command 'ls -la /boot/grub2/'

echo ""
echo "Step 4: Verify bootloader installation"
echo "---------------------------------------"
if virt-ls -a "$TEMP_IMAGE" /boot/grub2/ 2>/dev/null | grep -q grub.cfg; then
    echo "✅ GRUB2 configuration found"
else
    echo "❌ GRUB2 configuration MISSING!"
    echo "Listing /boot/grub2/ contents:"
    virt-ls -a "$TEMP_IMAGE" /boot/grub2/ 2>/dev/null || echo "Directory doesn't exist"
fi

if virt-ls -a "$TEMP_IMAGE" /boot/ 2>/dev/null | grep -q vmlinuz; then
    echo "✅ Kernel found"
else
    echo "❌ Kernel MISSING!"
fi

if virt-ls -a "$TEMP_IMAGE" /boot/ 2>/dev/null | grep -q initramfs; then
    echo "✅ Initramfs found"
else
    echo "❌ Initramfs MISSING!"
fi

echo ""
read -p "Do you want to continue with application installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build stopped. Temporary image saved as: $TEMP_IMAGE"
    exit 1
fi

echo ""
echo "Step 5: Install applications (httpd, qemu-guest-agent, etc.)"
echo "-------------------------------------------------------------"
virt-customize -a "$TEMP_IMAGE" \
    --install httpd,qemu-guest-agent,cloud-init,firewalld \
    --run-command 'systemctl enable httpd qemu-guest-agent firewalld' \
    --mkdir /var/www/html \
    --write '/var/www/html/index.html:<!DOCTYPE html>
<html>
<head>
    <title>CentOS Stream 9</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: Arial, sans-serif;
            background-color: #000000;
            color: #ffffff;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            max-width: 800px;
        }
        h1 {
            color: #ee0000;
            font-size: 2.5em;
            margin-bottom: 20px;
        }
        .logo {
            max-width: 400px;
            width: 100%;
            height: auto;
            margin: 20px 0;
        }
        .info {
            background-color: #1a1a1a;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>CentOS Stream 9</h1>
        <img src="redhat-logo.png" alt="Red Hat Logo" class="logo" onerror="this.style.display=none">
        <div class="info">
            <h2>Custom OpenShift Virtualization Boot Image</h2>
            <p>This VM is running on OpenShift Virtualization</p>
            <p>Apache httpd is configured and running</p>
            <p>Hostname: centos-stream-9-httpd</p>
        </div>
    </div>
</body>
</html>' \
    --run-command 'chown -R apache:apache /var/www/html' \
    --run-command 'restorecon -Rv /var/www/html' \
    --selinux-relabel

# If you have a Red Hat logo, copy it into the image
if [ -f "redhat-logo.png" ]; then
    echo ""
    echo "Step 6: Adding Red Hat logo..."
    echo "-------------------------------"
    virt-customize -a "$TEMP_IMAGE" \
        --copy-in redhat-logo.png:/var/www/html/ \
        --run-command 'chown apache:apache /var/www/html/redhat-logo.png' \
        --run-command 'restorecon -v /var/www/html/redhat-logo.png'
fi

echo ""
echo "Step 7: Optimize image"
echo "----------------------"
mv "$TEMP_IMAGE" "$OUTPUT_IMAGE"
virt-sparsify --compress "$OUTPUT_IMAGE" "${IMAGE_NAME}-compressed.qcow2"
mv "${IMAGE_NAME}-compressed.qcow2" "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Image Information:"
echo "========================================="
qemu-img info "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Final Verification:"
echo "========================================="
./verify-image.sh

echo ""
echo "Build complete! Image: $OUTPUT_IMAGE"
