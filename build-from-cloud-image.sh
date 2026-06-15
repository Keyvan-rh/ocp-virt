#!/bin/bash
set -e

# Build from Official CentOS Stream 9 Cloud Image (Known Bootable)
# This is more reliable than virt-builder for bootability

IMAGE_NAME="centos-stream-9-httpd-custom"
OUTPUT_IMAGE="${IMAGE_NAME}.qcow2"
CLOUD_IMAGE_URL="https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
BASE_IMAGE="CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"

# Fix libguestfs permissions issue
export LIBGUESTFS_BACKEND=direct

echo "========================================="
echo "Building from Official Cloud Image"
echo "========================================="
echo ""

# Download official cloud image if not present
if [ ! -f "$BASE_IMAGE" ]; then
    echo "Downloading CentOS Stream 9 Cloud Image..."
    echo "URL: $CLOUD_IMAGE_URL"
    curl -L -o "$BASE_IMAGE" "$CLOUD_IMAGE_URL"
    echo "Download complete!"
else
    echo "Using existing cloud image: $BASE_IMAGE"
fi

echo ""
echo "Copying base image..."
cp "$BASE_IMAGE" "$OUTPUT_IMAGE"

echo ""
echo "Resizing image to 30GB..."
qemu-img resize "$OUTPUT_IMAGE" 30G

echo ""
echo "Expanding root partition and filesystem..."
virt-resize --expand /dev/sda3 "$BASE_IMAGE" "$OUTPUT_IMAGE" || \
virt-resize --expand /dev/sda2 "$BASE_IMAGE" "$OUTPUT_IMAGE" || \
echo "Note: Could not auto-resize, filesystem will expand on first boot"

echo ""
echo "Customizing image..."
virt-customize -a "$OUTPUT_IMAGE" \
    --root-password password:redhat \
    --hostname centos-stream-9-httpd \
    --run-command 'dnf update -y --security' \
    --install httpd,qemu-guest-agent,firewalld \
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
    echo "Adding Red Hat logo..."
    virt-customize -a "$OUTPUT_IMAGE" \
        --copy-in redhat-logo.png:/var/www/html/ \
        --run-command 'chown apache:apache /var/www/html/redhat-logo.png' \
        --run-command 'restorecon -v /var/www/html/redhat-logo.png'
fi

echo ""
echo "Sparsifying image..."
virt-sparsify --compress "$OUTPUT_IMAGE" "${IMAGE_NAME}-compressed.qcow2"
mv "${IMAGE_NAME}-compressed.qcow2" "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Image Information:"
echo "========================================="
qemu-img info "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "Verification:"
echo "========================================="

# Quick verification
if virt-ls -a "$OUTPUT_IMAGE" /boot/grub2/ 2>/dev/null | grep -q grub.cfg; then
    echo "✅ GRUB2 configuration found"
else
    echo "❌ GRUB2 configuration not found"
fi

if virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep -q vmlinuz; then
    echo "✅ Kernel found"
else
    echo "❌ Kernel not found"
fi

if virt-ls -a "$OUTPUT_IMAGE" /boot/ 2>/dev/null | grep -q initramfs; then
    echo "✅ Initramfs found"
else
    echo "❌ Initramfs not found"
fi

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="
echo "Image: $OUTPUT_IMAGE"
echo ""
echo "This image is built from the official CentOS Stream 9 cloud image"
echo "which is guaranteed to be bootable."
echo ""
echo "Next steps:"
echo "1. Run: ./verify-image.sh (for detailed verification)"
echo "2. Build container: ./build-container.sh"
echo "3. Push to registry: ./push-image.sh"
echo "4. Deploy to OpenShift: kubectl apply -f openshift-manifests/"
echo ""
