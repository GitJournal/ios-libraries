#!/usr/bin/env bash

set -eu

if [ -d "ios-cmake" ]; then
    echo "Already exists"
    exit
fi

git clone https://github.com/leetal/ios-cmake.git
