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
            name: "BookOCRKit",
            targets: ["BookOCRKit"]
        ),
        .library(
            name: "BookRecommendationKit",
            targets: ["BookRecommendationKit"]
        ),
        .library(
            name: "BookMatchService",
            targets: ["BookMatchService"]
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
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.8.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
        .package(path: "../NetworkKit"),
        .package(path: "../LogKit"),
    ],
    targets: [
        .target(
            name: "BookOCRKit",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookMatchCore", "BookMatchAPI", "BookMatchStrategy", "BookMatchService",
                .product(name: "LogKit", package: "LogKit"),
            ]
        ),
        .target(
            name: "BookRecommendationKit",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookMatchCore", "BookMatchAPI", "BookMatchService",
                .product(name: "LogKit", package: "LogKit"),
            ]
        ),
        .target(
            name: "BookMatchStrategy",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookMatchCore",
                .product(name: "LogKit", package: "LogKit"),
            ]
        ),
        .target(
            name: "BookMatchCore",
            dependencies: [
                "RxSwift", "SwiftFormat",
                .product(name: "LogKit", package: "LogKit"),
            ]
        ),
        .target(
            name: "BookMatchService",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookMatchCore", "BookMatchAPI",
                .product(name: "LogKit", package: "LogKit"),
            ],
            resources: [
                .process("Resources/MyObjectDetector5_1.mlmodel"),
            ]
        ),
        .target(
            name: "BookMatchAPI",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookMatchCore",
                .product(name: "NetworkKit", package: "NetworkKit"),
                .product(name: "LogKit", package: "LogKit"),
            ]
        ),
        .testTarget(
            name: "BookMatchKitTests",
            dependencies: [
                "RxSwift", "SwiftFormat",
                "BookOCRKit", "BookRecommendationKit", "BookMatchCore",
            ],
            resources: [
                .process("Resources/images"),
            ]
        ),
    ]
)
