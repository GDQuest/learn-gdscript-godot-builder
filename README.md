# Custom Godot builder for Learn GDScript

This repository serves to build a custom version of the Godot engine's templates, editor and headless editor, provided a functional repository and branch.

This is configured for 3.x builds and has not been tested or vetoed for 4.x build.

## Configuration

All configuration is done by editing the `.env` file.

- `DOCKER_USERNAME`: The username for docker.io where the builder image is stored.
- `DOCKER_BUILDER_VERSION`: The version of the builder image to use when building godot.
- `DOCKER_PUSH`: true|false; when running build-image.sh, whether to push the new image online or keep it in local storage.
- `OSX_SDK_VERSION`: When running build-image.sh, will try to grab this SDK at the root of this repository.
- `OSXCROSS_SDK_VERSION`: When running build-image.sh, will provide this version to scons to append to clang tools
- `GODOT_REPO`: The repository to grab the Godot source from.
- `GODOT_BRANCH`: The branch to grab the Godot source from.
- `PUBLISH_REPO`: The repository that the release will end up in when running publish-release.sh.

## Functions

### build-image.sh

The build system uses a docker image based on Fedora. While building the image, it installs on itself:

- Dependency libraries for building Godot on Linux. These are built by the godot developers to use old versions of glibc for compatibility
- MinGW64 to build Windows template
- Builds apple clang and OSXCross to build the MacOS template
- EmScripten to build the Javascript template

Everything is in one image, which is fairly meaty, but we shouldn't have to rebuild a godot-building image that often, and it's convenient to just build everything in one script.

An image is already available at `docker.io/razoric480/godot-learn-builder:1.0.0`

### build-godot.sh

Pulls the Builder image from docker as defined in `.env`, mounts the build-output/ folder, loads the .env files, clones godot, and copies files from the /inject dir for use in the image; namely a custom.py to control modules and the start.sh script to actually compile with.

As of this writing, the script:

1. Compiles the headless tools, statically linked
1. Compiles the X11 editor, statically linked
1. Compiles the X11 release template, statically linked
1. Compiles the Windows release template
1. Compiles the Arm64 and x86_64 MacOS release templates, lipo's them together, and builds a .app bundle
1. Compiles the Javascript release template
1. ZIPs up the templates together, then the editor and headless separately, and puts everything into build-output/ as godot-learn.VERSION.TYPE.zip

### publish-release.sh

Uses the github CLI (gh) to remove any previous version using the same tag, makes a new release, and uploads the files produced by build-godot.sh

Once published, the headless and template URLs can be fed into other build systems, like, `registry.gitlab.com/greenfox/godot-build-automation:latest` (see [this guide](https://gitlab.com/greenfox/godot-build-automation/-/blob/master/advanced_topics.md#using-a-custom-build-of-godot)).
