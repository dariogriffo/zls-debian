ZIG_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("jammy" "noble" "questing")
for i in "${arr[@]}"
do
  UBUNTU_DIST=$i
  FULL_VERSION=$ZIG_VERSION-${BUILD_VERSION}+${UBUNTU_DIST}_amd64_ubu

  docker build . -f meta_Dockerfile.ubu -t zls-ubuntu-$UBUNTU_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create zls-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/zls_$FULL_VERSION.deb - > ./zls_$FULL_VERSION.deb
  tar -xf ./zls_$FULL_VERSION.deb

  docker build . -f zero_Dockerfile.ubu -t zls-ubuntu-$UBUNTU_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg UBUNTU_DIST=$UBUNTU_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION
  id="$(docker create zls-ubuntu-$UBUNTU_DIST)"
  docker cp $id:/zls-zero_$FULL_VERSION.deb - > ./zls-zero_$FULL_VERSION.deb
  tar -xf ./zls-zero_$FULL_VERSION.deb

done
