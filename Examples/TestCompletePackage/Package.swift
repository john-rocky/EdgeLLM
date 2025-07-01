// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TestCompletePackage",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/john-rocky/EdgeLLM", from: "0.1.1")
    ],
    targets: [
        .executableTarget(
            name: "TestCompletePackage",
            dependencies: [
                .product(name: "EdgeLLM", package: "EdgeLLM")
            ]
        )
    ]
)