// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CreditFeature",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "CreditFeature", targets: ["CreditFeature"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        .package(path: "../CoreKit"),
    ],
    targets: [
        .target(
            name: "CreditFeature",
            dependencies: [
                "CoreKit",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ],
            path: "Sources/CreditFeature"
        ),
        .testTarget(
            name: "CreditFeatureTests",
            dependencies: ["CreditFeature"],
            path: "Tests/CreditFeatureTests"
        ),
    ]
)
