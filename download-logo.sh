#!/bin/bash

# Download a Red Hat logo for the web page

echo "Downloading Red Hat logo..."

# Try multiple sources
if curl -L -o redhat-logo.png "https://www.redhat.com/rhdc/managed-files/styles/wysiwyg_full_width/private/Logo-redhat-color-375.png" 2>/dev/null; then
    echo "✅ Downloaded from redhat.com"
elif curl -L -o redhat-logo.png "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Red_Hat_logo.svg/1200px-Red_Hat_logo.svg.png" 2>/dev/null; then
    echo "✅ Downloaded from Wikimedia"
else
    echo "⚠️  Could not download automatically."
    echo ""
    echo "Please download a Red Hat logo manually and save as 'redhat-logo.png'"
    echo ""
    echo "Suggestions:"
    echo "1. Visit: https://www.redhat.com/en/about/brand/standards/logo"
    echo "2. Or search: 'Red Hat logo PNG' and download"
    echo "3. Save the file as: redhat-logo.png"
    exit 1
fi

# Verify it's an image
if file redhat-logo.png | grep -q image; then
    echo "✅ Verified: redhat-logo.png is an image file"
    ls -lh redhat-logo.png
else
    echo "❌ Error: Downloaded file is not a valid image"
    rm -f redhat-logo.png
    exit 1
fi

echo ""
echo "Ready to build! Run: ./build-from-cloud-image.sh"
