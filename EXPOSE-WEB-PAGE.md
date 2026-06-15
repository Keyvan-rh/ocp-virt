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

## Step 2: Create a Service to Expose Port 80

Create a file `httpd-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: httpd-vm-service
  namespace: default  # Change to your namespace
spec:
  selector:
    kubevirt.io/vm: YOUR-VM-NAME  # Change to your actual VM name
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

Apply it:
```bash
oc apply -f httpd-service.yaml
```

## Step 3: Create a Route to Expose Externally

Create a file `httpd-route.yaml`:

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: httpd-vm-route
  namespace: default  # Change to your namespace
spec:
  to:
    kind: Service
    name: httpd-vm-service
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

Apply it:
```bash
oc apply -f httpd-route.yaml
```

## Step 4: Get the URL and Access from Your Laptop

```bash
# Get the route URL
oc get route httpd-vm-route -o jsonpath='{.spec.host}'

# Or print it nicely
echo "https://$(oc get route httpd-vm-route -o jsonpath='{.spec.host}')"
```

Copy the URL and open it in your laptop browser - you should see your web page with the Red Hat logo!

## Quick One-Liner (All in One)

```bash
# Create service and route in one command
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Service
metadata:
  name: httpd-vm-service
spec:
  selector:
    kubevirt.io/vm: YOUR-VM-NAME
  ports:
    - name: http
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

# Get the URL
echo "https://$(oc get route httpd-vm-route -o jsonpath='{.spec.host}')"
```

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

- Check if the VM has the correct label (`kubevirt.io/vm: YOUR-VM-NAME`)
- Verify the Service selector matches the VM label

### Red Hat Logo Not Showing

- Logo file wasn't added to the image (that's OK, page will still show)
- Or check `/var/www/html/` inside the VM has the logo file
