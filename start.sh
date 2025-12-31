#!/bin/bash

cd /emsdk
source ./emsdk_env.sh
cd /
git clone -b ${GODOT_BRANCH} --depth=1 --single-branch https://github.com/${GODOT_REPO}.git
cd godot
chmod +x ${BUILD_SCRIPT}
source ./${BUILD_SCRIPT}
