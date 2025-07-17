#!/bin/bash
# Build the Flutter web app and corresponding Docker image.
set -e

# Build web assets inside a Flutter Docker container
DOCKER_IMAGE="ghcr.io/cirruslabs/flutter:latest"

docker run --rm -v "$(pwd)":/app -w /app $DOCKER_IMAGE flutter build web

# Build the web Docker image with Nginx

docker build -t hanziapp_web -f Dockerfile.web .
