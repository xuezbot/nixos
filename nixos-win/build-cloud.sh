#!/bin/sh
set -e

# Default to current directory if not set
OUTPUT_DIR="${OUTPUT_DIR:-.}"

echo "Output directory: $OUTPUT_DIR"

# Build the VMA image
echo "Building NixOS VMA image..."
nix build .#proxmox --print-build-logs

# Handle output
# The 'result' symlink points to the output in /nix/store
if [ -L result ]; then
    TARGET=$(readlink -f result)
    echo "Build successful. Output: $TARGET"
    
    # Find the VMA file
    VMA_FILE=$(find "$TARGET" -name "*.vma.zst" | head -n 1)
    
    if [ -z "$VMA_FILE" ]; then
        echo "Error: No VMA file found in output!"
        exit 1
    fi
    
    echo "Found VMA file: $VMA_FILE"
    
    # Extract NixOS version (Major version)
    # We try to get it from the flake or default to 'unstable'
    VERSION=$(nix eval --raw .#nixosConfigurations.nixos-server.config.system.nixos.release 2>/dev/null || echo "unknown")
    echo "Detected version: $VERSION"
    
    # Construct new filename: vzdump-qemu-100-YYYY_MM_DD-HH_MM_SS.vma.zst
    # Proxmox requires this specific naming convention to recognize the archive info.
    # We use a placeholder VMID (100) and the current timestamp.
    TIMESTAMP=$(date +%Y_%m_%d-%H_%M_%S)
    NEW_NAME="vzdump-qemu-100-${TIMESTAMP}.vma.zst"
    
    echo "Copying to output directory as: $NEW_NAME"
    cp "$VMA_FILE" "$OUTPUT_DIR/$NEW_NAME"
    
    echo "Artifact copied to $OUTPUT_DIR/$NEW_NAME"
else
    echo "Error: 'result' symlink not found."
    exit 1
fi
