#! /usr/bin/env bash

set -eux

if [ -z "$OPENSSL_BASE_DIR" ]; then
    echo "Missing $OPENSSL_BASE_DIR"
    exit 1
fi

./get-cmake-config.sh
CMAKE_IOS_DIR="$(pwd)/ios-cmake"

LIBSSH2_FULL_VERSION="libssh2-1.8.2"
if [ ! -f "$LIBSSH2_FULL_VERSION.tar.gz" ]; then
    curl -O https://www.libssh2.org/download/$LIBSSH2_FULL_VERSION.tar.gz
fi
tar -xvzf $LIBSSH2_FULL_VERSION.tar.gz

cd $LIBSSH2_FULL_VERSION
LIBSSH2_FULL_PATH=$(pwd)

IOS_LIB_ROOT=$(pwd)/libs/libssh2
rm -rf "${IOS_LIB_ROOT:?}/*"

#for IOS_TARGET_PLATFORM in armv7s arm64 x86_64; do
for IOS_TARGET_PLATFORM in armv7s; do
    echo "Building libssh2 for ${IOS_TARGET_PLATFORM}"
    mkdir -p "${IOS_TARGET_PLATFORM}/${IOS_TARGET_PLATFORM}"

    export OPENSSL_ROOT_DIR=${OPENSSL_BASE_DIR}/${IOS_TARGET_PLATFORM}/

    cd "$LIBSSH2_FULL_PATH"
    rm -rf "build-${IOS_TARGET_PLATFORM}"
    mkdir "build-${IOS_TARGET_PLATFORM}"
    cd "build-${IOS_TARGET_PLATFORM}"

    CMAKE_PLATFORM_NAME="OS"

    cmake ../ \
        -DOPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR} \
        -DOPENSSL_INCLUDE_DIR=${OPENSSL_ROOT_DIR}/include \
        -DOPENSSL_SSL_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libssl.a \
        -DOPENSSL_CRYPTO_LIBRARY=${OPENSSL_ROOT_DIR}/lib/libcrypto.a \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_IOS_DIR}/ios.toolchain.cmake \
        -DPLATFORM=$CMAKE_PLATFORM_NAME \
        -DCMAKE_INSTALL_PREFIX=${IOS_LIB_ROOT}/${IOS_TARGET_PLATFORM}

    if [ $? -ne 0 ]; then
        echo "Error executing cmake"
        exit 1
    fi

    cmake --build . --config Release --target install
    if [ $? -ne 0 ]; then
        echo "Error building for platform:${ANDROID_TARGET_PLATFORM}"
        exit 1
    fi
done
