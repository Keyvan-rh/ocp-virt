#!/bin/bash
set -e

# Container Image Builder
IMAGE_NAME="centos-stream-9-httpd-custom"
VERSION="1.0"
REGISTRY="${CONTAINER_REGISTRY:-quay.io/$(whoami)}"  # Override with env var
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${VERSION}"
FULL_IMAGE_LATEST="${REGISTRY}/${IMAGE_NAME}:latest"

echo "========================================="
echo "Building Container Image"
echo "========================================="
echo "Image: $FULL_IMAGE"
echo ""

# Check if qcow2 image exists
if [ ! -f "centos-stream-9-httpd-custom.qcow2" ]; then
    echo "Error: centos-stream-9-httpd-custom.qcow2 not found!"
    echo "Please run ./build-custom-rhel9.sh first"
    exit 1
fi

# Build container image
echo "Building container with podman..."
podman build -t "$FULL_IMAGE" -t "$FULL_IMAGE_LATEST" .

echo ""
echo "========================================="
echo "Container built successfully!"
echo "========================================="
echo "Tagged as:"
echo "  - $FULL_IMAGE"
echo "  - $FULL_IMAGE_LATEST"
echo ""
echo "To push to registry:"
echo "  podman push $FULL_IMAGE"
echo "  podman push $FULL_IMAGE_LATEST"
echo ""
echo "Or run: ./push-image.sh"
