# Custom CentOS Stream 9 Boot Image for OpenShift Virtualization

This repository contains scripts and manifests to build a custom CentOS Stream 9 boot distribution with Apache httpd pre-installed and configured for OpenShift Virtualization.

---

## 🚀 Quick Start (Simple Upload via UI)

**Want to just build and upload? See [SIMPLE-GUIDE.md](SIMPLE-GUIDE.md)**

The simple guide shows you how to:
1. Build a bootable qcow2 image with httpd
2. Upload directly via OpenShift UI (no container registry needed)
3. Create a VM and access the web server

---

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

**⚠️ IMPORTANT: If you're having bootability issues, use Method 2 (cloud image)**

#### Method 1: Using virt-builder (Original)

```bash
chmod +x build-custom-rhel9.sh
./build-custom-rhel9.sh
```

#### Method 2: Using Official CentOS Stream 9 Cloud Image (RECOMMENDED)

This method uses the official CentOS Stream 9 cloud image which is guaranteed bootable:

```bash
chmod +x build-from-cloud-image.sh
./build-from-cloud-image.sh
```

**Why use Method 2?**
- Official cloud image is guaranteed bootable
- Already has kernel, initramfs, and grub2 properly configured
- Faster build (no kernel installation needed)
- More reliable for production use

#### Method 3: Step-by-Step Debug Build

If you want to see exactly what's happening during the build:

```bash
chmod +x build-custom-rhel9-v2.sh
./build-custom-rhel9-v2.sh
```

This will pause and show you verification results before continuing.

### Step 3a: Verify the Image (Optional but Recommended)

```bash
chmod +x verify-image.sh
./verify-image.sh
```

This checks that the image has:
- Bootloader (GRUB2) properly configured
- Kernel and initramfs present
- Required packages installed
- Web content in place

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
- `verify-image.sh` - Verifies the built image has bootloader, kernel, and packages
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

## Manual Upload to OpenShift (Alternative to Container Registry)

If you want to upload the qcow2 directly instead of using a container registry:

### Option 1: Upload via Web Console

1. Navigate to **Virtualization** → **Boot sources**
2. Click **Add boot source to catalog**
3. Select **Upload local file**
4. Choose your `centos-stream-9-httpd-custom.qcow2`
5. Wait for upload to complete

**Important:** Make sure the DataVolume is created with `contentType: kubevirt` for proper boot detection.

### Option 2: Create DataVolume with HTTP Source

If you have the qcow2 on a web server:

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataVolume
metadata:
  name: centos-stream-9-httpd-custom
  namespace: openshift-virtualization-os-images
spec:
  source:
    http:
      url: "http://your-server/centos-stream-9-httpd-custom.qcow2"
  pvc:
    accessModes:
      - ReadWriteMany
    resources:
      requests:
        storage: 30Gi
    storageClassName: ocs-storagecluster-ceph-rbd
```

### Option 3: Upload via virtctl

```bash
# Upload the image
virtctl image-upload dv centos-stream-9-custom \
  --size=30Gi \
  --image-path=centos-stream-9-httpd-custom.qcow2 \
  --namespace=openshift-virtualization-os-images \
  --storage-class=ocs-storagecluster-ceph-rbd \
  --insecure
```

## Troubleshooting

### Image Not Bootable

If the VM doesn't boot after upload:

1. **Verify the image has a bootloader:**
   ```bash
   ./verify-image.sh
   ```

2. **Check GRUB is present:**
   ```bash
   virt-ls -a centos-stream-9-httpd-custom.qcow2 /boot/grub2/
   ```

3. **Rebuild with explicit grub configuration:**
   ```bash
   # The build script already runs grub2-mkconfig
   # If it's still not bootable, check the base image
   virt-builder --list | grep centosstream-9
   ```

4. **Test boot locally with QEMU:**
   ```bash
   qemu-system-x86_64 -m 2048 \
     -hda centos-stream-9-httpd-custom.qcow2 \
     -boot c \
     -nographic
   ```

5. **Check VM events in OpenShift:**
   ```bash
   oc describe vmi <vm-name>
   oc logs -n openshift-cnv virt-launcher-<vm-name>
   ```

### firewall-cmd / dbus Error

If you get an error like:
```
Error: DBUS_ERROR: Failed to connect to socket /run/dbus/system_bus_socket
virt-builder: error: firewall-cmd --permanent --add-service=http: command exited with an error
```

**Fix:** This is already fixed in the current version. The firewall is configured at boot time via cloud-init, not during image build. If you're seeing this, make sure you have the latest version of `build-custom-rhel9.sh`.

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
