#!/bin/sh

set -e

cd "$(dirname "$0")"

target="$1"
action="${2:-build}"
script="./build_deps_$target.sh"

if [ -z "$target" ]; then
    echo "Usage: $0 <target> [clean]" >&2
    exit 1
fi

if [ ! -x "$script" ]; then
    echo "error: $script not found or not executable" >&2
    exit 1
fi

for var in DEPS_BUILD_DIR SDKROOT MACOSX_DEPLOYMENT_TARGET CONFIGURATION ARCHS; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
        echo "error: $var is not set" >&2
        exit 1
    fi
done

mkdir -p "$DEPS_BUILD_DIR"

if [ "$action" = clean ]; then
    rm -rf "$DEPS_BUILD_DIR"/*
    exit
fi

# Include Homebrew binaries on PATH if not there yet:
# Also make sure that GNU sed and recent version of GNU make are used, as
# GNU gettext requires that for compilation:

add_homebrew_paths() {
    for root in /opt/homebrew /usr/local; do
        [ -d "$root/bin" ] && PATH="$root/bin:$PATH"
        for pkg in "$@"; do
            prefix="$root/opt/$pkg"
            [ -d "$prefix/libexec/gnubin" ] && PATH="$prefix/libexec/gnubin:$PATH"
            [ -d "$prefix/bin" ] && PATH="$prefix/bin:$PATH"
        done
    done
    return 0
}

add_homebrew_paths gnu-sed make bison curl
export PATH

# Prevent Homebrew libraries from being picked up by configure checks. We want
# to build against the macOS SDK, not against the local machine's Homebrew tree.
unset PKG_CONFIG_PATH
export PKG_CONFIG_LIBDIR="$SDKROOT/usr/lib/pkgconfig:$SDKROOT/usr/share/pkgconfig"

# Check that the tools have appropriate versions.
if ! make --version 2>/dev/null | grep -q 'GNU Make'; then
    echo "Error: GNU make required (brew install make)." >&2
    exit 1
fi
if make --version | head -n1 | grep -q 'GNU Make 3\.'; then
    echo "Error: GNU make >= 4 required (brew install make)." >&2
    exit 1
fi

if ! sed --version 2>/dev/null | grep -q 'GNU sed'; then
    echo "Error: GNU sed required (brew install gnu-sed)." >&2
    exit 1
fi

if yacc --version | head -n1 | grep -q 'GNU Bison 2\.'; then
    echo "Error: GNU bison >= 3 required (brew install bison)." >&2
    exit 1
fi

# Use ccache if present, but don't require it.
ccache_prefix="$(brew --prefix ccache 2>/dev/null || true)"
if [ -n "$ccache_prefix" ] && [ -d "$ccache_prefix/libexec" ]; then
    CC="$ccache_prefix/libexec/clang"
    CXX="$ccache_prefix/libexec/clang++"
else
    CC=clang
    CXX=clang++
fi
export CC CXX

# Don't use unoptimized debug builds here: they make gettext tools too slow and
# don't buy much for this dependency build. Keep debug symbols in Debug builds.
if [ "$CONFIGURATION" = "Debug" ]; then
    cflags_config="-O2 -ggdb3"
    ldflags_config="-O2 -ggdb3"
else
    cflags_config="-O2"
    ldflags_config=""
fi

ncpu="$(sysctl -n hw.ncpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
MAKEFLAGS="-j$ncpu -l$ncpu"
TOP_SRCDIR="$(pwd)"
export target MAKEFLAGS TOP_SRCDIR

# Don't produce an Xcode error if the build is stopped for other reasons.
trap "exit 0" INT

for ARCH in $ARCHS; do
    INTDIR="$DEPS_BUILD_DIR/_intermediate.$ARCH"
    WORKDIR="$INTDIR/$target"
    DESTDIR="$DEPS_BUILD_DIR/$target.$ARCH"
    CONFIG_CACHE="$INTDIR/$target.config.cache"

    cflags_sdk="-arch $ARCH -isysroot $SDKROOT -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
    CFLAGS="$cflags_sdk $cflags_config -w"
    CXXFLAGS="$cflags_sdk $cflags_config -stdlib=libc++ -w"
    LDFLAGS="$cflags_sdk -Wl,-syslibroot,$SDKROOT -Wl,-macosx_version_min,$MACOSX_DEPLOYMENT_TARGET $ldflags_config"

    export ARCH INTDIR WORKDIR DESTDIR CONFIG_CACHE CFLAGS CXXFLAGS LDFLAGS
    "$script"
done

./merge-archs.sh "$DEPS_BUILD_DIR/$target"
