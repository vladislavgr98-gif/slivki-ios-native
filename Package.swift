// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Slivki",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "Slivki", targets: ["Slivki"])
    ],
    targets: [
        .target(
            name: "Slivki",
            path: "Slivki",
            exclude: ["SlivkiApp.swift"]
        ),
        .testTarget(
            name: "SlivkiTests",
            dependencies: ["Slivki"],
            path: "SlivkiTests"
        )
    ]
)
