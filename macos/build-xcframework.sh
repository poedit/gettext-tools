#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

. ./versions.config

: "${GETTEXT_VERSION:?}"

name=GettextTools
build_dir=build/macos
archive_path="$build_dir/macosx.xcarchive"
xcframework_path="$build_dir/$name.xcframework"
package_path="$build_dir/$name-package"
zip_name="$name.xcframework.zip"
zip_path="$build_dir/$zip_name"
url="https://github.com/poedit/gettext-tools/releases/download/v$GETTEXT_VERSION/$zip_name"

mkdir -p "$build_dir"
rm -rf "$archive_path" "$xcframework_path" "$package_path" "$zip_path"

xcodebuild archive \
    -quiet \
    -sdk macosx \
    -archivePath "$archive_path" \
    -scheme "$name"

xcodebuild -create-xcframework \
    -output "$xcframework_path" \
    -archive "$archive_path" \
    -framework "$name.framework"

mkdir -p "$package_path/bin"
cp -a "$xcframework_path" "$package_path/"

helpers_path="$(find "$package_path/$name.xcframework" -path "*/$name.framework/Versions/A/Helpers" -type d -print -quit)"
helpers_path="${helpers_path#$package_path/}"
(
    cd "$package_path/bin"
    ln -s "../$helpers_path"/* .
)

(
    cd "$package_path"
    ditto -c -k --sequesterRsrc . "../$zip_name"
)

checksum="$(swift package compute-checksum "$zip_path")"

url="$url" checksum="$checksum" perl -0pi -e '
    s|(url:\s*")[^"]+(")|$1$ENV{url}$2|s
        or die "error: binary target URL not found\n";
    s|(checksum:\s*")[0-9a-f]{64}(")|$1$ENV{checksum}$2|s
        or die "error: binary target checksum not found\n";
' Package.swift

cat <<EOF
Created $zip_path
Updated Package.swift
Release URL: $url
Checksum: $checksum
EOF
