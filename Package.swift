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
            url: "https://github.com/poedit/gettext-tools/releases/download/v1.0/GettextTools.xcframework.zip",
            checksum: "04dcba5b92ad8d0ff475e29baee72180f096431af220a858f0d29a9ec8988dcd"
        ),
    ]
)
