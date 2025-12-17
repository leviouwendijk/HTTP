// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTP",
    products: [
        .library(
            name: "HTTP",
            targets: ["HTTP"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Parsers.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "HTTP",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Parsers", package: "Parsers"),
            ]
        ),
        .testTarget(
            name: "HTTPTests",
            dependencies: ["HTTP"]
        ),
    ]
)
