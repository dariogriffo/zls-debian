ZIG_VERSION=$1
BUILD_VERSION=$2

UNAME_ARCH=$(uname -m)
case "$UNAME_ARCH" in
  x86_64)      ZLS_ARCH="x86_64-linux";      DEB_ARCH="amd64"   ;;
  aarch64)     ZLS_ARCH="aarch64-linux";     DEB_ARCH="arm64"   ;;
  armv7l)      ZLS_ARCH="arm-linux";         DEB_ARCH="armhf"   ;;
  i686)        ZLS_ARCH="x86-linux";         DEB_ARCH="i386"    ;;
  ppc64le)     ZLS_ARCH="powerpc64le-linux"; DEB_ARCH="ppc64el" ;;
  riscv64)     ZLS_ARCH="riscv64-linux";     DEB_ARCH="riscv64" ;;
  s390x)       ZLS_ARCH="s390x-linux";       DEB_ARCH="s390x"   ;;
  loongarch64) ZLS_ARCH="loongarch64-linux"; DEB_ARCH="loong64" ;;
  *) echo "Unsupported architecture: $UNAME_ARCH"; exit 1 ;;
esac

mkdir zls_download
cd zls_download
wget https://github.com/zigtools/zls/releases/download/$ZIG_VERSION/zls-$ZLS_ARCH.tar.xz
tar -xf zls-$ZLS_ARCH.tar.xz
cd ..
mv zls_download/zls .

declare -a arr=("jammy" "noble" "questing")
for i in "${arr[@]}"
do
  UBUNTU_DIST=$i
  FULL_VERSION=$ZIG_VERSION-${BUILD_VERSION}+${UBUNTU_DIST}_${DEB_ARCH}_ubu

  docker build . -f meta_Dockerfile.ubu -t zls-ubuntu-$UBUNTU_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION --build-arg DEB_ARCH=$DEB_ARCH
  id="$(docker create zls-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/zls_$FULL_VERSION.deb - > ./zls_$FULL_VERSION.deb
  tar -xf ./zls_$FULL_VERSION.deb

  docker build . -f zero_Dockerfile.ubu -t zls-ubuntu-$UBUNTU_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION --build-arg DEB_ARCH=$DEB_ARCH
  id="$(docker create zls-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/zls-zero_$FULL_VERSION.deb - > ./zls-zero_$FULL_VERSION.deb
  tar -xf ./zls-zero_$FULL_VERSION.deb

done

rm -fRd zls_download
rm -f zls
