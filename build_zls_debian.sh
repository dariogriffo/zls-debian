#!/bin/bash
ZLS_VERSION=$1
ZIG_VERSION=$2
BUILD_VERSION=$3
ARCH=${4:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$ZLS_VERSION" ] || [ -z "$ZIG_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <zls_version> <zig_version> <build_version> [architecture]"
    echo "Example: $0 0.16.0 0.16.0 1 arm64"
    echo "Example: $0 0.16.0 0.16.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armhf, i386, ppc64el, riscv64, s390x, loong64, all"
    exit 1
fi

# Map a Debian architecture to the zls release asset. Every zls binary is
# statically linked, so all of them run on every suite we target and the
# packages need no dependencies. zls-arm-linux is EABI5 hard-float (VFP
# registers), which is armhf rather than armel.
get_zls_arch() {
    case "$1" in
        "amd64")   echo "x86_64-linux"      ;;
        "arm64")   echo "aarch64-linux"     ;;
        "armhf")   echo "arm-linux"         ;;
        "i386")    echo "x86-linux"         ;;
        "ppc64el") echo "powerpc64le-linux" ;;
        "riscv64") echo "riscv64-linux"     ;;
        "s390x")   echo "s390x-linux"       ;;
        "loong64") echo "loongarch64-linux" ;;
        *)         echo ""                  ;;
    esac
}

declare -a DISTS=("bookworm" "trixie" "forky" "sid")

build_architecture() {
    local build_arch=$1
    local zls_arch

    zls_arch=$(get_zls_arch "$build_arch")
    if [ -z "$zls_arch" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, armhf, i386, ppc64el, riscv64, s390x, loong64"
        return 1
    fi

    echo "Building for architecture: $build_arch using zls-$zls_arch"

    rm -rf "dist/$build_arch" || true
    mkdir -p "dist/$build_arch"

    if ! wget -q "https://github.com/zigtools/zls/releases/download/${ZLS_VERSION}/zls-${zls_arch}.tar.xz" \
            -O "dist/$build_arch/zls.tar.xz"; then
        echo "❌ Failed to download zls-${zls_arch}.tar.xz"
        return 1
    fi
    if ! tar -xf "dist/$build_arch/zls.tar.xz" -C "dist/$build_arch"; then
        echo "❌ Failed to extract zls-${zls_arch}.tar.xz"
        return 1
    fi
    rm -f "dist/$build_arch/zls.tar.xz"

    if [ ! -s "dist/$build_arch/zls" ]; then
        echo "❌ Unexpected archive layout for $build_arch (no zls binary)"
        return 1
    fi

    for dist in "${DISTS[@]}"; do
        FULL_VERSION="$ZLS_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        for spec in "zls:meta_Dockerfile" "zls-zero:zero_Dockerfile"; do
            pkg="${spec%%:*}"
            dockerfile="${spec##*:}"

            if ! docker build . -f "$dockerfile" -t "$pkg-$dist-$build_arch" \
                --build-arg ZLS_VERSION="$ZLS_VERSION" \
                --build-arg ZIG_VERSION="$ZIG_VERSION" \
                --build-arg DEBIAN_DIST="$dist" \
                --build-arg BUILD_VERSION="$BUILD_VERSION" \
                --build-arg FULL_VERSION="$FULL_VERSION" \
                --build-arg DEB_ARCH="$build_arch"; then
                echo "❌ Failed to build $pkg image for $dist on $build_arch"
                return 1
            fi

            id="$(docker create "$pkg-$dist-$build_arch")"
            if ! docker cp "$id:/${pkg}_${FULL_VERSION}.deb" - > "./${pkg}_${FULL_VERSION}.deb"; then
                echo "❌ Failed to extract $pkg .deb for $dist on $build_arch"
                return 1
            fi
            if ! tar -xf "./${pkg}_${FULL_VERSION}.deb"; then
                echo "❌ Failed to extract $pkg .deb contents for $dist on $build_arch"
                return 1
            fi
        done
    done

    rm -rf "dist/$build_arch" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

if [ "$ARCH" = "all" ]; then
    echo "🚀 Building zls $ZLS_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    ARCHITECTURES=("amd64" "arm64" "armhf" "i386" "ppc64el" "riscv64" "s390x" "loong64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la zls_*.deb zls-zero_*.deb
else
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
