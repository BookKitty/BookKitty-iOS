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
            name: "BookRecommendationKit",
            targets: ["BookRecommendationKit"]
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
    ],
    targets: [
        .target(
            name: "BookMatchKit",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"), // ✅ RxCocoa 참조 정확히 수정
                "SwiftFormat",
                "BookMatchCore", "BookMatchAPI", "BookMatchStrategy",
            ],
            resources: [
                .process("Resources/MyObjectDetector5_1.mlmodel"), // ✅ CoreML 모델 포함
            ]
        ),
        .target(
            name: "BookRecommendationKit",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"), // ✅ RxCocoa 참조 정확히 수정
                "SwiftFormat",
                "BookMatchCore", "BookMatchAPI", "BookMatchStrategy",
            ]
        ),
        .target(
            name: "BookMatchStrategy",
            dependencies: [
                "SwiftFormat",
                "BookMatchCore",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"), // ✅ RxCocoa 참조 정확히 수정
            ]
        ),
        .target(
            name: "BookMatchCore",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"), // ✅ RxCocoa 참조 정확히 수정
                "SwiftFormat",
            ]
        ),
        .target(
            name: "BookMatchAPI",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"), // ✅ RxCocoa 참조 정확히 수정
                "SwiftFormat",
                "BookMatchCore",
                .product(name: "NetworkKit", package: "NetworkKit"),
            ]
        ),
        .testTarget(
            name: "BookMatchKitTests",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxTest", package: "RxSwift"), // ✅ RxTest 추가 (테스트 라이브러리)
                "SwiftFormat",
                "BookMatchKit", "BookRecommendationKit", "BookMatchCore",
            ]
        ),
    ]
)
