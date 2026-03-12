// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"]),
    ],
    targets: [
        .target(
            name: "DesignKit",
            path: "Sources/DesignKit"
        ),
        .testTarget(
            name: "DesignKitTests",
            dependencies: ["DesignKit"],
            path: "Tests/DesignKitTests"
        ),
    ]
)
