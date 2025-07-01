// swift-tools-version: 5.9
// Standalone version for Swift Package Manager
import PackageDescription

let package = Package(
    name: "EdgeLLM",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EdgeLLM",
            targets: ["EdgeLLM"]
        ),
    ],
    targets: [
        .target(
            name: "EdgeLLM",
            path: "Sources/EdgeLLM",
            exclude: ["Resources"],
            swiftSettings: [
                .unsafeFlags(["-enable-bare-slash-regex"])
            ]
        )
    ]
)