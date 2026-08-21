#!/bin/bash
ZLS_VERSION=$1
ZIG_VERSION=$2
BUILD_VERSION=$3
ARCH=${4:-amd64}  # Default to amd64 if no architecture specified

./build_zls_debian.sh $1 $2 $3 $4
./build_zls_ubuntu.sh $1 $2 $3 $4
./build_src.sh $1 $3
