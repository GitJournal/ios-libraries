#! /usr/bin/env bash

set -eux
cd "$(dirname "$0")"

rm -rf release
mkdir -p release/include
RELEASE_DIR=$(pwd)/release

cd libs

cd libssh2/
lipo -create arm/lib/libssh2.a x86_64/lib/libssh2.a -o $RELEASE_DIR/libssh2.framework
cp -r arm/include/* $RELEASE_DIR/include/
cd ../

cd libgit2/
lipo -create arm/lib/libgit2.a x86_64/lib/libgit2.a -o $RELEASE_DIR/libgit2.framework
cp -r arm/include/* $RELEASE_DIR/include/
cd ../

tar cvzf $RELEASE_DIR/../release.tgz -C $RELEASE_DIR .
