// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PromptFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "PromptFeature", targets: ["PromptFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
        .package(path: "../DesignKit"),
    ],
    targets: [
        .target(
            name: "PromptFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/PromptFeature"
        ),
        .testTarget(
            name: "PromptFeatureTests",
            dependencies: ["PromptFeature"],
            path: "Tests/PromptFeatureTests"
        ),
    ]
)
