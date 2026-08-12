// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTTP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "HTTP",
            targets: ["HTTP"]
        ),
        .executable(
            name: "httptest",
            targets: ["HTTPTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Parsers.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Parsing.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Path.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "HTTP",
            dependencies: [
                .product(name: "Primitives", package: "Primitives"),
                .product(name: "Parsers", package: "Parsers"),
                .product(name: "Parsing", package: "Parsing"),
                .product(name: "Path", package: "Path"),
                .product(name: "TestFlows", package: "TestFlows"),
            ]
        ),
        .executableTarget(
            name: "HTTPTestFlows",
            dependencies: [
                "HTTP",
                "Path",
                "TestFlows",
            ]
        ),
    ]
)
