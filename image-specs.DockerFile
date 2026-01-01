FROM fedora:32 AS builder

ENV PATH="${PATH}:/osxcross/bin" \
  OSXCROSS_ROOT=/osxcross \
  OSXCROSS_SDK_ROOT=/osxcross/SDK/MacOSX${OSX_SDK_VERSION}.sdk

COPY bootstrap.sh bootstrap.sh
COPY MacOSX${OSX_SDK_VERSION}.sdk.tar.xz MacOSX${OSX_SDK_VERSION}.sdk.tar.xz

RUN dnf install -y \
  # osxcross deps
  openssl-devel make xz-devel libxml2-devel patch cpio git bzip2 \
  bzip2-libs zlib-devel bzip2-devel xz findutils git \

  # godot deps
  scons pkgconfig libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel \
  libXi-devel mesa-libGL-devel mesa-libGLU-devel alsa-lib-devel pulseaudio-libs-devel \
  libudev-devel yasm gcc-c++ libstdc++-static libatomic-static zip unzip git \

  # windows deps
  mingw64-gcc-c++ mingw64-winpthreads-static mingw32-gcc-c++ mingw32-winpthreads-static \

  # emsdk
  python3.10 && \

  # Fedora:32's cmake is too old, so we'll build it ourselves
  curl -OL https://github.com/Kitware/CMake/releases/download/v3.31.10/cmake-3.31.10.tar.gz && \
  tar -xzf cmake-3.31.10.tar.gz && cd cmake-3.31.10 && \
  ./bootstrap && make -j$(nproc) && make install && cd / && \
  rm -rf cmake-3.31.10 && rm -f cmake-3.31.10.tar.gz && \

  # clone OSX Cross
  git clone --depth=1 https://github.com/tpoechtrager/osxcross.git "osxcross-src" && \
  # package
  mv MacOSX${OSX_SDK_VERSION}.sdk.tar.xz osxcross-src/tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz && \
  # build. Fedora:32's clang is too old, so we'll build it ourselves.
  cd osxcross-src && UNATTENDED=1 ./build_clang.sh && cd /osxcross-src/build/clang-20.1.8/build_stage2 && \
  # build OSXCross
  make install && cd /osxcross-src && TARGET_DIR="/osxcross" UNATTENDED=1 ./build.sh && ./build_compiler_rt.sh && \

  cd / && rm -rf osxcross-src && \

  # emscripten
  git clone --depth=1 https://github.com/emscripten-core/emsdk.git && cd emsdk && \
  git pull && rm -rf .git && ./emsdk install latest && ./emsdk activate latest && \

  cd / && mkdir output && chmod +x bootstrap.sh

CMD ["/bootstrap.sh"]
