# Custom Godot builder for Learn GDScript

This repository has scripts to build a custom version of the Godot engine's templates, editor, and headless editor for [Learn GDScript From Zero](https://github.com/GDQuest/learn-gdscript/).

At the time of writing the repository is set up for Godot 3 builds and has not been tested for Godot 4.

## Configuration

All configuration is done by editing the `.env` file.

- `DOCKER_USERNAME`: The username for docker.io where the builder image is stored.
- `DOCKER_BUILDER_VERSION`: The version of the builder image to use when building godot.
- `DOCKER_PUSH`: true|false; when running build-image.sh, whether to push the new image to docker.io or only keep it in local storage.
- `OSX_SDK_VERSION`: When running build-image.sh, will try to grab this SDK at the root of this repository.
- `OSXCROSS_SDK_VERSION`: When running build-image.sh, will provide this version to scons to append to clang tools
- `GODOT_REPO`: The repository to grab the Godot source from.
- `GODOT_BRANCH`: The branch to grab the Godot source from.
- `PUBLISH_REPO`: The repository that the release will end up in when running publish-release.sh.

## Scripts

### build-image.sh

This is a all-in-one image that can compile a custom godot 3.x repository using a container image.

#### Requirements

- `podman`
- A `MacOSX--.-.sdk.tar.xz` file should be added to the local repository. This is extracted from either XCode or XCode Command Line Tools. See the OSXCross repository for details on how to get this.

#### Technical Details

Based on Fedora 43, while building the image, it installs on itself:

- Dependency libraries for building Godot on Linux. These are built by the godot developers to use glibc 2.28 for maximum compatibility
- MinGW64 to build Windows template
- Builds Apple clang and OSXCross to build the MacOS template
- EmScripten to build the Javascript template

Everything is in one image, which is heavy. We use this because we very rarely have to rebuild a godot-building image or to build a new version of Godot.

An image is already available at `docker.io/razoric480/godot-learn-builder:1.0.0`

### build-godot.sh

This uses the previously built image by build-image to actually compile Godot, outputting the artefacts into `build-output/`.

#### Requirements

- `podman`

#### Technical Details

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

#### Requirements

- `gh`
- `gh auth status` to show you to be logged in
- Permission on your github account to make releases on the target repo noted in .env

#### Technical Details

Uses the github CLI (gh) to remove any previous version using the same tag, makes a new release, and uploads the files produced by build-godot.sh, using the publish repository deifned in the `.env` file.

Once published, the editor, headless and template URLs can be fed into other build systems, namely `registry.gitlab.com/greenfox/godot-build-automation:latest` (see [this guide](https://gitlab.com/greenfox/godot-build-automation/-/blob/master/advanced_topics.md#using-a-custom-build-of-godot)).
