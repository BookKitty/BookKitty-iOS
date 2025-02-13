// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [
        .iOS(.v16), // 여기에서 iOS 버전을 변경
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to
        // other packages.
        .library(
            name: "DesignSystem",
            targets: ["DesignSystem"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/devxoul/Then.git", from: "3.0.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "Then", package: "Then"),
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            resources: [
                .process("Resource/Fonts"),
                .process("Resource/Colors.xcassets"),
                .process("Resource/Images.xcassets"),
                .process("Resource/LottieJson"),
            ]
        ),
    ]
)
