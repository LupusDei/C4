// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StoryboardFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "StoryboardFeature", targets: ["StoryboardFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
    ],
    targets: [
        .target(
            name: "StoryboardFeature",
            dependencies: [
                "CoreKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/StoryboardFeature"
        ),
        .testTarget(
            name: "StoryboardFeatureTests",
            dependencies: ["StoryboardFeature"],
            path: "Tests/StoryboardFeatureTests"
        ),
    ]
)
