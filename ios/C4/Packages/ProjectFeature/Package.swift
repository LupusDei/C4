// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ProjectFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "ProjectFeature", targets: ["ProjectFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
        .package(path: "../DesignKit"),
        .package(path: "../GenerateFeature"),
        .package(path: "../PromptFeature"),
        .package(path: "../StoryboardFeature"),
    ],
    targets: [
        .target(
            name: "ProjectFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                "GenerateFeature",
                "PromptFeature",
                "StoryboardFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/ProjectFeature"
        ),
        .testTarget(
            name: "ProjectFeatureTests",
            dependencies: ["ProjectFeature"],
            path: "Tests/ProjectFeatureTests"
        ),
    ]
)
