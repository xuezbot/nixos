# Build the Docker image
docker build -t nixos-vma-builder .

# Run the container
# Mounts the current directory to /app in the container
docker run --rm --privileged -v ${PWD}:/app nixos-vma-builder
