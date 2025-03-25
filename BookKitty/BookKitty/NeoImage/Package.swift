// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeoImage",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "NeoImage", targets: ["NeoImage"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/onevcat/Kingfisher", from: "8.3.0"),
    ],
    targets: [
        .target(
            name: "NeoImage",
            path: "Sources"
        ),
        .testTarget(
            name: "ImageViewExtensionTests",
            dependencies: [
                "NeoImage",
                .product(name: "Kingfisher", package: "Kingfisher"),
            ]
        ),
    ]
)
