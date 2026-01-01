#!/bin/bash

source ./.env

DOCKER_URI="docker.io/${DOCKER_USERNAME}/godot-learn-builder:${DOCKER_BUILDER_VERSION}"

if ! podman image exists ${DOCKER_URI}; then
  podman pull ${DOCKER_URI}
  if ! podman image exists ${DOCKER_URI}; then
    echo "Failed to pull ${DOCKER_URI}. Run build-image.sh or update .env repository data."
    exit 1
  fi
fi

rm -rf build-output
mkdir build-output
podman run --env-file ./.env --rm -v ./build-output:/output:Z -v ./inject:/inject:Z ${DOCKER_URI}
