// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "C4",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"]),
        .library(name: "ProjectFeature", targets: ["ProjectFeature"]),
        .library(name: "GenerateFeature", targets: ["GenerateFeature"]),
        .library(name: "AssemblyFeature", targets: ["AssemblyFeature"]),
        .library(name: "CreditFeature", targets: ["CreditFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
    ],
    targets: [
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
            name: "ProjectFeature",
            dependencies: [
                "CoreKit",
                "GenerateFeature",
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
            name: "CreditFeature",
            dependencies: [
                "CoreKit",
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
