#!/bin/bash
# Build the Flutter web app and corresponding Docker image.
set -e

# Docker image with Flutter SDK
DOCKER_IMAGE="ghcr.io/cirruslabs/flutter:latest"
APP_DIR="$(pwd)"
# Host dir to persist pub cache
PUB_CACHE="${HOME}/.pub-cache"

# 0. Ensure host cache dir exists
mkdir -p "$PUB_CACHE"

# 1–4. In one go: repair cache, clean, get deps, build web
docker run --rm \
  -v "$APP_DIR":/app \
  -v "$PUB_CACHE":/root/.pub-cache \
  -w /app \
  $DOCKER_IMAGE \
  bash -c "
    flutter pub cache repair &&       # Fix any corrupted package in cache
    flutter clean &&                  # Remove old build artifacts
    flutter pub get &&                # Fetch dependencies
    flutter build web                 # Build web assets
  "

# 5. Build final Docker image serving with Nginx
docker build -t hanziapp_web -f Dockerfile.web .

