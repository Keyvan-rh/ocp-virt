#!/bin/bash

# Create a simple Red Hat inspired logo using ImageMagick
# Or provide instructions for manual download

echo "========================================="
echo "Creating Red Hat Logo"
echo "========================================="
echo ""

# Option 1: Try to create with ImageMagick
if command -v convert &> /dev/null; then
    echo "Creating logo with ImageMagick..."

    # Create a simple Red Hat colored box with text
    convert -size 400x200 xc:black \
            -fill '#EE0000' -draw "rectangle 50,50 350,150" \
            -fill white -pointsize 36 -gravity center \
            -annotate +0+0 "Red Hat" \
            redhat-logo.png

    if [ -f "redhat-logo.png" ]; then
        echo "✅ Created redhat-logo.png"
        ls -lh redhat-logo.png
        echo ""
        echo "Ready to build! Run: ./build-from-cloud-image.sh"
        exit 0
    fi
fi

# Option 2: Use curl to download from a working source
echo "Attempting to download from GitHub (commons images)..."
if curl -L -o redhat-logo.png "https://raw.githubusercontent.com/RedHatOfficial/RedHatFont/master/images/RedHat-Logo.png" 2>/dev/null && [ -f "redhat-logo.png" ] && file redhat-logo.png | grep -q -i "image\|png"; then
    echo "✅ Downloaded redhat-logo.png from GitHub"
    ls -lh redhat-logo.png
    echo ""
    echo "Ready to build! Run: ./build-from-cloud-image.sh"
    exit 0
fi

# Option 3: Manual instructions
echo ""
echo "========================================="
echo "⚠️  Automatic methods failed"
echo "========================================="
echo ""
echo "Please download a Red Hat logo manually:"
echo ""
echo "Method 1: From Red Hat's official site"
echo "  1. Visit: https://www.redhat.com/en/about/brand/standards/logo"
echo "  2. Download any Red Hat logo PNG"
echo "  3. Save it as: redhat-logo.png"
echo ""
echo "Method 2: Google Images"
echo "  1. Search: 'Red Hat logo PNG transparent'"
echo "  2. Download any official-looking Red Hat logo"
echo "  3. Save it as: redhat-logo.png"
echo ""
echo "Method 3: Use any image you like"
echo "  Just save any PNG image as: redhat-logo.png"
echo ""
echo "Once you have redhat-logo.png, run: ./build-from-cloud-image.sh"
echo ""
