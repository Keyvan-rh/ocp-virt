# Custom RHEL 9 Boot Image for OpenShift Virtualization

This repository contains scripts and manifests to build a custom RHEL 9 boot distribution with Apache httpd pre-installed and configured for OpenShift Virtualization.

## Features

- RHEL 9 base image
- Apache httpd pre-installed and auto-starting
- Simple web page displaying a Red Hat logo
- qemu-guest-agent for VM management
- cloud-init support
- Firewall configured for HTTP/HTTPS

## Prerequisites

### On Your Build Machine

- RHEL 9 or compatible Linux system
- `libguestfs-tools` package installed:
  ```bash
  sudo dnf install libguestfs-tools libguestfs-tools-c
  ```
- `podman` for building container images
- Access to a RHEL 9 base image or subscription

### On OpenShift Cluster

- OpenShift Virtualization operator installed
- Permissions to create resources in `openshift-virtualization-os-images` namespace
- Container registry access (quay.io, internal registry, etc.)

## Quick Start

### Step 1: Get a Red Hat Logo

Download a Red Hat logo image and save it as `redhat-logo.png` in this directory:

```bash
# Example: Download from Red Hat's brand resources
# Or use any Red Hat logo you have permission to use
curl -o redhat-logo.png "https://www.redhat.com/cms/managed-files/styles/max_size/s3/Logo-RedHat-A-Color-CMYK%20%281%29.jpg"
```

### Step 2: Obtain RHEL 9 Base Image

You'll need a RHEL 9 qcow2 image. You can:

**Option A: Download from Red Hat Customer Portal**
```bash
# Download from https://access.redhat.com/downloads/content/479/ver=/rhel---9/9.x/x86_64/product-software
# Save as rhel-baseos-9-latest.qcow2
```

**Option B: Use virt-builder** (if available)
```bash
virt-builder --list | grep rhel
```

### Step 3: Build the Custom Image

```bash
chmod +x build-custom-rhel9.sh
./build-custom-rhel9.sh
```

This creates `rhel9-httpd-custom.qcow2`.

### Step 4: Build Container Image

```bash
chmod +x build-container.sh
./build-container.sh
```

### Step 5: Push to Registry

Update the registry in the script or set environment variable:

```bash
export CONTAINER_REGISTRY="quay.io/yourusername"
chmod +x push-image.sh
./push-image.sh
```

### Step 6: Update OpenShift Manifests

Edit `openshift-manifests/datasource.yaml` and update the registry URL:

```yaml
spec:
  source:
    registry:
      url: "docker://quay.io/yourusername/rhel9-httpd-custom:latest"
```

### Step 7: Deploy to OpenShift

```bash
# Create the DataSource
kubectl apply -f openshift-manifests/datasource.yaml

# Wait for it to be ready
kubectl get datasource -n openshift-virtualization-os-images

# Create a test VM
kubectl apply -f openshift-manifests/test-vm.yaml

# Expose via service and route
kubectl apply -f openshift-manifests/service.yaml
```

### Step 8: Access the Web Server

```bash
# Get the route URL
oc get route rhel9-httpd-test

# Access in browser
echo "https://$(oc get route rhel9-httpd-test -o jsonpath='{.spec.host}')"
```

## Files Description

- `build-custom-rhel9.sh` - Builds the custom RHEL 9 qcow2 image
- `cloud-init-userdata.yaml` - Cloud-init configuration for httpd setup
- `Dockerfile` - Container image definition
- `build-container.sh` - Builds the container disk image
- `push-image.sh` - Pushes image to registry
- `openshift-manifests/` - Kubernetes manifests
  - `datasource.yaml` - DataSource for boot source
  - `test-vm.yaml` - Example VM using the boot source
  - `service.yaml` - Service and Route to expose httpd

## Customization

### Modify the Web Page

Edit the HTML in `cloud-init-userdata.yaml` under the `runcmd` section, or mount your own HTML files.

### Add More Packages

In `build-custom-rhel9.sh`, add packages to the `--install` parameter:

```bash
--install httpd,qemu-guest-agent,your-package-here
```

### Change VM Resources

Edit `openshift-manifests/test-vm.yaml`:

```yaml
resources:
  requests:
    memory: 4Gi  # Increase memory
    cpu: 4       # Increase CPUs
```

## Troubleshooting

### Check VM Status

```bash
kubectl get vm
kubectl get vmi
kubectl describe vm rhel9-httpd-test
```

### Access VM Console

```bash
virtctl console rhel9-httpd-test
```

### Check Logs

```bash
kubectl logs -n openshift-cnv $(kubectl get pods -n openshift-cnv -l kubevirt.io=virt-launcher -o name | grep rhel9-httpd-test)
```

### Verify httpd is Running

Connect to the VM console and run:

```bash
systemctl status httpd
firewall-cmd --list-services
curl localhost
```

## Security Notes

- Default password is `redhat` - **change this for production!**
- Update cloud-init-userdata.yaml with your SSH keys
- Use secrets for sensitive data
- Enable SELinux policies
- Keep the base image updated

## License

This is example code for demonstration purposes.
