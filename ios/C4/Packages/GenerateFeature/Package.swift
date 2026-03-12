// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GenerateFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "GenerateFeature", targets: ["GenerateFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
        .package(path: "../DesignKit"),
        .package(path: "../PromptFeature"),
    ],
    targets: [
        .target(
            name: "GenerateFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                "PromptFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/GenerateFeature"
        ),
        .testTarget(
            name: "GenerateFeatureTests",
            dependencies: ["GenerateFeature"],
            path: "Tests/GenerateFeatureTests"
        ),
    ]
)
