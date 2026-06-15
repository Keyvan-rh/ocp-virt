# Repository Cleanup Plan

## Current State
We have multiple build methods and debugging scripts. Now that we know what works, let's simplify.

## What to KEEP (Essential Files)

### Primary Build Method
- ✅ **build-from-cloud-image.sh** - MAIN build script (uses official cloud image)
- ✅ **verify-image.sh** - Verify bootability
- ✅ **create-logo.sh** - Get/create Red Hat logo

### Documentation
- ✅ **README.md** - Main documentation
- ✅ **SIMPLE-GUIDE.md** - Quick start guide
- ✅ **EXPOSE-WEB-PAGE.md** - How to expose httpd externally
- ✅ **.gitignore** - Ignore qcow2, temp files

### Cloud-init & Manifests (Optional - for DataSource workflow)
- ✅ **cloud-init-userdata.yaml** - Reference cloud-init config
- ✅ **openshift-manifests/** - For container registry workflow (optional)

### Container Build (Optional - if using registry instead of direct upload)
- ⚠️ **Dockerfile** - Only needed if using container registry
- ⚠️ **build-container.sh** - Only needed if using container registry  
- ⚠️ **push-image.sh** - Only needed if using container registry

## What to REMOVE (Debugging/Alternative Methods)

### Alternative Build Scripts (No longer needed)
- ❌ **build-custom-rhel9.sh** - virt-builder method (had issues)
- ❌ **build-custom-rhel9-v2.sh** - Debug version (no longer needed)
- ❌ **build-simple.sh** - Debug version (no longer needed)

### Debug Scripts (Only needed during troubleshooting)
- ❌ **debug-base-image.sh** - Only needed for troubleshooting
- ❌ **check-prereqs.sh** - Can keep or remove
- ❌ **TROUBLESHOOTING-STEPS.md** - Move to README troubleshooting section

### Duplicate Scripts
- ❌ **download-logo.sh** - Replaced by create-logo.sh

## Proposed Final Structure

```
ocp-virt/
├── README.md                          # Main documentation
├── SIMPLE-GUIDE.md                   # Quick start
├── EXPOSE-WEB-PAGE.md                # How to expose web page
├── .gitignore
│
├── build-from-cloud-image.sh         # MAIN BUILD SCRIPT
├── verify-image.sh                   # Verify bootability
├── create-logo.sh                    # Get/create logo (optional)
│
├── cloud-init-userdata.yaml          # Reference (optional)
│
└── openshift-manifests/              # Optional: for registry workflow
    ├── datasource.yaml
    ├── test-vm.yaml
    └── service.yaml
```

## Optional: Container Registry Workflow
If you want to keep the container registry workflow as an alternative:

```
├── Dockerfile                        # Container disk image
├── build-container.sh                # Build container
└── push-image.sh                     # Push to registry
```

## Decision Points

### Minimal Setup (Direct Upload Only)
**Remove:**
- All alternative build scripts
- All debug scripts  
- Container/registry scripts (Dockerfile, build-container.sh, push-image.sh)
- openshift-manifests/ directory

**Keep only:**
- README.md, SIMPLE-GUIDE.md, EXPOSE-WEB-PAGE.md
- build-from-cloud-image.sh, verify-image.sh, create-logo.sh
- .gitignore

### Full Setup (Both Upload Methods)
**Remove:**
- Alternative build scripts (build-custom-rhel9*.sh, build-simple.sh)
- Debug scripts (debug-base-image.sh)
- TROUBLESHOOTING-STEPS.md (merge into README)
- download-logo.sh (duplicate)

**Keep:**
- Everything in Minimal setup
- Plus: Dockerfile, build-container.sh, push-image.sh, openshift-manifests/

## Which do you prefer?

1. **Minimal** - Just direct upload (simplest)
2. **Full** - Both direct upload and container registry options
