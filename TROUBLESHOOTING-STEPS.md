# Troubleshooting Bootability Issues

## Current Situation
The verify-image.sh script shows errors for kernel, initramfs, and grub2 even when using the official CentOS Stream 9 cloud image.

## Steps to Debug on Your RHEL 9 Box

### 1. Pull Latest Changes

```bash
cd /path/to/ocp-virt
git pull origin main
```

### 2. Check the Base Cloud Image FIRST

This will tell us if the downloaded cloud image itself is bootable:

```bash
./debug-base-image.sh
```

**What to look for:**
- Does it find `vmlinuz-*` in /boot/?
- Does it find `initramfs-*` in /boot/?
- Does it find `grub.cfg` in /boot/grub2/?
- What partition structure does it show?

**Share the output with me** - this will tell us if the problem is:
- The base image is not bootable (need different URL)
- virt-ls can't see the files (partition/mount issue)
- Something else entirely

### 3. Try the Simplest Build

```bash
./build-simple.sh
```

This just copies the cloud image and installs httpd - nothing fancy.

It will show kernel/grub status BEFORE and AFTER customization.

### 4. Verify the Result

```bash
./verify-image.sh
```

## Expected Outputs

### If Everything Works:
```
✅ GRUB2 configuration found
✅ Kernel found
✅ Initramfs found
```

### If Base Image Has Issues:
```
❌ Kernel NOT found!
❌ Initramfs NOT found!
❌ GRUB2 configuration NOT found!
```

This means we need to try a different base image source.

## Alternative Base Images to Try

If the CentOS cloud image doesn't work, try these:

### Option 1: CentOS Stream 9 (Generic Cloud)
```bash
# Already using this
https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2
```

### Option 2: Fedora Cloud Base (Similar to CentOS/RHEL)
```bash
https://download.fedoraproject.org/pub/fedora/linux/releases/39/Cloud/x86_64/images/Fedora-Cloud-Base-39-1.5.x86_64.qcow2
```

### Option 3: Use virt-builder with Rocky Linux
```bash
virt-builder rockylinux-9 --output test.qcow2
```

## Questions to Answer

Please run the debug script and tell me:

1. **What does debug-base-image.sh show for:**
   - Kernel found? (yes/no)
   - Initramfs found? (yes/no)  
   - GRUB found? (yes/no)
   - Partition structure? (what partitions does it list?)

2. **What does build-simple.sh show:**
   - BEFORE customization status?
   - AFTER customization status?

3. **Any error messages during the build?**

Once I see this output, I can tell you exactly what's wrong and how to fix it!
