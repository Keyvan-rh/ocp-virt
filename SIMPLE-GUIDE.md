# Simple Guide: Bootable CentOS Stream 9 with httpd

## Goal
Create a bootable qcow2 image with httpd serving a Red Hat logo, then upload it to OpenShift Virtualization.

## Step 1: Download Red Hat Logo

```bash
# Download an official Red Hat logo
curl -L -o redhat-logo.png "https://www.redhat.com/rhdc/managed-files/styles/wysiwyg_full_width/private/Logo-redhat-color-375.png"

# Or any Red Hat logo you have
```

## Step 2: Build the Bootable Image

Use the cloud image method (most reliable):

```bash
chmod +x build-from-cloud-image.sh
./build-from-cloud-image.sh
```

This creates: `centos-stream-9-httpd-custom.qcow2` (~1-2GB)

## Step 3: Verify It's Bootable

```bash
./verify-image.sh
```

You should see:
- ✅ GRUB2 configuration found
- ✅ Kernel found  
- ✅ Initramfs found
- ✅ Web page found

## Step 4: Upload to OpenShift via UI

### Using Web Console:

1. Go to **Virtualization** → **Catalog**
2. Click **Add volume**
3. Choose:
   - **Source**: Upload local file
   - **File**: Select `centos-stream-9-httpd-custom.qcow2`
   - **PVC name**: `centos-stream-9-httpd`
   - **Storage class**: Choose your storage class (e.g., `ocs-storagecluster-ceph-rbd`)
   - **Size**: 30 GiB
4. Click **Upload**
5. Wait for upload to complete

### Using virtctl (Alternative):

```bash
virtctl image-upload pvc centos-stream-9-httpd \
  --size=30Gi \
  --image-path=centos-stream-9-httpd-custom.qcow2 \
  --storage-class=ocs-storagecluster-ceph-rbd \
  --access-mode=ReadWriteMany \
  --insecure
```

## Step 5: Create VM from the Uploaded Volume

### Via Web Console:

1. Go to **Virtualization** → **VirtualMachines**
2. Click **Create** → **From template** or **From YAML**
3. Use the uploaded PVC as the boot disk

### Via YAML:

```bash
kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: centos-httpd-vm
  namespace: default
spec:
  running: true
  template:
    metadata:
      labels:
        kubevirt.io/vm: centos-httpd-vm
    spec:
      domain:
        devices:
          disks:
            - name: rootdisk
              disk:
                bus: virtio
          interfaces:
            - name: default
              masquerade: {}
        resources:
          requests:
            memory: 2Gi
            cpu: 2
      networks:
        - name: default
          pod: {}
      volumes:
        - name: rootdisk
          persistentVolumeClaim:
            claimName: centos-stream-9-httpd
EOF
```

## Step 6: Access the Web Server

### Create a Service and Route:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: centos-httpd-vm
  namespace: default
spec:
  selector:
    kubevirt.io/vm: centos-httpd-vm
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: centos-httpd-vm
  namespace: default
spec:
  to:
    kind: Service
    name: centos-httpd-vm
  port:
    targetPort: http
  tls:
    termination: edge
EOF
```

### Get the URL:

```bash
echo "http://$(oc get route centos-httpd-vm -o jsonpath='{.spec.host}')"
```

Open in browser to see the Red Hat logo!

## Login Credentials

- **User**: `root`
- **Password**: `redhat`

## Access VM Console

```bash
virtctl console centos-httpd-vm
```

## Troubleshooting

### VM Won't Boot
- Run `./verify-image.sh` to check bootloader
- Check VM events: `oc describe vmi centos-httpd-vm`

### Can't Access Web Page
- Check if httpd is running: `virtctl console centos-httpd-vm` then `systemctl status httpd`
- Check if firewall is configured: `firewall-cmd --list-services`

### Upload Failed
- Check storage class has enough space
- Try using `virtctl image-upload` instead of web console
- Check CDI pod logs: `oc logs -n openshift-cnv -l app=containerized-data-importer`

---

**That's it!** No container registry, no DataSource, no complicated setup. Just:
1. Build qcow2
2. Upload via UI
3. Create VM
4. Access web server
