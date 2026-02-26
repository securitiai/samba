#!/bin/bash
set -e

# Script to build Docker image with custom smbcacls

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

IMAGE_NAME="${IMAGE_NAME:-smbcacls-custom}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

# GitHub repo settings - CHANGE THESE to your fork
SAMBA_REPO="${SAMBA_REPO:-https://github.com/securitiai/samba.git}"
SAMBA_BRANCH="${SAMBA_BRANCH:-custom-max-depth}"

echo -e "${BLUE}Building Docker image with custom smbcacls...${NC}"
echo -e "${BLUE}Image: ${FULL_IMAGE}${NC}"
echo -e "${BLUE}Repo: ${SAMBA_REPO}${NC}"
echo -e "${BLUE}Branch: ${SAMBA_BRANCH}${NC}"
echo ""

# Build the image
docker build \
  --build-arg SAMBA_REPO="${SAMBA_REPO}" \
  --build-arg SAMBA_BRANCH="${SAMBA_BRANCH}" \
  -t "${FULL_IMAGE}" \
  .

echo ""
echo -e "${GREEN}✓ Build complete!${NC}"
echo ""

# Test the image
echo -e "${BLUE}Testing the image...${NC}"
echo ""

echo -e "${YELLOW}1. Checking --help output:${NC}"
docker run --rm "${FULL_IMAGE}" --help | grep max-depth || {
    echo -e "\033[0;31m✗ --max-depth flag not found in help output${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}✓ Custom smbcacls with --max-depth support is working!${NC}"
echo ""

echo -e "${BLUE}Image details:${NC}"
docker images "${IMAGE_NAME}" | grep "${IMAGE_TAG}"

echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  # Run smbcacls:"
echo "  docker run --rm ${FULL_IMAGE} //server/share /path --help"
echo ""
echo "  # Interactive shell:"
echo "  docker run --rm -it --entrypoint /bin/sh ${FULL_IMAGE}"
echo ""
echo "  # Copy binary out of image:"
echo "  docker run --rm ${FULL_IMAGE} cat /usr/local/bin/smbcacls > smbcacls"
echo "  chmod +x smbcacls"
echo ""
echo -e "${GREEN}Done!${NC}"
