#!/bin/bash
set -e

IMAGE_NAME="rhel9-httpd-custom"
VERSION="1.0"
REGISTRY="${CONTAINER_REGISTRY:-quay.io/$(whoami)}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${VERSION}"
FULL_IMAGE_LATEST="${REGISTRY}/${IMAGE_NAME}:latest"

echo "========================================="
echo "Pushing Container Image to Registry"
echo "========================================="

# Login to registry (if needed)
echo "Logging into $REGISTRY..."
podman login "$REGISTRY"

# Push images
echo ""
echo "Pushing $FULL_IMAGE..."
podman push "$FULL_IMAGE"

echo ""
echo "Pushing $FULL_IMAGE_LATEST..."
podman push "$FULL_IMAGE_LATEST"

echo ""
echo "========================================="
echo "Images pushed successfully!"
echo "========================================="
echo "Update the image reference in openshift-manifests/datasource.yaml"
echo "Then apply: kubectl apply -f openshift-manifests/"
