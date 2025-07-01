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
        .target(
            name: "EdgeLLM",
            dependencies: ["MLCRuntime"],
            path: "Sources/EdgeLLM",
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        ),
        .binaryTarget(
            name: "MLCRuntime",
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.2.0/MLCRuntime.xcframework.zip",
            checksum: "f555cf5b549575d5dba7c6d4bf27a928c04a5620d15c5474fa7bb3efa12b6a23"
        )
    ]
)