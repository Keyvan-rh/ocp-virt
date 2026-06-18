# Setup Boot Source for Template

For the template to appear in the catalog when creating VMs, you need a **DataSource** in the `openshift-virtualization-os-images` namespace.

## Prerequisites

You should have already uploaded your `centos-stream-9-httpd-custom.qcow2` as a PVC.

## Step 1: Verify Your PVC Exists

```bash
# Check if your uploaded PVC exists
oc get pvc centos-web -n openshift-virtualization-os-images

# If it's in a different namespace, note the namespace and name
oc get pvc | grep centos
```

## Step 2: Create the DataSource

### Option A: If PVC is in openshift-virtualization-os-images namespace

```bash
# Apply the DataSource
oc apply -f centos-web-datasource.yaml

# Verify
oc get datasource centos-web -n openshift-virtualization-os-images
```

### Option B: If PVC is in a different namespace

Edit `centos-web-datasource.yaml` and update the PVC reference:

```yaml
spec:
  source:
    pvc:
      name: YOUR-PVC-NAME           # Change this
      namespace: YOUR-NAMESPACE      # Change this
```

Then apply:
```bash
oc apply -f centos-web-datasource.yaml
```

## Step 3: Install the Template

```bash
oc apply -f centos-web-template.yaml
```

## Step 4: Verify Template Shows in Catalog

### Via Web Console:
1. Go to **Virtualization** → **Catalog**
2. Look for **"CentOS Stream 9 Web Server"**
3. It should show with a boot source available

### Via CLI:
```bash
# Check template exists
oc get template centos-web-server -n openshift

# Check boot source is available
oc get datasource centos-web -n openshift-virtualization-os-images
```

## Troubleshooting

### Template doesn't show in catalog

**Check 1: DataSource exists and is ready**
```bash
oc get datasource centos-web -n openshift-virtualization-os-images
# Should show: Ready = True
```

**Check 2: Template references correct DataSource**
```bash
oc get template centos-web-server -n openshift -o yaml | grep -A5 sourceRef
# Should show:
#   sourceRef:
#     kind: DataSource
#     name: centos-web
#     namespace: openshift-virtualization-os-images
```

**Check 3: PVC exists**
```bash
oc get pvc -n openshift-virtualization-os-images | grep centos-web
```

### DataSource shows as not ready

```bash
# Check DataSource status
oc describe datasource centos-web -n openshift-virtualization-os-images

# Check if source PVC exists
oc get pvc centos-web -n openshift-virtualization-os-images
```

### Create DataSource from PVC in Different Namespace

If your PVC is in a different namespace (e.g., `default`), you have two options:

**Option 1: Move PVC to openshift-virtualization-os-images**

This is complex - easier to create a DataSource that references it.

**Option 2: Create DataSource pointing to PVC in original namespace**

```yaml
apiVersion: cdi.kubevirt.io/v1beta1
kind: DataSource
metadata:
  name: centos-web
  namespace: openshift-virtualization-os-images
spec:
  source:
    pvc:
      name: centos-web
      namespace: default  # Your original namespace
```

## Complete Setup Example

```bash
# 1. Upload image via UI or virtctl
virtctl image-upload pvc centos-web \
  --size=30Gi \
  --image-path=centos-stream-9-httpd-custom.qcow2 \
  --storage-class=ocs-storagecluster-ceph-rbd \
  --namespace=openshift-virtualization-os-images \
  --insecure

# 2. Create DataSource
oc apply -f centos-web-datasource.yaml

# 3. Wait for DataSource to be ready
oc wait --for=condition=Ready datasource/centos-web -n openshift-virtualization-os-images --timeout=5m

# 4. Install Template
oc apply -f centos-web-template.yaml

# 5. Check in Web Console
# Go to Virtualization → Catalog
# You should see "CentOS Stream 9 Web Server" with boot source available
```

## Alternative: Use Existing PVC Name

If you already uploaded with a different name, update the DataSource:

```bash
# Find your PVC
oc get pvc -A | grep centos

# Edit centos-web-datasource.yaml with the correct name/namespace
# Then apply
oc apply -f centos-web-datasource.yaml
```

## Status Check Script

```bash
#!/bin/bash
echo "Checking boot source setup..."
echo ""
echo "1. PVC Status:"
oc get pvc centos-web -n openshift-virtualization-os-images
echo ""
echo "2. DataSource Status:"
oc get datasource centos-web -n openshift-virtualization-os-images
echo ""
echo "3. Template Status:"
oc get template centos-web-server -n openshift
echo ""
echo "If all three exist, the template should be visible in the catalog."
```
