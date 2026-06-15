FROM scratch

# Add the custom CentOS Stream 9 qcow2 image
ADD centos-stream-9-httpd-custom.qcow2 /disk/

# Labels for OpenShift Virtualization
LABEL name="centos-stream-9-httpd-custom" \
      version="1.0" \
      description="Custom CentOS Stream 9 with Apache httpd" \
      io.kubevirt.os="centos-stream-9" \
      io.kubevirt.flavor="server"
