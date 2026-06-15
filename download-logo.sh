#!/bin/bash

# Create a Red Hat logo SVG for the web page
# Since direct downloads often fail, we'll create an SVG inline

echo "Creating Red Hat logo..."

cat > redhat-logo.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 613 145" width="400">
  <defs>
    <style>.cls-1{fill:#e00;}.cls-2{fill:#fff;}</style>
  </defs>
  <g id="Layer_1" data-name="Layer 1">
    <path class="cls-1" d="M127.47,83.49c12.51,0,30.61-2.58,30.61-17.46a14,14,0,0,0-.31-3.42l-7.45-32.36c-1.72-7.12-3.23-10.35-15.73-16.6C124.89,8.69,103.76.5,97.51.5,91.69.5,90,8,83.06,8c-6.68,0-11.64-5.6-17.89-5.6-6,0-9.91,4.09-12.93,12.5,0,0-8.41,23.72-9.49,27.16A6.43,6.43,0,0,0,42.53,44c0,9.22,36.3,39.45,84.94,39.45M160,72.07c1.73,8.19,1.73,9.05,1.73,10.13,0,14-15.74,21.77-36.43,21.77C78.54,104,37.58,76.6,37.58,58.49a18.45,18.45,0,0,1,1.51-7.33C22.27,52,.5,55,.5,74.22c0,31.48,74.59,70.28,133.65,70.28,45.28,0,56.7-20.48,56.7-36.65,0-12.72-11-27.16-30.83-35.78"/>
    <path class="cls-1" d="M160,72.07c1.73,8.19,1.73,9.05,1.73,10.13,0,14-15.74,21.77-36.43,21.77C78.54,104,37.58,76.6,37.58,58.49a18.45,18.45,0,0,1,1.51-7.33l3.66-9.06A6.43,6.43,0,0,0,42.53,44c0,9.22,36.3,39.45,84.94,39.45,12.51,0,30.61-2.58,30.61-17.46a14,14,0,0,0-.31-3.42Z"/>
  </g>
</svg>
EOF

# Convert SVG to PNG using ImageMagick or rsvg-convert if available
if command -v convert &> /dev/null; then
    echo "Converting SVG to PNG with ImageMagick..."
    convert -background none redhat-logo.svg redhat-logo.png
    rm redhat-logo.svg
    echo "✅ Created redhat-logo.png"
elif command -v rsvg-convert &> /dev/null; then
    echo "Converting SVG to PNG with rsvg-convert..."
    rsvg-convert -w 400 -h 200 redhat-logo.svg -o redhat-logo.png
    rm redhat-logo.svg
    echo "✅ Created redhat-logo.png"
else
    # Just use SVG directly
    mv redhat-logo.svg redhat-logo.png
    echo "✅ Created redhat-logo.png (SVG format - browsers will render it fine)"
    echo "   Note: To convert to PNG, install ImageMagick or rsvg-convert"
fi

# Verify file exists
if [ -f "redhat-logo.png" ]; then
    ls -lh redhat-logo.png
    echo ""
    echo "Ready to build! Run: ./build-from-cloud-image.sh"
else
    echo "❌ Error: Could not create logo file"
    echo ""
    echo "Manual option: Download any Red Hat logo and save as 'redhat-logo.png'"
    echo "1. Search Google Images for 'Red Hat logo PNG'"
    echo "2. Download and save as: redhat-logo.png"
    exit 1
fi

