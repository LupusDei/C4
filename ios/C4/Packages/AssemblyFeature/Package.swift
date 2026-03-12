// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AssemblyFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "AssemblyFeature", targets: ["AssemblyFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
        .package(path: "../DesignKit"),
    ],
    targets: [
        .target(
            name: "AssemblyFeature",
            dependencies: [
                "CoreKit",
                "DesignKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/AssemblyFeature"
        ),
        .testTarget(
            name: "AssemblyFeatureTests",
            dependencies: ["AssemblyFeature"],
            path: "Tests/AssemblyFeatureTests"
        ),
    ]
)
