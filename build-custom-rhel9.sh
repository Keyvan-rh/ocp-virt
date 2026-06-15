#!/bin/bash
set -e

# Custom CentOS Stream 9 / RHEL 9 Image Builder for OpenShift Virtualization
# This script creates a customized CentOS Stream 9 qcow2 image with httpd

IMAGE_NAME="centos-stream-9-httpd-custom"
IMAGE_VERSION="1.0"
OUTPUT_IMAGE="${IMAGE_NAME}.qcow2"
REGISTRY="quay.io/$(whoami)"  # Change this to your registry

echo "========================================="
echo "Building Custom CentOS Stream 9 Image"
echo "========================================="

# Method 1: Using virt-builder with CentOS Stream 9
if command -v virt-builder &> /dev/null; then
    echo "Using virt-builder method..."

    virt-builder centos-stream-9 \
        --format qcow2 \
        --size 30G \
        --root-password password:redhat \
        --hostname centos-stream-9-httpd \
        --install httpd,qemu-guest-agent,cloud-init \
        --run-command 'systemctl enable httpd qemu-guest-agent' \
        --run-command 'firewall-cmd --permanent --add-service=http' \
        --run-command 'firewall-cmd --permanent --add-service=https' \
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
        --selinux-relabel \
        --output "$OUTPUT_IMAGE"

    echo "Image built successfully: $OUTPUT_IMAGE"

    # If you have a Red Hat logo, copy it into the image
    if [ -f "redhat-logo.png" ]; then
        echo "Adding Red Hat logo to image..."
        virt-customize -a "$OUTPUT_IMAGE" \
            --copy-in redhat-logo.png:/var/www/html/ \
            --run-command 'chown apache:apache /var/www/html/redhat-logo.png' \
            --run-command 'restorecon -v /var/www/html/redhat-logo.png'
    fi
fi

# Method 2: Using virt-customize on existing CentOS Stream 9 / RHEL 9 image
# Uncomment and use this if you have a pre-downloaded qcow2 image
# if [ -f "centos-stream-9-base.qcow2" ]; then
#     echo "Using virt-customize method on existing image..."
#
#     cp centos-stream-9-base.qcow2 "$OUTPUT_IMAGE"
#
#     virt-customize -a "$OUTPUT_IMAGE" \
#         --root-password password:redhat \
#         --hostname centos-stream-9-httpd \
#         --install httpd,qemu-guest-agent \
#         --run-command 'systemctl enable httpd qemu-guest-agent' \
#         --run-command 'firewall-cmd --permanent --add-service=http' \
#         --run-command 'firewall-cmd --permanent --add-service=https' \
#         --copy-in redhat-logo.png:/var/www/html/ \
#         --write '/var/www/html/index.html:...' \
#         --run-command 'chown -R apache:apache /var/www/html' \
#         --run-command 'restorecon -Rv /var/www/html' \
#         --selinux-relabel
#
#     echo "Image customized successfully: $OUTPUT_IMAGE"
# fi

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
echo "1. (Optional) Download a Red Hat logo and save as 'redhat-logo.png'"
echo "   Then re-run this script to add it to the image"
echo "2. Build container: ./build-container.sh"
echo "3. Deploy to OpenShift: kubectl apply -f openshift-manifests/"
echo ""
echo "Note: Image name is ${IMAGE_NAME}.qcow2"
echo "      Update Dockerfile and manifests if you renamed the image"
echo ""
