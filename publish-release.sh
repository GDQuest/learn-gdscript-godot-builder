#!/bin/bash

source ./.env

curl -OL https://raw.githubusercontent.com/${GODOT_REPO}/refs/heads/${GODOT_BRANCH}/version.py
GODOT_VERSION=$(python3 -c "import pathlib; ns={}; exec(pathlib.Path('version.py').read_text(), ns); print(f\"{ns['major']}.{ns['minor']}.{ns['patch']}\")")
rm -f version.py

if [[ ! -e "./build-output/godot-learn.${GODOT_VERSION}.templates.zip" || ! -e "./build-output/godot-learn.${GODOT_VERSION}.headless.zip" || ! -e "./build-output/godot-learn.${GODOT_VERSION}.editor.zip" ]]; then
  echo "Godot artefacts for version ${GODOT_VERSION} do not exist in build-output - run build-godot.sh or update .env with HEAD version"
  exit 1
fi

if [[ ! "$(command -v gh)" ]]; then
  echo "No github CLI found - install GH"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "GH not authenticated - run gh auth login"
  exit 1
fi

gh release delete "learn-${GODOT_VERSION}" --repo=${PUBLISH_REPO}
gh release create "learn-${GODOT_VERSION}" --repo=${PUBLISH_REPO} --title "Godot Learn ${GODOT_VERSION}" --notes "Automated release of custom Godot templates ${GODOT_VERSION}"
gh release upload "learn-${GODOT_VERSION}" "./build-output/godot-learn.${GODOT_VERSION}.templates.zip#Templates" "./build-output/godot-learn.${GODOT_VERSION}.headless.zip#Headless" "./build-output/godot-learn.${GODOT_VERSION}.editor.zip#Editor" --repo=${PUBLISH_REPO}
