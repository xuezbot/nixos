#!/bin/sh
set -e

# Copy files to a temporary directory to avoid permission issues with bind mounts
# and to ensure a clean build environment.
BUILD_DIR=$(mktemp -d)
echo "Copying source files to build directory: $BUILD_DIR"
cp -r /app/* "$BUILD_DIR/"
cd "$BUILD_DIR"

# Build the VMA image
echo "Building NixOS VMA image..."
nix build .#proxmox --print-build-logs

# Handle output
# The 'result' symlink points to the output in /nix/store
if [ -L result ]; then
    TARGET=$(readlink -f result)
    echo "Build successful. Output: $TARGET"
    
    # If the result is a directory (common for some formats), copy contents
    if [ -d "$TARGET" ]; then
        echo "Output is a directory. Copying contents..."
        cp -r "$TARGET"/* /app/
    else
        # If it's a file
        echo "Output is a file. Copying..."
        cp "$TARGET" /app/
    fi
    
    # Specifically look for .vma.zst if it's nested
    find "$TARGET" -name "*.vma.zst" -exec cp {} /app/ \; 2>/dev/null || true
    
    echo "Artifacts copied to host directory."
else
    echo "Error: 'result' symlink not found."
    exit 1
fi
