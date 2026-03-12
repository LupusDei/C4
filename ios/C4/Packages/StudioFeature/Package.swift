// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StudioFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "StudioFeature", targets: ["StudioFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
    ],
    targets: [
        .target(
            name: "StudioFeature",
            dependencies: [
                "CoreKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/StudioFeature"
        ),
        .testTarget(
            name: "StudioFeatureTests",
            dependencies: ["StudioFeature"],
            path: "Tests/StudioFeatureTests"
        ),
    ]
)
