#! /usr/bin/env bash

set -eux

if [ -z "$OPENSSL_BASE_DIR" ]; then
    echo "Missing $OPENSSL_BASE_DIR"
    exit 1
fi

./get-cmake-config.sh
CMAKE_IOS_DIR="$(pwd)/ios-cmake"

LIBGIT2_VERSION="0.28.1"
if [ ! -f "libgit2.tar.gz" ]; then
    curl https://codeload.github.com/libgit2/libgit2/tar.gz/v${LIBGIT2_VERSION} -o libgit2.tar.gz
fi
tar -xvzf libgit2.tar.gz

cd libgit2-${LIBGIT2_VERSION}
LIBGIT2_FULL_PATH=$(pwd)

IOS_LIB_ROOT=$(pwd)/../libs/libgit2
rm -rf "${IOS_LIB_ROOT:?}/*"

for IOS_TARGET_PLATFORM in armv7s arm64 x86_64; do
    echo "Building libgit2 for ${IOS_TARGET_PLATFORM}"
    case "${IOS_TARGET_PLATFORM}" in
    armv7s)
        CMAKE_PLATFORM_NAME="OS"
        ;;
    arm64)
        CMAKE_PLATFORM_NAME="OS64"
        ;;
    x86_64)
        CMAKE_PLATFORM_NAME="SIMULATOR_TVOS"
        ;;
    *)
        echo "Unsupported build platform:${IOS_TARGET_PLATFORM}"
        exit 1
        ;;
    esac

    mkdir -p "${IOS_TARGET_PLATFORM}/${IOS_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=${OPENSSL_BASE_DIR}/${IOS_TARGET_PLATFORM}/

    cd "$LIBGIT2_FULL_PATH"
    rm -rf "build-${IOS_TARGET_PLATFORM}"
    mkdir "build-${IOS_TARGET_PLATFORM}"
    cd "build-${IOS_TARGET_PLATFORM}"

    export PKG_CONFIG_PATH=${IOS_LIB_ROOT}/${IOS_TARGET_PLATFORM}/lib/pkgconfig/:${IOS_LIB_ROOT}/openssl-lib/${IOS_TARGET_PLATFORM}/lib/pkgconfig/
    cmake ../ \
        -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR} \
        -DOPENSSL_INCLUDE_DIR=${OPENSSL_ROOT_DIR}/include \
        -DOPENSSL_SSL_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libssl.a \
        -DOPENSSL_CRYPTO_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libcrypto.a \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_IOS_DIR}/ios.toolchain.cmake \
        -DPLATFORM=$CMAKE_PLATFORM_NAME \
        -DCMAKE_INSTALL_PREFIX=${IOS_LIB_ROOT}/${IOS_TARGET_PLATFORM} \
        -DBUILD_SHARED_LIBS=false \
        -DBUILD_CLAR=false

    if [ $? -ne 0 ]; then
        echo "Error executing cmake"
        exit 1
    fi

    cmake --build . --config Release --target install
    if [ $? -ne 0 ]; then
        echo "Error building for platform:${IOS_TARGET_PLATFORM}"
        exit 1
    fi
done
