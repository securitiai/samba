# Building Custom smbcacls Docker Image

This directory contains a Dockerfile to build a Docker image with your custom smbcacls binary that includes `--max-depth` support.

## Prerequisites

1. Fork Samba on GitHub and push your changes:
   ```bash
   cd ~/Projects/samba
   git remote add origin https://github.com/securitiai/samba.git
   git checkout -b custom-max-depth
   git add source3/utils/smbcacls.c
   git commit -m "Add --max-depth flag to smbcacls"
   git push origin custom-max-depth
   ```

## Quick Start

### Option 1: Use the build script (easiest)

```bash
cd ~/Projects/samba

# Update the script with your fork URL first:
# Edit build-docker-image.sh and change:
# SAMBA_REPO="${SAMBA_REPO:-https://github.com/securitiai/samba.git}"

# Then build:
./build-docker-image.sh
```

Or pass as environment variables:

```bash
SAMBA_REPO=https://github.com/securitiai/samba.git \
SAMBA_BRANCH=custom-max-depth \
./build-docker-image.sh
```

This creates an image named `smbcacls-custom:latest`.

### Option 2: Build manually

```bash
cd ~/Projects/samba

# Build with your GitHub fork
docker build \
  --build-arg SAMBA_REPO=https://github.com/securitiai/samba.git \
  --build-arg SAMBA_BRANCH=custom-max-depth \
  -t smbcacls-custom:latest \
  .
```

**Note:** The Dockerfile clones from your GitHub fork, so you don't need the local source code - just the Dockerfile itself.

## Using the Image

### Run smbcacls with --max-depth

```bash
# Show help
docker run --rm smbcacls-custom:latest --help

# Test max-depth flag
docker run --rm smbcacls-custom:latest --help | grep max-depth

# Run against a server (example)
docker run --rm smbcacls-custom:latest \
    //server/share /path \
    --numeric \
    --recurse \
    --max-depth=1 \
    --save /tmp/output.txt \
    -U username%password
```

### Extract the binary from the image

```bash
# Copy binary to current directory
docker run --rm smbcacls-custom:latest cat /usr/local/bin/smbcacls > smbcacls
chmod +x smbcacls

# Test it
./smbcacls --help | grep max-depth
```

### Interactive shell

```bash
docker run --rm -it --entrypoint /bin/sh smbcacls-custom:latest

# Inside container:
/usr/local/bin/smbcacls --help
```

## Pushing to a Registry

### Tag and push to Docker Hub

```bash
# Tag for your Docker Hub account
docker tag smbcacls-custom:latest YOUR_USERNAME/smbcacls-custom:latest

# Push
docker push YOUR_USERNAME/smbcacls-custom:latest
```

### Tag and push to private registry

```bash
# Tag for your private registry
docker tag smbcacls-custom:latest registry.yourcompany.com/smbcacls-custom:latest

# Push
docker push registry.yourcompany.com/smbcacls-custom:latest
```

## Using in Other Dockerfiles

### Copy binary from this image

```dockerfile
# In your application's Dockerfile
FROM alpine:3.19

# Copy smbcacls from the custom image
COPY --from=smbcacls-custom:latest /usr/local/bin/smbcacls /usr/bin/smbcacls

# Or pull from a registry
COPY --from=registry.yourcompany.com/smbcacls-custom:latest /usr/local/bin/smbcacls /usr/bin/smbcacls

# Install runtime dependencies
RUN apk add --no-cache gnutls talloc tdb tevent popt iniparser libarchive

# Your app can now use smbcacls with --max-depth
```

## Image Details

### Build stages

1. **Builder stage**: Compiles smbcacls from source with all build dependencies
2. **Final stage**: Small Alpine image with only runtime dependencies + the binary

### Image size

- Builder stage: ~500MB (with all build tools)
- Final image: ~50MB (minimal runtime)

### Binary location in image

- `/usr/local/bin/smbcacls` - The custom smbcacls binary

### Runtime dependencies included

- gnutls
- talloc
- tdb
- tevent
- popt
- iniparser
- libarchive

## Versioning

You can build with different tags:

```bash
# Development build
docker build -f Dockerfile.smbcacls -t smbcacls-custom:dev .

# Version build
docker build -f Dockerfile.smbcacls -t smbcacls-custom:1.0.0 .

# Using environment variables
IMAGE_NAME=my-smbcacls IMAGE_TAG=v1.0 ./build-docker-image.sh
```

## Integration with CI/CD

### Example GitHub Actions

```yaml
name: Build smbcacls Docker Image

on:
  push:
    branches: [custom-max-depth]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Build Docker image
        run: docker build -f Dockerfile.smbcacls -t smbcacls-custom:${{ github.sha }} .

      - name: Test image
        run: |
          docker run --rm smbcacls-custom:${{ github.sha }} --help | grep max-depth

      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker tag smbcacls-custom:${{ github.sha }} your-org/smbcacls-custom:latest
          docker push your-org/smbcacls-custom:latest
```

## Files

- `Dockerfile.smbcacls` - Multi-stage Dockerfile to build the image
- `build-docker-image.sh` - Helper script to build and test
- `DOCKER.md` - This documentation

## Troubleshooting

### Build fails during git clone

Check that:
- Your GitHub fork URL is correct
- The branch name exists in your fork
- The branch contains the modified smbcacls.c

```bash
# Verify your fork and branch exist
curl -I https://github.com/securitiai/samba/tree/custom-max-depth

# Or check with git
git ls-remote https://github.com/securitiai/samba.git custom-max-depth
```

### Build fails with missing dependencies

Check that Alpine packages are available and properly specified in the Dockerfile.

### Build shows "securitiai" in error

Check that:
- The securitiai organization exists on GitHub
- Your fork is named correctly: `https://github.com/securitiai/samba.git`
- The `custom-max-depth` branch exists in your fork

### Binary doesn't work at runtime

Check that runtime dependencies are installed:
```bash
docker run --rm -it --entrypoint /bin/sh smbcacls-custom:latest
# Inside container:
ldd /usr/local/bin/smbcacls
```

### --max-depth flag missing

Verify your changes are in smbcacls.c:
```bash
grep "max-depth" source3/utils/smbcacls.c
```

## Next Steps

After building this image, you can:

1. Use it directly for testing
2. Push it to your registry
3. Reference it in your worker Dockerfile (as shown above)
4. Extract the binary for local testing

See the main README and CUSTOM_SAMBA.md for integration with the access-management worker.
