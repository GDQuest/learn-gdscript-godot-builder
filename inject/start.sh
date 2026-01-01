#!/bin/bash

cd /emsdk
source ./emsdk_env.sh

cd /godot

rm -rf ./bin

echo "Compiling headless"

scons p=server target=release_debug lto=full tools=yes
strip bin/godot_server.x11.opt.tools.64
chmod +x bin/godot_server.x11.opt.tools.64

echo "Compiling linux editor"

scons p=x11 target=release_debug lto=full tools=yes
strip bin/godot.x11.opt.tools.64
chmod +x bin/godot.x11.opt.tools.64

echo "Compiling linux release template"

scons p=x11 target=release optimize=speed disable_3d=true lto=full tools=no
strip bin/godot.x11.opt.64
chmod +x bin/godot.x11.opt.64

echo "Patching os_windows.cpp"

# fedora:32's mingw doesn't have this constant defined
sed -i '55 i\\n#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING\n  #define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004\n#endif' platform/windows/os_windows.cpp

echo "Compiling windows release template"

scons p=windows target=release optimize=speed disable_3d=true lto=full tools=no bits=64
strip bin/godot.windows.opt.64.exe

echo "Patching osx detect.py for modern OSXCross if needed"

# modern osxcross omits the /target prefix
sed -i 's@basecmd = root + "/target/bin/@basecmd = root + "/bin/@g' platform/osx/detect.py

echo "Compiling arm64 OSX template"

scons p=osx osxcross_sdk=darwin${OSXCROSS_SDK_VERSION} target=release optimize=speed disable_3d=true tools=no arch=arm64
x86_64-apple-darwin${OSXCROSS_SDK_VERSION}-strip -u -r bin/godot.osx.opt.arm64

echo "Compiling x86_64 OSX template"

scons p=osx osxcross_sdk=darwin${OSXCROSS_SDK_VERSION} target=release optimize=speed disable_3d=true tools=no arch=x86_64
x86_64-apple-darwin${OSXCROSS_SDK_VERSION}-strip -u -r bin/godot.osx.opt.x86_64

echo "Combining into universal OSX template"

lipo -create bin/godot.osx.opt.arm64 bin/godot.osx.opt.x86_64 -output bin/godot.osx.opt.universal

echo "Building universal bundle"

cp -r misc/dist/osx_template.app bin/osx_template.app
mkdir -p bin/osx_template.app/Contents/MacOS
cp bin/godot.osx.opt.universal bin/osx_template.app/Contents/MacOS/godot_osx_release.64
cp bin/godot.osx.opt.universal bin/osx_template.app/Contents/MacOS/godot_osx_debug.64
chmod +x osx_template.app/Contents/MacOS/godot_osx*
zip -q -9 -r bin/osx_template.zip bin/osx_template.app

echo "Building web export"

EMSDK_PYTHON=/usr/bin/python3.10 scons p=javascript target=release optimize=speed disable_3d=true tools=no

echo "Packing result"

GODOT_VERSION=$(/usr/bin/python3.10 -c "import pathlib; ns={}; exec(pathlib.Path('version.py').read_text(), ns); print(f\"{ns['major']}.{ns['minor']}.{ns['patch']}\")")

zip -j /output/godot-learn.${GODOT_VERSION}.templates.zip bin/godot.windows.opt.64.exe bin/godot.javascript.opt.zip bin/godot.x11.opt.64 bin/osx_template.zip
zip -j /output/godot-learn.${GODOT_VERSION}.headless.zip bin/godot_server.x11.opt.tools.64
zip -j /output/godot-learn.${GODOT_VERSION}.editor.zip bin/godot.x11.opt.tools.64

echo "Done compiling. Archived into /output"
