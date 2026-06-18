#!/bin/bash

echo "========================================="
echo "Debugging Template Visibility"
echo "========================================="
echo ""

echo "1. Check if template exists:"
echo "----------------------------"
oc get template centos-web-server -n openshift -o name 2>/dev/null || echo "❌ Template NOT found in openshift namespace"
echo ""

echo "2. Check template labels:"
echo "------------------------"
oc get template centos-web-server -n openshift -o jsonpath='{.metadata.labels}' 2>/dev/null | jq '.' || echo "Template not found"
echo ""

echo "3. Check template annotations:"
echo "-----------------------------"
oc get template centos-web-server -n openshift -o jsonpath='{.metadata.annotations}' 2>/dev/null | jq '.' || echo "Template not found"
echo ""

echo "4. Check all templates in openshift namespace:"
echo "----------------------------------------------"
oc get templates -n openshift | head -20
echo ""

echo "5. Compare with working template (if any):"
echo "------------------------------------------"
WORKING_TEMPLATE=$(oc get templates -n openshift -o name | grep -i centos | head -1)
if [ ! -z "$WORKING_TEMPLATE" ]; then
    echo "Found: $WORKING_TEMPLATE"
    echo "Labels:"
    oc get $WORKING_TEMPLATE -n openshift -o jsonpath='{.metadata.labels}' | jq '.'
    echo ""
    echo "Annotations:"
    oc get $WORKING_TEMPLATE -n openshift -o jsonpath='{.metadata.annotations}' | jq '.'
else
    echo "No CentOS templates found to compare"
fi
echo ""

echo "6. Check if DataSource exists:"
echo "-----------------------------"
oc get datasource centos-web -n openshift-virtualization-os-images 2>/dev/null || echo "⚠️  DataSource 'centos-web' NOT found"
echo ""

echo "7. Check common boot sources:"
echo "----------------------------"
oc get datasources -n openshift-virtualization-os-images 2>/dev/null | head -10
echo ""

echo "========================================="
echo "Recommendations:"
echo "========================================="
echo ""
echo "If template exists but not visible:"
echo "1. Template might need specific namespace (usually 'openshift')"
echo "2. Check labels match other templates"
echo "3. DataSource must exist and be available"
echo "4. UI might cache - try refresh or different browser"
echo ""
echo "If DataSource missing:"
echo "1. Upload your image as a PVC first"
echo "2. Create DataSource pointing to the PVC"
echo "3. Or modify template to use PVC directly"
