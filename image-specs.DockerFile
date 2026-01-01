FROM fedora:43

ENV GODOT_SDK_LINUX_X86_64=/x86_64-godot-linux-gnu_sdk-buildroot \
  PATH="/osxcross/bin:${PATH}" \
  BASE_PATH=${PATH} \
  OSXCROSS_ROOT=/osxcross \
  OSXCROSS_SDK_ROOT=/osxcross/SDK/MacOSX${OSX_SDK_VERSION}.sdk

COPY bootstrap.sh bootstrap.sh
COPY MacOSX${OSX_SDK_VERSION}.sdk.tar.xz MacOSX${OSX_SDK_VERSION}.sdk.tar.xz

RUN dnf install -y --setopt=install_weak_deps=False \
  # base
  bash binutils bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz \

  # windows
  mingw32-gcc mingw32-gcc-c++ mingw32-winpthreads-static mingw64-gcc mingw64-gcc-c++ mingw64-winpthreads-static \

  # osxcross
  automake autoconf bzip2-devel cmake gcc gcc-c++ libdispatch libicu-devel libtool \
  libxml2-devel openssl-devel uuid-devel yasm \

  # web
  libatomic && \

  pip install scons==4.10.0 && \

  # linux build root
  curl -LO https://github.com/godotengine/buildroot/releases/download/godot-2023.08.x-4/x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  tar xf x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  rm -f x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
  cd x86_64-godot-linux-gnu_sdk-buildroot && \
  ./relocate-sdk.sh && \
  cd .. && \

  # clone OSX Cross
  git clone --depth=1 https://github.com/tpoechtrager/osxcross.git "osxcross-src" && \
  # package
  mv MacOSX${OSX_SDK_VERSION}.sdk.tar.xz osxcross-src/tarballs/MacOSX${OSX_SDK_VERSION}.sdk.tar.xz && \
  # build OSXCross and apple clang
  cd /osxcross-src && UNATTENDED=1 ENABLE_CLANG_INSTALL=1 INSTALLPREFIX=/usr ./build_apple_clang.sh && \
  TARGET_DIR="/osxcross" UNATTENDED=1 ./build.sh && ./build_compiler_rt.sh && \
  cd / && rm -rf osxcross-src && \

  # emscripten
  git clone --depth=1 https://github.com/emscripten-core/emsdk.git && cd emsdk && \
  git pull && rm -rf .git && ./emsdk install latest && ./emsdk activate latest && \

  cd / && mkdir output && chmod +x bootstrap.sh

CMD ["/bootstrap.sh"]
