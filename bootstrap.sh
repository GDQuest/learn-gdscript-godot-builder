#!/bin/bash

cp /inject/start.sh /start.sh
git clone -b ${GODOT_BRANCH} --depth=1 --single-branch https://github.com/${GODOT_REPO}.git
cp /inject/custom.py /godot/custom.py
chmod +x /start.sh
./start.sh
