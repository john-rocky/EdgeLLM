// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "MLCRuntime",
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.4.0/MLCRuntime.xcframework.zip",
            checksum: "3fc79c1d2c4a31f717dd943ec8b492183661c8e93c073c37c03dae1cefb89c66"
        ),
        .target(
            name: "EdgeLLM",
            dependencies: ["MLCRuntime"],
            path: "Sources/EdgeLLM",
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        )
    ]
)