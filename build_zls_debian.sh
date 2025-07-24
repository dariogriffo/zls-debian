ZIG_VERSION=$1
BUILD_VERSION=$2
declare -a arr=("bookworm" "trixie" "sid")
for i in "${arr[@]}"
do
  DEBIAN_DIST=$i
  FULL_VERSION=$ZIG_VERSION-${BUILD_VERSION}+${DEBIAN_DIST}_amd64
  
  docker build . -t zls-$DEBIAN_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION -f meta_Dockerfile
  id="$(docker create zls-$DEBIAN_DIST)"
  docker cp $id:/zls_$FULL_VERSION.deb - > ./zls_$FULL_VERSION.deb
  tar -xf ./zls_$FULL_VERSION.deb

  docker build . -t zls-$DEBIAN_DIST --build-arg ZIG_VERSION=$ZIG_VERSION --build-arg DEBIAN_DIST=$DEBIAN_DIST --build-arg BUILD_VERSION=$BUILD_VERSION --build-arg FULL_VERSION=$FULL_VERSION -f zero_Dockerfile
  id="$(docker create zls-$DEBIAN_DIST)"
  docker cp $id:/zls-zero_$FULL_VERSION.deb - > ./zls-zero_$FULL_VERSION.deb
  tar -xf ./zls-zero_$FULL_VERSION.deb

done
