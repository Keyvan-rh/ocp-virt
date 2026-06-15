#!/bin/bash

# Cleanup script for minimal setup (direct upload workflow only)

echo "========================================="
echo "Cleaning up repository for minimal setup"
echo "========================================="
echo ""
echo "This will remove:"
echo "  - Alternative build scripts"
echo "  - Debug scripts"
echo "  - Container registry workflow files"
echo "  - OpenShift manifests directory"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo ""
echo "Removing files..."

# Alternative build scripts
rm -f build-custom-rhel9.sh
rm -f build-custom-rhel9-v2.sh
rm -f build-simple.sh
echo "✅ Removed alternative build scripts"

# Debug scripts
rm -f debug-base-image.sh
rm -f check-prereqs.sh
echo "✅ Removed debug scripts"

# Container/registry workflow
rm -f Dockerfile
rm -f build-container.sh
rm -f push-image.sh
echo "✅ Removed container registry workflow files"

# Duplicate/unnecessary files
rm -f download-logo.sh
rm -f cloud-init-userdata.yaml
rm -f TROUBLESHOOTING-STEPS.md
rm -f CLEANUP-PLAN.md
echo "✅ Removed duplicate/unnecessary files"

# OpenShift manifests directory
rm -rf openshift-manifests/
echo "✅ Removed openshift-manifests directory"

echo ""
echo "========================================="
echo "Files remaining:"
echo "========================================="
ls -1 *.sh *.md 2>/dev/null | grep -v cleanup-minimal.sh

echo ""
echo "========================================="
echo "Cleanup complete!"
echo "========================================="
echo ""
echo "Your repository now contains only:"
echo "  📄 Documentation: README.md, SIMPLE-GUIDE.md, EXPOSE-WEB-PAGE.md"
echo "  🔧 Build: build-from-cloud-image.sh"
echo "  ✓ Verify: verify-image.sh"
echo "  🎨 Logo: create-logo.sh"
echo "  🚫 Ignore: .gitignore"
echo ""
echo "Next steps:"
echo "  1. git add -A"
echo "  2. git commit -m 'Cleanup: Keep only essential files for direct upload workflow'"
echo "  3. git push"
echo ""
echo "You can now delete this cleanup script:"
echo "  rm cleanup-minimal.sh"
