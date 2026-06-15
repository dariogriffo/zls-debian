ZLS_VERSION=$1
ZIG_VERSION=$2
BUILD_VERSION=$3
./build_zls_debian.sh $1 $2 $3
./build_zls_ubuntu.sh $1 $2 $3
./build_src.sh $1 $3

