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
            url: "https://download.poedit.com/tmp/GettextTools-1.0-2.xcframework.zip",
            checksum: "7bfa5a1efb2fd903fc8f65bf699bb4a81766feedae9183cac595d63652d526f2"
        ),
    ]
)
