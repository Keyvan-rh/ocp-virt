# Custom CentOS Stream 9 Boot Image for OpenShift Virtualization

This repository contains scripts and manifests to build a custom CentOS Stream 9 boot distribution with Apache httpd pre-installed and configured for OpenShift Virtualization.

## Features

- CentOS Stream 9 base image (RHEL 9 compatible)
- Apache httpd pre-installed and auto-starting
- Simple web page displaying a Red Hat logo (optional)
- qemu-guest-agent for VM management
- cloud-init support
- Firewall configured for HTTP/HTTPS

## Prerequisites

### On Your Build Machine

- RHEL 9, CentOS Stream 9, or compatible Linux system
- `libguestfs-tools` package installed:
  ```bash
  sudo dnf install libguestfs-tools libguestfs-tools-c
  ```
- `podman` for building container images
- `virt-builder` will automatically download CentOS Stream 9 base image

### On OpenShift Cluster

- OpenShift Virtualization operator installed
- Permissions to create resources in `openshift-virtualization-os-images` namespace
- Container registry access (quay.io, internal registry, etc.)

## Quick Start

### Step 0: Check Prerequisites (Recommended)

```bash
chmod +x check-prereqs.sh
./check-prereqs.sh
```

This script checks for all required tools and common issues.

### Step 1: Verify virt-builder has CentOS Stream 9

```bash
virt-builder --list | grep centosstream
```

You should see `centosstream-9` in the list.

**Important:** The image name is `centosstream-9` (no hyphen between centos and stream).

### Step 2: (Optional) Get a Red Hat Logo

If you want to display a Red Hat logo on the web page:

```bash
# Download or copy your Red Hat logo to this directory
# Save it as: redhat-logo.png
```

### Step 3: Build the Custom Image

```bash
chmod +x build-custom-rhel9.sh
./build-custom-rhel9.sh
```

This downloads CentOS Stream 9 and creates `centos-stream-9-httpd-custom.qcow2`.

**Note:** First run will download the base image (~800MB), subsequent runs will be faster.

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
oc get route centos-stream-9-httpd-test

# Access in browser
echo "https://$(oc get route centos-stream-9-httpd-test -o jsonpath='{.spec.host}')"
```

## Files Description

- `check-prereqs.sh` - Checks for required tools and common configuration issues
- `build-custom-rhel9.sh` - Builds the custom CentOS Stream 9 qcow2 image using virt-builder
- `cloud-init-userdata.yaml` - Cloud-init configuration for httpd setup (reference)
- `Dockerfile` - Container image definition for containerDisk
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

### libguestfs Permission Error

If you get an error like:
```
virt-resize: error: libguestfs error: could not create appliance through libvirt.
Original error from libvirt: Cannot access storage file
```

**Fix:** The script already sets `LIBGUESTFS_BACKEND=direct`, but if you still have issues:

```bash
# Run with direct backend (no libvirt)
export LIBGUESTFS_BACKEND=direct
./build-custom-rhel9.sh

# OR add your user to the libvirt group
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt

# OR run with sudo (if necessary)
sudo ./build-custom-rhel9.sh
```

### SELinux Issues

If SELinux is blocking virt-builder:

```bash
# Temporarily set SELinux to permissive
sudo setenforce 0
./build-custom-rhel9.sh
sudo setenforce 1

# Or create proper SELinux policy
sudo ausearch -c 'qemu-system-x86' --raw | audit2allow -M my-virtbuilder
sudo semodule -i my-virtbuilder.pp
```

### Check VM Status

```bash
kubectl get vm
kubectl get vmi
kubectl describe vm centos-stream-9-httpd-test
```

### Access VM Console

```bash
virtctl console centos-stream-9-httpd-test
```

### Check Logs

```bash
kubectl logs -n openshift-cnv $(kubectl get pods -n openshift-cnv -l kubevirt.io=virt-launcher -o name | grep centos-stream-9-httpd-test)
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
