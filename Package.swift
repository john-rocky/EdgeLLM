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
            url: "https://github.com/john-rocky/EdgeLLM/releases/download/v0.3.0/MLCRuntime.xcframework.zip",
            checksum: "ccbf13400898c99eaddbb9b82eac0174747fc462a8f6a020a838d919f6d04514"
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