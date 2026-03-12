// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "C4",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"]),
        .library(name: "PromptFeature", targets: ["PromptFeature"]),
        .library(name: "ProjectFeature", targets: ["ProjectFeature"]),
        .library(name: "GenerateFeature", targets: ["GenerateFeature"]),
        .library(name: "AssemblyFeature", targets: ["AssemblyFeature"]),
        .library(name: "CreditFeature", targets: ["CreditFeature"]),
        .library(name: "StoryboardFeature", targets: ["StoryboardFeature"]),
        .library(name: "DesignKit", targets: ["DesignKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "DesignKit",
            path: "Packages/DesignKit/Sources/DesignKit"
        ),
        .target(
            name: "CoreKit",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/CoreKit/Sources/CoreKit"
        ),
        .testTarget(
            name: "CoreKitTests",
            dependencies: ["CoreKit"],
            path: "Packages/CoreKit/Tests/CoreKitTests"
        ),
        .target(
            name: "PromptFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/PromptFeature/Sources/PromptFeature"
        ),
        .testTarget(
            name: "PromptFeatureTests",
            dependencies: ["PromptFeature"],
            path: "Packages/PromptFeature/Tests/PromptFeatureTests"
        ),
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
            path: "Packages/ProjectFeature/Sources/ProjectFeature"
        ),
        .testTarget(
            name: "ProjectFeatureTests",
            dependencies: ["ProjectFeature"],
            path: "Packages/ProjectFeature/Tests/ProjectFeatureTests"
        ),
        .target(
            name: "GenerateFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                "PromptFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/GenerateFeature/Sources/GenerateFeature"
        ),
        .testTarget(
            name: "GenerateFeatureTests",
            dependencies: ["GenerateFeature"],
            path: "Packages/GenerateFeature/Tests/GenerateFeatureTests"
        ),
        .target(
            name: "AssemblyFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/AssemblyFeature/Sources/AssemblyFeature"
        ),
        .testTarget(
            name: "AssemblyFeatureTests",
            dependencies: ["AssemblyFeature"],
            path: "Packages/AssemblyFeature/Tests/AssemblyFeatureTests"
        ),
        .target(
            name: "StoryboardFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/StoryboardFeature/Sources/StoryboardFeature"
        ),
        .testTarget(
            name: "StoryboardFeatureTests",
            dependencies: ["StoryboardFeature"],
            path: "Packages/StoryboardFeature/Tests/StoryboardFeatureTests"
        ),
        .target(
            name: "CreditFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Packages/CreditFeature/Sources/CreditFeature"
        ),
        .testTarget(
            name: "CreditFeatureTests",
            dependencies: ["CreditFeature"],
            path: "Packages/CreditFeature/Tests/CreditFeatureTests"
        ),
    ]
)
