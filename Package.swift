// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "GettextTools",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "GettextTools",
            targets: ["GettextTools"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "GettextTools",
            url: "https://github.com/poedit/gettext-tools/releases/download/0.26/GettextTools.xcframework.zip",
            checksum: "0000000000000000000000000000000000000000000000000000000000000000"
        ),
    ]
)
