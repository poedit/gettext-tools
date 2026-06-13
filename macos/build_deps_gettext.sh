#!/bin/sh

set -e

. ../versions.config

GETTEXT_TARBALL="gettext-$GETTEXT_VERSION.tar.xz"
GETTEXT_URL="https://ftpmirror.gnu.org/gnu/gettext/$GETTEXT_TARBALL"
GETTEXT_DOWNLOAD="$DEPS_BUILD_DIR/$GETTEXT_TARBALL"

download_gettext() {
    if [ -f "$GETTEXT_DOWNLOAD" ]; then
        actual_sha256="$(shasum -a256 "$GETTEXT_DOWNLOAD" | cut -f1 -d' ')"
        if [ "$actual_sha256" = "$GETTEXT_SHA256" ]; then
            return
        fi
    fi

    echo "Downloading $GETTEXT_URL..."
    curl --fail --location --retry 5 --retry-all-errors -o "$GETTEXT_DOWNLOAD.tmp" "$GETTEXT_URL"
    actual_sha256="$(shasum -a256 "$GETTEXT_DOWNLOAD.tmp" | cut -f1 -d' ')"
    if [ "$actual_sha256" != "$GETTEXT_SHA256" ]; then
        echo "error: checksum mismatch for $GETTEXT_TARBALL" >&2
        rm -f "$GETTEXT_DOWNLOAD.tmp"
        exit 1
    fi
    mv "$GETTEXT_DOWNLOAD.tmp" "$GETTEXT_DOWNLOAD"
}

download_gettext

# Fake Java binaries so gettext's configure/build scripts don't invoke the
# system Java tools just because they happen to be installed.
helpers_dir="$DEPS_BUILD_DIR/helpers"
mkdir -p "$helpers_dir"
touch "$helpers_dir/java" "$helpers_dir/javac"
chmod +x "$helpers_dir/java" "$helpers_dir/javac"
PATH="$helpers_dir:$PATH"
export PATH

rm -rf "$WORKDIR" "$DESTDIR"
mkdir -p "$WORKDIR" "$INTDIR"

echo "Building gettext for $ARCH..."
tar -x -f "$GETTEXT_DOWNLOAD" -C "$WORKDIR" --strip-components 1
for patch in ../patches/*.patch; do
    [ -e "$patch" ] || continue
    patch -d "$WORKDIR" -p1 < "$patch"
done

cd "$WORKDIR"

# Prevent automake regeneration.
find . -name aclocal.m4 -exec touch {} +
find . -name configure -exec touch {} +
find . -name config.h.in -exec touch {} +
find . -name Makefile.in -exec touch {} +
find . -name '*.1' -exec touch {} +
find . -name '*.3' -exec touch {} +
find . -name '*.html' -exec touch {} +

# Prevent running msgfmt.
find . -name '*.gmo' -exec touch {} +

# GNU gettext checks against and won't use macOS-provided iconv(), see here:
# https://mail.gnu.org/archive/html/bug-gnulib/2024-05/msg00375.html
# They are not wrong about it being POSIX-broken, but it doesn't seem to
# materially affect Poedit's use (conversions of catalogs are avoided and
# other contexts are OK with this particular issue). And as this is a
# runtime difference, we've been using "bad" iconv() implementation
# for over a year, so...
#
# Hence this:
#     'am_cv_func_iconv_works=yes'
#
#
# On macOS 10.15 Vista, mere use of CFLocale or CFPreferences from command line
# executables, as done by gettext tools, triggers UAC prompts if the hosting app
# happens to be in e.g. ~/Desktop or ~/Downloads. As we don't care for these
# capabilities in gettext tools anyway, just disable them as the lesser evil.
#
# Hence these:
#     'gt_cv_func_CFPreferencesCopyAppValue=no',
#     'gt_cv_func_CFLocaleCopyPreferredLanguages=no',
./configure \
    --prefix=/42 \
    --bindir=/42/Helpers \
    --libdir=/42/Frameworks \
    --datarootdir=/42/Resources \
    CC="$CC" \
    CXX="$CXX" \
    CFLAGS="$CFLAGS" \
    CXXFLAGS="$CXXFLAGS" \
    LDFLAGS="$LDFLAGS" \
    am_cv_func_iconv_works=yes \
    gt_cv_func_CFPreferencesCopyAppValue=no \
    gt_cv_func_CFLocaleCopyPreferredLanguages=no \
    --cache-file=$CONFIG_CACHE \
    --with-libiconv-prefix="$SDKROOT/usr" \
    --with-libxml2-prefix="$SDKROOT/usr" \
    --disable-static \
    --disable-java \
    --disable-csharp \
    --disable-rpath \
    --disable-dependency-tracking \
    --enable-silent-rules \
    --enable-relocatable

make
make install -j1 DESTDIR="$DESTDIR"

# Delete unwanted tools.
rm -f \
    "$DESTDIR"/42/Helpers/autopoint \
    "$DESTDIR"/42/Helpers/envsubst \
    "$DESTDIR"/42/Helpers/gettext* \
    "$DESTDIR"/42/Helpers/ngettext \
    "$DESTDIR"/42/Helpers/po-fetch \
    "$DESTDIR"/42/Helpers/spit \
    "$DESTDIR"/42/Helpers/recode-sr-latin

# Fix dylib references to work inside the framework.
"$TOP_SRCDIR/fixup-dylib-deps.sh" /42/Frameworks @rpath "$DESTDIR"/42/Frameworks "$DESTDIR"/42/Helpers/*

# Move files out of the fake install prefix.
mv "$DESTDIR"/42/* "$DESTDIR"/
rmdir "$DESTDIR"/42 2>/dev/null || true

# Strip executables and libraries.
for binary in msgfmt msgmerge msgunfmt msgcat xgettext; do
    [ -f "$DESTDIR/Helpers/$binary" ] && strip -S -u -r "$DESTDIR/Helpers/$binary"
done
for dylib in "$DESTDIR"/Frameworks/lib*.*.dylib; do
    [ -f "$dylib" ] && strip -S -x "$dylib"
done

rm -rf "$WORKDIR"
touch "$INTDIR/$target.done"
