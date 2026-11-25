// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HTTPTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "httptest",
            targets: ["HTTPTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Path.git", branch: "master"),
        .package(url: "https://github.com/swift-tooling/TestFlows.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "HTTPTestFlows",
            dependencies: [
                .product(name: "HTTP", package: "HTTP"),
                .product(name: "Path", package: "Path"),
                .product(name: "TestFlows", package: "TestFlows"),
            ]
        ),
    ]
)
