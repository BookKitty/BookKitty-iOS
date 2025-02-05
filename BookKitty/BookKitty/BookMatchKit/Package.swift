// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BookMatchKit",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "BookMatchKit",
            targets: ["BookMatchKit"]
        ),
        .library(
            name: "BookMatchCore",
            targets: ["BookMatchCore"]
        ),
        .library(
            name: "BookMatchAPI",
            targets: ["BookMatchAPI"]
        ),
        .library(
            name: "BookMatchStrategy",
            targets: ["BookMatchStrategy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
    ],
    targets: [
        .target(
            name: "BookMatchCore",
            dependencies: ["SwiftFormat"]
        ),

        .target(
            name: "BookMatchAPI",
            dependencies: ["BookMatchCore", "SwiftFormat"]
        ),

        .target(
            name: "BookMatchStrategy",
            dependencies: ["BookMatchCore", "SwiftFormat"]
        ),

        .target(
            name: "BookMatchKit",
            dependencies: [
                "BookMatchCore",
                "BookMatchAPI",
                "BookMatchStrategy",
                "SwiftFormat",
            ]
        ),

        .testTarget(
            name: "BookMatchKitTests",
            dependencies: [
                "BookMatchKit",
                "BookMatchCore",
                "BookMatchAPI",
            ]
        ),
    ]
)
