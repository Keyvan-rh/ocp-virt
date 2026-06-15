#!/bin/bash
set -e

# Custom RHEL 9 Image Builder for OpenShift Virtualization
# This script creates a customized RHEL 9 qcow2 image with httpd

IMAGE_NAME="rhel9-httpd-custom"
IMAGE_VERSION="1.0"
OUTPUT_IMAGE="${IMAGE_NAME}.qcow2"
REGISTRY="quay.io/$(whoami)"  # Change this to your registry

echo "========================================="
echo "Building Custom RHEL 9 Image"
echo "========================================="

# Method 1: Using virt-builder (if you have a base RHEL 9 template)
if command -v virt-builder &> /dev/null; then
    echo "Using virt-builder method..."

    virt-builder rhel-9 \
        --format qcow2 \
        --size 30G \
        --root-password password:redhat \
        --hostname rhel9-custom \
        --install httpd,qemu-guest-agent,cloud-init \
        --run-command 'systemctl enable httpd qemu-guest-agent' \
        --upload cloud-init-userdata.yaml:/etc/cloud/cloud.cfg.d/99-custom.cfg \
        --selinux-relabel \
        --output "$OUTPUT_IMAGE"

    echo "Image built successfully: $OUTPUT_IMAGE"
fi

# Method 2: Using virt-customize on existing RHEL 9 image
if [ -f "rhel-baseos-9-latest.qcow2" ]; then
    echo "Using virt-customize method..."

    cp rhel-baseos-9-latest.qcow2 "$OUTPUT_IMAGE"

    virt-customize -a "$OUTPUT_IMAGE" \
        --root-password password:redhat \
        --hostname rhel9-httpd \
        --install httpd,qemu-guest-agent \
        --run-command 'systemctl enable httpd qemu-guest-agent' \
        --run-command 'firewall-cmd --permanent --add-service=http' \
        --run-command 'firewall-cmd --permanent --add-service=https' \
        --copy-in redhat-logo.png:/var/www/html/ \
        --write '/var/www/html/index.html:<!DOCTYPE html>
<html>
<head><title>Red Hat</title></head>
<body style="background:#000;color:#fff;text-align:center;padding:50px;">
<h1 style="color:#ee0000;">Red Hat Enterprise Linux 9</h1>
<img src="redhat-logo.png" style="max-width:400px;">
<p>Custom OpenShift Virtualization Image</p>
</body>
</html>' \
        --run-command 'chown -R apache:apache /var/www/html' \
        --run-command 'restorecon -Rv /var/www/html' \
        --selinux-relabel

    echo "Image customized successfully: $OUTPUT_IMAGE"
fi

# Optimize the image
echo "Optimizing image..."
virt-sparsify --compress "$OUTPUT_IMAGE" "${IMAGE_NAME}-compressed.qcow2"
mv "${IMAGE_NAME}-compressed.qcow2" "$OUTPUT_IMAGE"

# Display image info
echo ""
echo "========================================="
echo "Image Information:"
echo "========================================="
qemu-img info "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo "1. Download a Red Hat logo and save as 'redhat-logo.png'"
echo "2. Build container: ./build-container.sh"
echo "3. Deploy to OpenShift: kubectl apply -f openshift-manifests/"
echo ""
