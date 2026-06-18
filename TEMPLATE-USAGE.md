# OpenShift Virtualization Template Usage

This template creates VMs with your custom `centos-web` boot source from the catalog.

## Install the Template

```bash
# Install template to the openshift namespace (makes it available to all users)
oc apply -f centos-web-template.yaml

# Verify it's installed
oc get template centos-web-server -n openshift
```

## Create VM from Template (Web Console)

1. Navigate to **Virtualization** → **Catalog**
2. Find **"CentOS Stream 9 Web Server"** in the list
3. Click **Customize VirtualMachine**
4. Configure:
   - **Name**: Auto-generated or custom
   - **Storage class**: Select your storage class
   - **Data source name**: `centos-web` (default)
   - **Data source namespace**: `openshift-virtualization-os-images` (default)
5. Click **Create VirtualMachine**

The VM will be created with:
- 4 vCPUs
- 16GB RAM
- 30GB disk
- httpd auto-started

## Create VM from Template (CLI)

### Basic creation with defaults:

```bash
oc process centos-web-server -n openshift | oc apply -f -
```

### Custom VM name:

```bash
oc process centos-web-server -n openshift \
  -p NAME=my-web-server | oc apply -f -
```

### All parameters:

```bash
oc process centos-web-server -n openshift \
  -p NAME=my-web-server \
  -p DATA_SOURCE_NAME=centos-web \
  -p DATA_SOURCE_NAMESPACE=openshift-virtualization-os-images \
  -p STORAGE_CLASS=ocs-storagecluster-ceph-rbd \
  -p CLOUD_USER_PASSWORD=mypassword | oc apply -f -
```

## Template Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `NAME` | VM name | Auto-generated: `centos-web-xxxxxx` |
| `DATA_SOURCE_NAME` | DataSource name | `centos-web` |
| `DATA_SOURCE_NAMESPACE` | DataSource namespace | `openshift-virtualization-os-images` |
| `STORAGE_CLASS` | Storage class for disk | `ocs-storagecluster-ceph-rbd` |
| `CLOUD_USER_PASSWORD` | Cloud-init user password | `redhat` |

## After Creating VM

### Expose the Web Server

```bash
# Get the VM name
VM_NAME=$(oc get vm -l vm.kubevirt.io/template=centos-web-server -o jsonpath='{.items[0].metadata.name}')

# Create Service and Route
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${VM_NAME}-web
spec:
  selector:
    vm.kubevirt.io/name: ${VM_NAME}
  ports:
    - name: http
      port: 80
      targetPort: 80
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: ${VM_NAME}-web
spec:
  to:
    kind: Service
    name: ${VM_NAME}-web
  port:
    targetPort: http
  tls:
    termination: edge
EOF

# Get the URL
echo "https://$(oc get route ${VM_NAME}-web -o jsonpath='{.spec.host}')"
```

## Modify the Template

### Change CPU/Memory defaults:

Edit `centos-web-template.yaml`:

```yaml
domain:
  cpu:
    cores: 8  # Change CPU
  resources:
    requests:
      memory: 32Gi  # Change memory
```

### Make CPU/Memory editable in the UI:

Already configured! Users can customize CPU and memory when creating from the web console.

### Add more parameters:

Add to the `parameters` section:

```yaml
parameters:
  - name: MY_PARAMETER
    description: My custom parameter
    value: default-value
```

Then use it in the template with `${MY_PARAMETER}`.

## Troubleshooting

### Template not showing in catalog

```bash
# Check if template exists
oc get template centos-web-server -n openshift

# Check labels
oc get template centos-web-server -n openshift -o yaml | grep labels -A5
```

### DataSource not found

```bash
# Verify DataSource exists
oc get datasource centos-web -n openshift-virtualization-os-images

# If not, you need to create it or use the PVC directly
```

### Storage class not available

```bash
# List available storage classes
oc get storageclass

# Update template with correct storage class
```

## Create Multiple VMs

```bash
# Create 3 VMs with different names
for i in {1..3}; do
  oc process centos-web-server -n openshift \
    -p NAME=web-server-${i} | oc apply -f -
done
```

## Update the Template

After modifying `centos-web-template.yaml`:

```bash
# Delete old template
oc delete template centos-web-server -n openshift

# Apply updated template
oc apply -f centos-web-template.yaml
```

Or simply re-apply:

```bash
oc apply -f centos-web-template.yaml
```

## Remove the Template

```bash
oc delete template centos-web-server -n openshift
```

This only removes the template, not VMs created from it.
