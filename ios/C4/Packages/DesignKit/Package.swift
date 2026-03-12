// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignKit", targets: ["DesignKit"]),
    ],
    targets: [
        .target(
            name: "DesignKit",
            path: "Sources/DesignKit"
        ),
    ]
)
