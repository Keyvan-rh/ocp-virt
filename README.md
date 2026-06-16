# Custom CentOS Stream 9 Boot Image for OpenShift Virtualization

Build a bootable CentOS Stream 9 qcow2 image with Apache httpd pre-installed, ready to upload directly to OpenShift Virtualization.

---

## 🚀 Quick Start

**See [SIMPLE-GUIDE.md](SIMPLE-GUIDE.md) for step-by-step instructions.**

---

## Features

- ✅ CentOS Stream 9 base image (RHEL 9 compatible)
- ✅ Apache httpd pre-installed and auto-starting
- ✅ Bootable with GRUB2, kernel, and initramfs
- ✅ qemu-guest-agent for VM management
- ✅ cloud-init support
- ✅ Simple web page (optional Red Hat logo)

## Prerequisites

### On Your Build Machine (RHEL 9 or Compatible)

```bash
sudo dnf install libguestfs-tools libguestfs-tools-c qemu-img curl
```

### On OpenShift Cluster

- OpenShift Virtualization operator installed
- Storage class available for PVCs

## Build the Image

### Step 1: Check Prerequisites

```bash
./check-prereqs.sh
```

### Step 2: (Optional) Create a Logo

```bash
./create-logo.sh
```

Or skip this step - the web page works fine without it.

### Step 3: Build the Image

```bash
./build-from-cloud-image.sh
```

This downloads the official CentOS Stream 9 cloud image (~400MB) and customizes it with httpd.

### Step 4: Verify Bootability

```bash
./verify-image.sh
```

You should see:
- ✅ GRUB2 configuration found
- ✅ Kernel found
- ✅ Initramfs found

**Output:** `centos-stream-9-httpd-custom.qcow2` (ready to upload!)

## Upload to OpenShift

### Via Web Console (Easiest)

1. Navigate to **Virtualization** → **Catalog** → **Add volume**
2. Choose **Upload local file**
3. Select `centos-stream-9-httpd-custom.qcow2`
4. Set storage class and size (30Gi recommended)
5. Wait for upload to complete

### Via virtctl

```bash
virtctl image-upload pvc my-centos-httpd \
  --size=30Gi \
  --image-path=centos-stream-9-httpd-custom.qcow2 \
  --storage-class=your-storage-class \
  --access-mode=ReadWriteMany \
  --insecure
```

## Create a VM

After uploading, create a VM using the uploaded PVC as the boot disk.

**Via Web Console:**
1. **Virtualization** → **VirtualMachines** → **Create**
2. Use the uploaded PVC as the root disk

**Via CLI:**
```bash
cat <<EOF | oc apply -f -
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: my-httpd-vm
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
        resources:
          requests:
            memory: 2Gi
            cpu: 2
      volumes:
        - name: rootdisk
          persistentVolumeClaim:
            claimName: my-centos-httpd
EOF
```

## Expose the Web Page

See [EXPOSE-WEB-PAGE.md](EXPOSE-WEB-PAGE.md) for complete instructions.

**Quick version:**

```bash
# Edit the template with your VM name
vi httpd-service-route.yaml
# Change: vm.kubevirt.io/name: YOUR-VM-NAME

# Apply
oc apply -f httpd-service-route.yaml

# Get the URL
echo "https://$(oc get route httpd-vm-route -o jsonpath='{.spec.host}')"
```

Open the URL in your browser!

## Files in This Repository

| File | Description |
|------|-------------|
| `README.md` | This file |
| `SIMPLE-GUIDE.md` | Step-by-step quick start guide |
| `EXPOSE-WEB-PAGE.md` | How to expose httpd externally |
| `check-prereqs.sh` | Verify system requirements |
| `build-from-cloud-image.sh` | **Main build script** |
| `verify-image.sh` | Verify image bootability |
| `create-logo.sh` | Create/download Red Hat logo (optional) |
| `httpd-service-route.yaml` | Template for Service and Route |
| `.gitignore` | Ignore qcow2 and temp files |

## Customization

### Change the Web Page Content

Edit `build-from-cloud-image.sh` and modify the HTML in the `--write '/var/www/html/index.html:...'` section.

### Add More Packages

In `build-from-cloud-image.sh`, add packages to the `--install` line:

```bash
--install httpd,qemu-guest-agent,firewalld,your-package-here \
```

### Change VM Size/Resources

When creating the VM, adjust the resources:

```yaml
resources:
  requests:
    memory: 4Gi  # Increase memory
    cpu: 4       # Increase CPUs
```

## Troubleshooting

### Image Not Bootable

Run `./verify-image.sh` - you should see all green ✅ checks. If not:

1. Make sure `LIBGUESTFS_BACKEND=direct` is set (the script sets this automatically)
2. Check you have enough disk space (10GB minimum)
3. Try re-downloading: `rm CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2` and rebuild

### Permission Denied Errors

```bash
export LIBGUESTFS_BACKEND=direct
./build-from-cloud-image.sh
```

Or add your user to the libvirt group:
```bash
sudo usermod -a -G libvirt $(whoami)
newgrp libvirt
```

### Can't Access Web Page

1. **Check VM is running:** `oc get vmi`
2. **Check httpd is running inside VM:**
   ```bash
   virtctl console YOUR-VM-NAME
   # Login: root / redhat
   systemctl status httpd
   ```
3. **Check Service has endpoints:**
   ```bash
   oc get endpoints httpd-vm-service
   ```
   If empty, the selector is wrong - see [EXPOSE-WEB-PAGE.md](EXPOSE-WEB-PAGE.md)

4. **Check firewall (if enabled):**
   ```bash
   # Inside VM
   systemctl status firewalld
   firewall-cmd --list-services  # Should show http
   ```

### VM Console Login

- **Username:** `root`
- **Password:** `redhat`

## How It Works

1. **Downloads** official CentOS Stream 9 cloud image (bootable, with kernel/grub)
2. **Customizes** it using `virt-customize`:
   - Sets root password
   - Installs httpd
   - Creates web page
   - Enables httpd service
3. **Optimizes** with `virt-sparsify` to reduce size
4. **Outputs** a bootable qcow2 ready for OpenShift Virtualization

## Security Notes

- Default root password is `redhat` - **change this for production!**
- Update the image regularly for security patches
- Consider using cloud-init for SSH key injection instead of password

## License

Example code for demonstration purposes.

## Contributing

Issues and pull requests welcome at: https://github.com/Keyvan-rh/ocp-virt
