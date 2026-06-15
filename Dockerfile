FROM scratch

# Add the custom RHEL 9 qcow2 image
ADD rhel9-httpd-custom.qcow2 /disk/

# Labels for OpenShift Virtualization
LABEL name="rhel9-httpd-custom" \
      version="1.0" \
      description="Custom RHEL 9 with Apache httpd" \
      io.kubevirt.os="rhel-9" \
      io.kubevirt.flavor="server"
