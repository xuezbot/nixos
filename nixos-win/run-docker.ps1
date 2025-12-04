# Build the Docker image
docker build -t nixos-vma-builder .

# Run the container
# Mounts the repo root (..) to /app in the container
# Mounts the current directory (.) to /output in the container
# Sets OUTPUT_DIR env var to /output
$repoRoot = Resolve-Path ".."
$currentDir = Get-Location

Write-Host "Repo Root: $repoRoot"
Write-Host "Output Dir: $currentDir"

docker run --rm --privileged -v "${repoRoot}:/app" -v "${currentDir}:/output" -e OUTPUT_DIR=/output nixos-vma-builder
