// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeoImage",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "NeoImage",
            targets: ["NeoImage"]
        ),
    ],
    targets: [
        .target(
            name: "NeoImage"
        ),
        .testTarget(
            name: "NeoImageTests",
            dependencies: ["NeoImage"]
        ),
    ]
)
