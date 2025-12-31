#!/bin/bash

source ./.env

if [[ ! -e "MacOSX${OSX_SDK_VERSION}.sdk.tar.xz" ]]; then
  echo "MacOSX${OSX_SDK_VERSION}.sdk.tar.xz not found. See OSXCross repo for packaging instructions or update ./.env version."
  exit 1
fi

podman build -t godot-builder -f image-specs.DockerFile .
podman tag localhost/godot-builder docker.io/${DOCKER_USERNAME}/godot-learn-builder:${DOCKER_BUILDER_VERSION}
if [ "${DOCKER_PUSH}" = "true" ]; then
  podman push docker.io/${DOCKER_USERNAME}/godot-learn-builder:${DOCKER_BUILDER_VERSION}
fi
