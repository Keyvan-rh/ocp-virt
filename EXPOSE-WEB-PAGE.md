# How to Expose the httpd Web Page

After you've uploaded your image and created a VM, here's how to access the web page from your laptop.

## Step 1: Make Sure Your VM is Running

```bash
# Check VM status
oc get vm

# If not running, start it
oc start vm <your-vm-name>

# Check VMI (Virtual Machine Instance) is ready
oc get vmi
```

## Step 2: Create Service and Route

### Method 1: Use the Template File (Recommended)

Edit the template file with your VM name:

```bash
# Get your VM name
oc get vm

# Edit the template
vi httpd-service-route.yaml
# Change: vm.kubevirt.io/name: YOUR-VM-NAME
# To:     vm.kubevirt.io/name: <your-actual-vm-name>

# Apply it
oc apply -f httpd-service-route.yaml
```

### Method 2: One-Liner (Replace YOUR-VM-NAME)

```bash
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: httpd-vm-service
spec:
  selector:
    vm.kubevirt.io/name: YOUR-VM-NAME
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: httpd-vm-route
spec:
  to:
    kind: Service
    name: httpd-vm-service
  port:
    targetPort: http
  tls:
    termination: edge
EOF
```

**IMPORTANT:** The selector must be `vm.kubevirt.io/name: YOUR-VM-NAME` (not `kubevirt.io/vm`)

## Step 4: Get the URL and Access from Your Laptop

```bash
# Get the route URL
oc get route httpd-vm-route -o jsonpath='{.spec.host}'

# Or print it nicely
echo "https://$(oc get route httpd-vm-route -o jsonpath='{.spec.host}')"
```

Copy the URL and open it in your laptop browser - you should see your web page with the Red Hat logo!


## Troubleshooting

### Can't Access the URL

1. **Check if httpd is running inside the VM:**
   ```bash
   virtctl console YOUR-VM-NAME
   # Login with root/redhat
   systemctl status httpd
   ```

2. **Check if firewall allows http:**
   ```bash
   # Inside the VM console
   firewall-cmd --list-services
   # Should show: http https
   
   # If not, add it:
   firewall-cmd --permanent --add-service=http
   firewall-cmd --reload
   systemctl restart httpd
   ```

3. **Check the route exists:**
   ```bash
   oc get route
   oc describe route httpd-vm-route
   ```

4. **Check the service has endpoints:**
   ```bash
   oc get endpoints httpd-vm-service
   # Should show the pod IP and port 80
   ```

5. **Test from inside the cluster:**
   ```bash
   # From another pod or use oc debug
   oc run test --image=registry.access.redhat.com/ubi9/ubi-minimal --rm -it -- curl http://httpd-vm-service
   ```

### 503 Service Unavailable

- VM is not running yet
- httpd service is not started
- Firewall is blocking port 80

### Connection Timeout

- Check the VM labels: `oc get vmi YOUR-VM-NAME --show-labels`
- The VM should have label: `vm.kubevirt.io/name=YOUR-VM-NAME`
- Verify the Service selector matches: `oc get service httpd-vm-service -o yaml | grep -A3 selector`
- Check endpoints exist: `oc get endpoints httpd-vm-service`

### Red Hat Logo Not Showing

- Logo file wasn't added to the image (that's OK, page will still show)
- Or check `/var/www/html/` inside the VM has the logo file
